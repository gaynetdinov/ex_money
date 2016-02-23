# ExMoney

`ExMoney` is a [work-in-progress] self-hosted web application which helps you to track your personal finances.  
It's built around [Spectre API](https://www.saltedge.com/products/spectre) so `ExMoney` can export bank transactions for you.
The list of available banks you can find [here](https://www.saltedge.com/countries).

The main idea behind `ExMoney` is to have free, open source application which can help to track personal finances at(almost) no cost.  
`ExMoney` is written in [Elixir](http://elixir-lang.org) using [Phoenix framework](http://www.phoenixframework.org),
the app on production consumes around 20 Mb of RAM and it should work just fine on [Heroku](https://heroku.com) free plan.

## Saltedge

[Spectre API](https://www.saltedge.com/products/spectre) is a Financial Data Aggregation Platform.  
It allows to export bank transactions automatically which allows `ExMoney` to solve the main flaw of most personal finance apps —
need to enter every single transaction.

[Spectre API](https://www.saltedge.com/products/spectre) provides 'Test' mode using which it's possible to have
connections with up to 10 providers(banks) **for free**.

## Mobile version

`ExMoney` has a mobile version for iOS devices. The mobile version is built using [Framework7](http://framework7.io).  
`ExMoney` is supposed to run as Standalone web app(i.e. `Add to Home Screen` in Safari).

Currently mobile version looks like this


![Dashboard](/screenshots/dashboard.jpg?raw=true "Dashboard")


[More screenshots](/screenshots/)

## Desktop version

`ExMoney` has a desktop version which is not ready yet, however it provides some `Settings` to manage providers(banks), accounts, categories, etc.  
The desktop version is built using [Bootstrap](http://getbootstrap.com) and utilizes default `Dashboard` template.

## Niceties

###### Rules

Currently `ExMoney` has two types of Rules which can be applied for every incoming transaction from [Spectre API](https://www.saltedge.com/products/spectre):

* a rule to reassign category which was assigned automatically by [Spectre API](https://www.saltedge.com/products/spectre)  
    In case of automatically assigned category does not make sense it's possible to reassign category based on transaction's description and payee.

* a rule to detect withdraw transaction and create appropriate 'Income' transactions in 'Cash' account

###### Automatic sync

If a bank does not require one-time-password/captcha/etc to log in, `ExMoney` will run a periodic job to export transactions for you.
`ExMoney` will run a job to export transactions from a bank every hour. Also `ExMoney` disables this task during night to not violate 
Heroku's free plan [limitations](https://blog.heroku.com/archives/2015/5/7/heroku-free-dynos).


###### Interactive providers

`ExMoney` allows to manually export transactions from banks which require one-time-password as well.
For now only `otp` is supported.

## How to use [TODO]

## Installation [TODO]

## Current state

Currently `ExMoney` is a work-in-progress/prototype/'works on my machine' stage.

## FAQ

### Why only iOS?

I don't have an Android device to test `ExMoney` on Android. Feel free to add necessary [Framework7](http://framework7.io) styles and test `ExMoney` on Android.

### Why Desktop version does not use React/ES7/Clojurescript/Elm/etc?

I'm a backend developer, I don't know frontend part, I don't know how to js/html/css, so I took the most easiest approach to build a frontend.

## Contributing

Contributions welcome! Please feel free to create pull-request or issues. 

## License

This software is licensed under [the ISC license](LICENSE).
