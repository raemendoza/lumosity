if (!requireNamespace("wec", quietly = TRUE)) install.packages("wec")
if (!requireNamespace("car", quietly = TRUE)) install.packages("car")
library(wec)
library(car)

# Import Data
df_og <- read.csv('raw_data.csv')
df <- read.csv('data.csv')

df$mood_num <- df$mood
df$sleep_num <- df$sleep

df$mood_cat <- factor(df$mood,
                      levels = -2:2,
                      labels = c("-2", "-1", "0", "1", "2"),
                      ordered = TRUE)
df$sleep_cat <- factor(df$sleep,
                       levels = 5:9,
                       labels = c("5", "6", "7", "8", "9"),
                       ordered = TRUE)
valid_ethnicities <- c("white", "hispanic", "black", "asian", "other")

df$hour      <- factor(df$hour, levels = 0:23)
df$weekday   <- factor(df$weekday,
                       levels = c("Mon", "Tues", "Wed", "Thurs", "Fri", "Sat", "Sun"),
                       ordered = FALSE)
df$agegroup  <- factor(df$agegroup,
                       levels = c("20–29", "30–39", "40–49", "50–59", "60–69", "70–79"),
                       ordered = FALSE)
df$gender    <- factor(df$gender, levels = c("male", "female"))
df$ethnicity <- factor(df$ethnicity,
                       levels = valid_ethnicities)
df$season    <- factor(df$season,
                       levels = c("winter", "spring", "summer", "fall"))

# ============================================================
# Descriptive Statistics of Variables (Raw Data)
# ============================================================

old_variable_list = c('gender', 'agegroup', 'ethnicity', 'hour', 'weekday',
                      'mood', 'quality')

for (var in old_variable_list) {
  cat("\n=============", var, "===========\n")
  print(format(table(df_og[[var]]), big.mark = ","))
  print(round(prop.table(table(df_og[[var]]))*100, 1))
}

# ============================================================
# Descriptive Statistics of Variables
# ============================================================

new_variable_list = c('gender', 'agegroup', 'ethnicity', 'hour', 'weekday',
                      'mood', 'sleep', 'season')

for (var in new_variable_list) {
  cat("\n=============", var, "===========\n")
  print(format(table(df[[var]]), big.mark = ","))
  print(round(prop.table(table(df[[var]]))*100, 1))
}

# ============================================================
# Variance Inflation Factor (VIF) Check
# ============================================================

m_full_mood <- lm(mood_num ~ hour + weekday + agegroup + 
                  ethnicity + gender + season + sleep_cat, data = df)
vif(m_full_mood)

m_full_sleep <- lm(sleep_num ~ hour + weekday + agegroup + 
                   ethnicity + gender + season + mood_cat, data = df)
vif(m_full_sleep)


# ============================================================
# Weight Effect Coding (WEC) for Coefficients
# ============================================================
# 1. Reference set to '0' (Calculates hour 0 coefficient implicitly)
df$hour.wec_ref0 <- factor(df$hour)
contrasts(df$hour.wec_ref0) <- contr.wec(df$hour.wec_ref0, "0")

# 2. Reference set to '12' (Calculates hour 12 coefficient implicitly)
df$hour.wec_ref12 <- factor(df$hour)
contrasts(df$hour.wec_ref12) <- contr.wec(df$hour.wec_ref12, "12")

# Keep existing weekday weights
df$weekday.wec <- factor(df$weekday)
contrasts(df$weekday.wec) <- contr.wec(df$weekday.wec, "Mon")

# Define a second weekday WEC variable where Sunday is the implicit reference
df$weekday.wec_refSun <- factor(df$weekday)
contrasts(df$weekday.wec_refSun) <- contr.wec(df$weekday.wec_refSun, "Sun")

# Use your existing WEC variable for the Monday reference
df$weekday.wec_refMon <- factor(df$weekday)
contrasts(df$weekday.wec_refMon) <- contr.wec(df$weekday.wec_refMon, "Mon")


# ============================================================
# Model 1M: Mood ~ Hour
# ============================================================

# Model 1M_Ref0: Mood ~ Hour (Circadian pattern only)
m1m_ref0 <- lm(mood_num ~ hour.wec_ref0, data = df)
summary(m1m_ref0)
car::Anova(m1m_ref0, type="III")

# Welch Test
oneway.test(mood_num ~ as.factor(hour), data = df, var.equal = FALSE)

# Model 1M_2_Ref0: Mood ~ Hour + Fixed Covariates
m1m_2_ref0 <- lm(mood_num ~ hour.wec_ref0 + agegroup + gender + ethnicity + season + weekday.wec,
                 data = df)
# summary(m1m_2_ref0)
car::Anova(m1m_2_ref0, type="III")

# Model 1M_3_Ref0: Mood ~ Hour + Fixed Covariates + Sleep
m1m_3_ref0 <- lm(mood_num ~ hour.wec_ref0 + agegroup + gender + ethnicity + season + weekday.wec + sleep_cat,
                 data = df)
# summary(m1m_3_ref0)
car::Anova(m1m_3_ref0, type="III")

# Model 1M_Ref12: Mood ~ Hour - For Coefficients
m1m_ref12 <- lm(mood_num ~ hour.wec_ref12, data = df)
summary(m1m_ref12)
car::Anova(m1m_ref12, type="III")


# ============================================================
# Model 1S: Sleep ~ Hour
# ============================================================

# Model 1S_Ref0: Sleep ~ Hour (Circadian pattern only)
m1s_ref0 <- lm(sleep_num ~ hour.wec_ref0, data = df)
summary(m1s_ref0)
car::Anova(m1s_ref0, type="III")

# Welch Test
oneway.test(sleep_num ~ hour.wec_ref0, data = df, var.equal = FALSE)

# Model 1S_2_Ref0: Sleep ~ Hour + Fixed Covariates
m1s_2_ref0 <- lm(sleep_num ~ hour.wec_ref0 + agegroup + gender + ethnicity + season + weekday.wec,
                 data = df)
# summary(m1s_2_ref0)
car::Anova(m1s_2_ref0, type="III")

# Model 1S_3_Ref0: Sleep ~ Hour + Fixed Covariates + Mood
m1s_3_ref0 <- lm(sleep_num ~ hour.wec_ref0 + agegroup + gender + ethnicity + season + weekday.wec + mood_cat,
                 data = df)
# summary(m1s_3_ref0)
car::Anova(m1s_3_ref0, type="III")

# Model 1S_Ref12: Sleep ~ Hour - For Coefficients
m1s_ref12 <- lm(sleep_num ~ hour.wec_ref12, data = df)
summary(m1s_ref12)
car::Anova(m1s_ref12, type="III")

# ============================================================
# Model 2M: Mood ~ Weekday (Reference Day = Monday)
# ============================================================

# Model 2M_RefMon: Mood ~ Weekday (Circadian pattern only)
m2m_refMon <- lm(mood_num ~ weekday.wec_refMon, data = df)
summary(m2m_refMon)
car::Anova(m2m_refMon, type="III")

# Welch Test
oneway.test(mood_num ~ weekday.wec_refMon, data = df, var.equal = FALSE)

# Model 2M_2_RefMon: Mood ~ Weekday + Fixed Covariates + Hour
# Note: I'm replacing the simple 'hour' factor with the WEC version for consistency,
# but using the simple 'hour' factor here (as you had it) to keep the models close to your original intent.
m2m_2_refMon <- lm(mood_num ~ weekday.wec_refMon + agegroup + gender + ethnicity + season + hour.wec_ref0,
                   data = df)
# summary(m2m_2_refMon)
car::Anova(m2m_2_refMon, type="III")

# Model 2M_3_RefMon: Mood ~ Weekday + Fixed Covariates + Hour + Sleep
m2m_3_refMon <- lm(mood_num ~ weekday.wec_refMon + agegroup + gender + ethnicity + season + hour.wec_ref0 + sleep_cat,
                   data = df)
# summary(m2m_3_refMon)
car::Anova(m2m_3_refMon, type="III")

# Model 2M_RefSun: Mood ~ Weekday - For Coefficients
m2m_refSun <- lm(mood_num ~ weekday.wec_refSun, data = df)
summary(m2m_refSun)
car::Anova(m2m_refSun, type="III")

# ============================================================
# Model 2S: Sleep ~ Weekday (Reference Day = Monday)
# ============================================================

# Model 2S_RefMon: Sleep ~ Weekday (Main effect only)
m2s_refMon <- lm(sleep_num ~ weekday.wec_refMon, data = df)
# summary(m2s_refMon)
car::Anova(m2s_refMon, type="III")

# Welch Test
oneway.test(sleep_num ~ weekday.wec_refMon, data = df, var.equal = FALSE)

# Model 2S_2_RefMon: Sleep ~ Weekday + Fixed Covariates + Hour
m2s_2_refMon <- lm(sleep_num ~ weekday.wec_refMon + agegroup + gender + ethnicity + season + hour.wec_ref0,
                   data = df)
# summary(m2s_2_refMon)
car::Anova(m2s_2_refMon, type="III")

# Model 2S_3_RefMon: Sleep ~ Weekday + Fixed Covariates + Hour + Mood
m2s_3_refMon <- lm(sleep_num ~ weekday.wec_refMon + agegroup + gender + ethnicity + season + hour.wec_ref0 + mood_cat,
                   data = df)
# summary(m2s_3_refMon)
car::Anova(m2s_3_refMon, type="III")

# Model 2S_RefSun: Sleep ~ Weekday - For Coefficients
m2s_refSun <- lm(sleep_num ~ weekday.wec_refSun, data = df)
# summary(m2s_refSun)
car::Anova(m2s_refSun, type="III")

# ============================================================
# Model 3M1: Mood ~ Hour * Gender 
# ============================================================

# Model 3Mg_Ref0: Mood ~ Hour * Gender (Circadian pattern only)
m3mg_ref0 <- lm(mood_num ~ hour.wec_ref12 * gender, data = df)
summary(m3mg_ref0)
car::Anova(m3mg_ref0, type="III")

# Model 3Mg_2_Ref0: Mood ~ Hour * Gender + Fixed Covariates
m3mg_2_ref0 <- lm(mood_num ~ hour.wec_ref0 * gender + agegroup + ethnicity + season + weekday.wec,
                 data = df)
summary(m3mg_2_ref0)
car::Anova(m3mg_2_ref0, type="III")

# Model 3Mg_3_Ref0: Mood ~ Hour * Gender + Fixed Covariates + Sleep
m3mg_3_ref0 <- lm(mood_num ~ hour.wec_ref0 * gender + agegroup + ethnicity + season + weekday.wec + sleep_cat,
                 data = df)
summary(m3mg_3_ref0)
car::Anova(m3mg_3_ref0, type="III")

# ============================================================
# Model 3M2: Mood ~ Hour * Ethnicity 
# ============================================================

# Model 3M_Ref0: Mood ~ Hour * Ethnicity (Circadian pattern only)
m3mr_ref0 <- lm(mood_num ~ hour.wec_ref0 * ethnicity, data = df)
summary(m3mr_ref0)
car::Anova(m3mr_ref0, type="III")

# Model 3M_2_Ref0: Mood ~ Hour * Ethnicity + Fixed Covariates
m3mr_2_ref0 <- lm(mood_num ~ hour.wec_ref0 * ethnicity + agegroup + gender + season + weekday.wec,
                 data = df)
# summary(m3mr_2_ref0)
car::Anova(m3mr_2_ref0, type="III")

# Model 3M_3_Ref0: Mood ~ Hour * Ethnicity + Fixed Covariates + Sleep
m3mr_3_ref0 <- lm(mood_num ~ hour.wec_ref0 * ethnicity + agegroup + gender + season + weekday.wec + sleep_cat,
                 data = df)
# summary(m3mr_3_ref0)
car::Anova(m3mr_3_ref0, type="III")

# ============================================================
# Model 3M3: Mood ~ Hour * Agegroup 
# ============================================================

# Model 3Ma_Ref0: Mood ~ Hour * Agegroup (Circadian pattern only)
m3ma_ref0 <- lm(mood_num ~ hour.wec_ref0 * agegroup, data = df)
summary(m3ma_ref0)
car::Anova(m3ma_ref0, type="III")

# Model 3Ma_2_Ref0: Mood ~ Hour * Agegroup + Fixed Covariates
m3ma_2_ref0 <- lm(mood_num ~ hour.wec_ref0 * agegroup + ethnicity + gender + season + weekday.wec,
                  data = df)
# summary(m3ma_2_ref0)
car::Anova(m3ma_2_ref0, type="III")

# Model 3Ma_3_Ref0: Mood ~ Hour * Agegroup + Fixed Covariates + Sleep
m3ma_3_ref0 <- lm(mood_num ~ hour.wec_ref0 * agegroup + ethnicity + gender + season + weekday.wec + sleep_cat,
                  data = df)
# summary(m3ma_3_ref0)
car::Anova(m3ma_3_ref0, type="III")

# ============================================================
# Model 3M4: Mood ~ Hour * Sleep 
# ============================================================

# Model 3Ms_Ref0: Mood ~ Hour * Sleep (Circadian pattern only)
m3ms_ref0 <- lm(mood_num ~ hour.wec_ref0 * sleep_cat, data = df)
summary(m3ms_ref0)
car::Anova(m3ms_ref0, type="III")

# Model 3Ms_2_Ref0: Mood ~ Hour * Sleep + Fixed Covariates
m3ms_2_ref0 <- lm(mood_num ~ hour.wec_ref0 * sleep_cat + agegroup + ethnicity + gender + season + weekday.wec,
                  data = df)
# summary(m3ms_2_ref0)
car::Anova(m3ms_2_ref0, type="III")

# ============================================================
# Model 3S1: Sleep ~ Hour * Gender 
# ============================================================

# Model 3Sg_Ref0: Sleep ~ Hour * Gender (Circadian pattern only)
m3sg_ref0 <- lm(sleep_num ~ hour.wec_ref0 * gender, data = df)
summary(m3sg_ref0)
car::Anova(m3sg_ref0, type="III")

# Model 3Sg_2_Ref0: Sleep ~ Hour * Gender + Fixed Covariates
m3sg_2_ref0 <- lm(sleep_num ~ hour.wec_ref0 * gender + agegroup + ethnicity + season + weekday.wec,
                  data = df)
summary(m3sg_2_ref0)
car::Anova(m3sg_2_ref0, type="III")

# Model 3Sg_3_Ref0: Sleep ~ Hour * Gender + Fixed Covariates + Mood
m3sg_3_ref0 <- lm(sleep_num ~ hour.wec_ref0 * gender + agegroup + ethnicity + season + weekday.wec + mood_cat,
                  data = df)
summary(m3sg_3_ref0)
car::Anova(m3sg_3_ref0, type="III")

# ============================================================
# Model 3S2: Sleep ~ Hour * Ethnicity 
# ============================================================

# Model 3Sr_Ref0: Sleep ~ Hour * Ethnicity (Circadian pattern only)
m3sr_ref0 <- lm(sleep_num ~ hour.wec_ref0 * ethnicity, data = df)
summary(m3sr_ref0)
car::Anova(m3sr_ref0, type="III")

# Model 3Sr_2_Ref0: Sleep ~ Hour * Ethnicity + Fixed Covariates
m3sr_2_ref0 <- lm(sleep_num ~ hour.wec_ref0 * ethnicity + agegroup + gender + season + weekday.wec,
                  data = df)
summary(m3sr_2_ref0)
car::Anova(m3sr_2_ref0, type="III")

# Model 3Sg_3_Ref0: Sleep ~ Hour * Ethnicity + Fixed Covariates + Mood
m3sr_3_ref0 <- lm(sleep_num ~ hour.wec_ref0 * ethnicity + agegroup + gender + season + weekday.wec + mood_cat,
                  data = df)
summary(m3sr_3_ref0)
car::Anova(m3sr_3_ref0, type="III")

# ============================================================
# Model 3S3: Sleep ~ Hour * Agegroup 
# ============================================================

# Model 3Sa_Ref0: Sleep ~ Hour * Agegroup (Circadian pattern only)
m3sa_ref0 <- lm(sleep_num ~ hour.wec_ref0 * agegroup, data = df)
summary(m3sa_ref0)
car::Anova(m3sa_ref0, type="III")

# Model 3Sa_2_Ref0: Sleep ~ Hour * Agegroup + Fixed Covariates
m3sa_2_ref0 <- lm(sleep_num ~ hour.wec_ref0 * agegroup + ethnicity + gender + season + weekday.wec,
                  data = df)
summary(m3sa_2_ref0)
car::Anova(m3sa_2_ref0, type="III")

# Model 3Sg_3_Ref0: Sleep ~ Hour * Agegroup + Fixed Covariates + Mood
m3sa_3_ref0 <- lm(sleep_num ~ hour.wec_ref0 * agegroup + ethnicity + gender + season + weekday.wec + mood_cat,
                  data = df)
summary(m3sa_3_ref0)
car::Anova(m3sa_3_ref0, type="III")

# ============================================================
# Model 3S4: Sleep ~ Hour * Mood 
# ============================================================

# Model 3Sm_Ref0: Mood ~ Hour * Sleep (Circadian pattern only)
m3sm_ref0 <- lm(sleep_num ~ hour.wec_ref0 * mood_cat, data = df)
summary(m3sm_ref0)
car::Anova(m3sm_ref0, type="III")

# Model 3Sm_2_Ref0: Mood ~ Hour * Sleep + Fixed Covariates
m3sm_2_ref0 <- lm(sleep_num ~ hour.wec_ref0 * mood_cat + agegroup + ethnicity + gender + season + weekday.wec,
                  data = df)
summary(m3sm_2_ref0)
car::Anova(m3sm_2_ref0, type="III")

# ============================================================
# Model 4M1: Mood ~ Weekday * Gender 
# ============================================================

# Model 4Mg_Ref0: Mood ~ Weekday * Gender (Circadian pattern only)
m4mg_ref0 <- lm(mood_num ~ weekday.wec_refMon * gender, data = df)
summary(m4mg_ref0)
car::Anova(m4mg_ref0, type="III")

# Model 4Mg_2_Ref0: Mood ~ Weekday * Gender + Fixed Covariates
m4mg_2_ref0 <- lm(mood_num ~ weekday.wec_refMon * gender + agegroup + ethnicity + season + hour.wec_ref0,
                  data = df)
summary(m4mg_2_ref0)
car::Anova(m4mg_2_ref0, type="III")

# Model 4Mg_3_Ref0: Mood ~ Weekday * Gender + Fixed Covariates + Sleep
m4mg_3_ref0 <- lm(mood_num ~ weekday.wec_refMon * gender + agegroup + ethnicity + season + hour.wec_ref0 + sleep_cat,
                  data = df)
summary(m4mg_3_ref0)
car::Anova(m4mg_3_ref0, type="III")

# ============================================================
# Model 4M2: Mood ~ Weekday * Ethnicity 
# ============================================================

# Model 4Me_Ref0: Mood ~ Weekday * Ethnicity (Circadian pattern only)
m4me_ref0 <- lm(mood_num ~ weekday.wec_refMon * ethnicity, data = df)
summary(m4me_ref0)
car::Anova(m4me_ref0, type="III")

# Model 4Me_2_Ref0: Mood ~ Weekday * Ethnicity + Fixed Covariates
m4me_2_ref0 <- lm(mood_num ~ weekday.wec_refMon * ethnicity + gender + agegroup + season + hour.wec_ref0,
                  data = df)
summary(m4me_2_ref0)
car::Anova(m4me_2_ref0, type="III")

# Model 4Me_3_Ref0: Mood ~ Weekday * Ethnicity + Fixed Covariates + Sleep
m4me_3_ref0 <- lm(mood_num ~ weekday.wec_refMon * ethnicity + gender + agegroup + season + hour.wec_ref0 + sleep_cat,
                  data = df)
summary(m4me_3_ref0)
car::Anova(m4me_3_ref0, type="III")

# ============================================================
# Model 4M3: Mood ~ Weekday * Agegroup 
# ============================================================

# Model 4Ma_Ref0: Mood ~ Weekday * Agegroup (Circadian pattern only)
m4ma_ref0 <- lm(mood_num ~ weekday.wec_refMon * agegroup, data = df)
summary(m4ma_ref0)
car::Anova(m4ma_ref0, type="III")

# Model 4Ma_2_Ref0: Mood ~ Weekday * Agegroup + Fixed Covariates
m4ma_2_ref0 <- lm(mood_num ~ weekday.wec_refMon * agegroup + gender + ethnicity + season + hour.wec_ref0,
                  data = df)
summary(m4ma_2_ref0)
car::Anova(m4ma_2_ref0, type="III")

# Model 4Ma_3_Ref0: Mood ~ Weekday * Agegroup + Fixed Covariates + Sleep
m4ma_3_ref0 <- lm(mood_num ~ weekday.wec_refMon * agegroup + gender + ethnicity + season + hour.wec_ref0 + sleep_cat,
                  data = df)
summary(m4ma_3_ref0)
car::Anova(m4ma_3_ref0, type="III")

# ============================================================
# Model 4M4: Mood ~ Weekday * Sleep 
# ============================================================

# Model 4Ms_Ref0: Mood ~ Weekday * Sleep (Circadian pattern only)
m4ms_ref0 <- lm(mood_num ~ weekday.wec_refMon * sleep_cat, data = df)
summary(m4ms_ref0)
car::Anova(m4ms_ref0, type="III")

# Model 4Ms_2_Ref0: Mood ~ Weekday * Sleep + Fixed Covariates
m4ms_2_ref0 <- lm(mood_num ~ weekday.wec_refMon * sleep_cat + agegroup + gender + ethnicity + season + hour.wec_ref0,
                  data = df)
summary(m4ms_2_ref0)
car::Anova(m4ms_2_ref0, type="III")

# ============================================================
# Model 4S1: Sleep ~ Weekday * Gender 
# ============================================================

# Model 4Sg_Ref0: Sleep ~ Weekday * Gender (Circadian pattern only)
m4sg_ref0 <- lm(sleep_num ~ weekday.wec_refMon * gender, data = df)
summary(m4sg_ref0)
car::Anova(m4sg_ref0, type="III")

# Model 4Sg_2_Ref0: Sleep ~ Weekday * Gender + Fixed Covariates
m4sg_2_ref0 <- lm(sleep_num ~ weekday.wec_refMon * gender + agegroup + ethnicity + season + hour.wec_ref0,
                  data = df)
summary(m4sg_2_ref0)
car::Anova(m4sg_2_ref0, type="III")

# Model 4Sg_3_Ref0: Sleep ~ Weekday * Gender + Fixed Covariates + Mood
m4sg_3_ref0 <- lm(sleep_num ~ weekday.wec_refMon * gender + agegroup + ethnicity + season + hour.wec_ref0 + mood_cat,
                  data = df)
summary(m4sg_3_ref0)
car::Anova(m4sg_3_ref0, type="III")

# ============================================================
# Model 4S2: Sleep ~ Weekday * Ethnicity 
# ============================================================

# Model 4Se_Ref0: Sleep ~ Weekday * Ethnicity (Circadian pattern only)
m4se_ref0 <- lm(sleep_num ~ weekday.wec_refMon * ethnicity, data = df)
summary(m4se_ref0)
car::Anova(m4se_ref0, type="III")

# Model 4Se_2_Ref0: Sleep ~ Weekday * Ethnicity + Fixed Covariates
m4se_2_ref0 <- lm(sleep_num ~ weekday.wec_refMon * ethnicity + agegroup + gender + season + hour.wec_ref0,
                  data = df)
summary(m4se_2_ref0)
car::Anova(m4se_2_ref0, type="III")

# Model 4Se_3_Ref0: Sleep ~ Weekday * Ethnicity + Fixed Covariates + Mood
m4se_3_ref0 <- lm(sleep_num ~ weekday.wec_refMon * ethnicity + agegroup + gender + season + hour.wec_ref0 + mood_cat,
                  data = df)
summary(m4se_3_ref0)
car::Anova(m4se_3_ref0, type="III")

# ============================================================
# Model 4S3: Sleep ~ Weekday * Agegroup 
# ============================================================

# Model 4Sa_Ref0: Sleep ~ Weekday * Agegroup  (Circadian pattern only)
m4sa_ref0 <- lm(sleep_num ~ weekday.wec_refMon * agegroup, data = df)
summary(m4sa_ref0)
car::Anova(m4sa_ref0, type="III")

# Model 4Sa_2_Ref0: Sleep ~ Weekday * Agegroup + Fixed Covariates
m4sa_2_ref0 <- lm(sleep_num ~ weekday.wec_refMon * agegroup + ethnicity + gender + season + hour.wec_ref0,
                  data = df)
summary(m4sa_2_ref0)
car::Anova(m4sa_2_ref0, type="III")

# Model 4Sa_3_Ref0: Sleep ~ Weekday * Agegroup + Fixed Covariates + Mood
m4sa_3_ref0 <- lm(sleep_num ~ weekday.wec_refMon * agegroup + ethnicity + gender + season + hour.wec_ref0 + mood_cat,
                  data = df)
summary(m4sa_3_ref0)
car::Anova(m4sa_3_ref0, type="III")

# ============================================================
# Model 4S4: Sleep ~ Weekday * Mood 
# ============================================================

# Model 4Sm_Ref0: Sleep ~ Weekday * Mood (Circadian pattern only)
m4sm_ref0 <- lm(sleep_num ~ weekday.wec_refMon * mood_cat, data = df)
summary(m4sm_ref0)
car::Anova(m4sm_ref0, type="III")

# Model 4Sm_2_Ref0: Sleep ~ Weekday * Mood + Fixed Covariates
m4sm_2_ref0 <- lm(sleep_num ~ weekday.wec_refMon * mood_cat + agegroup + ethnicity + gender + season + hour.wec_ref0,
                  data = df)
summary(m4sm_2_ref0)
car::Anova(m4sm_2_ref0, type="III")
