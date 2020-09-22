source("../../src/gam_functions.R")

cod_catch_data = get_ecomon_catch_data("gadmor_100m3", "../../auxdata/catch-data/ecomon_cod.csv")
had_catch_data = get_ecomon_catch_data("melaeg_100m3", "../../auxdata/catch-data/ecomon_haddock.csv")
flo_catch_data = get_ecomon_catch_data("limfer_100m3", "../../auxdata/catch-data/ecomon_flounder.csv")
mac_catch_data = get_ecomon_catch_data("scosco_100m3", "../../auxdata/catch-data/ecomon_mackerel.csv")
but_catch_data = get_ecomon_catch_data("pepspp_100m3", "../../auxdata/catch-data/ecomon_butterfish.csv")

cod_catch_data = cbind(cod_catch_data, convert_to_northing_easting(cod_catch_data$lat, cod_catch_data$lon))
had_catch_data = cbind(had_catch_data, convert_to_northing_easting(had_catch_data$lat, had_catch_data$lon))
flo_catch_data = cbind(flo_catch_data, convert_to_northing_easting(flo_catch_data$lat, flo_catch_data$lon))
mac_catch_data = cbind(mac_catch_data, convert_to_northing_easting(mac_catch_data$lat, mac_catch_data$lon))
but_catch_data = cbind(but_catch_data, convert_to_northing_easting(but_catch_data$lat, but_catch_data$lon))

cod_catch_data=cbind(cod_catch_data, Species=rep_len("Atlantic Cod", length(cod_catch_data[,1])))
had_catch_data=cbind(had_catch_data, Species=rep_len("Haddock", length(had_catch_data[,1])))
flo_catch_data=cbind(flo_catch_data, Species=rep_len("Yellowtail Flounder", length(flo_catch_data[,1])))
mac_catch_data=cbind(mac_catch_data, Species=rep_len("Atlantic Mackerel", length(mac_catch_data[,1])))
but_catch_data=cbind(but_catch_data, Species=rep_len("American Butterfish", length(but_catch_data[,1])))

cod_catch_data$std_catch = cod_catch_data$catch/sum(cod_catch_data$catch)
had_catch_data$std_catch = had_catch_data$catch/sum(had_catch_data$catch)
flo_catch_data$std_catch = flo_catch_data$catch/sum(flo_catch_data$catch)
mac_catch_data$std_catch = mac_catch_data$catch/sum(mac_catch_data$catch)
but_catch_data$std_catch = but_catch_data$catch/sum(but_catch_data$catch)

catch_data = dplyr::bind_rows(cod_catch_data, had_catch_data, flo_catch_data, mac_catch_data, but_catch_data)
catch_data$Species = factor(catch_data$Species, levels=c("Atlantic Cod", "Haddock", "Yellowtail Flounder", "Atlantic Mackerel", "American Butterfish"))

#ggplot()+
  geom_point(data=cod_catch_data, aes(x=sfc_temp,y=catch, colour="cod"), colour="red", alpha=0.5)+
  geom_point(data=had_catch_data, aes(x=sfc_temp,y=catch, colour="haddock"), colour="blue", alpha=0.5)+
  geom_point(data=flo_catch_data, aes(x=sfc_temp,y=catch, colour="flounder"), colour="green", alpha=0.5)+
  geom_point(data=mac_catch_data, aes(x=sfc_temp,y=catch, colour="mackerel"), colour="purple", alpha=0.5)+
  geom_point(data=but_catch_data, aes(x=sfc_temp,y=catch, colour="butterfish"), colour="black", alpha=0.5)
  labs(x="Temperature (˚C)", y="Catch (fish/100m^3)", title = "Catch vs Sea Surface Temperature")

ggplot()+
  geom_boxplot(data=catch_data, aes(x=Species, y=sfc_temp, weight=catch, fill=Species), outlier.shape=NA)+
  scale_y_continuous(breaks=round(seq(0, 30, by = 5),1))+
  labs(y="Sea Surface Temperature (˚C)", title="Catch Distribution by Temperature")

ggsave("../../figs/habitat-models/temp-dist.png", width=10, height=5, units="in", dpi=500)

ggplot()+
  geom_boxplot(data=catch_data, aes(x=Species, y=sfc_salt, weight=catch, fill=Species), outlier.shape=NA)+
  ylim(25, 35)+
  labs(y="Sea Surface Salinity (psu)", title="Catch Distribution by Salinity")

ggsave("../../figs/habitat-models/salt-dist.png", width=10, height=5, units="in", dpi=500)

ggplot()+
  geom_boxplot(data=catch_data, aes(x=Species, y=depth, weight=catch, fill=Species), outlier.shape=NA)+
  ylim(0, 200)+
  labs(y="Bathymetric Depth (m)", title="Catch Distribution by Depth")

ggsave("../../figs/habitat-models/depth-dist.png", width=10, height=5, units="in", dpi=500)

ggplot()+
  geom_boxplot(data=catch_data, aes(x=Species, y=month, weight=catch, fill=Species), outlier.shape=NA)+
  scale_y_continuous(breaks=round(seq(1, 12, by = 1),1))+
  labs(y="Month of Year", title="Catch Distribution by Month")

ggplot(catch_data,aes(x=lon,y=lat, weight=std_catch))+
  geom_bin2d(bins=100)+ggtitle("Catch")+facet_wrap(~Species)+
  scale_fill_gradient(low="white", high="red")+
  labs(x="Longitude", y="Latitude", title="Catch Distribution", fill="% catch")

ggsave("../../figs/habitat-models/geo-dist.png", width=15, height=10, units="in", dpi=500)

