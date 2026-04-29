# terraform-module

Terraform-модули для развёртывания EC2-инстансов на AWS с полной сетевой инфраструктурой. Репозиторий организован по принципу **reusable modules + environments**: два переиспользуемых модуля (`network`, `server`) и три готовых окружения (`dev`, `stage`, `prod`).

## Архитектура

```
terraform-module/
├── network/               # Модуль: VPC, Subnet, IGW, Route Table, Security Group, EIP
├── server/                # Модуль: EC2 (Ubuntu 24.04), TLS-ключ, Apache2
└── environments/
    ├── dev/               # Окружение: us-east-2, t2.micro
    ├── stage/             # Окружение: us-east-2, t2.micro
    └── prod/              # Окружение: us-east-2, t2.micro
```

Каждое окружение поднимает оба модуля и привязывает Elastic IP к инстансу.

---

## Модуль `network`

Создаёт изолированную сетевую инфраструктуру для одного окружения.

**Ресурсы:**
- `aws_vpc` — VPC с уникальным CIDR на окружение и поддержкой IPv6
- `aws_subnet` — публичная подсеть (`map_public_ip_on_launch = true`)
- `aws_internet_gateway` — интернет-шлюз
- `aws_route_table` + `aws_route_table_association` — маршрут `0.0.0.0/0` через IGW
- `aws_eip` — Elastic IP
- `aws_security_group` — группа безопасности с правилами по переданным портам
  - Ingress: TCP по указанным портам (IPv4 + IPv6, включая `0.0.0.0/0`)
  - Egress: весь трафик разрешён

**CIDR по окружениям:**

| env   | VPC CIDR       |
|-------|----------------|
| dev   | `10.2.0.0/16`  |
| stage | `10.3.0.0/16`  |
| prod  | `10.1.0.0/16`  |

### Inputs

| Переменная | Тип            | Описание                                  |
|------------|----------------|-------------------------------------------|
| `env`      | `string`       | Окружение. Допустимые: `dev`, `stage`, `prod` |
| `ports`    | `list(number)` | Список TCP-портов для открытия в SG       |

### Outputs

| Имя           | Описание                        |
|---------------|---------------------------------|
| `public_ip`   | Публичный IP Elastic IP         |
| `public_dns`  | DNS-имя Elastic IP              |
| `eip_id`      | ID Elastic IP (для ассоциации)  |
| `vpc_id`      | ID VPC                          |
| `subnet_id`   | ID подсети                      |
| `sec_group_id`| `list(string)` с ID SG          |

---

## Модуль `server`

Создаёт EC2-инстанс на Ubuntu 24.04 LTS, автоматически генерирует SSH-ключ и устанавливает Apache2.

**Ресурсы:**
- `data.aws_ami` — динамически подбирает последний образ Ubuntu 24.04 (`ubuntu-noble-24.04-amd64-server-*`) от Canonical (`099720109477`)
- `tls_private_key` — генерирует RSA-4096 ключ
- `aws_key_pair` — загружает публичный ключ в AWS
- `local_file` — сохраняет приватный ключ в `./<key_name>.pem` (chmod `0400`)
- `aws_instance` — EC2 с `remote-exec` provisioner: устанавливает и запускает `apache2`

### Inputs

| Переменная      | Тип            | Описание                              |
|-----------------|----------------|---------------------------------------|
| `region`        | `string`       | AWS-регион                            |
| `instance_type` | `string`       | Тип инстанса (например, `t2.micro`)   |
| `key_name`      | `string`       | Имя ключевой пары в AWS               |
| `subnet_id`     | любой          | ID подсети для размещения инстанса    |
| `sec_group_id`  | `list(string)` | Список ID групп безопасности          |

### Outputs

| Имя           | Описание              |
|---------------|-----------------------|
| `instance_id` | ID EC2-инстанса       |
| `region`      | Регион (из переменной)|

---

## Окружения

Все три окружения (`dev`, `stage`, `prod`) имеют идентичную структуру и используют AWS-провайдер `hashicorp/aws` версии `6.42.0`, регион `us-east-2`.

| Параметр        | dev        | stage        | prod      |
|-----------------|------------|--------------|-----------|
| `instance_type` | `t2.micro` | `t2.micro`   | `t2.micro`|
| `key_name`      | `mykey`    | `mykey-stage`| `mykey`   |
| `ports`         | 22, 80, 443, 8080, 9090 | 22, 80, 443, 8080, 9090 | 22, 80, 443, 8080, 9090 |

---

### Развёртывание окружения

```bash
cd environments/dev

terraform init
terraform plan
terraform apply
```

После успешного `apply` приватный ключ будет сохранён в файл `./mykey.pem`.

### Подключение к инстансу

```bash
ssh -i ./mykey.pem ubuntu@<public_ip>
```

Публичный IP можно получить командой:

```bash
terraform output -module=network public_ip
```

### Удаление ресурсов

```bash
terraform destroy
```
---

## Структура файлов

```
network/
├── main.tf        # VPC, Subnet, IGW, Route Table, SG, EIP
├── variables.tf   # env, ports
└── outputs.tf     # public_ip, public_dns, eip_id, vpc_id, subnet_id, sec_group_id

server/
├── main.tf        # aws_instance + remote-exec (apache2)
├── keys.tf        # tls_private_key, aws_key_pair, local_file
├── variables.tf   # region, instance_type, key_name, subnet_id, sec_group_id
└── outputs.tf     # instance_id, region

environments/
├── dev/main.tf
├── stage/main.tf
└── prod/main.tf
```

---

## Лицензия

MIT
