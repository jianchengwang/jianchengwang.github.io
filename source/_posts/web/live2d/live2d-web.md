---
title: live2d-web
categories: 
- play
- live2d
tags: 
- live2d
---

`Live2d` 是一种应用于电子游戏的绘图渲染技术,技术由日本Cybernoids公司开发.

最近博客想换个**看板娘** ,网上找到的一般都只不支持**moc3** .所以本着自己动手,丰衣足食的想法,便入坑学习一波.

<!-- more -->

### 准备工作

[Live2D Cubism](https://www.live2d.com/download/cubism/) 

- Live2D Cubism Viewer 4.0 查看模型的软件
- Live2D Cubism Editor 4.0 制作模型的软件

[Live2d Web Sdk](https://www.live2d.com/download/cubism-sdk/)

解压后推荐用**vscode**进行编辑

```shell
unzip CubismSdkForWeb-4-r.1.zip
cd CubismSdkForWeb-4-r.1/Samples/TypeScript/Demo
npm install
npm run build
npm run serve
```

访问 http://localhost:5000/Samples/TypeScript/Demo/ 看下demo效果

### 示例源码

**lappdefine.ts**  定义基本的参数
**lappdelegate.ts** 初始化,释放资源,事件绑定
**lapplive2dmanager.ts** 模型的管理类,进行模型生成和废弃,事件的处理,模型切换.
**lappmodel.ts** 模型类,定义模型的基本属性
**lappal.ts** 读取文件,抽象文件数据(算是工具类)
**lappsprite.ts** 动画精灵类,(有h5游戏开发应该了解)
**lapptexturemanager.ts** 纹理管理类,进行图像读取和管理的类
**lappview.ts** 视图类,生成模型的图像被lapplive2dmanager管理
**main.ts** 主程序启动程序
**touchmanager.ts** 事件的管理类(比如移动鼠标,点击鼠标,触摸屏触碰等)

**index.html** 页面入口,我们可以看到非常简单,就是引入几个js

```html
<!-- Pollyfill script -->
<script src="https://unpkg.com/core-js-bundle@3.6.1/minified.js"></script>
<!-- Live2DCubismCore script -->
<script src = "../../../Core/live2dcubismcore.js"></script>
<!-- Build script -->
<script src = "./dist/bundle.js"></script>
```

### 自定义

#### Index.html



