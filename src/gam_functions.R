library(tidyverse)  
library(ggplot2)
library(dplyr)
library(mgcv)
library(DHARMa)
library(MASS)
library(rgdal)
library(gridExtra)
source("https://gist.githubusercontent.com/TonyLadson/f37aab3e2ef517188a7f27166307c985/raw/0822970769bc90fcc28052a91b375399d665286e/UTM2deg.R")

get_ecomon_catch_data <- function(species, fname){
  catch_data = read.csv(fname)
  
  catch_data = dplyr::select(catch_data, -c("X", "year", "btm_temp", "btm_salt")) #drop unecsarry columns
  catch_data = dplyr::rename(catch_data, c("catch"=species)) # restrict to species of interest
  catch_data$btm_sub = factor(catch_data$btm_sub)
  return(catch_data)
}

convert_to_northing_easting <- function(lat, lon){
  coords.dec = SpatialPoints(cbind(lon, lat), proj4string=CRS("+proj=longlat"))
  coords.UTM = spTransform(coords.dec, CRS("+init=epsg:26983"))
  cs = coordinates(coords.UTM)
  colnames(cs)=c("easting", "northing")
  return(cs)
}

simulateNegbin <- function(modfit, nsims=250, offsetval=1){
  muval = predict(modfit, type = "response")*offsetval  #Get the mean with offset
  nObs = length(muval)  
  thetaval = modfit$family$getTheta(trans=TRUE)  #Get theta not log transforme
  sim = replicate(nsims,rnbinom(nObs,mu=muval, size=thetaval))  #Simulate negative binomial data
  return(sim)
}

get_dharma_residuals <- function(gam, data){
  pred_vals = mgcv::predict.gam(gam, type="response")
  
  # Subset simulations for better residual vs predicted dharma plot
  simvals=simulateNegbin(gam,250,offsetval=1)
  
  DHARMaRes = createDHARMa(simulatedResponse = simvals, 
                           observedResponse = data$catch, 
                           fittedPredictedResponse = pred_vals
  )
  return(DHARMaRes)
}

compute_aic_scores <- function(...){
  aic_scores = AIC(...)
  aic_scores = aic_scores[order(aic_scores$AIC),]
  delta_aic = aic_scores$AIC - min(aic_scores$AIC)
  aic_scores = cbind(aic_scores, delta_aic)
  aic_scores = round(aic_scores, 3)
  return(aic_scores)
}

check_model <- function(model, data){
  residuals = get_dharma_residuals(model, data)
  resids = plot(residuals)
  dispersion = testDispersion(residuals)
  uniformity = testUniformity(residuals)
  zeroinflation = testZeroInflation(residuals)
  outliers = testOutliers(residuals)
  
  model_check_stats = c(dispersion$statistic, uniformity$statistic, zeroinflation$statistic)
  model_check_pval = c(dispersion$p.value, uniformity$p.value, zeroinflation$p.value)
  
  model_check = data.frame(model_check_stats, model_check_pval)
  colnames(model_check) = c("Statistic", "p-value")
  row.names(model_check) = c("Dispersion", "Uniformity", "Zero-Inflation")
  model_check = round(model_check, 3)
  return(model_check)
}

plot_gam_spline <- function(spline){
  p = plot(spline)+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
    l_ciLine(mul = 5, colour = "blue", linetype = 2) + l_points(alpha=0.2) + geom_hline(yintercept=0)
  
  return(p)
}

repredict_data <- function(model, data){
  re_predicted = predict(model, type="response")
  re_predicted_data = cbind(data, re_predicted)
  diff = re_predicted_data$catch - re_predicted_data$re_predicted
  re_predicted_data = cbind(re_predicted_data, diff)
  
  return(re_predicted_data)
}

plot_repredicted_distributions <- function(data){
  catch_plot = ggplot(data,aes(x=easting,y=northing, weight=catch))+geom_bin2d(bins=100)+ggtitle("Catch")
  predicted_plot = ggplot(data,aes(x=easting,y=northing, weight=re_predicted))+geom_bin2d(bins=100)+ggtitle("Predicted")
  diff_plot = ggplot(data,aes(x=easting,y=northing, weight=diff))+geom_bin2d(bins=100)+ggtitle("Diff")+scale_fill_gradient2()
  return(grid.arrange(catch_plot, predicted_plot, diff_plot, nrow=1))
}

plot_repredicted_params <- function(data, x, binwidth){
  # Temperature, Depth, and Salinity Plot Comparisons
  return (
    ggplot(data)+
          geom_histogram(aes(x=x, weight=catch), binwidth=binwidth, fill='black', alpha=0.5)+
          geom_histogram(aes(x=x, weight=re_predicted), binwidth=binwidth, fill='red', alpha=0.3)
  )
}

predict_data <- function(model, data){
  predicted = predict(model, data, type="response")
  pred_new = cbind(data, predicted)
  pred_new$floored = floor(predicted)
  return(pred_new)
}

get_environmental_data <- function(ys, ms=1:12){
  predicted_data = data.frame()
  for(y in ys){
    for(m in ms){
      month = str_pad(m, 2, pad="0")
      fname=paste("../auxdata/environmental-data/environmental_data_", y, month, ".csv", sep="")
      print(fname)
      pred_data = read.csv(fname)
      colnames(pred_data) = c("lon", "lat", "sfc_temp", "sfc_salt", "depth")
      nor_eas = convert_to_northing_easting(pred_data$lat, pred_data$lon)
      pred_data = cbind(pred_data, nor_eas)
      
      # sub = (pred_data$sfc_salt > 30 & pred_data$sfc_salt < 35) & 
      #   (pred_data$sfc_temp > -2 & pred_data$sfc_temp < 30) & 
      #   (pred_data$depth > 0 & pred_data$depth < 2000)
      # 
      # pred_data = pred_data[sub,]
      
      # predicted = predict_data(model, pred_data)
      len = length(pred_data[,1])
      years = rep(y, len)
      months = rep(m, len)
      
      pred_data$year = years
      pred_data$month = months
      
      predicted_data = dplyr::bind_rows(predicted_data, pred_data)
    }
  }
  return(predicted_data)
}

plot_cumulative_catch <- function(df, title){
  summed_predictions = df %>% group_by(lat, lon) %>% summarise(Total=sum(predicted))
  summed_predictions = as.data.frame(summed_predictions)
  p = ggplot(summed_predictions)+
    geom_point(
      aes(x=lon, 
          y=lat, 
          colour=log(floor(Total)), 
          alpha=ifelse(log(floor(Total)) < 0, 0, 1)
      ), 
      size=0.1
    )+
    scale_color_gradient2()+
    labs(x="Longitude", 
         y="Latitude", 
         title=title, 
         color="Catch"
    )+
    guides(alpha=FALSE)
  return(p)
}

plot_average_catch <- function(df, title){
  average_predictions = df %>% group_by(lat, lon) %>% summarise(Average=mean(predicted))
  average_predictions = as.data.frame(average_predictions)
  p = ggplot(average_predictions)+
    geom_point(
      aes(x=lon, 
          y=lat, 
          colour=log(floor(Average)), 
          alpha=ifelse(log(floor(Average)) < 0, 0, 1)
      ), 
      size=0.1
    )+
    scale_color_gradient2()+
    labs(x="Longitude", 
         y="Latitude", 
         title=title, 
         color="Catch"
    )+
    guides(alpha=FALSE)
  return(p)
}

plot_yearly_catch <- function(df, title){
  yearly_average_predictions = df %>% 
    group_by(lat, lon, year) %>% 
    summarise(Total=sum(predicted))
  yearly_average_predictions = as.data.frame(yearly_average_predictions)
  p = ggplot(yearly_average_predictions)+
    geom_point(
      aes(x=lon,
          y=lat,
          colour=log(floor(Total)),
          alpha=ifelse(log(floor(Total)) < 0, 0, 1)
      ),
      size=0.1
    )+
    scale_color_gradient2()+
    labs(x="Longitude",
         y="Latitude",
         title=title,
         color="Catch"
    )+
    guides(alpha=FALSE)+facet_wrap(~year)
  return(p)
}

plot_monthly_catch <- function(df, title){
  monthly_average_predictions = df %>% 
    group_by(lat, lon, month) %>% 
    summarise(Total=sum(predicted))
  
  ggplot(monthly_average_predictions)+
    geom_point(
      aes(x=lon,
          y=lat,
          colour=log(floor(Total)),
          alpha=ifelse(log(floor(Total)) < 0, 0, 1)
      ),
      size=0.1
    )+
    scale_color_gradient2()+
    labs(x="Longitude",
         y="Latitude",
         title=title,
         color="Catch"
    )+
    guides(alpha=FALSE)+facet_wrap(~month)
}




