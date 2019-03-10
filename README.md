# Hotel Price Recommendation
## Introduction
The objective for this project is to recommend optimal pricing in order to maximize profit for a local hotel owner. I was fortunate enough to be able to partner with a local ML startup for this project, and the foundational data used for the exercise was real historical data from one of their clients - a local hotel owner. In order to preserve privacy, the real prices have been transformed and the data provided does not contain any identifiable attributes.

## Approach
The approach for this project can be boiled down to 4 steps:
1. Determine the relationship between the independent variable Price, and the dependent variable Rooms Booked. (Using multiple-regression model's regression coefficient for price)
2. Establish a "baseline" forecast for Rooms Booked assuming constant price.
3. Determine expected profit for the baseline forecast, using additional inputs for a comprehensive profit calculation.
4. Compute resultant profit from changes to the independent variable Price, given the relationship between price, rooms booked, and profit.

Because the project uses real data and will ultimately be delivered to a customer, priority was given to completing all 4 of the above steps, occasionally at the expense of further data collection, model tuning and other refinements. Basically - I took a "prototype" approach, as illustrated below:

![gordon-davis-uncertainty](https://github.com/cmeade001/img/blob/master/gordon-davis-uncertainty.PNG)

This is a truncated version of Gordon Davis' 4 levels of uncertainty, and simply highlights that for the purview of this project the degree of certainty in the output was sacrificed in favor of completeness of the prototype.

## Project Phases
1. Data Collection, Cleanup & Exploration
2. Feature Extraction & Model Validation
3. Forecasting
4. Marginal Returns
5. Optimal Price & Maximum Profit Outputs

## Phase 1 - Data Collection, Cleanup & Exploration
One lesson learned during this project is the time required to gather data in the real world. Additionally, working with small businesses or immature data organizations necessitates more up-front time after collection working on cleanup. The core data used for this project was delivered primarily in PDF format, requiring some manual data entry and table transformation.

In addition, given the industry for the customer of the project - travel - I assumed seasonality would be of paramount importance to the model. I spent time manually researching and compiling local, regional and national events and holidays over the historical period covered in the customer's data - about 4 years. The other challenge presented by seasonal data is that most variables are categorical - eg: day of week, month, holiday, etc. So, after getting input data in a useable format for exploration it also had to be transformed into factors with many more than 2 levels.

One task which was particularly challenging for me (but shouldn't have been, and likely wouldn't be for most people) was creating a factor for days within +/-N days of a holiday - the premise being that a *weekend's proximity* to a holiday and not simply the exact day of a holiday should be a better predictor of changes in booking behavior. I accomplished this using SQL and my script is attached. And, I was relieved to see, this derived variable was strongly correlated and made the cut for the final model :)

## Phase 2 - Feature Extraction & Model Validation
The modeling approach used for this project was multiple regression (lm function in r). There were many more model variations than what's posted in the final script, but the process boiled down to:

1. Input all features
2. Summarize
3. Remove insignificant features (p-value>.05)
4. Input remaining features
n. Repeat

At the end, I was left with 16 IVs which had an adjusted r-squared of ~56%. Not wonderful but not horrible - summary below:

![feature-extraction-final-model](https://github.com/cmeade001/img/blob/master/feature-extraction-final-model.png?raw=true)

I also evaluated this model against several other model generations:

![feature-extraction-cv-output](https://github.com/cmeade001/img/blob/master/feature-extraction-cv-output.png?raw=true)

Surprisingly, the model which featured EVERY independent variable - close to the first generation - performed the best in every measure besides Schwarz's Bayesion Information Criterion - which is easily explained by the fact that this measure more heavily penalizes the number of parameters than any other measure of model fit.

Given the insignificant drop in explained variation (adjusted r squared) between the full model and the model with fewer inputs, I opted to use the smaller model for subsequent outputs. Code for the final model is below:

```
#Final Model
fu002<-lm(booking_total~is_weekend+
            jan+
            feb+
            mar+
            apr+
            may+
            sep+
            oct+
            nov+
            sun+
            mon+
            fri+
            holiday_5+
            websession+
            seosearch45+
          +priceact, data=crs01)
```
One particularly frustrating realization from this process was that the relationship between Price and Rooms Booked is *positive*. This is an issue because as previously stated the approach calls for using Price's coefficient (0.25) as an input to the diminishing returns model, and this coefficient essentially says that for ever $4 increase in price rooms booked will *increase* by 1.

While it's possible that some fluke of psychology leads consumers to have a postivie association with higher hotel prices, it seems more likely to be caused by the fact that hotel pricing is already variable and demand-based. My theory is that the model is picking up on non-causal correlation between seasonal change in price and bookings.

The appropriate solution to validate this theory is to create a seasonally-adjusted price attribute to use in the model. However, given limited time I took a shortcut here - the value I passed to the marginal returns step just cut the price coefficient in half and made it negative. Not particularly scientific, but allows us to build the illustration.

## Phase 3 - Forecasting
Forecasting is where things get fun. Rob Hyndman is the god of forecasting and has all but open-sourced his brain between the r packages and the [content](https://otexts.com/fpp2/) he's published - see references for more information.

Initially, I'd planned to use the lm model from phase 2 to produce the forecast, but in researching Hyndman's textbook I learned about the science behind univariate time-series forecasts and decided to try both in parallel and pick the best one.

### Forecasting with Univariate Time-Series Data
The first step for both methods is converting the modeling data into a time-series (ts) object. From there, you can pretty much run the forecast() package.

![forecast-univariate-time-series](https://github.com/cmeade001/img/blob/master/forecast-univariate-ts.png?raw=true)

Notice the forecast package automatically projects into the future based on the horizon (h) you define for it. Neat.

### Forecasting with Regression
Regression forecasts are a little trickier. I burned a couple of hours trying to figure out why my lm forecasts weren't providing future projections, before I realized the regression forecast isn't using trailing dependent-variable data to project the future - it's using the attributes in the lm model. So, you need to have future observations for your predictors in order to forecast with regression.

There were some predictors in our model which we could have easily created future data for - day of week, month, holidays, etc. Some others would require additional feedback from the customer, which takes time. Still others (web pageviews, paid search queries, etc) wouldn't be possible to collect for future dates. So, how to solve for all three categories quickly? I just ran a ts forecast for ALL predictors, then used the predicted values for the predictors as inputs for the LM forecast. It's a hack, and not something you'd want in a final product, but pretty cool that you could run it in 10 seconds to at least estimate and unblock.

Here is the output for the regression forecast:

![forecast-regression](https://github.com/cmeade001/img/blob/master/forecast-regression.png?raw=true)

Based on the eye-test alone, it's clear that the univariate ts forecast is more appropriate. The highs are too low, lows are too high, and spikes go way higher than any historical observations. The "derivation of a derivation" effect is likely not helping our case.

Remembering that this forecast's foundation is our lm model which is also the father of our Price : Rooms Booked coefficient, a conservative application of the price coefficient in the marginal returns model is advised.

### Forecasting with Limits
One other problem with the base forecast package is that it doesn't have inputs for upper and lower limits. In the case of this project, it's not possible to book fewer than 0 rooms, and the transformed max capacity for the hotel is 90 rooms. So, the upper and lower limits of the forecast are projecting impossible values:

![forecast-before-limits](https://github.com/cmeade001/img/blob/master/forecast-before-limits.png?raw=true)

The solution for this problem is a scaled logit transformation:
```
a=1
b=93
c=tsfppbkttl[,"booking_total"]

#Transform prediction to log scale
unifcst<-forecast(log((c-a)/(b-c)),h=365.25)

#Convert log scale back to original scale
unifcst$mean <- (b-a)*exp(unifcst$mean)/(1+exp(unifcst$mean)) + a
unifcst$lower <- (b-a)*exp(unifcst$lower)/(1+exp(unifcst$lower)) + a
unifcst$upper <- (b-a)*exp(unifcst$upper)/(1+exp(unifcst$upper)) + a
unifcst$x <- c
```
By transforming the forecast in this way we can see the output is now limited by the constraints we gave the model:

![forecast-after-limits](https://github.com/cmeade001/img/blob/master/forecast-after-limits.png?raw=true)

### Forecast Validation
Even though I pretty much wrote off the regression forecast already, I did want to run more formal validation on the univariate time-series forecast. To start, I produced a cross-validation dataset - forecasting a period where I have actual observations, and plotted the result using a loess line to smooth the noise in the daily results:

![forecast-validation](https://github.com/cmeade001/img/blob/master/forecasting-validation.png?raw=true)

This looks good enough to proceed with a prototype, but not as tight as I'd want to see for a production, customer-facing product. Another thing you can't see without the daily data, is the ts() transformations appear to have caused forecast dates to be slightly out of sync with actual.

For more scientific testing, I used checkresiduals() and accuracy() functions, with the following results:

![forecast-residuals](https://github.com/cmeade001/img/blob/master/forecasting-checkresiduals.png?raw=true)

```
> accuracy(unifcst)
                  ME     RMSE     MAE      MPE     MAPE     MASE     ACF1
Training set 59.9755 64.85173 59.9755 98.99535 98.99535 3.378268 0.586669
```
Those results are... not wonderful. The root mean standard error in particular is much higher than benchmarks I've seen in other forecasting work. However, they are better than the lm forecast results, they're the best we have and they're not the worst in the world. This is another area ear-marked for enhancement, and I believe the best approach would be to improve the base lm model and capture future values for the improved model's predictors to use in a regression forecast.

Code for the final univariate TS forecast used in the project is below:
```
#Final Forecast - Univariate TS
#Create dataset for time series vector
fppbkttl<-select(crs01, booking_total, priceact)
#Convert univariate data to time-series vector
tsfppbkttl<-ts(fppbkttl,start=c(2015,1),frequency=365.25)
unifcst<-forecast(tsfppbkttl[,"booking_total"],h=365.25)
plot(unifcst)
pfcst<-forecast(tsfppbkttl[,"priceact"],h=365.25)
write.csv(unifcst,"unifcst01.csv")

#Logit transformation for upper and lower limits
a=1
b=93
c=tsfppbkttl[,"booking_total"]

#Transform prediction to log scale
unifcst<-forecast(log((c-a)/(b-c)),h=365.25)

#Convert log scale back to original scale
unifcst$mean <- (b-a)*exp(unifcst$mean)/(1+exp(unifcst$mean)) + a
unifcst$lower <- (b-a)*exp(unifcst$lower)/(1+exp(unifcst$lower)) + a
unifcst$upper <- (b-a)*exp(unifcst$upper)/(1+exp(unifcst$upper)) + a
unifcst$x <- c
```

## Phase 4 - Marginal Returns
As stated previously, the objective for this project is to find the profit-maximizing combination of hotel price x rooms booked. In addition to the Price : Rooms Booked coefficient and the baseline forecast detailed thus far, we also need the inputs for a profit function. Pretecting anonymity, these dummy values are used for the purpose of this project:

* Fixed hotel cost per night: $1,000
* Cost per occupied room per night: -$75
* Upsell per room per night: $50
* Price : Rooms Booked Coefficient (multiplier): 0.25
* Price : Rooms Booked relationship transformation: -0.5

In addition to these inputs, I constrained the model to cap change in Rooms Booked at +/- 10% from baseline. This is a shortcut to protect us from drastic recommendations, which in the future should be replaced by an exponential decay function.

The ideal process for marginal returns would be building (or finding) an r function to produce step-wise outputs with exponential decay. I couldn't find a suitable function and haven't yet built a fully automated one, so for now the model computes 5 profit steps between -10% < baseline < +10%. We then feed r the association between profit steps and price steps, grab the max profit from each row and return the associated price. Code below:

```
#Output ts() object from unifcst & pfcst. Don't know future list prices so using a forecast as a placeholder.
fcstts<-unifcst$mean
pfcstts<-pfcst$mean

#Profit Table step 1 - Create table, extract date information and forecast from fcstts & pfcst
ptable<-data.frame(date=time(fcstts),blrooms=as.matrix(fcstts),blprice=as.matrix(pfcstts))

#Profit function inputs 
maxb=1.1
midhb=1.05
minb=.9
midlb=.95
p=-.125

#Profit Table step 2 - Add baseline profit, min, mid and max bookings
ptable$blprofit<-(ptable$blrooms*ptable$blprice)-(75*ptable$blrooms)+(50*ptable$blrooms)-1000
ptable$maxrooms<-ptable$blrooms*maxb
ptable$minrooms<-ptable$blrooms*minb
ptable$midhrooms<-ptable$blrooms*midhb
ptable$midlrooms<-ptable$blrooms*midlb

#Profit Table step 3 - build function for diminishing marginal returns. THIS IS A HACK, PLACEHOLDER FOR FUTURE EXPONENTIAL DECAY CURVE.

ptable$price1<-(((ptable$maxrooms-ptable$blrooms)/p)+ptable$blprice)
ptable$price2<-(((ptable$minrooms-ptable$blrooms)/p+ptable$blprice))
ptable$price3<-(((ptable$midhrooms-ptable$blrooms)/p)+ptable$blprice)
ptable$price4<-(((ptable$midlrooms-ptable$blrooms)/p+ptable$blprice))

ptable$profit1<-(ptable$maxrooms*ptable$price1)-(75*ptable$maxrooms)+(50*ptable$maxrooms)-1000
ptable$profit2<-(ptable$minrooms*ptable$price2)-(75*ptable$minrooms)+(50*ptable$minrooms)-1000
ptable$profit3<-(ptable$maxrooms*ptable$price3)-(75*ptable$midhrooms)+(50*ptable$midhrooms)-1000
ptable$profit4<-(ptable$minrooms*ptable$price4)-(75*ptable$midlrooms)+(50*ptable$midlrooms)-1000

#Profit Table step 4 - select profit maximizing price and write into a new column

#Grab max profit from array of steps.
ptable$maxprofit<-apply(ptable[,c(4,13:16)],1,max)

#Grab column index from maxprofit column in order to find associated price.
index<-data.frame(which(ptable[,1:16]==ptable[,17], arr.ind=TRUE))
#Sort to align order to ptable
index<-index[order(index$row),]
#Write colnumber into ptable$index (new field)
ptable$profitindex<-index$col

#If statement to write correct colnumber for price. For reference, here is association between profit columns and price columns: 4:3, 13:9, 14:10, 15:11, 16:12

ptable$priceindex<-ifelse(ptable$profitindex==16,12,ifelse(ptable$profitindex==15,11,ifelse(ptable$profitindex==14,10,ifelse(ptable$profitindex==13,9,ifelse(ptable$profitindex==4,3,"NA")))))

ptable$maxprofitprice<-ifelse(ptable$priceindex==3,ptable$blprice,ifelse(ptable$priceindex==9,ptable$price1,ifelse(ptable$priceindex==10,ptable$price2,ifelse(ptable$priceindex==11,ptable$price3,ifelse(ptable$priceindex==12,ptable$price4,NA)))))

ptable$maxprofitrooms<-ifelse(ptable$priceindex==3,ptable$blrooms,ifelse(ptable$priceindex==9,ptable$maxrooms,ifelse(ptable$priceindex==10,ptable$minrooms,ifelse(ptable$priceindex==11,ptable$midhrooms,ifelse(ptable$priceindex==12,ptable$midlrooms,NA)))))
```

## Phase 5 - Optimal Price & Maximum Profit Outputs
And voila! We have an output.

The model's recommendation to the customer is over the next year, to increase price by an average of +29% in order to increase profit +23% on -10% fewer bookings.

![profit-table](https://github.com/cmeade001/img/blob/master/profit-chart.png?raw=true)

![baseline-vs-max-price](https://github.com/cmeade001/img/blob/master/baseline-v-max-price.png?raw=true)

![baseline-vs-max-profit](https://github.com/cmeade001/img/blob/master/baseline-v-max-profit.png?raw=true)

## Conclusions
To this point, I've kept a laundry list of areas requiring improvement. However, I believe the project in its current form does a good job at demonstrating the concept in a working environment with real recommendations as an output. Given time for improvements, this comes close to an approach which could be applied in a live testing environment.

## References
Hyndman, R.J., & Athanasopoulos, G. (2018) Forecasting: principles and practice, 2nd edition, OTexts: Melbourne, Australia. OTexts.com/fpp2. Accessed on 3/9/18
Rob Hyndman (2018). fpp2: Data for "Forecasting: Principles and Practice" (2nd Edition). R package version 2.3.  https://CRAN.R-project.org/package=fpp2
Davis, G. B. (1982). Strategies for information requirements determination. IBM Systems Journal, 21(1). Retrieved March 09, 2019.
R Core Team (2018). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria. URL https://www.R-project.org/.
