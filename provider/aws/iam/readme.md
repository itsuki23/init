# IAM


## 前提
- ルートアカウントによるIAMユーザへの請求情報のアクセス許可
- BillingのViewとCost&Budget関連の全てにアクセス
（Cost＆Budget関連の取捨選択はリサーチ不足のため要相談）

## 案１ Adminグループにポリシーアタッチするだけ

##### Policy: DenyBillActExceptViewBill, DenyDetach, DenyEdit
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyBillActExceptViewBill",
            "Effect": "Deny",
            "Action": [
                "aws-portal:ModifyBilling",
                "aws-portal:ViewPaymentMethods",
                "aws-portal:ModifyAccount",
                "aws-portal:ViewAccount",
                "aws-portal:ModifyPaymentMethods",
                "aws-portal:ViewUsage"
            ],
            "Resource": "*"
        },

        {
            "Sid": "DenyDetachPolicyFromGroup",
            "Effect": "Deny",
            "Action": [
                "iam:DetachGroupPolicy"
            ],
            "Resource": "arn:aws:iam::< ID >:group/<group_name>"
        },

        {
            "Sid": "DenyEditThisPolicy",
            "Effect": "Deny",
            "Action": [
                "iam:CreatePolicyVersion",
                "iam:DeletePolicy",
                "iam:DeletePolicyVersion",
                "iam:SetDefaultPolicyVersion"
            ],
            "Resource": "arn:aws:iam::< ID >:policy/<this_policy_name>"
        }

    ]
}
```






## 案２ 請求情報などを確認するためのIAMを作成
- 請求情報・コスト関連を確認操作したい場合、専用IAMで操作
##### 1. Finance専用IAMグループ・ユーザーに以下のカスタマー管理ポリシーアタッチ
```
- Allow Billing[viewのみ]
- Allow Cost and Usage Report
- Allow Cost Explorer Service Allow
- Allow Budget 
```
##### 2. Adminグループにポリシーアタッチ
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyBill",
            "Effect": "Deny",
            "Action": [
                "aws-portal:*",
                "cur:*",
                "budgets:*",
                "ce:*"
            ],
            "Resource": "*"
        }
    ]
}
```






## 案3 番外編
##### IAMの権限境界をつくる (但し、手間がかかる)
手順
```
Permissions boundaryでアクセス権限の境界を設定。
Permissions boundaryを削除・編集等できないようにポリシー記述。
Permissions boundaryをアタッチされたユーザーが作成するユーザー、ロールに指定のPermisson boundaryを設定しなければならない制限を記述。
```
つまり、Permissions boundaryに関して周知させなければならない。
ルートアカウント>IamAdmin>ユーザー
<br>

##### ルートアカウントが作成するIamAdminにアタッチするポリシー
```
ポリシー「iam_all」↓を「IAM_Adminグループ」にアタッチ ※FullAccessはorganizations:...があるので今回使わず
-------------------------------------------------------------
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowIamAll",
            "Effect": "Allow",
            "Action": "iam:*",
            "Resource": "*"
        }
    ]
}


ポリシー「IamAdmin_boundary」↓を「IamAdminユーザー」の「Permissions boundary」にアタッチ  ※グループに「Permissions boundary」はない
-------------------------------------------------------------
{
    "Version": "2012-10-17",
    "Statement": [
        # 最初に全て許可
        {
            "Sid": "AllowIamAll",
            "Effect": "Allow",
            "Action": "iam:*",
            "Resource": "*"
        },

        # User_Boundaryポリシー(後述)をboundaryにアタッチしてないユーザーは作れない
        {
            "Sid": "DenyCreateWithoutBoundary",
            "Effect": "Deny",
            "Action": [
                "iam:CreateUser",
                "iam:PutUserPolicy",
                "iam:DeleteUserPolicy",
                "iam:AttachUserPolicy",
                "iam:DetachUserPolicy",
                "iam:PutUserPermissionsBoundary"
                "iam:UpdateUser",
            ],
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "iam:PermissionsBoundary": "arn:aws:iam::< ID >:policy/User_Boundary"
                }
            }
        },

        #  同様にロールも権限境界を超えないようにboundaryを義務付ける
        {
            "Sid": "DenyCreateOrChangeRoleWithoutBoundary",
            "Effect": "Deny",
            "Action": [
                "iam:CreateRole",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePermissionsBoundary"
            ],
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "iam:PermissionsBoundary": "arn:aws:iam::< ID >:policy/User_Boundary"
                }
            }
        },

        # boundary用ポリシーを編集できないように
        {
            "Sid": "DenyBoundaryPolicyEdit",
            "Effect": "Deny",
            "Action": [
                "iam:CreatePolicyVersion",
                "iam:DeletePolicy",
                "iam:DeletePolicyVersion",
                "iam:SetDefaultPolicyVersion"
            ],
            "Resource": [
                "arn:aws:iam::< ID >:policy/IamAdmin_boundary",
                "arn:aws:iam::< ID >:policy/User_Boundary"
            ]
        },

        # boundary自体をデタッチできないように
        {
            "Sid": "DenyBoundaryDelete",
            "Effect": "Deny",
            "Action": [
                "iam:DeleteUserPermissionsBoundary",
                "iam:DeleteRolePermissionsBoundary"
            ],
            "Resource": "*"
        }
    ]
}
```
<br>



##### IAM_Adminが作成するIAMグループに付与するポリシー
```
ポリシー「administrator」↓を「administratorグループ」にアタッチ
-------------------------------------------------------------
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AdministratorAccess",
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}


ポリシー「User_boundary」↓を「administratorユーザー」の「Permissions boundary」にアタッチ
-------------------------------------------------------------
{
    "Version": "2012-10-17",
    "Statement": [
        # 最初に全て許可
        {
            "Sid": "AdministratorAccess",
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        },

        # BillingのViewだけ許可
        {
            "Sid": "DenyBillActExceptViewBill",
            "Effect": "Deny",
            "Action": [
                "aws-portal:ModifyBilling",
                "aws-portal:ViewPaymentMethods",
                "aws-portal:ModifyAccount",
                "aws-portal:ViewAccount",
                "aws-portal:ModifyPaymentMethods",
                "aws-portal:ViewUsage"
            ],
            "Resource": "*"
        },

        # User_Boundary(後述)をboundaryにアタッチしてないユーザーは作れない
        {
            "Sid": "DenyCreateWithoutBoundary",
            "Effect": "Deny",
            "Action": [
                "iam:CreateUser",
                "iam:PutUserPolicy",
                "iam:DeleteUserPolicy",
                "iam:AttachUserPolicy",
                "iam:DetachUserPolicy",
                "iam:PutUserPermissionsBoundary"
                "iam:UpdateUser",
            ],
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "iam:PermissionsBoundary": "arn:aws:iam::< ID >:policy/User_Boundary"
                }
            }
        },

        #  同様にロールも権限境界を超えないようにboundaryを義務付ける
        {
            "Sid": "DenyCreateOrChangeRoleWithoutBoundary",
            "Effect": "Deny",
            "Action": [
                "iam:CreateRole",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePermissionsBoundary"
            ],
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "iam:PermissionsBoundary": "arn:aws:iam::< ID >:policy/User_Boundary"
                }
            }
        },

        # boundary用ポリシーを編集できないように
        {
            "Sid": "DenyBoundaryPolicyEdit",
            "Effect": "Deny",
            "Action": [
                "iam:CreatePolicyVersion",
                "iam:DeletePolicy",
                "iam:DeletePolicyVersion",
                "iam:SetDefaultPolicyVersion"
            ],
            "Resource": [
                "arn:aws:iam::< ID >:policy/IamAdmin_Boundary",
                "arn:aws:iam::< ID >:policy/User_Boundary"
            ]
        },

        # boundary自体をデタッチできないように
        {
            "Sid": "DenyBoundaryDelete",
            "Effect": "Deny",
            "Action": [
                "iam:DeleteUserPermissionsBoundary",
                "iam:DeleteRolePermissionsBoundary"
            ],
            "Resource": "*"
        }
    ]
}
```





# 参考
AWS Policy Generator
https://awspolicygen.s3.amazonaws.com/policygen.html

AWS IAM Policy Simulator
https://policysim.aws.amazon.com/home/index.jsp?#

Document
https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/list_identityandaccessmanagement.html

DeleteUserPermissionsBoundary
https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/access_policies_boundaries.html
https://qiita.com/f-daiki/items/e435159db6bde4d0c0ec ★aws
https://dev.classmethod.jp/articles/iam-permissions-boundary/
https://dev.classmethod.jp/articles/iam-policy-simulator-now-simulates-permissions-boundary/
