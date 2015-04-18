+++
title = "Funny C# code"
Description = ""
date = "2015-04-11T20:10:50+01:00"
tags = ["coding", "fun", "csharp", "msnet"]
categories = ["misc"]
menu = "post"
comments = "yes"
share = "yes"
+++

Even though I don’t know the author of the lines below I would say “Thank you man. You made day”.

```
try
{
 HOME:
   do
   {
     Play(“World of Warcraft”);
   }
   while (!asleep);
 
   Thread.Sleep(12 * 60 * 60 * 1000);
 
   WakeUp(coffee);
 
   if (you_still_give_a_shit())
     goto WORK;
   else
     goto OUT;
 
 WORK:
   do
   {
     if (got_something_to_do())
     {
       LookAtTheMonitor();
       Press_Some_Keys(new string[] { “Ctrl+C”, “Ctrl+V” });
     }
 
     Browse(“vbox7.com”);
     Browse(“topsport.bg”);
     Browse(“youtube.com”);
 
     Have_a_Break();
     Have_a_Kitkat();
 
   }
   while (DateTime.Now.Hour < 5);
 
   if (DateTime.Now.Day == 1)
   {
     // at least
     GetSomeCash(3000);
   }
 OUT:
   switch (mood)
   {
 
     case Mood.Horny:
       ChaseChicks(“hot!”);
       break;
     case Mood.Dull:
       SmokeSomeStuff(new Stuff[] { “Grass”, “Serious Stuff” });
       break;
     default:
       DrinkBeer(5);
       break;
 
   }
   goto HOME;
}
catch (HealthException x)
{
    SeeTheDoctor(x);
}
catch (NoMoneyException)
{
    ShitHappens();
}
```

