library(mgcViz)
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

# ---------------- Fit GAMs For Each Species ---------------- #
model_formula = catch~s(depth)+s(sfc_temp)+s(sfc_salt)

cod_gam = gam(model_formula, data=cod_catch_data, family="nb")
had_gam = gam(model_formula, data=had_catch_data, family="nb")
flo_gam = gam(model_formula, data=flo_catch_data, family="nb")
mac_gam = gam(model_formula, data=mac_catch_data, family="nb")
but_gam = gam(model_formula, data=but_catch_data, family="nb")

species = list("Atlantic Cod", "Haddock", "Yelllowtail Flounder", "Atlantic Mackerel", "American Butterfish")
models = list(cod_gam, had_gam, flo_gam, mac_gam, but_gam)

# ---------------- Plot Splines For Each Species ------------- #
s=getViz(cod_gam)
depth_smooth = sm(s, 1)
temp_smooth  = sm(s, 2)
salt_smooth  = sm(s, 3)
cod_temp_plot = plot_gam_spline(temp_smooth)+ylim(-10, 10) + xlim(0, 25) + labs(x="Surface Temperature (˚C)", title="Atlantic Cod - Temperature Spline")
cod_depth_plot = plot_gam_spline(depth_smooth)+ylim(-10, 10) + xlim(0, 200) + labs(x="Depth (m)", title="Atlantic Cod - Depth Spline")
cod_salt_splot = plot_gam_spline(salt_smooth)+ylim(-10, 10) + xlim(30, 35) + labs(x="Salinity (psu)", title="Atlantic Cod - Salinity Spline")
cod_plots = gridPrint(cod_temp_plot, cod_salt_splot, cod_depth_plot, ncol=3)
ggsave("../../figs/habitat-models/splines/cod-splines.png", cod_plots, width=15, height=5, dpi=500, units="in")

s=getViz(had_gam)
depth_smooth = sm(s, 1)
temp_smooth  = sm(s, 2)
salt_smooth  = sm(s, 3)
had_temp_plot = plot_gam_spline(temp_smooth)+ylim(-10, 10) + xlim(0, 25) + labs(x="Surface Temperature (˚C)", title="Haddock - Temperature Spline")
had_depth_plot = plot_gam_spline(depth_smooth)+ylim(-10, 10) + xlim(0, 200) + labs(x="Depth (m)", title="Haddock - Depth Spline")
had_salt_splot = plot_gam_spline(salt_smooth)+ylim(-10, 10) + xlim(30, 35) + labs(x="Salinity (psu)", title="Haddock - Salinity Spline")
had_plots = gridPrint(had_temp_plot, had_salt_splot, had_depth_plot, ncol=3)
ggsave("../../figs/habitat-models/splines/had-splines.png", had_plots, width=15, height=5, dpi=500, units="in")

s=getViz(flo_gam)
depth_smooth = sm(s, 1)
temp_smooth  = sm(s, 2)
salt_smooth  = sm(s, 3)
flo_temp_plot = plot_gam_spline(temp_smooth)+ylim(-10, 10) + xlim(0, 25) + labs(x="Surface Temperature (˚C)", title="Yellowtail Flounder - Temperature Spline")
flo_depth_plot = plot_gam_spline(depth_smooth)+ylim(-10, 10) + xlim(0, 200) + labs(x="Depth (m)", title="Yellowtail Flounder - Depth Spline")
flo_salt_splot = plot_gam_spline(salt_smooth)+ylim(-10, 10) + xlim(30, 35) + labs(x="Salinity (psu)", title="Yellowtail Flounder - Salinity Spline")
flo_plots = gridPrint(flo_temp_plot, flo_salt_splot, flo_depth_plot, ncol=3)
ggsave("../../figs/habitat-models/splines/flo-splines.png", flo_plots, width=15, height=5, dpi=500, units="in")

s=getViz(mac_gam)
depth_smooth = sm(s, 1)
temp_smooth  = sm(s, 2)
salt_smooth  = sm(s, 3)
mac_temp_plot = plot_gam_spline(temp_smooth)+ylim(-10, 10) + xlim(0, 25) + labs(x="Surface Temperature (˚C)", title="Atlantic Mackerel - Temperature Spline")
mac_depth_plot = plot_gam_spline(depth_smooth)+ylim(-10, 10) + xlim(0, 200) + labs(x="Depth (m)", title="Atlantic Mackerel - Depth Spline")
mac_salt_splot = plot_gam_spline(salt_smooth)+ylim(-10, 10) + xlim(30, 35) + labs(x="Salinity (psu)", title="Atlantic Mackerel - Salinity Spline")
mac_plots = gridPrint(mac_temp_plot, mac_salt_splot, mac_depth_plot, ncol=3)
ggsave("../../figs/habitat-models/splines/mac-splines.png", mac_plots, width=15, height=5, dpi=500, units="in")

s=getViz(but_gam)
depth_smooth = sm(s, 1)
temp_smooth  = sm(s, 2)
salt_smooth  = sm(s, 3)
but_temp_plot = plot_gam_spline(temp_smooth)+ylim(-10, 10) + xlim(0, 25) + labs(x="Surface Temperature (˚C)", title="American Butterfish - Temperature Spline")
but_depth_plot = plot_gam_spline(depth_smooth)+ylim(-10, 10) + xlim(0, 200) + labs(x="Depth (m)", title="American Butterfish - Depth Spline")
but_salt_splot = plot_gam_spline(salt_smooth)+ylim(-10, 10) + xlim(30, 35) + labs(x="Salinity (psu)", title="American Butterfish - Salinity Spline")
but_plots = gridPrint(but_temp_plot, but_salt_splot, but_depth_plot, ncol=3)
ggsave("../../figs/habitat-models/splines/but-splines.png", but_plots, width=15, height=5, dpi=500, units="in")


gridPrint(cod_temp_plot, cod_depth_plot, cod_salt_splot,
          had_temp_plot, had_depth_plot, had_salt_splot,
          flo_temp_plot, flo_depth_plot, flo_salt_splot,
          mac_temp_plot, mac_depth_plot, mac_salt_splot,
          but_temp_plot, but_depth_plot, but_salt_splot,
          nrow=5, ncol=3)

