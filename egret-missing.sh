
egret create game之后，
执行egret run 会出现
missing appdata path

原因已经找到，
在run.js中把
toolsList = project_1.launcher.getLauncherLibrary().getInstalledTools();
这一行注释掉即可，
