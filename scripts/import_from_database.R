require("RPostgreSQL")
require("RPostgres")

# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")

# creates a connection to the postgres database
# note that "con" will be used later in each connection to the database
user <- "romunov"  # obviously, change this to your username

con <- dbConnect(
  RPostgres::Postgres(),
  host = "osug-postgres.u-ga.fr",
  user = user,
  password = rstudioapi::askForPassword(prompt = sprintf("Enter password for %s", user)),
  dbname = "bearconnect",
  sslcert = "~/.postgresql/grenoble.crt",
  sslkey = "~/.postgresql/romunov.key"
)

#Check database's tables
dbListTables(con)

# Captured animals query
# format: dataframe

animals=dbGetQuery(con,"SELECT ani.t_ani_id,ani.t_ani_origin_id,ani.t_ani_name,t_ani_sex,resgroup.t_resgroup_name,pop.t_final_pop_name
                   from t_animal_ani ani
                   inner join t_population_pop pop on ani.t_ani_pop_id=pop.t_pop_id
                   inner join t_capture_cap cap on cap.cap_ani_id=ani.t_ani_id
                   inner join t_researchgroup_resgroup resgroup on resgroup.t_resgroup_id=cap.cap_resgroup_id")


# Locations query
# format: dataframe
locations=dbGetQuery(con,"SELECT ani.t_ani_id,ani.t_ani_origin_id,ani.t_ani_name,resgroup.t_resgroup_name,pop.t_final_pop_name,loc.t_loc_x,loc.t_loc_y,loc.t_loc_dop,loc.t_loc_nav,cast(loc.t_loc_datetimestamp as text)
                        from t_localisation_loc loc
                        inner join t_animal_sensor_anse anse on loc.t_loc_anse_id=anse.t_anse_id
                        inner join t_animal_ani ani on anse.t_anse_ani_id=ani.t_ani_id
                        inner join t_population_pop pop on ani.t_ani_pop_id=pop.t_pop_id
                        inner join t_capture_cap cap on cap.cap_ani_id=ani.t_ani_id
                        inner join t_researchgroup_resgroup resgroup on resgroup.t_resgroup_id=cap.cap_resgroup_id")


# Genotypes query
# format: dataframe

genotypes=dbGetQuery(con,"SELECT distinct gensam.t_gensam_origin_id_sample, ani.t_ani_id animal_id,ani.t_ani_origin_id,ani.t_ani_name animal_name,ani.t_ani_sex sex,resgroup.t_resgroup_name research_group,pop.t_final_pop_name pop_name,gensam.t_gensam_id_sample id_sample,gensam.t_gensam_collection_date collection_date,gensam.t_gensam_x_sample_location x,gensam.t_gensam_y_sample_location y,samtype.t_samtype_typename type_name,samdes.t_samdes_name design,sammeth.t_sammeth_name method_name,sammeth.t_sammeth_invasiveness invasiveness
                     from t_genetic_samples_gensam gensam
                     inner join t_genetic_samples_loci_gensamlo gensamlo on gensam.t_gensam_id_sample=gensamlo.t_gensamlo_id_sample
                     left join t_sampling_sampletype_samtype samtype on samtype.t_samtype_id=gensam.t_gensam_sampletype_id
                     left join t_sampling_design_samdes samdes on samdes.t_samdes_id=gensam.t_gensam_sampling_design
                     left join t_sampling_method_sammeth sammeth on sammeth.t_sammeth_id=gensam.t_gensam_sampling_method
                     inner join t_animal_ani ani on gensam.t_gensam_ani_id=ani.t_ani_id
                     inner join t_population_pop pop on ani.t_ani_pop_id=pop.t_pop_id
                     inner join t_researchgroup_resgroup resgroup on resgroup.t_resgroup_id=gensam.t_gensam_resgroup_id")

# Microsat query
# format: dataframe

microsat <- dbGetQuery(con, "SELECT ani.t_ani_id animal_id,ani.t_ani_origin_id,ani.t_ani_name animal_name,ani.t_ani_sex sex,resgroup.t_resgroup_name research_group,pop.t_final_pop_name pop_name,gensam.t_gensam_id_sample id_sample,gensam.t_gensam_collection_date collection_date,gensam.t_gensam_x_sample_location x,gensam.t_gensam_y_sample_location y,samtype.t_samtype_typename type_name,samdes.t_samdes_name design,sammeth.t_sammeth_name method_name,sammeth.t_sammeth_invasiveness invasiveness,msat.t_msat_loci_name loci_name,gensamlo.t_gensam_loci_all1_size size_all1,gensamlo.t_gensam_loci_all2_size size_all2
                    from t_genetic_samples_gensam gensam
                    inner join t_genetic_samples_loci_gensamlo gensamlo on gensam.t_gensam_id_sample=gensamlo.t_gensamlo_id_sample
                    inner join t_microsat_msat msat on gensamlo.t_gensamlo_loci_id=msat.t_msat_id
                    left join t_sampling_sampletype_samtype samtype on samtype.t_samtype_id=gensam.t_gensam_sampletype_id
                    left join t_sampling_design_samdes samdes on samdes.t_samdes_id=gensam.t_gensam_sampling_design
                    left join t_sampling_method_sammeth sammeth on sammeth.t_sammeth_id=gensam.t_gensam_sampling_method
                    inner join t_animal_ani ani on gensam.t_gensam_ani_id=ani.t_ani_id
                    inner join t_population_pop pop on ani.t_ani_pop_id=pop.t_pop_id
                    inner join t_researchgroup_resgroup resgroup on resgroup.t_resgroup_id=gensam.t_gensam_resgroup_id")

############ Those lines below are just here to pivot the microsat table
############ Pivot table for Allele 1 size column
allsize1=as.data.frame(tapply(microsat$size_all1,list(microsat$id_sample,microsat$loci_name),mean))
############ Pivot table for Allele 2 size column
allsize2=as.data.frame(tapply(microsat$size_all2,list(microsat$id_sample,microsat$loci_name),mean))


########### Recombine the colums to get the right format
allall = data.frame(ID = rownames(allsize1))
allall = cbind(allall, allsize1[,1,drop=F],allsize2[,1,drop=F])
for(i in 2:ncol(allsize1))
{
  allall = cbind(allall, allsize1[,i,drop=F])
  allall = cbind(allall, allsize2[,i,drop=F])
}

########## Final output
MicrosatOutput=merge(x=genotypes,y=allall,by.x='id_sample',by.y='ID',all.x="TRUE")


########################################
save(microsat, file = "./scripts/grenoble_microsat.RData")
########################################

library(tidyr)

xy <- pivot_wider(
  data = microsat,
  id_cols = c(animal_id, pop_name, id_sample),
  names_from = loci_name,
  values_from = c(size_all1, size_all2))