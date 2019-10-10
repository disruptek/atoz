
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Certificate Manager Private Certificate Authority
## version: 2017-08-22
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>This is the <i>ACM Private CA API Reference</i>. It provides descriptions, syntax, and usage examples for each of the actions and data types involved in creating and managing private certificate authorities (CA) for your organization.</p> <p>The documentation for each action shows the Query API request parameters and the XML response. Alternatively, you can use one of the AWS SDKs to access an API that's tailored to the programming language or platform that you're using. For more information, see <a href="https://aws.amazon.com/tools/#SDKs">AWS SDKs</a>.</p> <note> <p>Each ACM Private CA API action has a throttling limit which determines the number of times the action can be called per second. For more information, see <a href="https://docs.aws.amazon.com/acm-pca/latest/userguide/PcaLimits.html#PcaLimits-api">API Rate Limits in ACM Private CA</a> in the ACM Private CA user guide.</p> </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/acm-pca/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "acm-pca.ap-northeast-1.amazonaws.com", "ap-southeast-1": "acm-pca.ap-southeast-1.amazonaws.com",
                           "us-west-2": "acm-pca.us-west-2.amazonaws.com",
                           "eu-west-2": "acm-pca.eu-west-2.amazonaws.com", "ap-northeast-3": "acm-pca.ap-northeast-3.amazonaws.com", "eu-central-1": "acm-pca.eu-central-1.amazonaws.com",
                           "us-east-2": "acm-pca.us-east-2.amazonaws.com",
                           "us-east-1": "acm-pca.us-east-1.amazonaws.com", "cn-northwest-1": "acm-pca.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "acm-pca.ap-south-1.amazonaws.com",
                           "eu-north-1": "acm-pca.eu-north-1.amazonaws.com", "ap-northeast-2": "acm-pca.ap-northeast-2.amazonaws.com",
                           "us-west-1": "acm-pca.us-west-1.amazonaws.com", "us-gov-east-1": "acm-pca.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "acm-pca.eu-west-3.amazonaws.com",
                           "cn-north-1": "acm-pca.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "acm-pca.sa-east-1.amazonaws.com",
                           "eu-west-1": "acm-pca.eu-west-1.amazonaws.com", "us-gov-west-1": "acm-pca.us-gov-west-1.amazonaws.com", "ap-southeast-2": "acm-pca.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "acm-pca.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "acm-pca.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "acm-pca.ap-southeast-1.amazonaws.com",
      "us-west-2": "acm-pca.us-west-2.amazonaws.com",
      "eu-west-2": "acm-pca.eu-west-2.amazonaws.com",
      "ap-northeast-3": "acm-pca.ap-northeast-3.amazonaws.com",
      "eu-central-1": "acm-pca.eu-central-1.amazonaws.com",
      "us-east-2": "acm-pca.us-east-2.amazonaws.com",
      "us-east-1": "acm-pca.us-east-1.amazonaws.com",
      "cn-northwest-1": "acm-pca.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "acm-pca.ap-south-1.amazonaws.com",
      "eu-north-1": "acm-pca.eu-north-1.amazonaws.com",
      "ap-northeast-2": "acm-pca.ap-northeast-2.amazonaws.com",
      "us-west-1": "acm-pca.us-west-1.amazonaws.com",
      "us-gov-east-1": "acm-pca.us-gov-east-1.amazonaws.com",
      "eu-west-3": "acm-pca.eu-west-3.amazonaws.com",
      "cn-north-1": "acm-pca.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "acm-pca.sa-east-1.amazonaws.com",
      "eu-west-1": "acm-pca.eu-west-1.amazonaws.com",
      "us-gov-west-1": "acm-pca.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "acm-pca.ap-southeast-2.amazonaws.com",
      "ca-central-1": "acm-pca.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "acm-pca"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCertificateAuthority_602803 = ref object of OpenApiRestCall_602466
proc url_CreateCertificateAuthority_602805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCertificateAuthority_602804(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a root or subordinate private certificate authority (CA). You must specify the CA configuration, the certificate revocation list (CRL) configuration, the CA type, and an optional idempotency token to avoid accidental creation of multiple CAs. The CA configuration specifies the name of the algorithm and key size to be used to create the CA private key, the type of signing algorithm that the CA uses, and X.500 subject information. The CRL configuration specifies the CRL expiration period in days (the validity period of the CRL), the Amazon S3 bucket that will contain the CRL, and a CNAME alias for the S3 bucket that is included in certificates issued by the CA. If successful, this action returns the Amazon Resource Name (ARN) of the CA.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "ACMPrivateCA.CreateCertificateAuthority"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_CreateCertificateAuthority_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a root or subordinate private certificate authority (CA). You must specify the CA configuration, the certificate revocation list (CRL) configuration, the CA type, and an optional idempotency token to avoid accidental creation of multiple CAs. The CA configuration specifies the name of the algorithm and key size to be used to create the CA private key, the type of signing algorithm that the CA uses, and X.500 subject information. The CRL configuration specifies the CRL expiration period in days (the validity period of the CRL), the Amazon S3 bucket that will contain the CRL, and a CNAME alias for the S3 bucket that is included in certificates issued by the CA. If successful, this action returns the Amazon Resource Name (ARN) of the CA.
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_CreateCertificateAuthority_602803; body: JsonNode): Recallable =
  ## createCertificateAuthority
  ## Creates a root or subordinate private certificate authority (CA). You must specify the CA configuration, the certificate revocation list (CRL) configuration, the CA type, and an optional idempotency token to avoid accidental creation of multiple CAs. The CA configuration specifies the name of the algorithm and key size to be used to create the CA private key, the type of signing algorithm that the CA uses, and X.500 subject information. The CRL configuration specifies the CRL expiration period in days (the validity period of the CRL), the Amazon S3 bucket that will contain the CRL, and a CNAME alias for the S3 bucket that is included in certificates issued by the CA. If successful, this action returns the Amazon Resource Name (ARN) of the CA.
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var createCertificateAuthority* = Call_CreateCertificateAuthority_602803(
    name: "createCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.CreateCertificateAuthority",
    validator: validate_CreateCertificateAuthority_602804, base: "/",
    url: url_CreateCertificateAuthority_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCertificateAuthorityAuditReport_603072 = ref object of OpenApiRestCall_602466
proc url_CreateCertificateAuthorityAuditReport_603074(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCertificateAuthorityAuditReport_603073(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an audit report that lists every time that your CA private key is used. The report is saved in the Amazon S3 bucket that you specify on input. The <a>IssueCertificate</a> and <a>RevokeCertificate</a> actions use the private key.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "ACMPrivateCA.CreateCertificateAuthorityAuditReport"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_CreateCertificateAuthorityAuditReport_603072;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates an audit report that lists every time that your CA private key is used. The report is saved in the Amazon S3 bucket that you specify on input. The <a>IssueCertificate</a> and <a>RevokeCertificate</a> actions use the private key.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_CreateCertificateAuthorityAuditReport_603072;
          body: JsonNode): Recallable =
  ## createCertificateAuthorityAuditReport
  ## Creates an audit report that lists every time that your CA private key is used. The report is saved in the Amazon S3 bucket that you specify on input. The <a>IssueCertificate</a> and <a>RevokeCertificate</a> actions use the private key.
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var createCertificateAuthorityAuditReport* = Call_CreateCertificateAuthorityAuditReport_603072(
    name: "createCertificateAuthorityAuditReport", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.CreateCertificateAuthorityAuditReport",
    validator: validate_CreateCertificateAuthorityAuditReport_603073, base: "/",
    url: url_CreateCertificateAuthorityAuditReport_603074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePermission_603087 = ref object of OpenApiRestCall_602466
proc url_CreatePermission_603089(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePermission_603088(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Assigns permissions from a private CA to a designated AWS service. Services are specified by their service principals and can be given permission to create and retrieve certificates on a private CA. Services can also be given permission to list the active permissions that the private CA has granted. For ACM to automatically renew your private CA's certificates, you must assign all possible permissions from the CA to the ACM service principal.</p> <p>At this time, you can only assign permissions to ACM (<code>acm.amazonaws.com</code>). Permissions can be revoked with the <a>DeletePermission</a> action and listed with the <a>ListPermissions</a> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "ACMPrivateCA.CreatePermission"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_CreatePermission_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns permissions from a private CA to a designated AWS service. Services are specified by their service principals and can be given permission to create and retrieve certificates on a private CA. Services can also be given permission to list the active permissions that the private CA has granted. For ACM to automatically renew your private CA's certificates, you must assign all possible permissions from the CA to the ACM service principal.</p> <p>At this time, you can only assign permissions to ACM (<code>acm.amazonaws.com</code>). Permissions can be revoked with the <a>DeletePermission</a> action and listed with the <a>ListPermissions</a> action.</p>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CreatePermission_603087; body: JsonNode): Recallable =
  ## createPermission
  ## <p>Assigns permissions from a private CA to a designated AWS service. Services are specified by their service principals and can be given permission to create and retrieve certificates on a private CA. Services can also be given permission to list the active permissions that the private CA has granted. For ACM to automatically renew your private CA's certificates, you must assign all possible permissions from the CA to the ACM service principal.</p> <p>At this time, you can only assign permissions to ACM (<code>acm.amazonaws.com</code>). Permissions can be revoked with the <a>DeletePermission</a> action and listed with the <a>ListPermissions</a> action.</p>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var createPermission* = Call_CreatePermission_603087(name: "createPermission",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.CreatePermission",
    validator: validate_CreatePermission_603088, base: "/",
    url: url_CreatePermission_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCertificateAuthority_603102 = ref object of OpenApiRestCall_602466
proc url_DeleteCertificateAuthority_603104(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCertificateAuthority_603103(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a private certificate authority (CA). You must provide the Amazon Resource Name (ARN) of the private CA that you want to delete. You can find the ARN by calling the <a>ListCertificateAuthorities</a> action. </p> <note> <p>Deleting a CA will invalidate other CAs and certificates below it in your CA hierarchy.</p> </note> <p>Before you can delete a CA that you have created and activated, you must disable it. To do this, call the <a>UpdateCertificateAuthority</a> action and set the <b>CertificateAuthorityStatus</b> parameter to <code>DISABLED</code>. </p> <p>Additionally, you can delete a CA if you are waiting for it to be created (that is, the status of the CA is <code>CREATING</code>). You can also delete it if the CA has been created but you haven't yet imported the signed certificate into ACM Private CA (that is, the status of the CA is <code>PENDING_CERTIFICATE</code>). </p> <p>When you successfully call <a>DeleteCertificateAuthority</a>, the CA's status changes to <code>DELETED</code>. However, the CA won't be permanently deleted until the restoration period has passed. By default, if you do not set the <code>PermanentDeletionTimeInDays</code> parameter, the CA remains restorable for 30 days. You can set the parameter from 7 to 30 days. The <a>DescribeCertificateAuthority</a> action returns the time remaining in the restoration window of a private CA in the <code>DELETED</code> state. To restore an eligible CA, call the <a>RestoreCertificateAuthority</a> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "ACMPrivateCA.DeleteCertificateAuthority"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_DeleteCertificateAuthority_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a private certificate authority (CA). You must provide the Amazon Resource Name (ARN) of the private CA that you want to delete. You can find the ARN by calling the <a>ListCertificateAuthorities</a> action. </p> <note> <p>Deleting a CA will invalidate other CAs and certificates below it in your CA hierarchy.</p> </note> <p>Before you can delete a CA that you have created and activated, you must disable it. To do this, call the <a>UpdateCertificateAuthority</a> action and set the <b>CertificateAuthorityStatus</b> parameter to <code>DISABLED</code>. </p> <p>Additionally, you can delete a CA if you are waiting for it to be created (that is, the status of the CA is <code>CREATING</code>). You can also delete it if the CA has been created but you haven't yet imported the signed certificate into ACM Private CA (that is, the status of the CA is <code>PENDING_CERTIFICATE</code>). </p> <p>When you successfully call <a>DeleteCertificateAuthority</a>, the CA's status changes to <code>DELETED</code>. However, the CA won't be permanently deleted until the restoration period has passed. By default, if you do not set the <code>PermanentDeletionTimeInDays</code> parameter, the CA remains restorable for 30 days. You can set the parameter from 7 to 30 days. The <a>DescribeCertificateAuthority</a> action returns the time remaining in the restoration window of a private CA in the <code>DELETED</code> state. To restore an eligible CA, call the <a>RestoreCertificateAuthority</a> action.</p>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_DeleteCertificateAuthority_603102; body: JsonNode): Recallable =
  ## deleteCertificateAuthority
  ## <p>Deletes a private certificate authority (CA). You must provide the Amazon Resource Name (ARN) of the private CA that you want to delete. You can find the ARN by calling the <a>ListCertificateAuthorities</a> action. </p> <note> <p>Deleting a CA will invalidate other CAs and certificates below it in your CA hierarchy.</p> </note> <p>Before you can delete a CA that you have created and activated, you must disable it. To do this, call the <a>UpdateCertificateAuthority</a> action and set the <b>CertificateAuthorityStatus</b> parameter to <code>DISABLED</code>. </p> <p>Additionally, you can delete a CA if you are waiting for it to be created (that is, the status of the CA is <code>CREATING</code>). You can also delete it if the CA has been created but you haven't yet imported the signed certificate into ACM Private CA (that is, the status of the CA is <code>PENDING_CERTIFICATE</code>). </p> <p>When you successfully call <a>DeleteCertificateAuthority</a>, the CA's status changes to <code>DELETED</code>. However, the CA won't be permanently deleted until the restoration period has passed. By default, if you do not set the <code>PermanentDeletionTimeInDays</code> parameter, the CA remains restorable for 30 days. You can set the parameter from 7 to 30 days. The <a>DescribeCertificateAuthority</a> action returns the time remaining in the restoration window of a private CA in the <code>DELETED</code> state. To restore an eligible CA, call the <a>RestoreCertificateAuthority</a> action.</p>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var deleteCertificateAuthority* = Call_DeleteCertificateAuthority_603102(
    name: "deleteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.DeleteCertificateAuthority",
    validator: validate_DeleteCertificateAuthority_603103, base: "/",
    url: url_DeleteCertificateAuthority_603104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePermission_603117 = ref object of OpenApiRestCall_602466
proc url_DeletePermission_603119(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePermission_603118(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Revokes permissions that a private CA assigned to a designated AWS service. Permissions can be created with the <a>CreatePermission</a> action and listed with the <a>ListPermissions</a> action. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "ACMPrivateCA.DeletePermission"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_DeletePermission_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes permissions that a private CA assigned to a designated AWS service. Permissions can be created with the <a>CreatePermission</a> action and listed with the <a>ListPermissions</a> action. 
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_DeletePermission_603117; body: JsonNode): Recallable =
  ## deletePermission
  ## Revokes permissions that a private CA assigned to a designated AWS service. Permissions can be created with the <a>CreatePermission</a> action and listed with the <a>ListPermissions</a> action. 
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var deletePermission* = Call_DeletePermission_603117(name: "deletePermission",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.DeletePermission",
    validator: validate_DeletePermission_603118, base: "/",
    url: url_DeletePermission_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificateAuthority_603132 = ref object of OpenApiRestCall_602466
proc url_DescribeCertificateAuthority_603134(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCertificateAuthority_603133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists information about your private certificate authority (CA). You specify the private CA on input by its ARN (Amazon Resource Name). The output contains the status of your CA. This can be any of the following: </p> <ul> <li> <p> <code>CREATING</code> - ACM Private CA is creating your private certificate authority.</p> </li> <li> <p> <code>PENDING_CERTIFICATE</code> - The certificate is pending. You must use your ACM Private CA-hosted or on-premises root or subordinate CA to sign your private CA CSR and then import it into PCA. </p> </li> <li> <p> <code>ACTIVE</code> - Your private CA is active.</p> </li> <li> <p> <code>DISABLED</code> - Your private CA has been disabled.</p> </li> <li> <p> <code>EXPIRED</code> - Your private CA certificate has expired.</p> </li> <li> <p> <code>FAILED</code> - Your private CA has failed. Your CA can fail because of problems such a network outage or backend AWS failure or other errors. A failed CA can never return to the pending state. You must create a new CA. </p> </li> <li> <p> <code>DELETED</code> - Your private CA is within the restoration period, after which it is permanently deleted. The length of time remaining in the CA's restoration period is also included in this action's output.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "ACMPrivateCA.DescribeCertificateAuthority"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_DescribeCertificateAuthority_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists information about your private certificate authority (CA). You specify the private CA on input by its ARN (Amazon Resource Name). The output contains the status of your CA. This can be any of the following: </p> <ul> <li> <p> <code>CREATING</code> - ACM Private CA is creating your private certificate authority.</p> </li> <li> <p> <code>PENDING_CERTIFICATE</code> - The certificate is pending. You must use your ACM Private CA-hosted or on-premises root or subordinate CA to sign your private CA CSR and then import it into PCA. </p> </li> <li> <p> <code>ACTIVE</code> - Your private CA is active.</p> </li> <li> <p> <code>DISABLED</code> - Your private CA has been disabled.</p> </li> <li> <p> <code>EXPIRED</code> - Your private CA certificate has expired.</p> </li> <li> <p> <code>FAILED</code> - Your private CA has failed. Your CA can fail because of problems such a network outage or backend AWS failure or other errors. A failed CA can never return to the pending state. You must create a new CA. </p> </li> <li> <p> <code>DELETED</code> - Your private CA is within the restoration period, after which it is permanently deleted. The length of time remaining in the CA's restoration period is also included in this action's output.</p> </li> </ul>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_DescribeCertificateAuthority_603132; body: JsonNode): Recallable =
  ## describeCertificateAuthority
  ## <p>Lists information about your private certificate authority (CA). You specify the private CA on input by its ARN (Amazon Resource Name). The output contains the status of your CA. This can be any of the following: </p> <ul> <li> <p> <code>CREATING</code> - ACM Private CA is creating your private certificate authority.</p> </li> <li> <p> <code>PENDING_CERTIFICATE</code> - The certificate is pending. You must use your ACM Private CA-hosted or on-premises root or subordinate CA to sign your private CA CSR and then import it into PCA. </p> </li> <li> <p> <code>ACTIVE</code> - Your private CA is active.</p> </li> <li> <p> <code>DISABLED</code> - Your private CA has been disabled.</p> </li> <li> <p> <code>EXPIRED</code> - Your private CA certificate has expired.</p> </li> <li> <p> <code>FAILED</code> - Your private CA has failed. Your CA can fail because of problems such a network outage or backend AWS failure or other errors. A failed CA can never return to the pending state. You must create a new CA. </p> </li> <li> <p> <code>DELETED</code> - Your private CA is within the restoration period, after which it is permanently deleted. The length of time remaining in the CA's restoration period is also included in this action's output.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var describeCertificateAuthority* = Call_DescribeCertificateAuthority_603132(
    name: "describeCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.DescribeCertificateAuthority",
    validator: validate_DescribeCertificateAuthority_603133, base: "/",
    url: url_DescribeCertificateAuthority_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificateAuthorityAuditReport_603147 = ref object of OpenApiRestCall_602466
proc url_DescribeCertificateAuthorityAuditReport_603149(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCertificateAuthorityAuditReport_603148(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists information about a specific audit report created by calling the <a>CreateCertificateAuthorityAuditReport</a> action. Audit information is created every time the certificate authority (CA) private key is used. The private key is used when you call the <a>IssueCertificate</a> action or the <a>RevokeCertificate</a> action. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "ACMPrivateCA.DescribeCertificateAuthorityAuditReport"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_DescribeCertificateAuthorityAuditReport_603147;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists information about a specific audit report created by calling the <a>CreateCertificateAuthorityAuditReport</a> action. Audit information is created every time the certificate authority (CA) private key is used. The private key is used when you call the <a>IssueCertificate</a> action or the <a>RevokeCertificate</a> action. 
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_DescribeCertificateAuthorityAuditReport_603147;
          body: JsonNode): Recallable =
  ## describeCertificateAuthorityAuditReport
  ## Lists information about a specific audit report created by calling the <a>CreateCertificateAuthorityAuditReport</a> action. Audit information is created every time the certificate authority (CA) private key is used. The private key is used when you call the <a>IssueCertificate</a> action or the <a>RevokeCertificate</a> action. 
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var describeCertificateAuthorityAuditReport* = Call_DescribeCertificateAuthorityAuditReport_603147(
    name: "describeCertificateAuthorityAuditReport", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com", route: "/#X-Amz-Target=ACMPrivateCA.DescribeCertificateAuthorityAuditReport",
    validator: validate_DescribeCertificateAuthorityAuditReport_603148, base: "/",
    url: url_DescribeCertificateAuthorityAuditReport_603149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCertificate_603162 = ref object of OpenApiRestCall_602466
proc url_GetCertificate_603164(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCertificate_603163(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a certificate from your private CA. The ARN of the certificate is returned when you call the <a>IssueCertificate</a> action. You must specify both the ARN of your private CA and the ARN of the issued certificate when calling the <b>GetCertificate</b> action. You can retrieve the certificate if it is in the <b>ISSUED</b> state. You can call the <a>CreateCertificateAuthorityAuditReport</a> action to create a report that contains information about all of the certificates issued and revoked by your private CA. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "ACMPrivateCA.GetCertificate"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_GetCertificate_603162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a certificate from your private CA. The ARN of the certificate is returned when you call the <a>IssueCertificate</a> action. You must specify both the ARN of your private CA and the ARN of the issued certificate when calling the <b>GetCertificate</b> action. You can retrieve the certificate if it is in the <b>ISSUED</b> state. You can call the <a>CreateCertificateAuthorityAuditReport</a> action to create a report that contains information about all of the certificates issued and revoked by your private CA. 
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_GetCertificate_603162; body: JsonNode): Recallable =
  ## getCertificate
  ## Retrieves a certificate from your private CA. The ARN of the certificate is returned when you call the <a>IssueCertificate</a> action. You must specify both the ARN of your private CA and the ARN of the issued certificate when calling the <b>GetCertificate</b> action. You can retrieve the certificate if it is in the <b>ISSUED</b> state. You can call the <a>CreateCertificateAuthorityAuditReport</a> action to create a report that contains information about all of the certificates issued and revoked by your private CA. 
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var getCertificate* = Call_GetCertificate_603162(name: "getCertificate",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.GetCertificate",
    validator: validate_GetCertificate_603163, base: "/", url: url_GetCertificate_603164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCertificateAuthorityCertificate_603177 = ref object of OpenApiRestCall_602466
proc url_GetCertificateAuthorityCertificate_603179(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCertificateAuthorityCertificate_603178(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the certificate and certificate chain for your private certificate authority (CA). Both the certificate and the chain are base64 PEM-encoded. The chain does not include the CA certificate. Each certificate in the chain signs the one before it. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "ACMPrivateCA.GetCertificateAuthorityCertificate"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_GetCertificateAuthorityCertificate_603177;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the certificate and certificate chain for your private certificate authority (CA). Both the certificate and the chain are base64 PEM-encoded. The chain does not include the CA certificate. Each certificate in the chain signs the one before it. 
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_GetCertificateAuthorityCertificate_603177;
          body: JsonNode): Recallable =
  ## getCertificateAuthorityCertificate
  ## Retrieves the certificate and certificate chain for your private certificate authority (CA). Both the certificate and the chain are base64 PEM-encoded. The chain does not include the CA certificate. Each certificate in the chain signs the one before it. 
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var getCertificateAuthorityCertificate* = Call_GetCertificateAuthorityCertificate_603177(
    name: "getCertificateAuthorityCertificate", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.GetCertificateAuthorityCertificate",
    validator: validate_GetCertificateAuthorityCertificate_603178, base: "/",
    url: url_GetCertificateAuthorityCertificate_603179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCertificateAuthorityCsr_603192 = ref object of OpenApiRestCall_602466
proc url_GetCertificateAuthorityCsr_603194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCertificateAuthorityCsr_603193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the certificate signing request (CSR) for your private certificate authority (CA). The CSR is created when you call the <a>CreateCertificateAuthority</a> action. Sign the CSR with your ACM Private CA-hosted or on-premises root or subordinate CA. Then import the signed certificate back into ACM Private CA by calling the <a>ImportCertificateAuthorityCertificate</a> action. The CSR is returned as a base64 PEM-encoded string. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "ACMPrivateCA.GetCertificateAuthorityCsr"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_GetCertificateAuthorityCsr_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the certificate signing request (CSR) for your private certificate authority (CA). The CSR is created when you call the <a>CreateCertificateAuthority</a> action. Sign the CSR with your ACM Private CA-hosted or on-premises root or subordinate CA. Then import the signed certificate back into ACM Private CA by calling the <a>ImportCertificateAuthorityCertificate</a> action. The CSR is returned as a base64 PEM-encoded string. 
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_GetCertificateAuthorityCsr_603192; body: JsonNode): Recallable =
  ## getCertificateAuthorityCsr
  ## Retrieves the certificate signing request (CSR) for your private certificate authority (CA). The CSR is created when you call the <a>CreateCertificateAuthority</a> action. Sign the CSR with your ACM Private CA-hosted or on-premises root or subordinate CA. Then import the signed certificate back into ACM Private CA by calling the <a>ImportCertificateAuthorityCertificate</a> action. The CSR is returned as a base64 PEM-encoded string. 
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var getCertificateAuthorityCsr* = Call_GetCertificateAuthorityCsr_603192(
    name: "getCertificateAuthorityCsr", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.GetCertificateAuthorityCsr",
    validator: validate_GetCertificateAuthorityCsr_603193, base: "/",
    url: url_GetCertificateAuthorityCsr_603194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCertificateAuthorityCertificate_603207 = ref object of OpenApiRestCall_602466
proc url_ImportCertificateAuthorityCertificate_603209(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportCertificateAuthorityCertificate_603208(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Imports a signed private CA certificate into ACM Private CA. This action is used when you are using a chain of trust whose root is located outside ACM Private CA. Before you can call this action, the following preparations must in place:</p> <ol> <li> <p>In ACM Private CA, call the <a>CreateCertificateAuthority</a> action to create the private CA that that you plan to back with the imported certificate.</p> </li> <li> <p>Call the <a>GetCertificateAuthorityCsr</a> action to generate a certificate signing request (CSR).</p> </li> <li> <p>Sign the CSR using a root or intermediate CA hosted either by an on-premises PKI hierarchy or a commercial CA..</p> </li> <li> <p>Create a certificate chain and copy the signed certificate and the certificate chain to your working directory.</p> </li> </ol> <p>The following requirements apply when you import a CA certificate.</p> <ul> <li> <p>You cannot import a non-self-signed certificate for use as a root CA.</p> </li> <li> <p>You cannot import a self-signed certificate for use as a subordinate CA.</p> </li> <li> <p>Your certificate chain must not include the private CA certificate that you are importing.</p> </li> <li> <p>Your ACM Private CA-hosted or on-premises CA certificate must be the last certificate in your chain. The subordinate certificate, if any, that your root CA signed must be next to last. The subordinate certificate signed by the preceding subordinate CA must come next, and so on until your chain is built. </p> </li> <li> <p>The chain must be PEM-encoded.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "ACMPrivateCA.ImportCertificateAuthorityCertificate"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_ImportCertificateAuthorityCertificate_603207;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Imports a signed private CA certificate into ACM Private CA. This action is used when you are using a chain of trust whose root is located outside ACM Private CA. Before you can call this action, the following preparations must in place:</p> <ol> <li> <p>In ACM Private CA, call the <a>CreateCertificateAuthority</a> action to create the private CA that that you plan to back with the imported certificate.</p> </li> <li> <p>Call the <a>GetCertificateAuthorityCsr</a> action to generate a certificate signing request (CSR).</p> </li> <li> <p>Sign the CSR using a root or intermediate CA hosted either by an on-premises PKI hierarchy or a commercial CA..</p> </li> <li> <p>Create a certificate chain and copy the signed certificate and the certificate chain to your working directory.</p> </li> </ol> <p>The following requirements apply when you import a CA certificate.</p> <ul> <li> <p>You cannot import a non-self-signed certificate for use as a root CA.</p> </li> <li> <p>You cannot import a self-signed certificate for use as a subordinate CA.</p> </li> <li> <p>Your certificate chain must not include the private CA certificate that you are importing.</p> </li> <li> <p>Your ACM Private CA-hosted or on-premises CA certificate must be the last certificate in your chain. The subordinate certificate, if any, that your root CA signed must be next to last. The subordinate certificate signed by the preceding subordinate CA must come next, and so on until your chain is built. </p> </li> <li> <p>The chain must be PEM-encoded.</p> </li> </ul>
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_ImportCertificateAuthorityCertificate_603207;
          body: JsonNode): Recallable =
  ## importCertificateAuthorityCertificate
  ## <p>Imports a signed private CA certificate into ACM Private CA. This action is used when you are using a chain of trust whose root is located outside ACM Private CA. Before you can call this action, the following preparations must in place:</p> <ol> <li> <p>In ACM Private CA, call the <a>CreateCertificateAuthority</a> action to create the private CA that that you plan to back with the imported certificate.</p> </li> <li> <p>Call the <a>GetCertificateAuthorityCsr</a> action to generate a certificate signing request (CSR).</p> </li> <li> <p>Sign the CSR using a root or intermediate CA hosted either by an on-premises PKI hierarchy or a commercial CA..</p> </li> <li> <p>Create a certificate chain and copy the signed certificate and the certificate chain to your working directory.</p> </li> </ol> <p>The following requirements apply when you import a CA certificate.</p> <ul> <li> <p>You cannot import a non-self-signed certificate for use as a root CA.</p> </li> <li> <p>You cannot import a self-signed certificate for use as a subordinate CA.</p> </li> <li> <p>Your certificate chain must not include the private CA certificate that you are importing.</p> </li> <li> <p>Your ACM Private CA-hosted or on-premises CA certificate must be the last certificate in your chain. The subordinate certificate, if any, that your root CA signed must be next to last. The subordinate certificate signed by the preceding subordinate CA must come next, and so on until your chain is built. </p> </li> <li> <p>The chain must be PEM-encoded.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var importCertificateAuthorityCertificate* = Call_ImportCertificateAuthorityCertificate_603207(
    name: "importCertificateAuthorityCertificate", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.ImportCertificateAuthorityCertificate",
    validator: validate_ImportCertificateAuthorityCertificate_603208, base: "/",
    url: url_ImportCertificateAuthorityCertificate_603209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_IssueCertificate_603222 = ref object of OpenApiRestCall_602466
proc url_IssueCertificate_603224(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_IssueCertificate_603223(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Uses your private certificate authority (CA) to issue a client certificate. This action returns the Amazon Resource Name (ARN) of the certificate. You can retrieve the certificate by calling the <a>GetCertificate</a> action and specifying the ARN. </p> <note> <p>You cannot use the ACM <b>ListCertificateAuthorities</b> action to retrieve the ARNs of the certificates that you issue by using ACM Private CA.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "ACMPrivateCA.IssueCertificate"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_IssueCertificate_603222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uses your private certificate authority (CA) to issue a client certificate. This action returns the Amazon Resource Name (ARN) of the certificate. You can retrieve the certificate by calling the <a>GetCertificate</a> action and specifying the ARN. </p> <note> <p>You cannot use the ACM <b>ListCertificateAuthorities</b> action to retrieve the ARNs of the certificates that you issue by using ACM Private CA.</p> </note>
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_IssueCertificate_603222; body: JsonNode): Recallable =
  ## issueCertificate
  ## <p>Uses your private certificate authority (CA) to issue a client certificate. This action returns the Amazon Resource Name (ARN) of the certificate. You can retrieve the certificate by calling the <a>GetCertificate</a> action and specifying the ARN. </p> <note> <p>You cannot use the ACM <b>ListCertificateAuthorities</b> action to retrieve the ARNs of the certificates that you issue by using ACM Private CA.</p> </note>
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var issueCertificate* = Call_IssueCertificate_603222(name: "issueCertificate",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.IssueCertificate",
    validator: validate_IssueCertificate_603223, base: "/",
    url: url_IssueCertificate_603224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCertificateAuthorities_603237 = ref object of OpenApiRestCall_602466
proc url_ListCertificateAuthorities_603239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCertificateAuthorities_603238(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the private certificate authorities that you created by using the <a>CreateCertificateAuthority</a> action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603240 = query.getOrDefault("NextToken")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "NextToken", valid_603240
  var valid_603241 = query.getOrDefault("MaxResults")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "MaxResults", valid_603241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603242 = header.getOrDefault("X-Amz-Date")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Date", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Security-Token")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Security-Token", valid_603243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603244 = header.getOrDefault("X-Amz-Target")
  valid_603244 = validateParameter(valid_603244, JString, required = true, default = newJString(
      "ACMPrivateCA.ListCertificateAuthorities"))
  if valid_603244 != nil:
    section.add "X-Amz-Target", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Content-Sha256", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Algorithm")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Algorithm", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Signature")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Signature", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-SignedHeaders", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Credential")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Credential", valid_603249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603251: Call_ListCertificateAuthorities_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the private certificate authorities that you created by using the <a>CreateCertificateAuthority</a> action.
  ## 
  let valid = call_603251.validator(path, query, header, formData, body)
  let scheme = call_603251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603251.url(scheme.get, call_603251.host, call_603251.base,
                         call_603251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603251, url, valid)

proc call*(call_603252: Call_ListCertificateAuthorities_603237; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCertificateAuthorities
  ## Lists the private certificate authorities that you created by using the <a>CreateCertificateAuthority</a> action.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603253 = newJObject()
  var body_603254 = newJObject()
  add(query_603253, "NextToken", newJString(NextToken))
  if body != nil:
    body_603254 = body
  add(query_603253, "MaxResults", newJString(MaxResults))
  result = call_603252.call(nil, query_603253, nil, nil, body_603254)

var listCertificateAuthorities* = Call_ListCertificateAuthorities_603237(
    name: "listCertificateAuthorities", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.ListCertificateAuthorities",
    validator: validate_ListCertificateAuthorities_603238, base: "/",
    url: url_ListCertificateAuthorities_603239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPermissions_603256 = ref object of OpenApiRestCall_602466
proc url_ListPermissions_603258(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPermissions_603257(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists all the permissions, if any, that have been assigned by a private CA. Permissions can be granted with the <a>CreatePermission</a> action and revoked with the <a>DeletePermission</a> action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603259 = query.getOrDefault("NextToken")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "NextToken", valid_603259
  var valid_603260 = query.getOrDefault("MaxResults")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "MaxResults", valid_603260
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603261 = header.getOrDefault("X-Amz-Date")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Date", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Security-Token")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Security-Token", valid_603262
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603263 = header.getOrDefault("X-Amz-Target")
  valid_603263 = validateParameter(valid_603263, JString, required = true, default = newJString(
      "ACMPrivateCA.ListPermissions"))
  if valid_603263 != nil:
    section.add "X-Amz-Target", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Content-Sha256", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Algorithm")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Algorithm", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Signature")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Signature", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-SignedHeaders", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Credential")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Credential", valid_603268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603270: Call_ListPermissions_603256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the permissions, if any, that have been assigned by a private CA. Permissions can be granted with the <a>CreatePermission</a> action and revoked with the <a>DeletePermission</a> action.
  ## 
  let valid = call_603270.validator(path, query, header, formData, body)
  let scheme = call_603270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603270.url(scheme.get, call_603270.host, call_603270.base,
                         call_603270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603270, url, valid)

proc call*(call_603271: Call_ListPermissions_603256; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPermissions
  ## Lists all the permissions, if any, that have been assigned by a private CA. Permissions can be granted with the <a>CreatePermission</a> action and revoked with the <a>DeletePermission</a> action.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603272 = newJObject()
  var body_603273 = newJObject()
  add(query_603272, "NextToken", newJString(NextToken))
  if body != nil:
    body_603273 = body
  add(query_603272, "MaxResults", newJString(MaxResults))
  result = call_603271.call(nil, query_603272, nil, nil, body_603273)

var listPermissions* = Call_ListPermissions_603256(name: "listPermissions",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.ListPermissions",
    validator: validate_ListPermissions_603257, base: "/", url: url_ListPermissions_603258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_603274 = ref object of OpenApiRestCall_602466
proc url_ListTags_603276(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTags_603275(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the tags, if any, that are associated with your private CA. Tags are labels that you can use to identify and organize your CAs. Each tag consists of a key and an optional value. Call the <a>TagCertificateAuthority</a> action to add one or more tags to your CA. Call the <a>UntagCertificateAuthority</a> action to remove tags. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603277 = query.getOrDefault("NextToken")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "NextToken", valid_603277
  var valid_603278 = query.getOrDefault("MaxResults")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "MaxResults", valid_603278
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603279 = header.getOrDefault("X-Amz-Date")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Date", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Security-Token")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Security-Token", valid_603280
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603281 = header.getOrDefault("X-Amz-Target")
  valid_603281 = validateParameter(valid_603281, JString, required = true,
                                 default = newJString("ACMPrivateCA.ListTags"))
  if valid_603281 != nil:
    section.add "X-Amz-Target", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Content-Sha256", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Algorithm")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Algorithm", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Signature")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Signature", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-SignedHeaders", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Credential")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Credential", valid_603286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603288: Call_ListTags_603274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags, if any, that are associated with your private CA. Tags are labels that you can use to identify and organize your CAs. Each tag consists of a key and an optional value. Call the <a>TagCertificateAuthority</a> action to add one or more tags to your CA. Call the <a>UntagCertificateAuthority</a> action to remove tags. 
  ## 
  let valid = call_603288.validator(path, query, header, formData, body)
  let scheme = call_603288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603288.url(scheme.get, call_603288.host, call_603288.base,
                         call_603288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603288, url, valid)

proc call*(call_603289: Call_ListTags_603274; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listTags
  ## Lists the tags, if any, that are associated with your private CA. Tags are labels that you can use to identify and organize your CAs. Each tag consists of a key and an optional value. Call the <a>TagCertificateAuthority</a> action to add one or more tags to your CA. Call the <a>UntagCertificateAuthority</a> action to remove tags. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603290 = newJObject()
  var body_603291 = newJObject()
  add(query_603290, "NextToken", newJString(NextToken))
  if body != nil:
    body_603291 = body
  add(query_603290, "MaxResults", newJString(MaxResults))
  result = call_603289.call(nil, query_603290, nil, nil, body_603291)

var listTags* = Call_ListTags_603274(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "acm-pca.amazonaws.com", route: "/#X-Amz-Target=ACMPrivateCA.ListTags",
                                  validator: validate_ListTags_603275, base: "/",
                                  url: url_ListTags_603276,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreCertificateAuthority_603292 = ref object of OpenApiRestCall_602466
proc url_RestoreCertificateAuthority_603294(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestoreCertificateAuthority_603293(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Restores a certificate authority (CA) that is in the <code>DELETED</code> state. You can restore a CA during the period that you defined in the <b>PermanentDeletionTimeInDays</b> parameter of the <a>DeleteCertificateAuthority</a> action. Currently, you can specify 7 to 30 days. If you did not specify a <b>PermanentDeletionTimeInDays</b> value, by default you can restore the CA at any time in a 30 day period. You can check the time remaining in the restoration period of a private CA in the <code>DELETED</code> state by calling the <a>DescribeCertificateAuthority</a> or <a>ListCertificateAuthorities</a> actions. The status of a restored CA is set to its pre-deletion status when the <b>RestoreCertificateAuthority</b> action returns. To change its status to <code>ACTIVE</code>, call the <a>UpdateCertificateAuthority</a> action. If the private CA was in the <code>PENDING_CERTIFICATE</code> state at deletion, you must use the <a>ImportCertificateAuthorityCertificate</a> action to import a certificate authority into the private CA before it can be activated. You cannot restore a CA after the restoration period has ended.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603295 = header.getOrDefault("X-Amz-Date")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Date", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Security-Token")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Security-Token", valid_603296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603297 = header.getOrDefault("X-Amz-Target")
  valid_603297 = validateParameter(valid_603297, JString, required = true, default = newJString(
      "ACMPrivateCA.RestoreCertificateAuthority"))
  if valid_603297 != nil:
    section.add "X-Amz-Target", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Content-Sha256", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Algorithm")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Algorithm", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Signature")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Signature", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-SignedHeaders", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Credential")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Credential", valid_603302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603304: Call_RestoreCertificateAuthority_603292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restores a certificate authority (CA) that is in the <code>DELETED</code> state. You can restore a CA during the period that you defined in the <b>PermanentDeletionTimeInDays</b> parameter of the <a>DeleteCertificateAuthority</a> action. Currently, you can specify 7 to 30 days. If you did not specify a <b>PermanentDeletionTimeInDays</b> value, by default you can restore the CA at any time in a 30 day period. You can check the time remaining in the restoration period of a private CA in the <code>DELETED</code> state by calling the <a>DescribeCertificateAuthority</a> or <a>ListCertificateAuthorities</a> actions. The status of a restored CA is set to its pre-deletion status when the <b>RestoreCertificateAuthority</b> action returns. To change its status to <code>ACTIVE</code>, call the <a>UpdateCertificateAuthority</a> action. If the private CA was in the <code>PENDING_CERTIFICATE</code> state at deletion, you must use the <a>ImportCertificateAuthorityCertificate</a> action to import a certificate authority into the private CA before it can be activated. You cannot restore a CA after the restoration period has ended.
  ## 
  let valid = call_603304.validator(path, query, header, formData, body)
  let scheme = call_603304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603304.url(scheme.get, call_603304.host, call_603304.base,
                         call_603304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603304, url, valid)

proc call*(call_603305: Call_RestoreCertificateAuthority_603292; body: JsonNode): Recallable =
  ## restoreCertificateAuthority
  ## Restores a certificate authority (CA) that is in the <code>DELETED</code> state. You can restore a CA during the period that you defined in the <b>PermanentDeletionTimeInDays</b> parameter of the <a>DeleteCertificateAuthority</a> action. Currently, you can specify 7 to 30 days. If you did not specify a <b>PermanentDeletionTimeInDays</b> value, by default you can restore the CA at any time in a 30 day period. You can check the time remaining in the restoration period of a private CA in the <code>DELETED</code> state by calling the <a>DescribeCertificateAuthority</a> or <a>ListCertificateAuthorities</a> actions. The status of a restored CA is set to its pre-deletion status when the <b>RestoreCertificateAuthority</b> action returns. To change its status to <code>ACTIVE</code>, call the <a>UpdateCertificateAuthority</a> action. If the private CA was in the <code>PENDING_CERTIFICATE</code> state at deletion, you must use the <a>ImportCertificateAuthorityCertificate</a> action to import a certificate authority into the private CA before it can be activated. You cannot restore a CA after the restoration period has ended.
  ##   body: JObject (required)
  var body_603306 = newJObject()
  if body != nil:
    body_603306 = body
  result = call_603305.call(nil, nil, nil, nil, body_603306)

var restoreCertificateAuthority* = Call_RestoreCertificateAuthority_603292(
    name: "restoreCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.RestoreCertificateAuthority",
    validator: validate_RestoreCertificateAuthority_603293, base: "/",
    url: url_RestoreCertificateAuthority_603294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeCertificate_603307 = ref object of OpenApiRestCall_602466
proc url_RevokeCertificate_603309(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RevokeCertificate_603308(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Revokes a certificate that was issued inside ACM Private CA. If you enable a certificate revocation list (CRL) when you create or update your private CA, information about the revoked certificates will be included in the CRL. ACM Private CA writes the CRL to an S3 bucket that you specify. For more information about revocation, see the <a>CrlConfiguration</a> structure. ACM Private CA also writes revocation information to the audit report. For more information, see <a>CreateCertificateAuthorityAuditReport</a>. </p> <note> <p>You cannot revoke a root CA self-signed certificate.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603310 = header.getOrDefault("X-Amz-Date")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Date", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Security-Token")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Security-Token", valid_603311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603312 = header.getOrDefault("X-Amz-Target")
  valid_603312 = validateParameter(valid_603312, JString, required = true, default = newJString(
      "ACMPrivateCA.RevokeCertificate"))
  if valid_603312 != nil:
    section.add "X-Amz-Target", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Content-Sha256", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Algorithm")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Algorithm", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Signature")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Signature", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-SignedHeaders", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Credential")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Credential", valid_603317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603319: Call_RevokeCertificate_603307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes a certificate that was issued inside ACM Private CA. If you enable a certificate revocation list (CRL) when you create or update your private CA, information about the revoked certificates will be included in the CRL. ACM Private CA writes the CRL to an S3 bucket that you specify. For more information about revocation, see the <a>CrlConfiguration</a> structure. ACM Private CA also writes revocation information to the audit report. For more information, see <a>CreateCertificateAuthorityAuditReport</a>. </p> <note> <p>You cannot revoke a root CA self-signed certificate.</p> </note>
  ## 
  let valid = call_603319.validator(path, query, header, formData, body)
  let scheme = call_603319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603319.url(scheme.get, call_603319.host, call_603319.base,
                         call_603319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603319, url, valid)

proc call*(call_603320: Call_RevokeCertificate_603307; body: JsonNode): Recallable =
  ## revokeCertificate
  ## <p>Revokes a certificate that was issued inside ACM Private CA. If you enable a certificate revocation list (CRL) when you create or update your private CA, information about the revoked certificates will be included in the CRL. ACM Private CA writes the CRL to an S3 bucket that you specify. For more information about revocation, see the <a>CrlConfiguration</a> structure. ACM Private CA also writes revocation information to the audit report. For more information, see <a>CreateCertificateAuthorityAuditReport</a>. </p> <note> <p>You cannot revoke a root CA self-signed certificate.</p> </note>
  ##   body: JObject (required)
  var body_603321 = newJObject()
  if body != nil:
    body_603321 = body
  result = call_603320.call(nil, nil, nil, nil, body_603321)

var revokeCertificate* = Call_RevokeCertificate_603307(name: "revokeCertificate",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.RevokeCertificate",
    validator: validate_RevokeCertificate_603308, base: "/",
    url: url_RevokeCertificate_603309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagCertificateAuthority_603322 = ref object of OpenApiRestCall_602466
proc url_TagCertificateAuthority_603324(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagCertificateAuthority_603323(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more tags to your private CA. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the private CA on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. You can apply a tag to just one private CA if you want to identify a specific characteristic of that CA, or you can apply the same tag to multiple private CAs if you want to filter for a common relationship among those CAs. To remove one or more tags, use the <a>UntagCertificateAuthority</a> action. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603325 = header.getOrDefault("X-Amz-Date")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Date", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Security-Token")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Security-Token", valid_603326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603327 = header.getOrDefault("X-Amz-Target")
  valid_603327 = validateParameter(valid_603327, JString, required = true, default = newJString(
      "ACMPrivateCA.TagCertificateAuthority"))
  if valid_603327 != nil:
    section.add "X-Amz-Target", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Content-Sha256", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Algorithm")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Algorithm", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Signature")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Signature", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-SignedHeaders", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Credential")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Credential", valid_603332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603334: Call_TagCertificateAuthority_603322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to your private CA. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the private CA on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. You can apply a tag to just one private CA if you want to identify a specific characteristic of that CA, or you can apply the same tag to multiple private CAs if you want to filter for a common relationship among those CAs. To remove one or more tags, use the <a>UntagCertificateAuthority</a> action. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ## 
  let valid = call_603334.validator(path, query, header, formData, body)
  let scheme = call_603334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603334.url(scheme.get, call_603334.host, call_603334.base,
                         call_603334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603334, url, valid)

proc call*(call_603335: Call_TagCertificateAuthority_603322; body: JsonNode): Recallable =
  ## tagCertificateAuthority
  ## Adds one or more tags to your private CA. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the private CA on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. You can apply a tag to just one private CA if you want to identify a specific characteristic of that CA, or you can apply the same tag to multiple private CAs if you want to filter for a common relationship among those CAs. To remove one or more tags, use the <a>UntagCertificateAuthority</a> action. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ##   body: JObject (required)
  var body_603336 = newJObject()
  if body != nil:
    body_603336 = body
  result = call_603335.call(nil, nil, nil, nil, body_603336)

var tagCertificateAuthority* = Call_TagCertificateAuthority_603322(
    name: "tagCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.TagCertificateAuthority",
    validator: validate_TagCertificateAuthority_603323, base: "/",
    url: url_TagCertificateAuthority_603324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagCertificateAuthority_603337 = ref object of OpenApiRestCall_602466
proc url_UntagCertificateAuthority_603339(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagCertificateAuthority_603338(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove one or more tags from your private CA. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this action, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. To add tags to a private CA, use the <a>TagCertificateAuthority</a>. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603340 = header.getOrDefault("X-Amz-Date")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Date", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Security-Token")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Security-Token", valid_603341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603342 = header.getOrDefault("X-Amz-Target")
  valid_603342 = validateParameter(valid_603342, JString, required = true, default = newJString(
      "ACMPrivateCA.UntagCertificateAuthority"))
  if valid_603342 != nil:
    section.add "X-Amz-Target", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Content-Sha256", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Algorithm")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Algorithm", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Signature")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Signature", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-SignedHeaders", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Credential")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Credential", valid_603347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603349: Call_UntagCertificateAuthority_603337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags from your private CA. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this action, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. To add tags to a private CA, use the <a>TagCertificateAuthority</a>. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ## 
  let valid = call_603349.validator(path, query, header, formData, body)
  let scheme = call_603349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603349.url(scheme.get, call_603349.host, call_603349.base,
                         call_603349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603349, url, valid)

proc call*(call_603350: Call_UntagCertificateAuthority_603337; body: JsonNode): Recallable =
  ## untagCertificateAuthority
  ## Remove one or more tags from your private CA. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this action, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. To add tags to a private CA, use the <a>TagCertificateAuthority</a>. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ##   body: JObject (required)
  var body_603351 = newJObject()
  if body != nil:
    body_603351 = body
  result = call_603350.call(nil, nil, nil, nil, body_603351)

var untagCertificateAuthority* = Call_UntagCertificateAuthority_603337(
    name: "untagCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.UntagCertificateAuthority",
    validator: validate_UntagCertificateAuthority_603338, base: "/",
    url: url_UntagCertificateAuthority_603339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCertificateAuthority_603352 = ref object of OpenApiRestCall_602466
proc url_UpdateCertificateAuthority_603354(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCertificateAuthority_603353(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the status or configuration of a private certificate authority (CA). Your private CA must be in the <code>ACTIVE</code> or <code>DISABLED</code> state before you can update it. You can disable a private CA that is in the <code>ACTIVE</code> state or make a CA that is in the <code>DISABLED</code> state active again.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603355 = header.getOrDefault("X-Amz-Date")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Date", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Security-Token")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Security-Token", valid_603356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603357 = header.getOrDefault("X-Amz-Target")
  valid_603357 = validateParameter(valid_603357, JString, required = true, default = newJString(
      "ACMPrivateCA.UpdateCertificateAuthority"))
  if valid_603357 != nil:
    section.add "X-Amz-Target", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Content-Sha256", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Algorithm")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Algorithm", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Signature")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Signature", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-SignedHeaders", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Credential")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Credential", valid_603362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603364: Call_UpdateCertificateAuthority_603352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status or configuration of a private certificate authority (CA). Your private CA must be in the <code>ACTIVE</code> or <code>DISABLED</code> state before you can update it. You can disable a private CA that is in the <code>ACTIVE</code> state or make a CA that is in the <code>DISABLED</code> state active again.
  ## 
  let valid = call_603364.validator(path, query, header, formData, body)
  let scheme = call_603364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603364.url(scheme.get, call_603364.host, call_603364.base,
                         call_603364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603364, url, valid)

proc call*(call_603365: Call_UpdateCertificateAuthority_603352; body: JsonNode): Recallable =
  ## updateCertificateAuthority
  ## Updates the status or configuration of a private certificate authority (CA). Your private CA must be in the <code>ACTIVE</code> or <code>DISABLED</code> state before you can update it. You can disable a private CA that is in the <code>ACTIVE</code> state or make a CA that is in the <code>DISABLED</code> state active again.
  ##   body: JObject (required)
  var body_603366 = newJObject()
  if body != nil:
    body_603366 = body
  result = call_603365.call(nil, nil, nil, nil, body_603366)

var updateCertificateAuthority* = Call_UpdateCertificateAuthority_603352(
    name: "updateCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.UpdateCertificateAuthority",
    validator: validate_UpdateCertificateAuthority_603353, base: "/",
    url: url_UpdateCertificateAuthority_603354,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
