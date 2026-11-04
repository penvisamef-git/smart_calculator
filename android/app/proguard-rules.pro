# Keep rules for the release build (R8 code shrinking).

# AdMob uses WorkManager, which uses Room. R8 removed the generated database
# class and the app crashed on start ("Failed to create an instance of
# androidx.work.impl.WorkDatabase"). Keep all Room databases.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.** { *; }

# Google Play Billing (in-app purchase)
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }
