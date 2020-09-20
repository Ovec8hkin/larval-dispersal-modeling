source("../src/gam_functions.R")

# -------------- Format raw catch data for input into model -------------- #
catch_data = get_ecomon_catch_data("melaeg_100m3", "../auxdata/catch-data/ecomon_haddock.csv")
nor_eas = convert_to_northing_easting(catch_data$lat, catch_data$lon)
catch_data = cbind(catch_data, nor_eas)

head(catch_data)
summary(catch_data)

# Plot raw catch data to see distribution of variables
ggplot(catch_data)+geom_point(aes(x=sfc_temp,y=catch))+
  labs(x="Temperature (˚C)", y="Catch (fish/100m^3)", title = "Haddock - Catch vs Sea Surface Temperature")
ggplot(catch_data)+geom_point(aes(x=sfc_salt,y=catch))+
  labs(x="Salinity (ppm)", y="Catch (fish/100m^3)", title = "Haddock - Catch vs Sea Surface Salinity")
ggplot(catch_data)+geom_point(aes(x=depth,y=catch))+
  labs(x="Temperature (˚C)", y="Catch (fish/100m^3)", title = "Haddock - Catch vs Bathymetric Depth")
ggplot(catch_data)+geom_bar(aes(x=btm_sub, weight=catch))+
  labs(x="Substrate Type", y="Catch (fish/100m^3)", title = "Haddock - Catch vs Substrate")

# Plot points in space to visualize geographic distribution
ggplot(catch_data,aes(x=easting,y=northing, weight=catch))+geom_bin2d(bins=100)+ggtitle("Haddock Catch")

# --------------  Run negative binomial GAMs using mgcv -------------- #

model_th = catch~s(depth)+s(sfc_temp)
gam_th = gam(model_th, data=catch_data, family="nb")

model_ths = catch~s(depth)+s(sfc_temp)+s(sfc_salt)
gam_ths = gam(model_ths, data=catch_data, family="nb")

model_thf = catch~s(depth)+s(sfc_temp)+btm_sub
gam_thf = gam(model_thf, data=catch_data, family="nb")

model_lalo_th = catch~te(easting, northing)+s(sfc_temp)+s(depth)
gam_lalo_th = gam(model_lalo_th, data=catch_data, family="nb")

model_lalo_ths = catch~te(easting, northing)+s(sfc_temp)+s(depth)+s(sfc_salt)
gam_lalo_ths = gam(model_lalo_ths, data=catch_data, family="nb")


# --------------  Model Comparisons -------------- #

# AIC and ∆AIC calculations
aic_scores = AIC(gam_th, gam_ths, gam_lalo_ths)
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
model_check = check_model(gam_ths, catch_data)

# --------------  Visualizations on LALO-THS model -------------- # 

library(mgcViz)
lths<-getViz(gam_lalo_ths)
lths_lalo_smooth=sm(lths, 1)
lths_temp_spline=sm(lths, 2)
lths_depth_spline=sm(lths, 3)
lths_salt_spline=sm(lths, 4)

temp_spline_plot = plot_gam_spline(lths_temp_spline)
temp_spline_plot+ylim(-10, 10) + xlim(0, 25) + labs(x="Surface Temperature (˚C)", title="Temperature Spline") 

depth_spline_plot = plot_gam_spline(lths_depth_spline)
depth_spline_plot+ylim(-10, 10) + xlim(0, 200) + labs(x="Depth (m)", title="Depth Spline")

salt_spline_plot = plot_gam_spline(lths_salt_spline)
salt_spline_plot + ylim(-10, 10) + xlim(30, 35) + labs(x="Salinity (psu)", title="Salinity Spline")


# --------------  Visualizations on THS Model -------------- # 

ths<-getViz(gam_ths)
ths_temp_spline=sm(ths, 2)
ths_depth_spline=sm(ths, 1)
ths_salt_spline=sm(ths, 3)

temp_spline_plot = plot_gam_spline(ths_temp_spline)
temp_spline_plot+ylim(-10, 10) + xlim(0, 25) + labs(x="Surface Temperature (˚C)", title="Temperature Spline") 

depth_spline_plot = plot_gam_spline(ths_depth_spline)
depth_spline_plot+ylim(-10, 10) + xlim(0, 200) + labs(x="Depth (m)", title="Depth Spline")

salt_spline_plot = plot_gam_spline(ths_salt_spline)
salt_spline_plot + ylim(-10, 10) + xlim(30, 35) + labs(x="Salinity (psu)", title="Salinity Spline")

# --------------  Repredict using LALO_THS model -------------- #

# Repredict the catch data using the model (lalo_ths)
lths_repredicted = repredict_data(gam_lalo_ths, catch_data)

# Plot true catch data and predicted catch data for comparison
plot_repredicted_distributions(lths_repredicted)

tdist = plot_repredicted_params(lths_repredicted, lths_repredicted$sfc_temp, binwidth=1)
tdist = tdist+xlim(0, 25)+labs(x="Temperature (˚C)", y="Catch (fish/100m^3)", title="Sea Surface Temperature", fill="Data")

hdist = plot_repredicted_params(lths_repredicted, lths_repredicted$depth, binwidth=10)
hdist = hdist+xlim(0, 300)+labs(x="Depth (m)", y="Catch (fish/100m^3)", title="Bathymetric Depth")

sdist = plot_repredicted_params(lths_repredicted, lths_repredicted$sfc_salt, binwidth=0.5)
sdist = sdist+xlim(25, 35)+labs(x="Salinity (psu)", y="Catch (fish/100m^3)", title="Salinity")

grid.arrange(tdist, hdist, sdist, nrow=1)

#----------------- Repredictions for THS model ---------------------#
# Repredict the catch data using the model (lalo_ths)
ths_repredicted = repredict_data(gam_ths, catch_data)

plot_repredicted_distributions(ths_repredicted)

tdist = plot_repredicted_params(ths_repredicted, ths_repredicted$sfc_temp, binwidth=1)
tdist = tdist+xlim(0, 25)+labs(x="Temperature (˚C)", y="Catch (fish/100m^3)", title="Sea Surface Temperature", fill="Data")

hdist = plot_repredicted_params(ths_repredicted, ths_repredicted$depth, binwidth=10)
hdist = hdist+xlim(0, 300)+labs(x="Depth (m)", y="Catch (fish/100m^3)", title="Bathymetric Depth")

sdist = plot_repredicted_params(ths_repredicted, ths_repredicted$sfc_salt, binwidth=0.5)
sdist = sdist+xlim(25, 35)+labs(x="Salinity (psu)", y="Catch (fish/100m^3)", title="Salinity")

grid.arrange(tdist, hdist, sdist, nrow=1)

# --------------  Format predictions data -------------- #

# Load and format data to make predictions on (data is for conditions during Jan 2016)
pred_data = read.csv("../auxdata/environmental_data_198603.csv")
colnames(pred_data) = c("lon", "lat", "sfc_temp", "sfc_salt", "depth", "btm_sub", "month")
nor_eas = convert_to_northing_easting(pred_data$lat, pred_data$lon)
pred_data = cbind(pred_data, nor_eas)

# -------------- Make new predictions on LALO-THS model -------------- #

# Now, make predictions on the actual prediction data (from gom3_201602.nc)
predicted = predict_data(gam_lalo_ths, pred_data)
ggplot(predicted[predicted$floored < 300,])+geom_point(aes(x=easting, y=northing, colour=log(floored)), size=0.001)+
  scale_colour_gradient2(low="blue", high="red", mid="white")

# -------------- Make new predictions on THS model -------------- #

predicted = predict_data(gam_ths, pred_data)
ggplot(predicted)+geom_point(aes(x=easting, y=northing, colour=log(floored)), size=0.001)+
  scale_colour_gradient2(low="blue", high="red", mid="white")+ggtitle("Haddock -  - THS")

# -------------- Make new predictions on THS model -------------- #

predicted = predict_data(gam_th, pred_data)
ggplot(predicted)+geom_point(aes(x=easting, y=northing, colour=log(floored)), size=0.001)+
  scale_colour_gradient2(low="blue", high="red", mid="white")+ggtitle("Haddock -  - TH")

gam_lalo_ths$coefficients
vcov(gam_lalo_ths)
gam_lalo_ths$family$getTheta(trans=TRUE)

