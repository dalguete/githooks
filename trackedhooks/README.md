Create all your scripts inside hook named container folders, like described below:

 trackedhooks/
  │
  ├── *commit-msg*.d/
  │   ├── script1
  │   ├── script2
  │   ├── ...
  │   └── scriptN
  │
  ├── *another hook*.d/
  │   ├── script1
  │   ├── script2
  │   ├── ...
  │   └── scriptN
  │
  ├── ...
  └── ...

Only the **scripts** directly below the container hook folder will be executed,
however you can have as many folder internally as your script requires

