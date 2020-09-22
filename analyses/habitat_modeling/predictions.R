source("../../src/gam_functions.R")

cod_catch_data = get_ecomon_catch_data("gadmor_100m3", "../auxdata/catch-data/ecomon_cod.csv")
had_catch_data = get_ecomon_catch_data("melaeg_100m3", "../auxdata/catch-data/ecomon_haddock.csv")
flo_catch_data = get_ecomon_catch_data("limfer_100m3", "../auxdata/catch-data/ecomon_flounder.csv")
mac_catch_data = get_ecomon_catch_data("scosco_100m3", "../auxdata/catch-data/ecomon_mackerel.csv")
but_catch_data = get_ecomon_catch_data("pepspp_100m3", "../auxdata/catch-data/ecomon_butterfish.csv")

cod_catch_data = cbind(cod_catch_data, convert_to_northing_easting(cod_catch_data$lat, cod_catch_data$lon))
had_catch_data = cbind(had_catch_data, convert_to_northing_easting(had_catch_data$lat, had_catch_data$lon))
flo_catch_data = cbind(flo_catch_data, convert_to_northing_easting(flo_catch_data$lat, flo_catch_data$lon))
mac_catch_data = cbind(mac_catch_data, convert_to_northing_easting(mac_catch_data$lat, mac_catch_data$lon))
but_catch_data = cbind(but_catch_data, convert_to_northing_easting(but_catch_data$lat, but_catch_data$lon))

model_formula = catch~s(depth)+s(sfc_temp)+s(sfc_salt)

cod_gam = gam(model_formula, data=cod_catch_data, family="nb")
had_gam = gam(model_formula, data=had_catch_data, family="nb")
flo_gam = gam(model_formula, data=flo_catch_data, family="nb")
mac_gam = gam(model_formula, data=mac_catch_data, family="nb")
but_gam = gam(model_formula, data=but_catch_data, family="nb")

#predicted_data = predict_for_years_months(1980:1990, model=gam_ths)

environmental_data = get_environmental_data(1980:1989)
sub = (pred_data$sfc_salt > 30 & pred_data$sfc_salt < 35) & 
  (pred_data$sfc_temp > -2 & pred_data$sfc_temp < 30) &
  (pred_data$depth > 0 & pred_data$depth < 2000)

edata = environmental_data[sub,]

cod_predicted = predict_data(cod_gam, edata)
had_predicted = predict_data(had_gam, edata)
flo_predicted = predict_data(flo_gam, edata)
mac_predicted = predict_data(mac_gam, edata)
but_predicted = predict_data(but_gam, edata)

cod_predicted=cbind(cod_predicted, Species=rep_len("Atlantic Cod", length(cod_predicted[,1])))
had_predicted=cbind(had_predicted, Species=rep_len("Haddock", length(had_predicted[,1])))
flo_predicted=cbind(flo_predicted, Species=rep_len("Yellowtail Flounder", length(flo_predicted[,1])))
mac_predicted=cbind(mac_predicted, Species=rep_len("Atlantic Mackerel", length(mac_predicted[,1])))
but_predicted=cbind(but_predicted, Species=rep_len("American Butterfish", length(but_predicted[,1])))

predicted = dplyr::bind_rows(cod_predicted, had_predicted, flo_predicted, mac_predicted, but_predicted)
predicted$Species = factor(predicted$Species, levels=c("Atlantic Cod", "Haddock", "Yellowtail Flounder", "Atlantic Mackerel", "American Butterfish"))


#-----

cod_annual = plot_yearly_catch(cod_predicted, title="Predicted Cumulative Atlantic Cod Distribution by Year")
cod_monthly = plot_monthly_catch(cod_predicted, title="Predicted Cumulative Atlantic Cod Distribution by Month")

cod_annual
cod_monthly
ggsave("../../figs/habitat-models/cod-monthly.png", width=20, height=15, dpi=500, units="in")


#-----
  
had_annual = plot_yearly_catch(had_predicted, title="Predicted Cumulative Haddock Distribution by Year")
had_monthly = plot_monthly_catch(had_predicted, title="Predicted Cumulative Haddock Distribution by Month")

had_annual
had_monthly
ggsave("../../figs/habitat-models/had-monthly.png", width=20, height=15, dpi=500, units="in")


#-----

flo_annual = plot_yearly_catch(flo_predicted, title="Predicted Cumulative Yellowtail Flounder Distribution by Year")
flo_monthly = plot_monthly_catch(flo_predicted, title="Predicted Cumulative Yellowtail Flounder Distribution by Month")

flo_annual
flo_monthly
ggsave("../../figs/habitat-models/flo-monthly.png", width=20, height=15, dpi=500, units="in")

#-----

mac_annual = plot_yearly_catch(mac_predicted, title="Predicted Cumulative Atlantic Mackerel Distribution by Year")
mac_monthly = plot_monthly_catch(mac_predicted, title="Predicted Cumulative Atlantic Mackerel Distribution by Month")

mac_annual
mac_monthly
ggsave("../../figs/habitat-models/mac-monthly.png", width=20, height=15, dpi=500, units="in")


#-----

but_annual = plot_yearly_catch(but_predicted, title="Predicted Cumulative American Butterfish Distribution by Year")
but_monthly = plot_monthly_catch(but_predicted, title="Predicted Cumulative American Butterfish Distribution by Month")

but_annual
but_monthly
ggsave("../../figs/habitat-models/but-monthly.png", width=20, height=15, dpi=500, units="in")


average_predictions = predicted %>% group_by(lat, lon, Species) %>% summarise(Average=mean(predicted))
average_predictions = as.data.frame(average_predictions)
ggplot(average_predictions)+
  geom_point(
    aes(x=lon, 
        y=lat, 
        colour=log(floor(Average)), 
        alpha=ifelse(log(floor(Average)) < 0, 0, 1)
    ), 
    size=0.1
  )+facet_wrap(~Species)+
  labs(x="Longitude",
       y="Latitude",
       title="Mean Predicted Distribution (Jan 1980 - Dec 1989)",
       colour="Catch"
  )+
  scale_colour_gradient(low="white", high="red")+
  guides(alpha=FALSE)

ggsave("../../figs/habitat-models/mean-predicted.png", width=15, height=10, dpi=500, units="in")

summed_predictions = predicted %>% group_by(lat, lon, Species) %>% summarise(Total=sum(predicted))
summed_predictions = as.data.frame(summed_predictions)
ggplot(summed_predictions)+
  geom_point(
    aes(x=lon, 
        y=lat, 
        colour=log(floor(Total)), 
        alpha=ifelse(log(floor(Total)) < 0, 0, 1)
    ), 
    size=0.1
  )+facet_wrap(~Species)+
  labs(x="Longitude",
       y="Latitude",
       title="Cumulative Predicted Distribution (Jan 1980 - Dec 1989)",
       colour="Catch"
  )+
  scale_colour_gradient(low="white", high="red")+
  guides(alpha=FALSE)

ggsave("../../figs/habitat-models/cumulate-predicted.png", width=15, height=10, dpi=500, units="in")

