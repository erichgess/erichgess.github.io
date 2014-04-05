---
layout: post
title: "Type Providers - Tutorial Part 2"
date: 2014-04-04 17:51:36 -0700
comments: true
categories: [F#, Tutorials, Type Providers]
---
In Part 1 of this series, I briefly explained what a Type Provider was and some of the main concepts which you would need to know.  In Part 2, I am going to build a very simple Type Provider.  The purpose of Part 2 is to cover the basics of developing Type Providers, how to test them with F# Interactive, and the support tools which make developing Type Providers easy.

I will make a Type Provider which generates a single type named "Hello".  At first it will just have a static property which returns the string `"World"`.  Then I will add a static method which takes no parameters.  Finally, I will add a static method which takes a parameter.
<!-- more -->
