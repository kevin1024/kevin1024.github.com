---
layout: post
title: "Setting Up vim for Clojure"
date: 2013-10-12 10:54
comments: true
categories: vim
---

I've been reading through [the second edition of They Joy Of Clojure](http://www.manning.com/fogus2/) for the [ClojureHNL](http://www.meetup.com/ClojureHNL/) meetup group and wanted to see how I could improve my Vim setup for editing Clojure code.  This is mostly a note to myself but I thought someone else might find it interesting.  The impetus behind this was feeling the pain of trying to balance parentheses and seeing some Emacs jockeys kick ass with nREPL and wanting in on the action.  So, without further ado, here is what I did.

# 1. Install pathogen
If you've played with vim plugins at all, you probably already know about [Pathogen](https://github.com/tpope/vim-pathogen) but if you don't, you're in for a treat.  Pathogen vastly simplifies installing and manaing your vim plugins.  [Follow the installation instructions](https://github.com/tpope/vim-pathogen#installation) and rejoice.

# 2. Run the newest version of vim
Vim versions newer than 7.3.803 ship with the [vim-static](https://github.com/guns/vim-clojure-static) runtime files.  These tell vim how to indent and syntax-highlight Clojure.

#3. Install vim-fireplace
[vim-fireplace](https://github.com/tpope/vim-fireplace) is a plugin that puts a Clojure repl inside your Vim.  It connects to nREPL (which is what you get when you run `lein repl`).  Here's how I installed it:

```bash
cd ~/.vim/bundle
git clone git://github.com/tpope/vim-fireplace.git
git clone git://github.com/tpope/vim-classpath.git
git clone git://github.com/guns/vim-clojure-static.git
```

#4. Install paredit.vim
This is the magic plugin that makes it so you don't have to worry about matching parentheses anymore.  

```bash
cd ~/.vim/bundle
git clone https://github.com/vim-scripts/paredit.vim
```

#5. Enjoy!
I usually start by going to my Clojure project and running `lein repl`.  This gives vim-fireplace something to connect to.  Now you can type `cqc` to get a repl, or `cqq` to put the code under your cursor into the repl.

Also, indentation works and matching parentheses are automatically added.  It's actually impossible to type parens that *don't* match.  You can do other awesome stuff with paredit, including *slurp* and *barf*!  Read more in the [paredit docs](https://github.com/vim-scripts/paredit.vim/blob/master/doc/paredit.txt)

#My .vimrc
Here's a heavily pared down minimal vimrc that works.

```vim
execute pathogen#infect()
syntax on
filetype plugin indent on
```
