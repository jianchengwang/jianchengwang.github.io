---
title: Hexo-theme-ass
categories: 
- Play
tags: 
- Hexo

---

### 前言

之前用的博客主题有`hexo-theme-next` ，`hexo-theme-melody`等，也喵了主题创建者的相关博客，所以就想着照葫芦画瓢自定义一个主题，暂时命名为`hexo-theme-ass`，屁股主题。

### 预备知识

静态站点，一般都是模板页面拼凑，加上样式，所以，选择一款自己容易上手的模板引擎，跟CSS预处理器是首要的，这里我选择的是[Pug](https://www.pugjs.cn/)跟[Stylus](https://stylus-lang.com/)

Hexo会植入模板引擎的[变量](https://hexo.io/docs/variables.html)，还有一些[辅助函数](https://hexo.io/docs/helpers.html)，这些通常是用来进行配置不同页面显示不同的内容。

### 主题脚手架

```shell
npm install hexo-cli yo generator-hexo-theme -g
mkdir hexo-theme-ass && cd hexo-theme-ass && hexo init 
npm install hexo-server hexo-browsersync hexo-renderer-pug hexo-renderer-stylus --save-dev
# 创建ass主题
cd themes && mkdir ass && cd ass && yo hexo-theme 
hexo s
```

### 配置文件

[datafile](https://hexo.io/docs/data-files.html)

简单来说，就是你可以通过在站点的`source/_data`目录下（`_data`文件夹不存在的话手动创建一个）新建配置文件，比如`ass.yml`，然后在主题里可以通过`site.data.ass.xxx`去访问配置文件里的配置。

但是这样对于写主题而言还是不太方便。因为有的用户并不需要频繁更新主题，他只需要修改主题的`_config.yml`就好了。那么我们在模板引擎里引用主题配置文件的内容是用`theme.xxx`来访问的。如果两种状态都要考虑的话，我们可能需要在写任何一个配置的时候都要判断一下主题的`_config.yml`里或者`_data`里的`ass.yml`存不存在。这样很麻烦。

参考hexo渲染的[事件](https://hexo.io/api/events.html)，可以找到`generateBefore`这个钩子，只要在这个钩子触发的时候，判断一下存不存在`data files`里的配置文件，存在的话就把这个配置文件替换或者合并主题本身的配置文件。`Next`主题采用的是覆盖，`melody`主题采用的是替换，各有各的好处，并不是绝对的。

我们这边很多都是借鉴`melody`主题的，所以也用替换形式。

写法是就是在我们的`ass`主题目录下的`scripts`文件夹里（没有就创建一个），写一个js文件，内容如下：

```js
/**
 * Note: configs in _data/temp.yml will replace configs in hexo.theme.config.
 */
hexo.on('generateBefore', function () {
  if (hexo.locals.get) {
    var data = hexo.locals.get('data') // 获取_data文件夹下的内容
    data && data.temp && (hexo.theme.config = data.temp) // 如果temp.yml 存在，就把内容替换掉主题的config
  }
})
```

### 页面编写

#### 数据获取



### 相关链接

[Hexo主题开发经验杂谈](https://molunerfinn.com/make-a-hexo-theme)

[Hexo 主题开发指南](https://xinyufeng.net/2019/04/15/hexo-theme-guide/)