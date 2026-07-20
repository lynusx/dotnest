## Overview

### 身份认证

> 语雀所有的开放 API 都需要 Token 验证之后才能访问。

在请求的 HTTP Headers 传入 `X-Auth-Token` 带入您的身份 Token 信息，用于完成认证。

### 响应

语雀所有的开放 API 遵循通用状态码。

| 状态码 | 说明                   |
| ------ | ---------------------- |
| 200    | OK                     |
| 400    | 请求参数非法           |
| 401    | Token/Scope 未通过鉴权 |
| 403    | 无操作权限             |
| 404    | 实体未找到             |
| 422    | 请求参数校验失败       |
| 429    | 访问频率超限           |
| 500    | 内部错误               |

### 如何使用接口

- 接口域名为 `https://www.yuque.com`
- 请注意，我们的服务有使用次数的限制：每小时最多 5000 次请求，每秒最多 100 次请求。如果请求太频繁，可能需要稍后重试。
- 当您调用我们的接口时，会看到 `X-RateLimit-Limit`（总次数限制）和 `X-RateLimit-Remaining`（剩余次数）这样的信息，这有助于您了解当前的使用情况。

## doc

### 获取知识库的文档列表

#### 请求地址

`GET /api/v2/repos/{book_id}/docs`

#### 请求参数

| **参数名** | **位置** | **类型** | **必填** | **说明**                       |
| :--------- | :------- | :------- | :------- | :----------------------------- |
| book_id    | path     | integer  | 是       | 知识库 ID                      |
| offset     | query    | integer  | 否       | 偏移量 [分页参数]默认值: 0     |
| limit      | query    | integer  | 否       | 每页数量 [分页参数]默认值: 100 |

#### 响应 (Responses)

**200** — OK

| 字段 | 类型                   | 必填 | 说明 |
| ---- | ---------------------- | ---- | ---- |
| meta | object                 | 否   |      |
| data | array[[V2Doc](#v2doc)] | 否   |      |

##### `meta` 结构

| 字段  | 类型    | 必填 | 说明     |
| ----- | ------- | ---- | -------- |
| total | integer | 否   | 结果总量 |

---

### 创建文档

#### 请求地址

`POST /api/v2/repos/{book_id}/docs`

**注意: 创建文档后不会自动添加到目录，需要调用"知识库目录更新接口"更新到目录中**

#### 请求参数

| 参数名  | 位置 | 类型    | 必填 | 说明      |
| ------- | ---- | ------- | ---- | --------- |
| book_id | path | integer | 是   | 知识库 ID |

#### 请求体 (Request Body)

Content-Type: `application/json`

| 字段  | 类型   | 必填 | 说明     |
| ----- | ------ | ---- | -------- |
| slug  | string | 否   | 路径     |
| title | string | 否   | 标题     |
| body  | string | 是   | 正文内容 |

#### 响应 (Responses)

**200** — OK

| **字段** | **类型**                    | **必填** |
| :------- | :-------------------------- | :------- |
| data     | [V2DocDetail](#V2docdetail) | 否       |

---

### repo

### 获取知识库列表

#### 请求地址

`GET /api/v2/users/{login}/repos`

#### 请求参数

| 参数名 | 位置  | 类型    | 必填 | 说明                            |
| ------ | ----- | ------- | ---- | ------------------------------- |
| login  | path  | string  | 是   | 用户登录名                      |
| offset | query | integer | 否   | 偏移量 [分页参数] 默认值: 0     |
| limit  | query | integer | 否   | 每页数量 [分页参数] 默认值: 100 |

#### 响应 (Responses)

**200** — OK

| 字段 | 类型                     | 必填 |
| ---- | ------------------------ | ---- |
| data | array[[V2Book](#v2book)] | 否   |

### 创建知识库

#### 路径

`POST /api/v2/users/{login}/repos`

#### 请求参数

| 参数名 | 位置 | 类型   | 必填 | 说明       |
| ------ | ---- | ------ | ---- | ---------- |
| login  | path | string | 是   | 用户登录名 |

#### 请求体 (Request Body)

Content-Type: `application/json`

| 字段        | 类型   | 必填 | 说明 |
| ----------- | ------ | ---- | ---- |
| name        | string | 是   | 名称 |
| slug        | string | 是   | 路径 |
| description | string | 否   | 简介 |

#### 响应 (Responses)

**200** — OK

| 字段 | 类型              | 必填 | 说明 |
| ---- | ----------------- | ---- | ---- |
| data | [V2Book](#v2book) | 否   |      |

---

### 更新知识库目录

#### 路径

`PUT /api/v2/repos/{book_id}`

#### 请求参数

| 参数名  | 位置 | 类型    | 必填 | 说明      |
| ------- | ---- | ------- | ---- | --------- |
| book_id | path | integer | 是   | 知识库 ID |

#### 请求体 (Request Body)

Content-Type: `application/json`

| 字段 | 类型   | 必填 | 说明                 |
| ---- | ------ | ---- | -------------------- |
| toc  | string | 否   | 目录（详见下方说明） |

> `toc`** 说明：**
>
> 目录
>
> - 可利用此字段批量更新知识库的目录
> - 必须是 Markdown 格式, `[名称](文档路径)` 示例:
> - 使用 JSON 字符串编码

```markdown
- [新手指引]()
  - [语雀是什么](about)
  - [常见问题](faq)
- [基础功能]()
  - [工作台](dashboard)
  - [如何设置自定义路径](nkt888)
  - [外链](http://www.alipay.com)
```

#### 响应 (Responses)

**200** — OK

| 字段 | 类型              | 必填 | 说明 |
| ---- | ----------------- | ---- | ---- |
| data | [V2Book](#v2book) | 否   |      |

---

## 附录：数据模型

**注意：附录表中的内容均为部分字段**

### V2Doc

| 字段        | 类型              | 必填 | 说明          |
| ----------- | ----------------- | ---- | ------------- |
| id          | integer(int64)    | 否   | 文档 ID       |
| slug        | string            | 否   | 路径          |
| title       | string            | 否   | 标题          |
| description | string            | 否   | 摘要          |
| user_id     | integer(int64)    | 否   | 归属用户 ID   |
| book_id     | integer(int64)    | 否   | 归属知识库 ID |
| user        | [V2User](#V2User) | 否   |               |

### V2Book

| 字段        | 类型              | 必填 | 说明        |
| ----------- | ----------------- | ---- | ----------- |
| id          | integer(int64)    | 否   | 知识库 ID   |
| slug        | string            | 否   | 路径        |
| name        | string            | 否   | 名称        |
| user_id     | integer(int64)    | 否   | 归属用户 ID |
| description | string            | 否   | 知识库 简介 |
| items_count | integer           | 否   | 文档数量    |
| user        | [V2User](#V2User) | 否   |             |

### V2User

| 字段               | 类型           | 必填 | 说明             |
| ------------------ | -------------- | ---- | ---------------- |
| id                 | integer(int64) | 否   | 用户ID           |
| login              | string         | 否   | 登录名           |
| books_count        | integer        | 否   | 知识库数量       |
| public_books_count | integer        | 否   | 公开的知识库数量 |

### V2DocDetail

| 字段        | 类型           | 必填 | 说明                                                                                                                                   |
| ----------- | -------------- | ---- | -------------------------------------------------------------------------------------------------------------------------------------- |
| id          | integer(int64) | 否   | 文档 ID                                                                                                                                |
| slug        | string         | 否   | 路径                                                                                                                                   |
| title       | string         | 否   | 标题                                                                                                                                   |
| description | string         | 否   | 摘要                                                                                                                                   |
| user_id     | integer(int64) | 否   | 归属用户 ID                                                                                                                            |
| book_id     | integer(int64) | 否   | 归属知识库 ID                                                                                                                          |
| format      | string         | 否   | 内容格式 (markdown:Markdown 格式, lake:语雀 Lake 格式, html:HTML 标准格式, lakesheet:语雀表格) 可选值: markdown, lake, html, lakesheet |
| body        | string         | 否   | 正文原始内容                                                                                                                           |
| body_html   | string         | 否   | 正文 HTML 标准格式内容                                                                                                                 |
