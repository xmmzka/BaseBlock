# BaseBlock
 lua framework
### build
1. 不要定义变量名与表中键名相同的局部变量（唯一前缀局部变量替换冲突）
2. 定义类时使用点语法或方括号为属性赋值，不要直接在大括号内定义属性（模块定义移除冲突）