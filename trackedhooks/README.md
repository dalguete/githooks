Create all your scripts inside hook named container folders, like described below:

<pre><strong>
trackedhooks/
 │
 ├── commit-msg.d/
 │   ├── script1
 │   ├── script2
 │   ├── ...
 │   └── scriptN
 │
 ├── another hook.d/
 │   ├── script1
 │   ├── script2
 │   ├── ...
 │   └── scriptN
 │
 ├── ...
 └── ...
</strong></pre>

Only the **scripts** directly below the container hook folder will be executed,
however you can any folder structure inside containers, as your scripts require.

