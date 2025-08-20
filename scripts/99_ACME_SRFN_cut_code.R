## Buffer selection

First we need to check which buffer size is most informative for each species, we do this by running the same global model repeatedly but with different buffer sizes, for each species.


Let's start with bears and use purrr to create a global model for every buffer distance

Recall `purrr::map()` is magical for iterations and will apply all the functions within the `map()` function to each item of the list supplied before the the `map()` function.
```{r black bear buffer model, eval=FALSE}

# create models for black bears at each buffer size
black_bear_buff <-  prop_det_data %>%

  # use purrr map to run the same functions for all buffer sizes ((all objects in list))
  purrr::map(
    ~.x %>%
      
      # glm function let's us run the proportional binomial model using cbind to combine the present and absent columns for each species
glm(cbind(black_bear, absent_black_bear) ~
      
      # covariates not correlated
      harvest +
      roads +
      seismic_lines +
      lc_agriculture +  
      lc_broadleaf  +
      lc_grassland  +
      lc_mixed  +
      lc_shrub,
    
    data = .,
    family = 'binomial'))

model.sel(black_bear_buff)


# just testing here how different the results are if we use glmmTMB function instead of glm 

black_bear_buff_TMB <-  prop_det_data %>%
  
  # use purrr map to run the same functions for all buffer sizes ((all objects in list))
  purrr::map(
    ~.x %>%
      
      # glm function let's us run the proportional binomial model using cbind to combine the present and absent columns for each species
      glmmTMB(cbind(black_bear, absent_black_bear) ~
                
                # covariates not correlated
                harvest +
                roads +
                seismic_lines +
                lc_agriculture +  
                lc_broadleaf  +
                lc_grassland  +
                lc_mixed  +
                lc_shrub,
              
              data = .,
              family = 'binomial'))

model.sel(black_bear_buff_TMB)


```

# 
Also of note the model results look exactly the same for both the glm and glmmTMB function- just wanted to test this since we've used both in the past. 




## Elk

Some uncertainty as to whether there are enough detections for this model so we will see, if not may move to the logistic regression model

### Correlation plot

The 1250m buffer was best fit for elk.

Again we will want to print the correlation plot for the buffer the best fit the elk data here for reference when building our models

```{r elk corr plot, warning=FALSE}

# open file to save plot
png("figures/corr_plot_elk.png",
    width = 1000,
    height = 800)

prop_det_data$`1250 meter buffer` %>% 
      
      # select only columns with covariates not other info to simplify the plot a bit
      select(harvest:lc_shrub) %>% 
      
      # use chart.correlation to produce plots for each buffer size 
      chart.Correlation(.,
                        histogram = TRUE, 
                        method = "pearson")

# close file
 dev.off()
```

### Models


```{r elk models}


# Null model
 elk_null <- glm(cbind(elk, absent_elk) ~ 1,
          data = prop_det_data$`1250 meter buffer`,
          family = 'binomial')

# global model
elk_global <- glm(cbind(elk, absent_elk) ~ 
                      scale(harvest_2000) +
                      scale(harvest_pre2000) +
                      scale(roads) + 
                      # scale(pipeline) + 
                      scale(seismic_lines) +
                      # scale(wells) +
                      # scale(lc_agriculture) +  
                      scale(lc_coniferous)  + 
                      scale(lc_grassland)  +
                      scale(lc_mixed)  +
                      scale(lc_shrub),
                    data = prop_det_data$`1250 meter buffer`,
                    family = 'binomial')

# Natural heterogeneity
elk_nat <- glm(cbind(elk, absent_elk) ~   
                      scale(lc_coniferous) +
                      scale(lc_grassland)  +
                      scale(lc_mixed)  +
                      scale(lc_shrub),
                    data = prop_det_data$`1250 meter buffer`,
                    family = 'binomial')

# forest harvest (TBD how this will look with yearly harvest data)
elk_harvest <- glm(cbind(elk, absent_elk) ~ 
                      scale(harvest_2000) +
                      scale(harvest_pre2000),
                    data = prop_det_data$`1250 meter buffer`,
                    family = 'binomial')

# transportation (roads) * at 1250m buffer can't combine with other industrial features (correlated with pipeline & wells)
elk_rds <- glm(cbind(elk, absent_elk) ~ 
                 scale(roads),
               data = prop_det_data$`1250 meter buffer`,
               family = 'binomial')

# linear energy development
elk_linear_energy <- glm(cbind(elk, absent_elk) ~ 
                           scale(pipeline) +
                           scale(seismic_lines),
                         data = prop_det_data$`1250 meter buffer`,
                         family = 'binomial')

# polygonal energy development
elk_poly_energy <- glm(cbind(elk, absent_elk) ~ 
                         scale(wells),
                       data = prop_det_data$`1250 meter buffer`,
                       family = 'binomial')


# energy development - can't do at 1250 pipeline and wells correlated and other two variables are already in a model on their own
# elk_energy <- glm(cbind(elk, absent_elk) ~ 
#                       scale(pipeline) +
#                       scale(seismic_lines) +
#                       scale(wells),
#                     data = prop_det_data$`1250 meter buffer`,
#                     family = 'binomial')


# polygonal disturbance (harvest + polygonal energy development + agriculture)
elk_poly <- glm(cbind(elk, absent_elk) ~ 
                  scale(harvest_2000) +
                  scale(harvest_pre2000) +
                  scale(wells),
                data = prop_det_data$`1250 meter buffer`,
                family = 'binomial')


# linear disturbance (transportation + linear energy development)
elk_linear <- glm(cbind(elk, absent_elk) ~ 
                    # scale(roads) +
                    scale(pipeline) + 
                    scale(seismic_lines),
                  data = prop_det_data$`1250 meter buffer`,
                  family = 'binomial')


# natural cover (natural heterogeneity + harvest + agriculture)
elk_cover <- glm(cbind(elk, absent_elk) ~ 
                   scale(harvest_2000) +
                   scale(harvest_pre2000) +
                   # scale(lc_agriculture) +  correlated with harvest -0.64
                   scale(lc_coniferous) +
                   scale(lc_grassland)  +
                   scale(lc_mixed)  +
                   scale(lc_shrub),
                 data = prop_det_data$`1250 meter buffer`,
                 family = 'binomial')

# overall human disturbance 
elk_disturb <- glm(cbind(elk, absent_elk) ~
                     scale(harvest_2000) +
                     scale(harvest_pre2000) +
                     scale(roads) +
                     # pipeline + can't include correlated
                     scale(seismic_lines),
                   # scale(lc_agriculture), correlated with harvest
                   # wells can't include correlated
                   data = prop_det_data$`1250 meter buffer`,
                   family = 'binomial')

# test for importance of broadleaf vs conifer
elk_conifer <- glm(cbind(elk, absent_elk) ~
                     scale(lc_coniferous),
                   data = prop_det_data$`1250 meter buffer`,
                   family = 'binomial')

elk_broadleaf <- glm(cbind(elk, absent_elk) ~
                       scale(lc_broadleaf),
                     data = prop_det_data$`1250 meter buffer`,
                     family = 'binomial')
```

### Model selection

```{r elk model sel}
# compare elk models
model.sel(elk_null,
          elk_global,
          elk_nat,
          elk_harvest,
          elk_rds,
          elk_linear_energy,
          elk_poly_energy,
          # elk_energy,
          elk_poly,
          elk_linear,
          elk_cover,
          elk_disturb,
          elk_conifer,
          elk_broadleaf)

```

> Elk models seem very sensitive to changes in one variable, global model is in the top two models generally but depends on which of the correlated features (rds, wells, pipelines) that I select. May be sensitive due to fewer detections; I'm going to try elk with the logistic regression as well.

### Top model 

```{r elk top model}

# The top model was the disturbance model

summary(elk_global)
```

### Model assumptions and fit

VIF 
```{r elk VIF}

# print vif
vif(elk_global)

# plot VIF
plot(elk_global,
       which = 1,
       main = 'VIF elk natural model')


# additional plot of each variable
# calculate vif
vif(elk_global) %>%
  
  # Converts the named vector returned by vif() into a tidy tibble
  enframe(name = 'Predictor', 
          value = 'VIF') %>%
  
  # plot with ggplot
  ggplot(aes(x = reorder(Predictor, VIF), # reorders from smallest VIF to largest (not sure I want like this)
             y = VIF)) +
  
  # plot as bars
  geom_bar(stat = 'identity', fill = 'skyblue') +
  
  # add labels
  labs(x = 'Predictor',
       y = 'VIF') +
  
  # set theme
  theme_classic()
```

> Very high VIF for some variables (>10) - possibly because there are some multicollinearity issues (p = 0.6 ish) for some variables at this scale. Let's limit the pearson r for these models to 6 instead of 6-7 and see what we come up with instead.

> When I re-run with no variables at 0.6 correlation or above the top model is disturbance instead of global and the  VIF is better


### Odds

```{r elk odds}

elk_model_odds <- 
  
  # extract the coefficients and upper and lower CI
  tidy(elk_global, conf.int = TRUE) %>% 
  
  # convert the coefficients into odds ratios
  mutate(estimate = exp(estimate),        
         conf.low = exp(conf.low),        
         conf.high = exp(conf.high)) %>%  
  
  # rename columns
  rename('lower' = conf.low,
         'upper' = conf.high) %>%
  
  # Remove intercept for plotting
  filter(term != '(Intercept)') 
```

Get silhouette from phylopic
```{r elk phylopic}

# I copied the uuid from phylopic online because the first silhouette is not the one I wanted to use
elk_img <- get_phylopic('b9a9382d-cb9f-4499-b14e-60faad285bb4')
```

Plot odds

```{r elk odds plot}
# name plot and assign to environment for use later
elk_odds_plot <- 
  
  # provide data and mapping aesthetics
  ggplot(elk_model_odds, aes(x = term, 
                             y = estimate)) +
  
  geom_point() +
  
  geom_errorbar(aes(ymin = lower, 
                    ymax = upper),
                width = 0.2,
                linewidth = 0.5,
                position = position_dodge(width = 0.9)) +
  
  geom_hline(yintercept = 1, linetype = "dashed") +
  
  labs(y = 'Odds ratio') +
  
  scale_x_discrete(labels = c('Harvest post 2000s',
                              'Harvest pre 2000s',
                              'Roads',
                              'Seismic Lines',
                              'Coniferous Forest',
                              'Grassland',
                              'Mixed Forest',
                              'Shrubs')) +
  
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)), 
                     limits = c(-0.5, NA)) +
  
  coord_flip() +
  
  add_phylopic(elk_img, 
               x = 4.2,
               y = 0.1,
               ysize = 0.75) +
  
  theme_classic() +
  
  theme(axis.title.y = element_blank(),
        axis.title = element_text(size = 16),
        axis.text = element_text(size = 14))

# view plot
elk_odds_plot
```
Save plot

```{r save elk odds plot}

ggsave('figures/odds_plot_elk.jpg',
       elk_odds_plot,
       width = 14,
       height = 10,
       units = 'in',
       dpi = 600)
```