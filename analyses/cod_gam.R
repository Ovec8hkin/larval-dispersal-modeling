library(mgcv)  #GAM library which estimates the smoothing parameters https://rdrr.io/cran/mgcv/man/gam.models.html
library(mgcViz) #For visualizing GAMs  https://cran.r-project.org/web/packages/mgcViz/vignettes/mgcviz.html
library(tidyverse)  
library(ggplot2)
library(dplyr)

catch_data = read.csv("/Users/joshua/Desktop/larval-dispersal-modeling/auxdata/catch-data/ecomon_cod.csv")

catch_data = select(catch_data, -c("X", "year", "month", "btm_temp", "btm_salt"))
catch_data = rename(catch_data, c("catch"="gadmor_100m3"))
catch_data$btm_sub =  factor(catch_data$btm_sub)

ggplot(catch_data,aes(x=sfc_temp,y=catch))+geom_point()
ggplot(catch_data,aes(x=sfc_salt,y=catch))+geom_point()
ggplot(catch_data,aes(x=depth,y=catch))+geom_point()
ggplot(catch_data,aes(x=lon,y=lat, z=catch))+geom_bin2d(bins=100)

gam_temp = gam(catch~s(sfc_temp),data=catch_data,family="gaussian")
summary(gam_temp)
plot(gam_temp)
gam.check(gam_temp)

b<-getViz(gam_temp)
plot(b) #Maes multiple plots.  use (sm(b,1)) to pull out first smooth, etc
plot(sm(b,1))+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + ylim(0, 5) + xlim(0, 10) + theme_classic()

pred_vals = predict.gam(gam_temp, catch_data, type="response")

plot(catch_data$catch, pred_vals)


gam_full = gam(catch~s(sfc_temp)+s(sfc_salt)+s(depth), data=catch_data, family="gaussian")
summary(gam_full)
plot(gam_full)
b<-getViz(gam_full)
plot(sm(b,1))+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + theme_classic()
plot(sm(b,2))+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + theme_classic()
plot(sm(b,3))+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + theme_classic()

pred=predict(gam_full)


gam_temp = gam(catch~s(sfc_temp),data=catch_data,family=negbin(theta=1))
summary(gam_temp)
plot(gam_temp)
gam.check(gam_temp)

b<-getViz(gam_temp)
plot(b) #Maes multiple plots.  use (sm(b,1)) to pull out first smooth, etc
plot(sm(b,1))+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + ylim(0, 5) + xlim(0, 10) + theme_classic()

gam_full = gam(catch~s(sfc_temp)+s(sfc_salt)+s(depth), data=catch_data, family=negbin(theta=3))
summary(gam_full)
plot(gam_full)
b<-getViz(gam_full)
plot(sm(b,1))+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + geom_hline(yintercept=0) + theme_classic()
plot(sm(b,2))+l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + geom_hline(yintercept=0) + theme_classic()
plot(sm(b,3))+
  l_fitLine(colour = "red") + l_rug(mapping = aes(x=x, y=y), alpha = 0.8) +
  l_ciLine(mul = 5, colour = "blue", linetype = 2) + 
  xlim(0, 200) + ylim(-10, 10) + 
  geom_hline(yintercept=0) + theme_classic()

plot(catch_data$lat, catch_data$catch)
plot(catch_data$lat, pred_vals)


gam_full_lalo = gam(catch~s(sfc_temp)+s(sfc_salt)+s(depth)+te(lat, lon), data=catch_data, family=negbin(theta=3))
summary(gam_full_lalo)
gam.check(gam_full_lalo)

plot(catch_data$catch, gam_full_lalo$fitted.values)

plot(catch_data$lat, catch_data$catch)
plot(catch_data$lat, pred_vals)

plot(catch_data$lon, catch_data$catch)
plot(catch_data$lon, gam_full_lalo$fitted.values)

#pred_data = read.csv("/Users/joshua/Desktop/larval-dispersal-modeling/auxdata/environmental_data_201601.csv")

#predicted = predict(gam_full, pred_data)
#predicted_pos = which(predicted > 0)

#write.csv(predicted, "/Users/joshua/Desktop/larval-dispersal-modeling/auxdata/predicted_cod.csv")
