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

#-----

cod_sum = plot_cumulative_catch(cod_predicted, title="Predicted Cumulative Atlantic Cod Distribution (Jan 1980 - Dec 1989)")
cod_annual = plot_yearly_catch(cod_predicted, title="Predicted Cumulative Atlantic Cod Distribution by Year")
cod_monthly = plot_monthly_catch(cod_predicted, title="Predicted Cumulative Atlantic Cod Distribution by Month")

cod_sum
cod_annual
cod_monthly

#-----
  
had_sum = plot_cumulative_catch(had_predicted, title="Predicted Cumulative Haddock Distribution (Jan 1980 - Dec 1989)")
had_annual = plot_yearly_catch(had_predicted, title="Predicted Cumulative Haddock Distribution by Year")
had_monthly = plot_monthly_catch(had_predicted, title="Predicted Cumulative Haddock Distribution by Month")

had_sum
had_annual
had_monthly

#-----

flo_sum = plot_cumulative_catch(flo_predicted, title="Predicted Cumulative Yellowtail Flounder Distribution (Jan 1980 - Dec 1989)")
flo_annual = plot_yearly_catch(flo_predicted, title="Predicted Cumulative Yellowtail Flounder Distribution by Year")
flo_monthly = plot_monthly_catch(flo_predicted, title="Predicted Cumulative Yellowtail Flounder Distribution by Month")
flo_mean = plot_average_catch(flo_predicted, title="Predicted Average Yellowtail Flounder Distribution")

flo_sum
flo_annual
flo_monthly
flo_mean
#-----

mac_sum = plot_cumulative_catch(mac_predicted, title="Predicted Cumulative Atlantic Mackerel Distribution (Jan 1980 - Dec 1989)")
mac_annual = plot_yearly_catch(mac_predicted, title="Predicted Cumulative Atlantic Mackerel Distribution by Year")
mac_monthly = plot_monthly_catch(mac_predicted, title="Predicted Cumulative Atlantic Mackerel Distribution by Month")

mac_sum
mac_annual
mac_monthly

#-----

but_sum = plot_cumulative_catch(but_predicted, title="Predicted Cumulative American Butterfish Distribution (Jan 1980 - Dec 1989)")
but_annual = plot_yearly_catch(but_predicted, title="Predicted Cumulative American Butterfish Distribution by Year")
but_monthly = plot_monthly_catch(but_predicted, title="Predicted Cumulative American Butterfish Distribution by Month")

but_sum
but_annual
but_monthly

grid.arrange(cod_annual, had_annual, flo_annual, mac_annual, but_annual)



