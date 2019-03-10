# Hotel Price Recommendation
## Introduction
The objective for this project is to recommend optimal pricing in order to maximize profit for a local hotel owner. I was fortunate enough to be able to partner with a local ML startup for this project, and the foundational data used for the exercise was real historical data from one of their clients - a local hotel owner. In order preserve privacy, the real prices have been transformed and the data provided does not contain any identifiable attributes.

## Approach


## Project Phases
1. Data Collection & Cleanup
2. Data Enhancement & Exploration
3. Feature Extraction & Model Validation
4. Forecasting
5. Marginal Returns
6. Optimal Price & Maximum Profit Outputs

## Phase 1 - Data Collection & Cleanup
## Phase 2 - Data Enhancement & Exploration
## Phase 3 - Feature Extraction & Model Validation
```

```
## Phase 4 - Forecasting

```

```
## Phase 5 - Marginal Returns

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

## Phase 6 - Optimal Price & Maximum Profit Outputs
![baseline-vs-max-price](https://github.com/cmeade001/img/blob/master/baseline-v-max-price.png?raw=true)
![baseline-vs-max-profit](https://github.com/cmeade001/img/blob/master/baseline-v-max-profit.png?raw=true)

## Conclusions

## References
Hyndman, R.J., & Athanasopoulos, G. (2018) Forecasting: principles and practice, 2nd edition, OTexts: Melbourne, Australia. OTexts.com/fpp2. Accessed on 3/9/18
Rob Hyndman (2018). fpp2: Data for "Forecasting: Principles and Practice" (2nd Edition). R package version 2.3.  https://CRAN.R-project.org/package=fpp2
