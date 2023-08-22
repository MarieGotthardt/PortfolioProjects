# Project Work for KTH Course Regression Analysis (SF2930): Large-Sample Regression Project on Body Mass Fat Data 

install.packages("TH.data")
install.packages("leaps")
install.packages("car")
install.packages("carData")
install.packages("MASS")
install.packages("olsrr")
install.packages("boot")

library("TH.data")
library(leaps)
library(car)
library(MASS)
library(olsrr)
library(boot)

##### GET AND EXPLORE DATA #####
data("bodyfat")

??bodyfat
bodyfat
show(bodyfat)

# scatterplot
plot(bodyfat, pch = 10, col = "orange")

x <- model.matrix(DEXfat ~ . -1, data = bodyfat)
y <- bodyfat$DEXfat

# show best models
bestmods <- leaps(x, y, nbest=1)
bestmods
bestmods$Cp
min(bestmods$Cp)



##### FIT LARGEST MODEL POSSIBLE ######
init_model <- lm(bodyfat$DEXfat ~ bodyfat$age + bodyfat$waistcirc + bodyfat$hipcirc + bodyfat$elbowbreadth + bodyfat$kneebreadth + bodyfat
           $anthro3a + bodyfat$anthro3b + bodyfat$anthro3c + bodyfat$anthro4, data = bodyfat)
summary(init_model) #p-value: <2.2e-16 -> sign; R-squared: 0.9231, adj_R-squared: 0.9117
anova(init_model)

summary(init_model)$coefficients #waistcirc, hipcirc, kneebreadth

# determine variance inflation factors to detect mutlicollinearity -> aiming for low VIFs
vif(init_model) 


##### ANALYSIS OF THE MODEL #####
# create correlation matrix
x <- model.matrix(DEXfat ~ . -1, data = bodyfat)
cor(x)

# calculate residuals
residuals <- resid(init_model)

# standardized and studentized residuals
standard.residulas <- rstandard(init_model)
studentized.residuals <- studres(init_model)
sorted.stud.res <- sort(studentized.residuals)

# qqnormplot 
#studentized residuals
y_expression <- expression(t[i])
qqnorm(sorted.stud.res, xlab = expression(p[i]),  ylab = y_expression)
qqline(sorted.stud.res) #negative skew probably

#standardized residuals
qqnorm(standard.residulas)
qqline(standard.residulas)

### studentized residuals vs. fitted response y-hat
init_model$fitted.values
plot(model$fitted.values, studentized.residuals)
abline(h=0)

##### TRANSFORMATION OF RESPONSE/ REGRESSORS #####
# log transformation of response 
resp.log.model <- lm(log(bodyfat$DEXfat) ~ bodyfat$age + bodyfat$waistcirc + bodyfat$hipcirc + bodyfat$elbowbreadth + bodyfat$kneebreadth + bodyfat$anthro3a + bodyfat$anthro3b + bodyfat$anthro3c + bodyfat$anthro4, data = bodyfat)
summary(resp.log.model) #waistcirc, hipcirc, kneebreadth, anthro3c sign, R-squared: 0.9408, adj_R-squared: 0.932
write.csv(summary(resp.log.model))

# residuals
resp.log.residuals <- resid(resp.log.model)
standard.resp.log.residulas <- rstandard(resp.log.model)
studentized.resp.log.residuals <- studres(resp.log.model)

# qqnormplot
qqnorm(sort(studentized.resp.log.residuals))
qqline(sort(studentized.resp.log.residuals)) #looks definetely better with the log

# response vs. stud resid
resp.log.model$fitted.values
plot(resp.log.model$fitted.values, studentized.resp.log.residuals)
abline(h=0) #not sure if there is some kind of curve now

# regressor vs. stud resid
plot(bodyfat$kneebreadth, studentized.resp.log.residuals)

##### OUTLIERS #####
# look at studentized residuals greater 2
which(studentized.resp.log.residuals > 3 | studentized.resp.log.residuals < -3 ) #73 or 27, 91 or 45, 92 or 46
sort(studentized.resp.log.residuals)
mean(studentized.resp.log.residuals)
sd(studentized.resp.log.residuals)
which(abs(studentized.resp.log.residuals - mean(studentized.resp.log.residuals)) > 3*sd(studentized.resp.log.residuals))

# leverage points
# each point with h_ii value > 2*p/n is a leverage point
hats <- as.data.frame(hatvalues(resp.log.model))
hats 
hats_outliers <- which(hats > 2*ncol(bodyfat)/nrow(bodyfat)) #25, 67 or 71 and 113
hats_outliers
studentized.resp.log.residuals[c(25, 67)]
rbind(c("hat-values", "Studentized residuals"), cbind(hats[c(25, 67),], studentized.resp.log.residuals[c(25, 67)]))

# cooks distance
cook <- cooks.distance(resp.log.model)
print(cook > 0.5)
plot(cooks.distance(resp.log.model))

# influence measures
influence_measures <- influence.measures(resp.log.model)

# options("max.print"=10000) fct to increase number of printed lines
influence_measures #71, 73, 82, 112, 113 -> same as for the plot

# dffits
df_fits <- dffits(resp.log.model)
df_fits

# cut-off of | DFFITSi|>2*sqrt(p/n)
outlier_df_fits <- which(abs(df_fits) > 2*sqrt(ncol(bodyfat)/nrow(bodyfat)))
outlier_df_fits #71, 73, 81, 91, 92 or 25, 27, 35, 45, 46 

# dfbetas
bodyfat.df_betas <- dfbetas(resp.log.model)

# cutoff | DFBETASij|>2/sqrt(n)
dfbetas.cutoff <- 2 / sqrt(nrow(bodyfat))


bodyfat.df_betas[abs(bodyfat.df_betas[, 1]) > dfbetas.cutoff, 1]  # beta_0: 71, 73, 78, 81, 92, 116
bodyfat.df_betas[abs(bodyfat.df_betas[, 2]) > dfbetas.cutoff, 2]  # beta_1: 100, 109
bodyfat.df_betas[abs(bodyfat.df_betas[, 3]) > dfbetas.cutoff, 3]  # beta_2: 50, 64, 67, 73, 78, 90, 101
bodyfat.df_betas[abs(bodyfat.df_betas[, 4]) > dfbetas.cutoff, 4]  # beta_3: 64, 66, 71, 73, 78, 91, 92, 100, 101, 116, 117
bodyfat.df_betas[abs(bodyfat.df_betas[, 5]) > dfbetas.cutoff, 5]  # beta_4: 71, 73, 78, 81, 91, 116, 117
bodyfat.df_betas[abs(bodyfat.df_betas[, 6]) > dfbetas.cutoff, 6]  # beta_5: 72, 73, 81, 87, 91, 94. 116, 117
bodyfat.df_betas[abs(bodyfat.df_betas[, 7]) > dfbetas.cutoff, 7]  # beta_6: 66, 71, 81, 91, 111
bodyfat.df_betas[abs(bodyfat.df_betas[, 8]) > dfbetas.cutoff, 8]  # beta_7: 60, 69, 71, 73, 83, 91, 111
bodyfat.df_betas[abs(bodyfat.df_betas[, 9]) > dfbetas.cutoff, 9]  # beta_8: 67, 92, 111
bodyfat.df_betas[abs(bodyfat.df_betas[, 10]) > dfbetas.cutoff, 10]# beta_9: 60, 69, 71, 73, 91, 111

ols_plot_dfbetas(resp.log.model)

overview <- list(leverage_pts, outlier_df_fits, outlier_cov_rat)
overview

# measure of model performance: covratio
cov_rat <- covratio(resp.log.model)
cov_rat
outlier_cov_rat <- which(cov_rat > (1 + 3* ncol(bodyfat)/nrow(bodyfat))| cov_rat < (1 - 3* ncol(bodyfat)/nrow(bodyfat)))
outlier_cov_rat #24, 27, 36, 50, 66, 67 or 70, 73, 82, 96, 112, 113

# plots
# residuals, outliers, leverage points
ols_plot_resid_lev(resp.log.model) #outlier: 27, 45, 46; leverage: 25, 67

# cooks distance
ols_plot_cooksd_bar(resp.log.model) #25, 27, 35, 45, 46


##### EXCLUDE OUTLIERS #####
outlier_leverage <- c(27)
bodyfat_cleaned <- bodyfat[-outlier_leverage, ]
cleaned_model <- lm(log(bodyfat_cleaned$DEXfat) ~ bodyfat_cleaned$age + bodyfat_cleaned$waistcirc + bodyfat_cleaned$hipcirc + bodyfat_cleaned$elbowbreadth + bodyfat_cleaned$kneebreadth + bodyfat_cleaned$anthro3a + bodyfat_cleaned$anthro3b + bodyfat_cleaned$anthro3c + bodyfat_cleaned$anthro4, data = bodyfat_cleaned)
summary(cleaned_model) #excluding obs 27 leads to adjr2: 09459, r2: 9529

ols_plot_resid_lev(cleaned_model) #35 still outlier, 62 leverage 

stud_res_cleaned <- rstudent(cleaned_model)

qqnorm(sort(stud_res_cleaned), ylim = c(-2, 4))
qqline(sort(stud_res_cleaned))


# leaps
# Cp
log_resp_data <- cbind(bodyfat$age, bodyfat$waistcirc, bodyfat$hipcirc, bodyfat$elbowbreadth, bodyfat$kneebreadth, bodyfat$anthro3a, bodyfat$anthro3b, bodyfat$anthro3c, bodyfat$anthro4)
x_log_resp <- log_resp_data
y_log_resp <- bodyfat$logDEXfat
bestmods <- leaps(x_log_resp, y_log_resp, nbest=1)
bestmods #6 regressors: age, waist, hip, knee, anthro3b, anthro3c
bestmods$Cp
min(bestmods$Cp)

# adjr
bestmodsadjr <- leaps(x_log_resp, y_log_resp, nbest=1, method = "adjr2")
bestmodsadjr
max(bestmodsadjr) #min 5, 5 or 6 are the highest


# log transformation of regressors
log.model <- lm(log(bodyfat$DEXfat) ~ log(bodyfat$age) + log(bodyfat$waistcirc) + log(bodyfat$hipcirc) + log(bodyfat$elbowbreadth) + log(bodyfat$kneebreadth) + bodyfat
                     $anthro3a + bodyfat$anthro3b + bodyfat$anthro3c + bodyfat$anthro4, data = bodyfat)
summary(log.model) #R-squared: 0.9452, adjusted R-squared: 0.9371

# residuals 
log.residuals <- resid(log.model)
standard.log.residulas <- rstandard(log.model)
studentized.log.residuals <- studres(log.model)

# qqnormplot
qqnorm(sort(studentized.log.residuals))
qqline(sort(studentized.log.residuals))

# response vs. stud resid
log.model$fitted.values
plot(log.model$fitted.values, studentized.log.residuals)
abline(h=0) 

# regressor vs. stud resid
plot(bodyfat$loghipcirc, studentized.log.residuals)

# plot for comparison of log regressors vs. non-log
par(mfrow=c(1, 2))
plot(log.model$fitted.values, studentized.log.residuals)
plot(resp.log.model$fitted.values, studentized.resp.log.residuals)

# leaps
log_data <- cbind(bodyfat$logage, bodyfat$logwaistcirc, bodyfat$loghipcirc, bodyfat$logelbowbreadth, bodyfat$logkneebreadth, bodyfat$anthro3a, bodyfat$anthro3b, bodyfat$anthro3c, bodyfat$anthro4)
x_log <- log_data
y_log <- bodyfat$logDEXfat
bestmods <- leaps(x_log, y_log, nbest=1)
bestmods$Cp
min(bestmods$Cp)

##### MODEL SELECTION #####
# Cp, BIC, adjR2
cleaned_models <- regsubsets(log(DEXfat) ~., data = bodyfat_cleaned)
res.sum_cleaned <- summary(cleaned_models)
res.sum_cleaned
#coef(models, 6)

cbind( 
  names <- res.sum_cleaned$which,
  Cp    <-  res.sum_cleaned$cp,
  r2     <- res.sum_cleaned$rsq,
  Adj_r2 <- res.sum_cleaned$adjr2, #age, waistcir, hipcir, kneebreath, anthro3b, anthro3c
  BIC    <- res.sum_cleaned$bic
)

# summary
data.frame(
  Adj.R2 = which.max(res.sum_cleaned$adjr2), #6
  CP = which.min(res.sum_cleaned$cp), #6
  BIC = which.min(res.sum_cleaned$bic) #5
)

# adjusted r2
res.sum_cleaned$adjr2
plot(res.sum_cleaned$adjr2,xlab='No. of Variables',ylab='Adj. R^2',type='l')
points(6,res.sum_cleaned$adjr2[6],pch=19,col='red')

# cp
res.sum_cleaned$cp
plot(res.sum_cleaned$cp,xlab='No. of Variables',ylab='Cp',type='l')
points(6,res.sum_cleaned$cp[6],pch=19,col='red')

# bic
res.sum_cleaned$bic
plot(res.sum_cleaned$bic,xlab='No. of Variables',ylab='BIC',type='l')
points(5,res.sum_cleaned$bic[5],pch=19,col='red')

##### FORWARD/ BACKWARDS SELECTION #####
# backward
cleaned_models_backward <- regsubsets(log(DEXfat) ~., data = bodyfat_cleaned, method= "backward")
res.sum_cleaned_backward <- summary(cleaned_models_backward)
res.sum_cleaned_backward
cbind( 
  names <- res.sum_cleaned_backward$which,
  Cp    <-  res.sum_cleaned_backward$cp,
  r2     <- res.sum_cleaned_backward$rsq,
  Adj_r2 <- res.sum_cleaned_backward$adjr2, #age, waistcir, hipcir, kneebreath, anthro3b, anthro3c
  BIC    <- res.sum_cleaned_backward$bic
)

# summary
data.frame(
  Adj.R2 = which.max(res.sum_cleaned_backward$adjr2), #6
  CP = which.min(res.sum_cleaned_backward$cp), #6
  BIC = which.min(res.sum_cleaned_backward$bic) #5
)

# forward
cleaned_models_forward <- regsubsets(log(DEXfat) ~., data = bodyfat_cleaned, method= "forward")
res.sum_cleaned_forward <- summary(cleaned_models_backward)
res.sum_cleaned_forward
cbind( 
  names <- res.sum_cleaned_forward$which,
  Cp    <-  res.sum_cleaned_forward$cp,
  r2     <- res.sum_cleaned_forward$rsq,
  Adj_r2 <- res.sum_cleaned_forward$adjr2, #age, waistcir, hipcir, kneebreath, anthro3b, anthro3c
  BIC    <- res.sum_cleaned_forward$bic
)

# summary
data.frame(
  Adj.R2 = which.max(res.sum_cleaned_forward$adjr2), #7
  CP = which.min(res.sum_cleaned_forward$cp), #6
  BIC = which.min(res.sum_cleaned_forward$bic) #6
)


# forward/ backwards selection with AIC
step.model_aic <- stepAIC(cleaned_model, direction = "forward", trace = FALSE)
summary(step.model_aic) #forward: age, waistcirc, hipcirc, kneebreadth, anthro3b, anthro3c; backward: age

intercept_only <- lm(log(DEXfat) ~ 1, data = bodyfat_cleaned)
all <- lm(log(DEXfat) ~., -1, data = bodyfat_cleaned)

# forward
forward <- step(intercept_only, direction = "forward", scope=formula(all), trace=0) #default is AIC

# backward
backward <- step(intercept_only, direction = "backward", scope=formula(all), trace=0) #default is AIC


##### CROSSVALIDATION #####
predict.regsubsets =function (object , newdata ,id ,...){
  form=as.formula (object$call [[2]])
  mat=model.matrix(form ,newdata )
  coefi=coef(object ,id=id)
  xvars=names(coefi)
  mat[,xvars]%*%coefi
}


k=10
set.seed(1)
folds=sample (1:k,nrow(bodyfat_cleaned),replace=TRUE)
cv.errors =matrix (NA,k,9, dimnames =list(NULL , paste (1:9) ))

for(j in 1:k){
  best.fit=regsubsets(log(DEXfat) ~. ,data = bodyfat_cleaned[folds!=j,],
                      nvmax=9)
  for(i in 1:9){
    pred=predict (best.fit ,bodyfat_cleaned [folds ==j,],id=i)
    cv.errors[j,i]= mean((log(bodyfat_cleaned$DEXfat[ folds==j])-pred)^2)
  }
}

mean.cv.errors=apply(cv.errors ,2, mean)
mean.cv.errors #6 variables: age, waistcir, hipcirc, kneebreadth, anthro3b, anthro3c

reg.best=regsubsets(log(DEXfat)~.,data=bodyfat_cleaned , nvmax=9)
reg.best

coef(reg.best ,6)


##### MULTICOLLINEARITY #####
#use variance inflation factors to detect mutlicollinearity -> aiming for low VIFs
vif(reduced_model) #only anthro3b and anthro 3c over 5


##### BOOOTSTRAPPING CI #####
func = function(data, idx){
  coef(lm(log(DEXfat)~ age + waistcirc + hipcirc + kneebreadth +anthro3b + anthro3c, d = data[idx,]))
}
B = boot(bodyfat_cleaned, func, R = 500)
B
plot(B)
 boot.ci(B, index = 7, type="perc")

hist(B)

##### FINAL MODEL #####
reduced_model <- lm(log(DEXfat) ~ age + waistcirc + hipcirc + kneebreadth +anthro3b + anthro3c, data = bodyfat_cleaned)
summary(reduced_model)
vif(reduced_model)

studentized.residuals_final_clean <- studres(reduced_model)
qqnorm(sort(studentized.residuals_final_clean), ylim=c(-2,4))
qqline(sort(studentized.residuals_final_clean))

confint(reduced_model, '(Intercept)', level=0.95)
      confint(reduced_model, 'age', level=0.95)
confint(reduced_model, '(Intercept)', level=0.95)
confint(reduced_model, 'age', level=0.95)
confint(reduced_model, 'waistcirc', level=0.95)
confint(reduced_model, 'hipcirc', level=0.95)
confint(reduced_model, 'kneebreadth', level=0.95)
confint(reduced_model, 'anthro3b', level=0.95)
confint(reduced_model, 'anthro3c', level=0.95)


##### FINAL MODEL WITH OUTLIER ######
# model which still contains the outlier to compare it to the model with the outlier removed
reduced_model_full <- lm(log(DEXfat) ~ age + waistcirc + hipcirc + kneebreadth +anthro3b + anthro3c, data = bodyfat)
summary(reduced_model)

studentized.residuals_final <- studres(reduced_model_full)
qqnorm(sort(studentized.residuals_final))
qqline(sort(studentized.residuals_final))
