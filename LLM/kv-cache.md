# 深入理解 KV Cache：大模型推理为什么离不开它？

在大语言模型推理过程中，经常会看到一个词：**KV Cache**。它是影响大模型生成速度、显存占用、上下文长度和并发能力的关键机制。

简单来说，KV Cache 是 Transformer 模型在生成文本时，对历史 token 的 **Key** 和 **Value** 结果进行缓存，从而避免重复计算。它本质上是一种典型的 **用空间换时间** 的优化手段。

---

## 一、KV Cache 是什么？

KV Cache 的全称是 **Key-Value Cache**。

在 Transformer 的 Self-Attention 机制中，每个 token 都会被映射成三个向量：

```text
Q = Query
K = Key
V = Value
```

Self-Attention 的核心逻辑是：

```text
当前 token 的 Q，去和所有历史 token 的 K 做匹配，
再根据匹配权重，对所有历史 token 的 V 做加权求和。
```

在大语言模型的自回归生成中，模型是一个 token 一个 token 地往后生成：

```text
输入：今天天气
生成：真
生成：不错
生成：。
```

每生成一个新 token，都需要关注前面所有 token 的信息。

但是前面那些 token 对应的 `K` 和 `V` 一旦计算出来，后续就不会再改变。因此可以把它们缓存起来，后面直接复用。

这个缓存下来的历史 `K` 和 `V`，就是 **KV Cache**。

---

## 二、为什么需要 KV Cache？

如果没有 KV Cache，每生成一个新 token，模型都要重新计算整个上下文的 K 和 V。

假设 prompt 长度是 1000 个 token，现在模型要继续生成内容。

### 1. 不使用 KV Cache

生成第 1001 个 token 时，要计算：

```text
前 1000 个 token + 当前 token
```

生成第 1002 个 token 时，又要重新计算：

```text
前 1001 个 token + 当前 token
```

生成第 1003 个 token 时，又要重新计算：

```text
前 1002 个 token + 当前 token
```

这样历史 token 会被反复计算，计算量非常浪费。

### 2. 使用 KV Cache

使用 KV Cache 后，历史 token 的 K 和 V 只计算一次。

生成第 1001 个 token 时：

```text
计算当前 token 的 Q/K/V
复用前 1000 个 token 的 K/V
```

生成第 1002 个 token 时：

```text
计算当前 token 的 Q/K/V
复用前 1001 个 token 的 K/V
```

这样每一步只需要处理新增 token，而不用反复计算历史 token。

所以 KV Cache 的核心价值是：

```text
减少重复计算，提高解码速度
```

---

## 三、KV Cache 在生成过程中的作用

大模型推理通常分为两个阶段：

```text
Prefill 阶段
Decode 阶段
```

### 1. Prefill 阶段

Prefill 阶段是处理用户输入 prompt 的阶段。

例如用户输入：

```text
请解释一下 KV Cache 的作用
```

模型会一次性处理这段 prompt，并计算出每一层 Transformer 中所有 token 的 K 和 V。

这些 K/V 会被保存到 KV Cache 中。

可以理解为：

```text
把用户输入的上下文先读完，并建立缓存
```

---

### 2. Decode 阶段

Decode 阶段是模型开始逐 token 生成回答的阶段。

例如模型开始生成：

```text
KV Cache 是一种...
```

每生成一个 token，只需要计算当前新 token 的 Q/K/V，然后把新的 K/V 追加到缓存中。

流程大致是：

```text
第 1 步：使用 prompt 的 KV Cache，生成第一个 token
第 2 步：把第一个 token 的 K/V 加入 Cache，生成第二个 token
第 3 步：把第二个 token 的 K/V 加入 Cache，生成第三个 token
...
```

所以 KV Cache 会随着生成过程不断变长。

---

## 四、KV Cache 缓存的结构

KV Cache 并不是只存一份数据，而是每一层 Transformer 都要存一份 K 和 V。

假设模型有 32 层 Transformer，那么 KV Cache 大致结构是：

```text
KV Cache
├── Layer 0
│   ├── K: [batch, kv_heads, seq_len, head_dim]
│   └── V: [batch, kv_heads, seq_len, head_dim]
├── Layer 1
│   ├── K: [batch, kv_heads, seq_len, head_dim]
│   └── V: [batch, kv_heads, seq_len, head_dim]
├── Layer 2
│   ├── K: [batch, kv_heads, seq_len, head_dim]
│   └── V: [batch, kv_heads, seq_len, head_dim]
...
└── Layer 31
    ├── K: [batch, kv_heads, seq_len, head_dim]
    └── V: [batch, kv_heads, seq_len, head_dim]
```

其中：

```text
batch      = 批量大小
kv_heads   = KV 头数量
seq_len    = 当前上下文长度
head_dim   = 每个 attention head 的维度
```

注意，`kv_heads` 不一定等于 `attention_heads`。

很多现代大模型会使用 **MQA** 或 **GQA** 来减少 KV Cache 的体积。

---

## 五、KV Cache 怎么计算？

KV Cache 的显存占用可以用下面这个公式估算：

```text
KV Cache 显存 =
batch_size × seq_len × num_layers × 2 × num_kv_heads × head_dim × bytes_per_element
```

参数说明：

| 参数                  | 含义             |
| ------------------- | -------------- |
| `batch_size`        | 批量大小           |
| `seq_len`           | 当前上下文 token 长度 |
| `num_layers`        | Transformer 层数 |
| `2`                 | 表示 K 和 V 两份    |
| `num_kv_heads`      | KV head 数量     |
| `head_dim`          | 每个 head 的维度    |
| `bytes_per_element` | 每个元素占用字节数      |

常见精度占用：

| 数据类型 |   每个元素大小 |
| ---- | -------: |
| FP32 |  4 bytes |
| FP16 |  2 bytes |
| BF16 |  2 bytes |
| INT8 |   1 byte |
| INT4 | 0.5 byte |

---

## 六、举例计算 KV Cache 显存

假设有一个模型参数如下：

```text
batch_size = 1
seq_len = 4096
num_layers = 32
num_kv_heads = 32
head_dim = 128
precision = FP16
bytes_per_element = 2
```

代入公式：

```text
KV Cache =
1 × 4096 × 32 × 2 × 32 × 128 × 2
```

计算结果：

```text
= 2,147,483,648 bytes
≈ 2 GB
```

也就是说，在这个配置下，单个请求、4096 token 上下文，仅 KV Cache 就需要大约 **2GB 显存**。

这还不包括模型参数本身的显存，也不包括运行时临时内存。

---

## 七、上下文越长，KV Cache 越大

KV Cache 和上下文长度是线性关系。

也就是说：

```text
上下文长度翻倍，KV Cache 显存也基本翻倍
```

还是以上面的模型为例：

|  上下文长度 | KV Cache 约占用 |
| -----: | -----------: |
|   4096 |         2 GB |
|   8192 |         4 GB |
|  16384 |         8 GB |
|  32768 |        16 GB |
| 131072 |        64 GB |

这就是为什么长上下文模型对显存要求极高。

很多人以为大模型显存主要被模型参数占用，实际上在长上下文、高并发场景下，KV Cache 可能成为更大的显存压力来源。

---

## 八、KV Cache 和模型参数显存的区别

模型参数显存是固定的。

例如一个 7B 模型，如果使用 FP16 加载：

```text
7B × 2 bytes ≈ 14 GB
```

这个显存基本在模型加载后就固定了。

但 KV Cache 是动态增长的。

它取决于：

```text
上下文长度
生成长度
batch size
并发请求数
模型层数
KV head 数量
数据精度
```

所以大模型真实推理显存大致可以理解为：

```text
总显存 ≈ 模型参数显存 + KV Cache 显存 + 临时激活内存 + 框架开销
```

在短上下文、低并发场景下，模型参数可能是主要显存占用。

在长上下文、高并发场景下，KV Cache 往往会成为主要瓶颈。

---

## 九、KV Cache 为什么影响并发？

每个请求都有自己的上下文。

因此，每个请求都会维护自己的 KV Cache。

假设单个请求的 KV Cache 是 2GB：

```text
1 个请求  ≈ 2GB
10 个请求 ≈ 20GB
50 个请求 ≈ 100GB
```

所以服务端部署大模型时，KV Cache 会直接影响：

```text
最大并发数
最大上下文长度
单卡可承载请求数
推理吞吐量
首 token 延迟
整体显存规划
```

这也是 vLLM、TensorRT-LLM、llama.cpp 等推理框架都非常重视 KV Cache 管理的原因。

---

## 十、GQA / MQA 为什么能减少 KV Cache？

传统 Multi-Head Attention 中，每个 attention head 都有自己的 K 和 V。

如果模型有 32 个 attention heads，那么通常也有 32 组 K/V。

但是现代模型经常使用：

```text
MQA = Multi-Query Attention
GQA = Grouped-Query Attention
```

它们的目标之一就是减少 KV head 数量。

### 1. MHA

```text
attention_heads = 32
kv_heads = 32
```

每个 Query head 都有独立的 K/V。

### 2. GQA

```text
attention_heads = 32
kv_heads = 8
```

多个 Query head 共享一组 K/V。

### 3. MQA

```text
attention_heads = 32
kv_heads = 1
```

所有 Query head 共享一组 K/V。

因为 KV Cache 的公式中直接包含 `num_kv_heads`：

```text
KV Cache ∝ num_kv_heads
```

所以 `num_kv_heads` 越少，KV Cache 占用越低。

例如：

```text
kv_heads = 32 时，KV Cache ≈ 2GB
kv_heads = 8  时，KV Cache ≈ 512MB
kv_heads = 1  时，KV Cache ≈ 64MB
```

这就是 GQA 和 MQA 对推理部署非常重要的原因。

---

## 十一、KV Cache 的优点

KV Cache 的优点非常明确。

### 1. 提升生成速度

历史 token 的 K/V 不需要重复计算，生成阶段每一步只处理新增 token。

### 2. 降低重复计算

没有 KV Cache 时，历史上下文会被反复计算。

有 KV Cache 后，历史计算结果可以复用。

### 3. 支持长文本连续生成

在多轮对话、长文总结、代码生成等场景中，KV Cache 可以保留历史上下文的注意力信息。

### 4. 提升服务端吞吐

合理管理 KV Cache，可以让推理框架更高效地调度多请求。

---

## 十二、KV Cache 的代价

KV Cache 不是免费的，它的主要代价是显存。

### 1. 显存占用高

上下文越长，KV Cache 越大。

### 2. 并发压力大

每个请求都需要独立 KV Cache，高并发时显存会迅速增长。

### 3. 管理复杂

服务端需要考虑：

```text
KV Cache 分配
KV Cache 回收
请求中断后的释放
多请求调度
分页管理
显存碎片
Prefix Cache 复用
```

### 4. 长上下文成本高

长上下文模型虽然看起来支持几十万 token，但真正部署时，KV Cache 会成为核心成本。

---

## 十三、常见优化方式

### 1. GQA / MQA

减少 `num_kv_heads`，从模型结构上降低 KV Cache 占用。

### 2. KV Cache 量化

把 KV Cache 从 FP16/BF16 压缩到 INT8，甚至更低精度。

例如：

```text
FP16 KV Cache：2 bytes
INT8 KV Cache：1 byte
```

理论上可以节省约一半显存。

### 3. PagedAttention

类似操作系统的分页思想，把 KV Cache 切分成 block 管理，减少显存碎片，提高多请求调度效率。

vLLM 的核心优化之一就是 PagedAttention。

### 4. Sliding Window Attention

只保留最近一段上下文的 KV Cache，而不是保留全部上下文。

适合某些不需要完整历史上下文的场景。

### 5. Prefix Cache

如果多个请求有相同的系统提示词或公共前缀，可以复用前缀部分的 KV Cache。

例如很多应用都会有固定 system prompt：

```text
你是一个专业的客服助手...
```

这部分可以被多个请求复用，减少重复 prefill 计算。

### 6. 控制 max context length

不要盲目把上下文长度设置得很大。

例如业务实际只需要 8K，就没有必要默认开 32K 或 128K。

---

## 十四、从工程角度怎么看 KV Cache？

在真实部署中，KV Cache 不是一个纯算法概念，而是一个工程资源管理问题。

它会影响：

```text
显存规划
模型选型
上下文长度设计
接口最大输入长度
并发数限制
推理框架选择
GPU 成本
响应速度
```

例如同样是一个 7B 模型：

```text
短上下文 + 低并发：普通 GPU 可能够用
长上下文 + 高并发：KV Cache 可能直接撑爆显存
```

所以在做 AI 应用服务端设计时，不能只看模型参数大小，还必须评估 KV Cache 成本。

---

## 十五、一个简单类比

可以把 KV Cache 理解成聊天时的“笔记”。

没有 KV Cache 时，模型每说一句话，都要重新阅读前面所有聊天记录，并重新整理重点。

有 KV Cache 时，模型已经把前面的重点整理成笔记，后面每次只需要看笔记，再结合新内容继续生成。

所以：

```text
没有 KV Cache：每一步都重新读全文
有 KV Cache：历史内容只处理一次，后面直接复用结果
```

代价是：

```text
笔记越长，占用的空间越大
```

---

## 十六、总结

KV Cache 是大语言模型推理中的关键优化机制。

它缓存的是 Transformer 每一层中历史 token 的 Key 和 Value。通过复用历史 K/V，模型在生成新 token 时不需要重复计算完整上下文，从而显著提升生成速度。

但 KV Cache 会占用大量显存，并且它的大小会随着上下文长度、batch size、并发数、模型层数和 KV head 数量线性增长。

核心公式是：

```text
KV Cache 显存 =
batch_size × seq_len × num_layers × 2 × num_kv_heads × head_dim × bytes_per_element
```

一句话概括：

```text
KV Cache 是大模型推理中用空间换时间的缓存机制。
它提升生成速度，但会显著增加显存占用。
```

在大模型部署中，KV Cache 不是可有可无的细节，而是决定推理性能、并发能力和部署成本的核心因素之一。
