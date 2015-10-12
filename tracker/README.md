# XD-Analytics Tracker



Assuming your directory structures is

```
.
├── xd-analytics
│   ├── tracker
├── project
│   ├── bower.json
```

Then your `bower.json` dependency should look like:

```
{
	...
  "dependencies": {
		...
		"xd-analytics": "../xd-analytics/tracker",
		...
	}
	...
}
```

Include the ```xd-analytics.js``` and its dependencies:

```
<script src="bower_components/ddp.js/src/ddp.js"></script>
<script src="bower_components/xd-analytics/xd-analytics.js"></script>
```

Then initialize `XDAnalytics` with the needed values:

```
analytics = new XDAnalytics({
	appId: "zk243C9PX8iHuLM3F",
	apiKey: "hjM0LHRAtbcs2mtWo",
	analyticsServer: "localhost",
	analyticsServerPort: "9003"
});
```
