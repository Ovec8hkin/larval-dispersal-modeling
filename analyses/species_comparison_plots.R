source("../src/gam_functions.R")

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

cod_catch_data=cbind(cod_catch_data, Species=rep_len("Atlantic Cod", length(cod_catch_data[,1])))
had_catch_data=cbind(had_catch_data, Species=rep_len("Haddock", length(had_catch_data[,1])))
flo_catch_data=cbind(flo_catch_data, Species=rep_len("Yellowtail Flounder", length(flo_catch_data[,1])))
mac_catch_data=cbind(mac_catch_data, Species=rep_len("Atlantcic Mackerel", length(mac_catch_data[,1])))
but_catch_data=cbind(but_catch_data, Species=rep_len("American Butterfish", length(but_catch_data[,1])))


ggplot()+
  geom_point(data=cod_catch_data, aes(x=sfc_temp,y=catch, colour="cod"), colour="red")+
  geom_point(data=had_catch_data, aes(x=sfc_temp,y=catch, colour="haddock"), colour="blue")+
  geom_point(data=flo_catch_data, aes(x=sfc_temp,y=catch, colour="flounder"), colour="green")+
  geom_point(data=mac_catch_data, aes(x=sfc_temp,y=catch, colour="mackerel"), colour="purple")+
  geom_point(data=but_catch_data, aes(x=sfc_temp,y=catch, colour="butterfish"), colour="black")
  labs(x="Temperature (˚C)", y="Catch (fish/100m^3)", title = "Catch vs Sea Surface Temperature")

ggplot()+geom_boxplot(data=cod_catch_data, aes(x=Species, y=sfc_temp, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=had_catch_data, aes(x=Species, y=sfc_temp, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=flo_catch_data, aes(x=Species, y=sfc_temp, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=mac_catch_data, aes(x=Species, y=sfc_temp, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=but_catch_data, aes(x=Species, y=sfc_temp, weight=catch), outlier.shape=NA)+
  scale_y_continuous(breaks=round(seq(0, 30, by = 5),1))+
  labs(y="Sea Surface Temperature (˚C)", title="Catch Distribution by Temperature")

ggplot()+geom_boxplot(data=cod_catch_data, aes(x=Species, y=sfc_salt, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=had_catch_data, aes(x=Species, y=sfc_salt, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=flo_catch_data, aes(x=Species, y=sfc_salt, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=mac_catch_data, aes(x=Species, y=sfc_salt, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=but_catch_data, aes(x=Species, y=sfc_salt, weight=catch), outlier.shape=NA)+
  ylim(25, 35)+
  labs(y="Sea Surface Salinity (psu)", title="Catch Distribution by Salinity")

ggplot()+geom_boxplot(data=cod_catch_data, aes(x=Species, y=depth, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=had_catch_data, aes(x=Species, y=depth, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=flo_catch_data, aes(x=Species, y=depth, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=mac_catch_data, aes(x=Species, y=depth, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=but_catch_data, aes(x=Species, y=depth, weight=catch), outlier.shape=NA)+
  ylim(0, 200)+
  labs(y="Bathymetric Depth (m)", title="Catch Distribution by Depth")

ggplot()+geom_boxplot(data=cod_catch_data, aes(x=Species, y=month, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=had_catch_data, aes(x=Species, y=month, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=flo_catch_data, aes(x=Species, y=month, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=mac_catch_data, aes(x=Species, y=month, weight=catch), outlier.shape=NA)+
  geom_boxplot(data=but_catch_data, aes(x=Species, y=month, weight=catch), outlier.shape=NA)+
  scale_y_continuous(breaks=round(seq(1, 12, by = 1),1))+
  labs(y="Month of Year", title="Catch Distribution by Month")

cod_catch_plot = ggplot(cod_catch_data,aes(x=easting,y=northing, weight=catch))+
  geom_bin2d(bins=100)+ggtitle("Atlantic Cod Catch")
had_catch_plot = ggplot(had_catch_data,aes(x=easting,y=northing, weight=catch))+
  geom_bin2d(bins=100)+ggtitle("Haddock Catch")
flo_catch_plot = ggplot(flo_catch_data,aes(x=easting,y=northing, weight=catch))+
  geom_bin2d(bins=100)+ggtitle("Yellowtail Flounder Catch")
mac_catch_plot = ggplot(mac_catch_data,aes(x=easting,y=northing, weight=catch))+
  geom_bin2d(bins=100)+ggtitle("Atlantic Mackerel Catch")
but_catch_plot = ggplot(but_catch_data,aes(x=easting,y=northing, weight=catch))+
  geom_bin2d(bins=100)+ggtitle("American Butterfish Catch")

grid.arrange(cod_catch_plot, had_catch_plot, flo_catch_plot, mac_catch_plot, but_catch_plot)
