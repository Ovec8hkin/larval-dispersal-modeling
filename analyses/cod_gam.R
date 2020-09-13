library(tidyverse)  
library(ggplot2)
library(dplyr)
library(mgcv)  #GAM library which estimates the smoothing parameters https://rdrr.io/cran/mgcv/man/gam.models.html
library(DHARMa)
library(MASS)
library(rgdal)
library(gridExtra)
source("https://gist.githubusercontent.com/TonyLadson/f37aab3e2ef517188a7f27166307c985/raw/0822970769bc90fcc28052a91b375399d665286e/UTM2deg.R")


run_gam <- function(model, data, family="nb", residuals=TRUE, plot=TRUE){
  gam = mgcv::gam(model, data=data, family=family)
  summary(gam)
  
  if(plot){
    plot(gam)
  }
  
  if(residuals){
    negbin_residuals(gam, data)
    
  }
  
  return(gam)
  
}

simulateNegbin <- function(modfit, nsims=250, offsetval=1){
  muval = predict(modfit, type = "response")*offsetval  #Get the mean with offset
  nObs = length(muval)  
  thetaval = modfit$family$getTheta(trans=TRUE)  #Get theta not log transforme
  sim = replicate(nsims,rnbinom(nObs,mu=muval, size=thetaval))  #Simulate negative binomial data
  return(sim)
}

negbin_residuals <- function(gam, data){
  pred_vals = mgcv::predict.gam(gam, type="response")
  
  # Subset simulations for better residual vs predicted dharma plot
  simvals=simulateNegbin(gam,250,offsetval=1)

  DHARMaRes = createDHARMa(simulatedResponse = simvals, 
                           observedResponse = data$catch, 
                           fittedPredictedResponse = pred_vals
                           )
  return(DHARMaRes)
}

# -------------- Format raw catch data for input into model -------------- #
catch_data = read.csv("/Users/joshua/Desktop/larval-dispersal-modeling/auxdata/catch-data/ecomon_cod.csv")

catch_data = dplyr::select(catch_data, -c("X", "year", "month", "btm_temp", "btm_salt")) #drop unecsarry columns
catch_data = dplyr::rename(catch_data, c("catch"="gadmor_100m3")) # restrict to species of interest
catch_data$btm_sub = factor(catch_data$btm_sub) #convert substrate into factor type

# Convert lat/lon coordinates into northing/easting coordinates
coords.dec = SpatialPoints(cbind(catch_data$lon, catch_data$lat), 
                                  proj4string=CRS("+proj=longlat"))
coords.UTM = spTransform(coords.dec, CRS("+init=epsg:26983"))
cs = coordinates(coords.UTM)
colnames(cs)=c("easting", "northing")
catch_data = cbind(catch_data, cs)

head(catch_data)
summary(catch_data)

# Plot raw catch data to see distribution of variable
ggplot(catch_data)+geom_point(aes(x=sfc_temp,y=catch))+
  labs(x="Temperature (˚C)", y="Catch (fish/100m^3)", title = "Catch vs Sea Surface Temperature")
ggplot(catch_data)+geom_point(aes(x=sfc_salt,y=catch))+
  labs(x="Salinity (ppm)", y="Catch (fish/100m^3)", title = "Catch vs Sea Surface Salinity")
ggplot(catch_data)+geom_point(aes(x=depth,y=catch))+
  labs(x="Temperature (˚C)", y="Catch (fish/100m^3)", title = "Catch vs Bathymetric Depth")
ggplot(catch_data)+geom_bar(aes(x=btm_sub, weight=catch))+
  labs(x="Substrate Type", y="Catch (fish/100m^3)", title = "Catch vs Substrate")

# Plot points in space to visualize geographic distribution
ggplot(catch_data, aes(x=easting, y=northing, colour=catch))+geom_point(size=1, stroke=0)+
  scale_colour_gradient(low="white", high="red")
ggplot(catch_data,aes(x=easting,y=northing, weight=catch))+geom_bin2d(bins=100)

# --------------  Run negative binomial GAMs using mgcv -------------- #

model_t = catch~s(sfc_temp)
gam_t = run_gam(model_t, data=catch_data, family="nb", residuals=FALSE, plot=FALSE)

model_h = catch~s(depth)
gam_h = run_gam(model_h, data=catch_data, family="nb", residuals=FALSE, plot=FALSE)

model_th = catch~s(depth)+s(sfc_temp)
gam_th = run_gam(model_th, data=catch_data, family="nb", residuals=FALSE, plot=FALSE)

model_ths = catch~s(depth)+s(sfc_temp)+s(sfc_salt)
gam_ths = run_gam(model_ths, data=catch_data, family="nb", residuals=FALSE, plot=FALSE)

model_thf = catch~s(depth)+s(sfc_temp)+btm_sub
gam_thf = run_gam(model_thf, data=catch_data, family="nb", residuals=FALSE, plot=FALSE)

model_lalo = catch~te(easting, northing)
gam_lalo = run_gam(model_lalo, data=catch_data, family="nb", residuals=FALSE, plot=FALSE)

model_lalo_th = catch~te(easting, northing)+s(sfc_temp)+s(depth)
gam_lalo_th = run_gam(model_lalo_th, data=catch_data, family="nb", residuals=FALSE, plot=FALSE)

model_lalo_ths = catch~te(easting, northing)+s(sfc_temp)+s(depth)+s(sfc_salt)
gam_lalo_ths = run_gam(model_lalo_ths, data=catch_data, family="nb", residuals=FALSE, plot=FALSE)

model_lalo_thf = catch~te(easting, northing)+s(sfc_temp)+s(depth)+btm_sub
gam_lalo_thf = run_gam(model_lalo_thf, data=catch_data, family="nb", residuals=FALSE, plot=FALSE)

model_lalo_thsf = catch~te(easting, northing)+s(sfc_temp)+s(depth)+s(sfc_salt)+btm_sub
gam_lalo_thsf = run_gam(model_lalo_thsf, data=catch_data, family="nb", residuals=FALSE, plot=FALSE)


# --------------  Model Comparisons -------------- #

# AIC and ∆AIC calculations
aic_scores = AIC(gam_t, gam_h, gam_th, gam_ths, gam_thf, gam_lalo, gam_lalo_th, gam_lalo_ths, gam_lalo_thf, gam_lalo_thsf)
aic_scores = aic_scores[order(aic_scores$AIC),]
delta_aic = aic_scores$AIC - min(aic_scores$AIC)
aic_scores = cbind(aic_scores, delta_aic)
round(aic_scores, 3)

# Looks like the temperature, depth, and salinity with
# 2D lat/lon smooth is the best model, followed by the 
# temp, depth, and lat/lon model. Seafloor substrate 
# does not appear to have any additional predictive
# affect on the model performance and penalize accordingly.
summary(gam_lalo_ths)

# --------------  Model Checking -------------- #

residuals = negbin_residuals(gam_lalo_ths, catch_data)
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
model_check
# --------------  Visualizations on LALO-THS model -------------- # 

library(mgcViz)
b<-getViz(gam_lalo_ths)
lths_lalo_smooth=sm(b, 1)
lths_temp_spline=sm(b, 2)
lths_depth_spline=sm(b, 3)
lths_salt_spline=sm(b, 4)

plot(lths_lalo_smooth)+l_fitRaster()+l_fitContour()+l_points()

# Plot temperature spline 0-25˚C with line through 0
plot(lths_temp_spline)+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + l_points(alpha=0.2) + geom_hline(yintercept=0) +
  ylim(-10, 10) + xlim(0, 25) + labs(x="Surface Temperature (˚C)", title="Temperature Spline") 

# Plot depth spline 0-200m with line through 0
plot(lths_depth_spline)+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + l_points(alpha=0.2) + geom_hline(yintercept=0) +
  ylim(-10, 10) + xlim(0, 200) + labs(x="Depth (m)", title="Depth Spline")

# Plot salinity spline 30-35psu with line through 0
plot(lths_salt_spline)+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + l_points(alpha=0.2) + geom_hline(yintercept=0) +
  ylim(-10, 10) + xlim(30, 35) + labs(x="Salinity (psu)", title="Salinity Spline") 

# Plot residuals and model checking
check(b)

# --------------  Visualizations on THS Model -------------- # 

c<-getViz(gam_ths)
ths_temp_spline=sm(c, 2)
ths_depth_spline=sm(c, 1)
ths_salt_spline=sm(c, 3)

# Plot temperature spline 0-25˚C with line through 0
plot(ths_temp_spline)+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + l_points(alpha=0.2) + geom_hline(yintercept=0) +
  ylim(-10, 10) + xlim(0, 25) + labs(x="Surface Temperature (˚C)", title="Temperature Spline") 

# Plot depth spline 0-200m with line through 0
plot(ths_depth_spline)+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + l_points(alpha=0.2) + geom_hline(yintercept=0) +
  ylim(-10, 10) + xlim(0, 200) + labs(x="Depth (m)", title="Depth Spline")

# Plot salinity spline 30-35psu with line through 0
plot(ths_salt_spline)+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + l_points(alpha=0.2) + geom_hline(yintercept=0) +
  ylim(-10, 10) + xlim(30, 35) + labs(x="Salinity (psu)", title="Salinity Spline")

# --------------  Format predictions data -------------- #

# Load and format data to make predictions on (data is for conditions during Jan 2016)
pred_data = read.csv("/Users/joshua/Desktop/larval-dispersal-modeling/auxdata/environmental_data_198403.csv")
colnames(pred_data) = c("lon", "lat", "sfc_temp", "sfc_salt", "depth", "btm_sub", "month")
coords.dec = SpatialPoints(cbind(pred_data$lon, pred_data$lat), proj4string=CRS("+proj=longlat"))
coords.UTM = spTransform(coords.dec, CRS("+init=epsg:26983"))
cs = coordinates(coords.UTM)
colnames(cs)=c("easting", "northing")
pred_data = cbind(pred_data, cs)

# --------------  Repredict using LALO_THS model -------------- #

# Repredict the catch data using the model (lalo_ths)
re_predicted = predict(gam_lalo_ths, type="response")
re_predicted_data = cbind(catch_data, re_predicted)
diff = re_predicted_data$catch - re_predicted_data$re_predicted
re_predicted_data = cbind(re_predicted_data, diff)

# Plot true catch data and predicted catch data for comparison
catch_plot = ggplot(re_predicted_data,aes(x=easting,y=northing, weight=catch))+geom_bin2d(bins=100)+ggtitle("CATCH")
predicted_plot = ggplot(re_predicted_data,aes(x=easting,y=northing, weight=re_predicted))+geom_bin2d(bins=100)+ggtitle("Predicted")
grid.arrange(catch_plot, predicted_plot, nrow=1)

# Temperature, Depth, and Salinity Plot Comparisons
ggplot(re_predicted_data)+
  geom_histogram(aes(x=sfc_temp, weight=catch), binwidth=1, fill='black', alpha=0.5)+
  geom_histogram(aes(x=sfc_temp, weight=re_predicted), binwidth=1, fill='red', alpha=0.3)+
  xlim(0, 25) + 
  labs(x="Temperature (˚C)", y="Catch (fish/100m^3)", title="Sea Surface Temperature", fill="Data")

ggplot(re_predicted_data)+
  geom_histogram(aes(x=depth, weight=catch), binwidth=20, fill='black', alpha=0.5)+
  geom_histogram(aes(x=depth, weight=re_predicted), binwidth=10, fill='red', alpha=0.3)+
  xlim(0, 200) + 
  labs(x="Depth (m)", y="Catch (fish/100m^3)", title="Bathymetric Depth")

ggplot(re_predicted_data)+
  geom_histogram(aes(x=sfc_salt, weight=catch), binwidth=1, fill='black', alpha=0.5)+
  geom_histogram(aes(x=sfc_salt, weight=re_predicted), binwidth=1, fill='red', alpha=0.3)+
  xlim(25, 35)+ 
  labs(x="Salinity (psu)", y="Catch (fish/100m^3)", title="Salinity")

#----------------- Repredictions for THS model ---------------------#
# Repredict the catch data using the model (lalo_ths)
re_predicted = predict(gam_ths, type="response")
re_predicted_data = cbind(catch_data, re_predicted)
diff = re_predicted_data$catch - re_predicted_data$re_predicted
re_predicted_data = cbind(re_predicted_data, diff)

# Plot true catch data and predicted catch data for comparison
catch_plot = ggplot(re_predicted_data,aes(x=easting,y=northing, weight=catch))+geom_bin2d(bins=100)+ggtitle("CATCH")
predicted_plot = ggplot(re_predicted_data,aes(x=easting,y=northing, weight=re_predicted))+geom_bin2d(bins=100)+ggtitle("Predicted")
grid.arrange(catch_plot, predicted_plot, nrow=1)

# Temperature, Depth, and Salinity Plot Comparisons
ggplot(re_predicted_data)+
  geom_histogram(aes(x=sfc_temp, weight=catch), binwidth=1, fill='black', alpha=0.5)+
  geom_histogram(aes(x=sfc_temp, weight=re_predicted), binwidth=1, fill='red', alpha=0.3)+
  xlim(0, 25) + 
  labs(x="Temperature (˚C)", y="Catch (fish/100m^3)", title="Sea Surface Temperature", fill="Data")

ggplot(re_predicted_data)+
  geom_histogram(aes(x=depth, weight=catch), binwidth=20, fill='black', alpha=0.5)+
  geom_histogram(aes(x=depth, weight=re_predicted), binwidth=10, fill='red', alpha=0.3)+
  xlim(0, 200) + 
  labs(x="Depth (m)", y="Catch (fish/100m^3)", title="Bathymetric Depth")

ggplot(re_predicted_data)+
  geom_histogram(aes(x=sfc_salt, weight=catch), binwidth=1, fill='black', alpha=0.5)+
  geom_histogram(aes(x=sfc_salt, weight=re_predicted), binwidth=1, fill='red', alpha=0.3)+
  xlim(25, 35)+ 
  labs(x="Salinity (psu)", y="Catch (fish/100m^3)", title="Salinity")


# -------------- Make new predictions on LALO-THS model -------------- #

# Now, make predictions on the actual prediction data (from gom3_201602.nc)
predicted = predict(gam_lalo_ths, pred_data, type="response")
pred_new = cbind(pred_data, predicted)
pred_new$floored = floor(predicted)

ggplot(pred_new[pred_new$floored < 300,])+geom_point(aes(x=easting, y=northing, colour=log(floored)), size=0.001)+
  scale_colour_gradient2(low="blue", high="red", mid="white")

# -------------- Make new predictions on THS model -------------- #

predicted_ths = predict(gam_ths, pred_data, type="response")
pred_new = cbind(pred_data, predicted_ths)
pred_new$floored = floor(predicted_ths)

ggplot(pred_new)+geom_point(aes(x=easting, y=northing, colour=log(floored)), size=0.001)+
  scale_colour_gradient2(low="blue", high="red", mid="white")



gam_lalo_ths$coefficients
vcov(gam_lalo_ths)
gam_lalo_ths$family$getTheta(trans=TRUE)

  