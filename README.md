# Hotel Price Recommendation
## Introduction
The objective for this project is to recommend optimal pricing in order to maximize profit for a local hotel owner. I was fortunate enough to be able to partner with a local ML startup for this project, and the foundational data used for the exercise was real historical data from one of their clients - a local hotel owner. In order preserve privacy, the real prices have been transformed and the data provided does not contain any identifiable attributes.

## Approach
The approach for this project can be boiled down to 4 steps:
1. Determine the relationship between the independent variable Price, and the dependent variable Rooms Booked.
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
![feature-extraction-final-model](https://github.com/cmeade001/img/blob/master/feature-extraction-final-model.png?raw=true)
![feature-extraction-cv-output](https://github.com/cmeade001/img/blob/master/feature-extraction-cv-output.png?raw=true)
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

## Phase 3 - Forecasting
![forecast-univariate-time-series](https://github.com/cmeade001/img/blob/master/forecast-univariate-ts.png?raw=true)
![forecast-regression](https://github.com/cmeade001/img/blob/master/forecast-regression.png?raw=true)
![forecast-before-limits](https://github.com/cmeade001/img/blob/master/forecast-before-limits.png?raw=true)
![forecast-after-limits](https://github.com/cmeade001/img/blob/master/forecast-after-limits.png?raw=true)
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
![profit-table](https://github.com/cmeade001/img/blob/master/profit-chart.png?raw=true)
![baseline-vs-max-price](https://github.com/cmeade001/img/blob/master/baseline-v-max-price.png?raw=true)
![baseline-vs-max-profit](https://github.com/cmeade001/img/blob/master/baseline-v-max-profit.png?raw=true)

## Conclusions
To this point, I've kept a laundry list of areas requiring improvement. However, I believe the project in its current form does a good job at demonstrating the concept in a working environment with real recommendations as an output. Given time for improvements, this comes close to an approach which could be applied in a live testing environment.

## References
Hyndman, R.J., & Athanasopoulos, G. (2018) Forecasting: principles and practice, 2nd edition, OTexts: Melbourne, Australia. OTexts.com/fpp2. Accessed on 3/9/18
Rob Hyndman (2018). fpp2: Data for "Forecasting: Principles and Practice" (2nd Edition). R package version 2.3.  https://CRAN.R-project.org/package=fpp2
Davis, G. B. (1982). Strategies for information requirements determination. IBM Systems Journal, 21(1). Retrieved March 09, 2019.

