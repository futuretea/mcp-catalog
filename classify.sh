#!/bin/bash
#
# MCP Server 部署分类：离线 / 内网 / 公网
#

OFFLINE_FILE=$(mktemp)
INTRANET_FILE=$(mktemp)
PUBLIC_FILE=$(mktemp)

offline=0
intranet=0
public=0
total=0

# 离线：纯本地运行
OFFLINE_LIST="markitdown"

# 内网：可配置指向内网服务
INTRANET_LIST="mysql postgresql redis mongodb_database elasticsearch chroma snowflake supabase bigquery grafana tableau terraform pagerduty salesforce hubspot filescom"

# 公网：必须连接公网（remote runtime 或公网SaaS）
PUBLIC_LIST="asana atlassian aws aws_cdk aws_documentation aws_eks aws_kendra aws_knowledge aws_redshift azure brave_search browserbase calendar cloudflare contact databricks_genie databricks_uc_functions databricks_vector_search datadog deepwiki digitalocean duckduckgo_search dynatrace exa_search excel firecrawl github github_enterprise gitlab gitmcp gmail google-calendar google-drive google-maps-grounding-lite google-sheets linear microsoft-docs mondaycom morningstar neon notion onedrive outlook paypal playwright postman ref render slack square stripe tavily_search todoist wix word wordpress zapier"

for f in *.yaml; do
    [[ "$f" == "DEPLOYMENT.md" ]] && continue
    [[ "$f" == "classify.sh" ]] && continue

    total=$((total + 1))
    name=$(grep "^name:" "$f" | head -1 | sed 's/^name: *//' | tr -d '"' | tr -d "'")
    basename=$(echo "$f" | sed 's/\.yaml$//')

    # 检查runtime
    runtime=$(grep "^runtime:" "$f" | head -1 | sed 's/^runtime: *//' | tr -d '"' | tr -d "'")

    # 优先检查 runtime=remote
    if [[ "$runtime" == "remote" ]]; then
        echo "- $name ($f)" >> "$PUBLIC_FILE"
        public=$((public + 1))
        continue
    fi

    # 按文件名分类
    found="no"
    for item in $OFFLINE_LIST; do
        if [[ "$basename" == "$item" ]]; then
            echo "- $name ($f)" >> "$OFFLINE_FILE"
            offline=$((offline + 1))
            found="yes"
            break
        fi
    done
    [[ "$found" == "yes" ]] && continue

    for item in $INTRANET_LIST; do
        if [[ "$basename" == "$item" ]]; then
            echo "- $name ($f)" >> "$INTRANET_FILE"
            intranet=$((intranet + 1))
            found="yes"
            break
        fi
    done
    [[ "$found" == "yes" ]] && continue

    for item in $PUBLIC_LIST; do
        if [[ "$basename" == "$item" ]]; then
            echo "- $name ($f)" >> "$PUBLIC_FILE"
            public=$((public + 1))
            found="yes"
            break
        fi
    done
    [[ "$found" == "yes" ]] && continue

    # 未匹配的，检查是否有env
    has_env=$(grep -q "^env:" "$f" && echo "yes" || echo "no")
    if [[ "$has_env" == "no" ]]; then
        echo "- $name ($f)" >> "$OFFLINE_FILE"
        offline=$((offline + 1))
    else
        # 默认归为内网（可配置）
        echo "- $name ($f)" >> "$INTRANET_FILE"
        intranet=$((intranet + 1))
    fi
done

echo "# MCP Server 部署分类"
echo ""
echo "## 离线 (Offline) - $offline 个"
echo "纯本地运行，无需网络："
echo ""
[ -s "$OFFLINE_FILE" ] && cat "$OFFLINE_FILE" | sort || echo "（无）"

echo ""
echo "## 内网 (Intranet) - $intranet 个"
echo "可配置连接内网服务："
echo ""
[ -s "$INTRANET_FILE" ] && cat "$INTRANET_FILE" | sort || echo "（无）"

echo ""
echo "## 公网 (Public) - $public 个"
echo "必须连接公网服务："
echo ""
[ -s "$PUBLIC_FILE" ] && cat "$PUBLIC_FILE" | sort || echo "（无）"

echo ""
echo "---"
echo "总计: $total 个"

# 保存到文件
cat > DEPLOYMENT.md << EOF
# MCP Server 部署分类

## 离线 (Offline) - $offline 个

纯本地运行，无需网络：

$(cat "$OFFLINE_FILE" | sort)

## 内网 (Intranet) - $intranet 个

可配置连接内网服务（如私有数据库、内网服务）：

$(cat "$INTRANET_FILE" | sort)

## 公网 (Public) - $public 个

必须连接公网服务：

$(cat "$PUBLIC_FILE" | sort)

---

总计: $total 个
EOF

rm -f "$OFFLINE_FILE" "$INTRANET_FILE" "$PUBLIC_FILE"

echo ""
echo "结果已保存到 DEPLOYMENT.md"
