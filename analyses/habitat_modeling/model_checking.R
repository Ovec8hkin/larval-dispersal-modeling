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

fish_datasets = list(cod_catch_data, had_catch_data, flo_catch_data, mac_catch_data, but_catch_data)

# ----------- Model Formulas --------- #
model_t = catch~s(sfc_temp)
model_h  = catch~s(depth)
model_th = catch~s(depth)+s(sfc_temp)
model_ths = catch~s(depth)+s(sfc_temp)+s(sfc_salt)
model_thf = catch~s(depth)+s(sfc_temp)+btm_sub

models = list(model_t, model_h, model_th, model_ths, model_thf)
dataframes = c()
for(f in fish_datasets){
  aic_scores = c()
  df = data.frame(row.names=c("temp", "depth", "temp-depth", "temp-depth-salt", "temp-depth-floor"))
  for(m in models){
    model.fitted = gam(m, data=f, family="nb")
    aic_scores = c(aic_scores, model.fitted$aic)
  }
  weights = qpcR::akaike.weights(aic_scores)
  
  df$aic = aic_scores
  df$daic = weights$deltaAIC
  df$weight = weights$weights
  
  df = df[order(df$aic),]
  
  dataframes = c(dataframes, list(df))
  #dataframes[length(dataframes)+1] = df
  
  print(df)
}
