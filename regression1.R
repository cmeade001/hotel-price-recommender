###-------------Configure Settings-------------------###
options(scipen=999)
save.image(file='myEnvironment.rds')
saveRDS(crs01,"crs01.rds")
crs01test=readRDS(file="crs01.rds")
?readRDS

###--------Install packages and load libraries--------------###
install.packages("dplyr")
install.packages("sqldf")
install.packages("fpp2")
install.packages("caret")
install.packages("GGally")
install.packages("ggplot2")
library(caret)
library(fpp2)
library(sqldf)
library(dplyr)
library(GGally)
library(zoo)
library(xts)
library(ggplot2)


###-------------Legacy Data Cleanup-------------###
#colnames(crs01)[1] <- "date"
crs01$priceact<-as.numeric(crs01$priceact)
crs01[1081,62]="255" #Fill in NA with dummy value.

#crs01<-crs01[-c(412,413,414),]
colnames(crs01)[41]<-"seosearch60"

###----------Feature Extraction models-----------##

##Multiple Regression exploration

model001_dayofweek<-lm(booking_total~sun+mon+tue+wed+thu+fri, data=crs01)
summary(model001_dayofweek)
#Saturday not correlated - basically a given

model002_month<-lm(booking_total~jan+feb+mar+apr+may+sep+oct+nov, data=crs01)
summary(model002_month)
#December is busiest month, July and August have insignificant negative correlation. June won't be significant if give up more DF

model003_holiday<-lm(booking_total~holiday_5+holiday_weekend, data=crs01)
summary(model003_holiday)

  
model004_price<-lm(booking_total~as.numeric(priceact), data=crs01)
summary(model004_price)

fu001<-lm(booking_total~is_weekend+
    jan+
    feb+
    mar+
    apr+
    may+
    jun+
    jul+
    aug+
    sep+
    oct+
    nov+
    dec+
    sun+
    mon+
    tue+
    wed+
    thu+
    fri+
    sat+
    is_holiday+
    holiday_5+
    holiday_weekend+
    websession+
    websession30+
    websession45+
    websession60+
    seosearch+
    seosearch30+
    seosearch45+
    +seosearch60
    +webhit
    +webhit30
    +webhit45
    +webhit60
    +webpv
    +webpv30
    +webpv45
    +webpv60
    +adclick
    +adclick30
    +adclick45
    +adclick60
    +adview
    +adview30
    +adview45
    +adview60
    +adconv
    +adconv30
    +adconv45
    +adconv60
    +priceact, data=crs01)
summary(fu001)

##Reduce to just the significant p-value columns, then reduce again until final IVs are all <.05

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
summary(fu002)

#Evaluate model fit
CV(model001_dayofweek)
CV(model002_month)
CV(model003_holiday)
CV(model004_price)
CV(fu001)
CV(fu002)
#fu002 has the best score in each of the 5 CV measures.

checkresiduals(fu002)

#Residuals mean = 0, but low p value indicates there's still information in the residuals which should be used in computing forecasts.

#Create data subset with only model columns
crs02<-crs01[,c(7,4,9,10,11,12,13,17,18,19,21,22,26,29,34,40,as.numeric(62))]


###---------------Forecast Package Exploration------------#

#Create dataset for time series vector
fppbkttl<-select(crs01, booking_total, priceact)
#Convert univariate data to time-series vector
tsfppbkttl<-ts(fppbkttl,start=c(2015,1),frequency=365.25)

##---OPTION 1 - UNIVARIATE TIME SERIES FORECAST---##
unifcst<-forecast(tsfppbkttl[,"booking_total"],h=365.25)
plot(unifcst)

pfcst<-forecast(tsfppbkttl[,"priceact"],h=365.25)
write.csv(unifcst,"unifcst01.csv")

#Create truncated visualization
vis<-window(tsfppbkttl[,"booking_total"],start=2018)
autoplot(vis) +
    autolayer(unifcst)

?forecast
#Forecast is useable in this format, but want to see if output changes with limits.

##Attempt to set 0,91 limit
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

# Plot result on original scale
plot(unifcst)
unifcst

#Smaller window view
autoplot(vis) +
  autolayer(unifcst)

##------OPTION 2 - REGRESSION MODEL FORECAST------##

#Parameterize forecast horizon
horizon=365.25

#Produce time-series forecast for predictors
tscrs02<-ts(crs02, start=c(2015,1), frequency=365.25)
lmfcst1<-forecast(tscrs02,h=horizon)
##For debugging:

#Write point forecast and read into dataframe object
write.csv(lmfcst1,"lmfcst_step1.csv")
lmfcst1df<-read.csv("lmfcst_step1.csv")

#Create placeholder dataframe for newdata
lmfcst2df<-data.frame(as.matrix(tscrs02[1:365,1:17]))

#Change booking_total colname for Time series placeholder
colnames(lmfcst2df)[colnames(lmfcst2df)=="booking_total"] = "Time"

#Parameterize row numbers for newdata
wes=horizon+1
wee=wes+(horizon-1)
jans=wee+1
jane=jans+(horizon-1)
febs=jane+1
febe=febs+(horizon-1)
mars=febe+1
mare=mars+(horizon-1)
aprs=mare+1
apre=aprs+(horizon-1)
mays=apre+1
maye=mays+(horizon-1)
seps=maye+1
sepe=seps+(horizon-1)
octs=sepe+1
octe=octs+(horizon-1)
novs=octe+1
nove=novs+(horizon-1)
suns=nove+1
sune=suns+(horizon-1)
mons=sune+1
mone=mons+(horizon-1)
fris=mone+1
frie=fris+(horizon-1)
hols=frie+1
hole=hols+(horizon-1)
webs=hole+1
webe=webs+(horizon-1)
seos=webe+1
seoe=seos+(horizon-1)
pris=seoe+1
prie=pris+(horizon-1)

#Replace newdata dataframe placeholders with lmfcst1 point values

lmfcst2df$Time<-lmfcst1df[1:365,2]
lmfcst2df$is_weekend<-lmfcst1df[wes:wee,4]
lmfcst2df$jan<-lmfcst1df[jans:jane,4]
lmfcst2df$feb<-lmfcst1df[febs:febe,4]
lmfcst2df$mar<-lmfcst1df[mars:mare,4]
lmfcst2df$apr<-lmfcst1df[aprs:apre,4]
lmfcst2df$may<-lmfcst1df[mays:maye,4]
lmfcst2df$sep<-lmfcst1df[seps:sepe,4]
lmfcst2df$oct<-lmfcst1df[octs:octe,4]
lmfcst2df$nov<-lmfcst1df[novs:nove,4]
lmfcst2df$sun<-lmfcst1df[suns:sune,4]
lmfcst2df$mon<-lmfcst1df[mons:mone,4]
lmfcst2df$fri<-lmfcst1df[fris:frie,4]
lmfcst2df$holiday_5<-lmfcst1df[hols:hole,4]
lmfcst2df$websession<-lmfcst1df[webs:webe,4]
lmfcst2df$seosearch45<-lmfcst1df[seos:seoe,4]
lmfcst2df$priceact<-lmfcst1df[pris:prie,4]

#Produce new dataset to ensure newdata datatypes match modeled datattypes

crs03<-crs02
crs03$is_weekend<-as.numeric(crs03$is_weekend)
crs03$jan<-as.numeric(crs03$jan)
crs03$feb<-as.numeric(crs03$feb)
crs03$mar<-as.numeric(crs03$mar)
crs03$apr<-as.numeric(crs03$apr)
crs03$may<-as.numeric(crs03$may)
crs03$sep<-as.numeric(crs03$sep)
crs03$oct<-as.numeric(crs03$oct)
crs03$nov<-as.numeric(crs03$nov)
crs03$sun<-as.numeric(crs03$sun)
crs03$mon<-as.numeric(crs03$mon)
crs03$fri<-as.numeric(crs03$fri)
crs03$holiday_5<-as.numeric(crs03$holiday_5)
crs03$websession<-as.numeric(crs03$websession)
crs03$seosearch45<-as.numeric(crs03$seosearch45)
crs03$priceact<-as.numeric(crs03$priceact)

#Produce new lm model with the revised datatypes

fu003<-lm(booking_total~is_weekend+
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
            +priceact, data=crs03)
summary(fu003)

#Produce booking_total forecast for newdata date range

lmfcst3<-forecast(fu003, newdata=lmfcst2df)
lmfcst3
write.csv(lmfcst3, "lmfcst_final.csv")
plot(lmfcst3$mean)

autoplot(vis) +
  autolayer(lmfcst3)


##-------EVALUATING FORECAST ACCURACY---------##

#Create forecast for historical period
d<-tsfppbkttl[,1]
val<-window(d,start=c(2015,1), end=c(2018,31))
valfc<-forecast(val,h=365.25)
plot(valfc)

#Set limits
c<-val
valfc<-forecast(log((c-a)/(b-c)),h=365.25)

#Convert log scale back to original scale
valfc$mean <- (b-a)*exp(valfc$mean)/(1+exp(valfc$mean)) + a
valfc$lower <- (b-a)*exp(valfc$lower)/(1+exp(valfc$lower)) + a
valfc$upper <- (b-a)*exp(valfc$upper)/(1+exp(valfc$upper)) + a
valfc$x <- c

#Grab forecast (vala) and actuals (valb)
vala<-valfc$mean
valb<-window(d, start=c(2018,32))
valc<-data.frame(date=time(valb),vala,valb)

#Visualize
autoplot(vala, series = "Predicted")+
         autolayer(valb, series = "Actual")+
         xlab("Year") + ylab("Bookings")

valplot<-ggplot(valc,aes(date))+
  xlab("Date")+
  ylab("Rooms Booked")+
  geom_smooth(aes(y=vala, colour="Predicted"))+
  geom_smooth(aes(y=valb, colour="Actual"))
valplot

accuracy(unifcst)


######################################################################################---------------------------------------------------------------------------------------------------BEGIN PROFIT MODEL---------------------------------------------------------------------------------------------------------------------------------------------------------------------#################################################################################

#Output ts() object from unifcst & pfcst. Don't know future list prices so using a forecast as a placeholder.
fcstts<-unifcst$mean
pfcstts<-pfcst$mean

#Profit Table step 1 - Create table, extract date information and forecast from fcstts & pfcst

###STILL NEED TO WRITE A FUNCTION TO PARSE TIME DECIMAL TO DAY WHOLE NUMBER AND WRITE INTO DATE FORMAT3333

ptable<-data.frame(date=time(fcstts),blrooms=as.matrix(fcstts),blprice=as.matrix(pfcstts))
#rm(ptable)

#Price equation inputs for reference:
#Fixed hotel cost per night -1000
#Cost per room per night	-75
#Max boost	10%
#Min boost	-10%
#Avg Upsell	50
#Inc. bookings per dollar change	0.25
#Discount Factor	0.5
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

finaloutput<-ptable[,c(1,2,3,4,17,20,21)]
finaloutput$incprofit<-finaloutput$maxprofit-finaloutput$blprofit
finaloutput$incprofitpercent<-(finaloutput$maxprofit-finaloutput$blprofit)/finaloutput$blprofit
finaloutput$pricediff<-finaloutput$maxprofitprice-finaloutput$blprice
finaloutput$pricediffpercent<-finaloutput$pricediff/finaloutput$blprice
finaloutput$incbookings<-finaloutput$maxprofitrooms-finaloutput$blrooms
finaloutput$incbookingspercent<-finaloutput$incbookings/finaloutput$blrooms

sum(finaloutput$maxprofit)
sum(finaloutput$blprofit)
mean(finaloutput$maxprofitrooms)
mean(finaloutput$blrooms)
mean(finaloutput$maxprofitprice)
mean(finaloutput$blprice)
sum(finaloutput$incprofit)/sum(finaloutput$blprofit)
sum(finaloutput$pricediff)/sum(finaloutput$blprice)
sum(finaloutput$incbookings)/sum(finaloutput$blrooms)

#Model recommendation: over 1 year, increase price on avg +29% to drive +23% profit on -10% bookings.

#Baseline vs. Profit max rooms
rooms<-ggplot(finaloutput,aes(date))+
  xlab("Date")+
  ylab("Rooms Booked")+
  geom_smooth(aes(y=blrooms, colour="Baseline"))+
  geom_smooth(aes(y=maxprofitrooms, colour="Profit Max"))
rooms2

rooms<-ggplot(finaloutput,aes(date))+
  xlab("Date")+
  ylab("Rooms Booked")+
  geom_line(aes(y=blrooms, colour="Baseline"))+
  geom_line(aes(y=maxprofitrooms, colour="Profit Max"))
rooms2

#Baseline vs. Profit max pricing
price<-ggplot(finaloutput,aes(date))+
  xlab("Date")+
  ylab("Price")+
  geom_smooth(aes(y=blprice, colour="Baseline"))+
  geom_smooth(aes(y=maxprofitprice, colour="Profit Max"))
price

price2<-ggplot(finaloutput,aes(date))+
  xlab("Date")+
  ylab("Price")+
  geom_line(aes(y=blprice, colour="Baseline"))+
  geom_line(aes(y=maxprofitprice, colour="Profit Max"))
price2

#Baseline vs. Profit max Profit
profit<-ggplot(finaloutput,aes(date))+
  xlab("Date")+
  ylab("Profit")+
  geom_line(aes(y=blprofit, colour="Baseline"))+
  geom_line(aes(y=maxprofit, colour="Profit Max"))
profit

profit2<-ggplot(finaloutput,aes(date))+
  xlab("Date")+
  ylab("Profit")+
  geom_smooth(aes(y=blprofit, colour="Baseline"))+
  geom_smooth(aes(y=maxprofit, colour="Profit Max"))
profit2

#Change in price vs. change in profit

priceprofit<-ggplot(finaloutput,aes(date))+
  xlab("Date")+
  ylab("Price")+
  geom_line(aes(y=incprofit, colour="Inc Profit"))+
  geom_line(aes(y=pricediff, colour="Price Change"))
priceprofit

priceprofit<-ggplot(finaloutput,aes(date))+
  xlab("Date")+
  ylab("Price")+
  geom_smooth(aes(y=incprofit, colour="Inc Profit"))+
  geom_smooth(aes(y=pricediff, colour="Price Change"))
priceprofit

###-----Appendix - Visualizations-----##

#Price:Bookings Visualization

crs01 %>%
  as.data.frame() %>%
  ggplot(aes(x=priceact, y=booking_total)) +
  ylab("Rooms Booked") +
  xlab("Avg Price") +
  geom_point() +
  geom_smooth(method="lm", se=FALSE)

crs02[,c(1,2,3,4)] %>%
  as.data.frame() %>%
  GGally::ggpairs()

ggseasonplot(tsfppbkttl[,"booking_total"]) +
  ggtitle("Bookings by Day") +
  xlab("Year")+
  ylab("Rooms")

ggseasonplot(tsfppbkttl[,"booking_total"])

#Citations
citation(package="fpp2")

