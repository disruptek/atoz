
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCertificateAuthority_610996 = ref object of OpenApiRestCall_610658
proc url_CreateCertificateAuthority_610998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCertificateAuthority_610997(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true, default = newJString(
      "ACMPrivateCA.CreateCertificateAuthority"))
  if valid_611123 != nil:
    section.add "X-Amz-Target", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-Signature")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-Signature", valid_611124
  var valid_611125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Content-Sha256", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Date")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Date", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Credential")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Credential", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Security-Token")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Security-Token", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Algorithm")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Algorithm", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-SignedHeaders", valid_611130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_CreateCertificateAuthority_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a root or subordinate private certificate authority (CA). You must specify the CA configuration, the certificate revocation list (CRL) configuration, the CA type, and an optional idempotency token to avoid accidental creation of multiple CAs. The CA configuration specifies the name of the algorithm and key size to be used to create the CA private key, the type of signing algorithm that the CA uses, and X.500 subject information. The CRL configuration specifies the CRL expiration period in days (the validity period of the CRL), the Amazon S3 bucket that will contain the CRL, and a CNAME alias for the S3 bucket that is included in certificates issued by the CA. If successful, this action returns the Amazon Resource Name (ARN) of the CA.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_CreateCertificateAuthority_610996; body: JsonNode): Recallable =
  ## createCertificateAuthority
  ## Creates a root or subordinate private certificate authority (CA). You must specify the CA configuration, the certificate revocation list (CRL) configuration, the CA type, and an optional idempotency token to avoid accidental creation of multiple CAs. The CA configuration specifies the name of the algorithm and key size to be used to create the CA private key, the type of signing algorithm that the CA uses, and X.500 subject information. The CRL configuration specifies the CRL expiration period in days (the validity period of the CRL), the Amazon S3 bucket that will contain the CRL, and a CNAME alias for the S3 bucket that is included in certificates issued by the CA. If successful, this action returns the Amazon Resource Name (ARN) of the CA.
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var createCertificateAuthority* = Call_CreateCertificateAuthority_610996(
    name: "createCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.CreateCertificateAuthority",
    validator: validate_CreateCertificateAuthority_610997, base: "/",
    url: url_CreateCertificateAuthority_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCertificateAuthorityAuditReport_611265 = ref object of OpenApiRestCall_610658
proc url_CreateCertificateAuthorityAuditReport_611267(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCertificateAuthorityAuditReport_611266(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "ACMPrivateCA.CreateCertificateAuthorityAuditReport"))
  if valid_611268 != nil:
    section.add "X-Amz-Target", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_CreateCertificateAuthorityAuditReport_611265;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates an audit report that lists every time that your CA private key is used. The report is saved in the Amazon S3 bucket that you specify on input. The <a>IssueCertificate</a> and <a>RevokeCertificate</a> actions use the private key.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_CreateCertificateAuthorityAuditReport_611265;
          body: JsonNode): Recallable =
  ## createCertificateAuthorityAuditReport
  ## Creates an audit report that lists every time that your CA private key is used. The report is saved in the Amazon S3 bucket that you specify on input. The <a>IssueCertificate</a> and <a>RevokeCertificate</a> actions use the private key.
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var createCertificateAuthorityAuditReport* = Call_CreateCertificateAuthorityAuditReport_611265(
    name: "createCertificateAuthorityAuditReport", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.CreateCertificateAuthorityAuditReport",
    validator: validate_CreateCertificateAuthorityAuditReport_611266, base: "/",
    url: url_CreateCertificateAuthorityAuditReport_611267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePermission_611280 = ref object of OpenApiRestCall_610658
proc url_CreatePermission_611282(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePermission_611281(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "ACMPrivateCA.CreatePermission"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_CreatePermission_611280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns permissions from a private CA to a designated AWS service. Services are specified by their service principals and can be given permission to create and retrieve certificates on a private CA. Services can also be given permission to list the active permissions that the private CA has granted. For ACM to automatically renew your private CA's certificates, you must assign all possible permissions from the CA to the ACM service principal.</p> <p>At this time, you can only assign permissions to ACM (<code>acm.amazonaws.com</code>). Permissions can be revoked with the <a>DeletePermission</a> action and listed with the <a>ListPermissions</a> action.</p>
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_CreatePermission_611280; body: JsonNode): Recallable =
  ## createPermission
  ## <p>Assigns permissions from a private CA to a designated AWS service. Services are specified by their service principals and can be given permission to create and retrieve certificates on a private CA. Services can also be given permission to list the active permissions that the private CA has granted. For ACM to automatically renew your private CA's certificates, you must assign all possible permissions from the CA to the ACM service principal.</p> <p>At this time, you can only assign permissions to ACM (<code>acm.amazonaws.com</code>). Permissions can be revoked with the <a>DeletePermission</a> action and listed with the <a>ListPermissions</a> action.</p>
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var createPermission* = Call_CreatePermission_611280(name: "createPermission",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.CreatePermission",
    validator: validate_CreatePermission_611281, base: "/",
    url: url_CreatePermission_611282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCertificateAuthority_611295 = ref object of OpenApiRestCall_610658
proc url_DeleteCertificateAuthority_611297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCertificateAuthority_611296(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true, default = newJString(
      "ACMPrivateCA.DeleteCertificateAuthority"))
  if valid_611298 != nil:
    section.add "X-Amz-Target", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_DeleteCertificateAuthority_611295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a private certificate authority (CA). You must provide the Amazon Resource Name (ARN) of the private CA that you want to delete. You can find the ARN by calling the <a>ListCertificateAuthorities</a> action. </p> <note> <p>Deleting a CA will invalidate other CAs and certificates below it in your CA hierarchy.</p> </note> <p>Before you can delete a CA that you have created and activated, you must disable it. To do this, call the <a>UpdateCertificateAuthority</a> action and set the <b>CertificateAuthorityStatus</b> parameter to <code>DISABLED</code>. </p> <p>Additionally, you can delete a CA if you are waiting for it to be created (that is, the status of the CA is <code>CREATING</code>). You can also delete it if the CA has been created but you haven't yet imported the signed certificate into ACM Private CA (that is, the status of the CA is <code>PENDING_CERTIFICATE</code>). </p> <p>When you successfully call <a>DeleteCertificateAuthority</a>, the CA's status changes to <code>DELETED</code>. However, the CA won't be permanently deleted until the restoration period has passed. By default, if you do not set the <code>PermanentDeletionTimeInDays</code> parameter, the CA remains restorable for 30 days. You can set the parameter from 7 to 30 days. The <a>DescribeCertificateAuthority</a> action returns the time remaining in the restoration window of a private CA in the <code>DELETED</code> state. To restore an eligible CA, call the <a>RestoreCertificateAuthority</a> action.</p>
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_DeleteCertificateAuthority_611295; body: JsonNode): Recallable =
  ## deleteCertificateAuthority
  ## <p>Deletes a private certificate authority (CA). You must provide the Amazon Resource Name (ARN) of the private CA that you want to delete. You can find the ARN by calling the <a>ListCertificateAuthorities</a> action. </p> <note> <p>Deleting a CA will invalidate other CAs and certificates below it in your CA hierarchy.</p> </note> <p>Before you can delete a CA that you have created and activated, you must disable it. To do this, call the <a>UpdateCertificateAuthority</a> action and set the <b>CertificateAuthorityStatus</b> parameter to <code>DISABLED</code>. </p> <p>Additionally, you can delete a CA if you are waiting for it to be created (that is, the status of the CA is <code>CREATING</code>). You can also delete it if the CA has been created but you haven't yet imported the signed certificate into ACM Private CA (that is, the status of the CA is <code>PENDING_CERTIFICATE</code>). </p> <p>When you successfully call <a>DeleteCertificateAuthority</a>, the CA's status changes to <code>DELETED</code>. However, the CA won't be permanently deleted until the restoration period has passed. By default, if you do not set the <code>PermanentDeletionTimeInDays</code> parameter, the CA remains restorable for 30 days. You can set the parameter from 7 to 30 days. The <a>DescribeCertificateAuthority</a> action returns the time remaining in the restoration window of a private CA in the <code>DELETED</code> state. To restore an eligible CA, call the <a>RestoreCertificateAuthority</a> action.</p>
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var deleteCertificateAuthority* = Call_DeleteCertificateAuthority_611295(
    name: "deleteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.DeleteCertificateAuthority",
    validator: validate_DeleteCertificateAuthority_611296, base: "/",
    url: url_DeleteCertificateAuthority_611297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePermission_611310 = ref object of OpenApiRestCall_610658
proc url_DeletePermission_611312(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePermission_611311(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611313 = header.getOrDefault("X-Amz-Target")
  valid_611313 = validateParameter(valid_611313, JString, required = true, default = newJString(
      "ACMPrivateCA.DeletePermission"))
  if valid_611313 != nil:
    section.add "X-Amz-Target", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_DeletePermission_611310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes permissions that a private CA assigned to a designated AWS service. Permissions can be created with the <a>CreatePermission</a> action and listed with the <a>ListPermissions</a> action. 
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_DeletePermission_611310; body: JsonNode): Recallable =
  ## deletePermission
  ## Revokes permissions that a private CA assigned to a designated AWS service. Permissions can be created with the <a>CreatePermission</a> action and listed with the <a>ListPermissions</a> action. 
  ##   body: JObject (required)
  var body_611324 = newJObject()
  if body != nil:
    body_611324 = body
  result = call_611323.call(nil, nil, nil, nil, body_611324)

var deletePermission* = Call_DeletePermission_611310(name: "deletePermission",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.DeletePermission",
    validator: validate_DeletePermission_611311, base: "/",
    url: url_DeletePermission_611312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificateAuthority_611325 = ref object of OpenApiRestCall_610658
proc url_DescribeCertificateAuthority_611327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCertificateAuthority_611326(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611328 = header.getOrDefault("X-Amz-Target")
  valid_611328 = validateParameter(valid_611328, JString, required = true, default = newJString(
      "ACMPrivateCA.DescribeCertificateAuthority"))
  if valid_611328 != nil:
    section.add "X-Amz-Target", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Signature", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Content-Sha256", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Date")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Date", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Credential")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Credential", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Security-Token")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Security-Token", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Algorithm")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Algorithm", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-SignedHeaders", valid_611335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_DescribeCertificateAuthority_611325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists information about your private certificate authority (CA). You specify the private CA on input by its ARN (Amazon Resource Name). The output contains the status of your CA. This can be any of the following: </p> <ul> <li> <p> <code>CREATING</code> - ACM Private CA is creating your private certificate authority.</p> </li> <li> <p> <code>PENDING_CERTIFICATE</code> - The certificate is pending. You must use your ACM Private CA-hosted or on-premises root or subordinate CA to sign your private CA CSR and then import it into PCA. </p> </li> <li> <p> <code>ACTIVE</code> - Your private CA is active.</p> </li> <li> <p> <code>DISABLED</code> - Your private CA has been disabled.</p> </li> <li> <p> <code>EXPIRED</code> - Your private CA certificate has expired.</p> </li> <li> <p> <code>FAILED</code> - Your private CA has failed. Your CA can fail because of problems such a network outage or backend AWS failure or other errors. A failed CA can never return to the pending state. You must create a new CA. </p> </li> <li> <p> <code>DELETED</code> - Your private CA is within the restoration period, after which it is permanently deleted. The length of time remaining in the CA's restoration period is also included in this action's output.</p> </li> </ul>
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_DescribeCertificateAuthority_611325; body: JsonNode): Recallable =
  ## describeCertificateAuthority
  ## <p>Lists information about your private certificate authority (CA). You specify the private CA on input by its ARN (Amazon Resource Name). The output contains the status of your CA. This can be any of the following: </p> <ul> <li> <p> <code>CREATING</code> - ACM Private CA is creating your private certificate authority.</p> </li> <li> <p> <code>PENDING_CERTIFICATE</code> - The certificate is pending. You must use your ACM Private CA-hosted or on-premises root or subordinate CA to sign your private CA CSR and then import it into PCA. </p> </li> <li> <p> <code>ACTIVE</code> - Your private CA is active.</p> </li> <li> <p> <code>DISABLED</code> - Your private CA has been disabled.</p> </li> <li> <p> <code>EXPIRED</code> - Your private CA certificate has expired.</p> </li> <li> <p> <code>FAILED</code> - Your private CA has failed. Your CA can fail because of problems such a network outage or backend AWS failure or other errors. A failed CA can never return to the pending state. You must create a new CA. </p> </li> <li> <p> <code>DELETED</code> - Your private CA is within the restoration period, after which it is permanently deleted. The length of time remaining in the CA's restoration period is also included in this action's output.</p> </li> </ul>
  ##   body: JObject (required)
  var body_611339 = newJObject()
  if body != nil:
    body_611339 = body
  result = call_611338.call(nil, nil, nil, nil, body_611339)

var describeCertificateAuthority* = Call_DescribeCertificateAuthority_611325(
    name: "describeCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.DescribeCertificateAuthority",
    validator: validate_DescribeCertificateAuthority_611326, base: "/",
    url: url_DescribeCertificateAuthority_611327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificateAuthorityAuditReport_611340 = ref object of OpenApiRestCall_610658
proc url_DescribeCertificateAuthorityAuditReport_611342(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCertificateAuthorityAuditReport_611341(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611343 = header.getOrDefault("X-Amz-Target")
  valid_611343 = validateParameter(valid_611343, JString, required = true, default = newJString(
      "ACMPrivateCA.DescribeCertificateAuthorityAuditReport"))
  if valid_611343 != nil:
    section.add "X-Amz-Target", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Algorithm")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Algorithm", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-SignedHeaders", valid_611350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_DescribeCertificateAuthorityAuditReport_611340;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists information about a specific audit report created by calling the <a>CreateCertificateAuthorityAuditReport</a> action. Audit information is created every time the certificate authority (CA) private key is used. The private key is used when you call the <a>IssueCertificate</a> action or the <a>RevokeCertificate</a> action. 
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_DescribeCertificateAuthorityAuditReport_611340;
          body: JsonNode): Recallable =
  ## describeCertificateAuthorityAuditReport
  ## Lists information about a specific audit report created by calling the <a>CreateCertificateAuthorityAuditReport</a> action. Audit information is created every time the certificate authority (CA) private key is used. The private key is used when you call the <a>IssueCertificate</a> action or the <a>RevokeCertificate</a> action. 
  ##   body: JObject (required)
  var body_611354 = newJObject()
  if body != nil:
    body_611354 = body
  result = call_611353.call(nil, nil, nil, nil, body_611354)

var describeCertificateAuthorityAuditReport* = Call_DescribeCertificateAuthorityAuditReport_611340(
    name: "describeCertificateAuthorityAuditReport", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com", route: "/#X-Amz-Target=ACMPrivateCA.DescribeCertificateAuthorityAuditReport",
    validator: validate_DescribeCertificateAuthorityAuditReport_611341, base: "/",
    url: url_DescribeCertificateAuthorityAuditReport_611342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCertificate_611355 = ref object of OpenApiRestCall_610658
proc url_GetCertificate_611357(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCertificate_611356(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611358 = header.getOrDefault("X-Amz-Target")
  valid_611358 = validateParameter(valid_611358, JString, required = true, default = newJString(
      "ACMPrivateCA.GetCertificate"))
  if valid_611358 != nil:
    section.add "X-Amz-Target", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_GetCertificate_611355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a certificate from your private CA. The ARN of the certificate is returned when you call the <a>IssueCertificate</a> action. You must specify both the ARN of your private CA and the ARN of the issued certificate when calling the <b>GetCertificate</b> action. You can retrieve the certificate if it is in the <b>ISSUED</b> state. You can call the <a>CreateCertificateAuthorityAuditReport</a> action to create a report that contains information about all of the certificates issued and revoked by your private CA. 
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_GetCertificate_611355; body: JsonNode): Recallable =
  ## getCertificate
  ## Retrieves a certificate from your private CA. The ARN of the certificate is returned when you call the <a>IssueCertificate</a> action. You must specify both the ARN of your private CA and the ARN of the issued certificate when calling the <b>GetCertificate</b> action. You can retrieve the certificate if it is in the <b>ISSUED</b> state. You can call the <a>CreateCertificateAuthorityAuditReport</a> action to create a report that contains information about all of the certificates issued and revoked by your private CA. 
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var getCertificate* = Call_GetCertificate_611355(name: "getCertificate",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.GetCertificate",
    validator: validate_GetCertificate_611356, base: "/", url: url_GetCertificate_611357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCertificateAuthorityCertificate_611370 = ref object of OpenApiRestCall_610658
proc url_GetCertificateAuthorityCertificate_611372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCertificateAuthorityCertificate_611371(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611373 = header.getOrDefault("X-Amz-Target")
  valid_611373 = validateParameter(valid_611373, JString, required = true, default = newJString(
      "ACMPrivateCA.GetCertificateAuthorityCertificate"))
  if valid_611373 != nil:
    section.add "X-Amz-Target", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Algorithm")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Algorithm", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-SignedHeaders", valid_611380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611382: Call_GetCertificateAuthorityCertificate_611370;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the certificate and certificate chain for your private certificate authority (CA). Both the certificate and the chain are base64 PEM-encoded. The chain does not include the CA certificate. Each certificate in the chain signs the one before it. 
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_GetCertificateAuthorityCertificate_611370;
          body: JsonNode): Recallable =
  ## getCertificateAuthorityCertificate
  ## Retrieves the certificate and certificate chain for your private certificate authority (CA). Both the certificate and the chain are base64 PEM-encoded. The chain does not include the CA certificate. Each certificate in the chain signs the one before it. 
  ##   body: JObject (required)
  var body_611384 = newJObject()
  if body != nil:
    body_611384 = body
  result = call_611383.call(nil, nil, nil, nil, body_611384)

var getCertificateAuthorityCertificate* = Call_GetCertificateAuthorityCertificate_611370(
    name: "getCertificateAuthorityCertificate", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.GetCertificateAuthorityCertificate",
    validator: validate_GetCertificateAuthorityCertificate_611371, base: "/",
    url: url_GetCertificateAuthorityCertificate_611372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCertificateAuthorityCsr_611385 = ref object of OpenApiRestCall_610658
proc url_GetCertificateAuthorityCsr_611387(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCertificateAuthorityCsr_611386(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611388 = header.getOrDefault("X-Amz-Target")
  valid_611388 = validateParameter(valid_611388, JString, required = true, default = newJString(
      "ACMPrivateCA.GetCertificateAuthorityCsr"))
  if valid_611388 != nil:
    section.add "X-Amz-Target", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Signature")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Signature", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Content-Sha256", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Date")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Date", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Credential")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Credential", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Security-Token")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Security-Token", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Algorithm")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Algorithm", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-SignedHeaders", valid_611395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611397: Call_GetCertificateAuthorityCsr_611385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the certificate signing request (CSR) for your private certificate authority (CA). The CSR is created when you call the <a>CreateCertificateAuthority</a> action. Sign the CSR with your ACM Private CA-hosted or on-premises root or subordinate CA. Then import the signed certificate back into ACM Private CA by calling the <a>ImportCertificateAuthorityCertificate</a> action. The CSR is returned as a base64 PEM-encoded string. 
  ## 
  let valid = call_611397.validator(path, query, header, formData, body)
  let scheme = call_611397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611397.url(scheme.get, call_611397.host, call_611397.base,
                         call_611397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611397, url, valid)

proc call*(call_611398: Call_GetCertificateAuthorityCsr_611385; body: JsonNode): Recallable =
  ## getCertificateAuthorityCsr
  ## Retrieves the certificate signing request (CSR) for your private certificate authority (CA). The CSR is created when you call the <a>CreateCertificateAuthority</a> action. Sign the CSR with your ACM Private CA-hosted or on-premises root or subordinate CA. Then import the signed certificate back into ACM Private CA by calling the <a>ImportCertificateAuthorityCertificate</a> action. The CSR is returned as a base64 PEM-encoded string. 
  ##   body: JObject (required)
  var body_611399 = newJObject()
  if body != nil:
    body_611399 = body
  result = call_611398.call(nil, nil, nil, nil, body_611399)

var getCertificateAuthorityCsr* = Call_GetCertificateAuthorityCsr_611385(
    name: "getCertificateAuthorityCsr", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.GetCertificateAuthorityCsr",
    validator: validate_GetCertificateAuthorityCsr_611386, base: "/",
    url: url_GetCertificateAuthorityCsr_611387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCertificateAuthorityCertificate_611400 = ref object of OpenApiRestCall_610658
proc url_ImportCertificateAuthorityCertificate_611402(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportCertificateAuthorityCertificate_611401(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611403 = header.getOrDefault("X-Amz-Target")
  valid_611403 = validateParameter(valid_611403, JString, required = true, default = newJString(
      "ACMPrivateCA.ImportCertificateAuthorityCertificate"))
  if valid_611403 != nil:
    section.add "X-Amz-Target", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611412: Call_ImportCertificateAuthorityCertificate_611400;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Imports a signed private CA certificate into ACM Private CA. This action is used when you are using a chain of trust whose root is located outside ACM Private CA. Before you can call this action, the following preparations must in place:</p> <ol> <li> <p>In ACM Private CA, call the <a>CreateCertificateAuthority</a> action to create the private CA that that you plan to back with the imported certificate.</p> </li> <li> <p>Call the <a>GetCertificateAuthorityCsr</a> action to generate a certificate signing request (CSR).</p> </li> <li> <p>Sign the CSR using a root or intermediate CA hosted either by an on-premises PKI hierarchy or a commercial CA..</p> </li> <li> <p>Create a certificate chain and copy the signed certificate and the certificate chain to your working directory.</p> </li> </ol> <p>The following requirements apply when you import a CA certificate.</p> <ul> <li> <p>You cannot import a non-self-signed certificate for use as a root CA.</p> </li> <li> <p>You cannot import a self-signed certificate for use as a subordinate CA.</p> </li> <li> <p>Your certificate chain must not include the private CA certificate that you are importing.</p> </li> <li> <p>Your ACM Private CA-hosted or on-premises CA certificate must be the last certificate in your chain. The subordinate certificate, if any, that your root CA signed must be next to last. The subordinate certificate signed by the preceding subordinate CA must come next, and so on until your chain is built. </p> </li> <li> <p>The chain must be PEM-encoded.</p> </li> </ul>
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_ImportCertificateAuthorityCertificate_611400;
          body: JsonNode): Recallable =
  ## importCertificateAuthorityCertificate
  ## <p>Imports a signed private CA certificate into ACM Private CA. This action is used when you are using a chain of trust whose root is located outside ACM Private CA. Before you can call this action, the following preparations must in place:</p> <ol> <li> <p>In ACM Private CA, call the <a>CreateCertificateAuthority</a> action to create the private CA that that you plan to back with the imported certificate.</p> </li> <li> <p>Call the <a>GetCertificateAuthorityCsr</a> action to generate a certificate signing request (CSR).</p> </li> <li> <p>Sign the CSR using a root or intermediate CA hosted either by an on-premises PKI hierarchy or a commercial CA..</p> </li> <li> <p>Create a certificate chain and copy the signed certificate and the certificate chain to your working directory.</p> </li> </ol> <p>The following requirements apply when you import a CA certificate.</p> <ul> <li> <p>You cannot import a non-self-signed certificate for use as a root CA.</p> </li> <li> <p>You cannot import a self-signed certificate for use as a subordinate CA.</p> </li> <li> <p>Your certificate chain must not include the private CA certificate that you are importing.</p> </li> <li> <p>Your ACM Private CA-hosted or on-premises CA certificate must be the last certificate in your chain. The subordinate certificate, if any, that your root CA signed must be next to last. The subordinate certificate signed by the preceding subordinate CA must come next, and so on until your chain is built. </p> </li> <li> <p>The chain must be PEM-encoded.</p> </li> </ul>
  ##   body: JObject (required)
  var body_611414 = newJObject()
  if body != nil:
    body_611414 = body
  result = call_611413.call(nil, nil, nil, nil, body_611414)

var importCertificateAuthorityCertificate* = Call_ImportCertificateAuthorityCertificate_611400(
    name: "importCertificateAuthorityCertificate", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.ImportCertificateAuthorityCertificate",
    validator: validate_ImportCertificateAuthorityCertificate_611401, base: "/",
    url: url_ImportCertificateAuthorityCertificate_611402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_IssueCertificate_611415 = ref object of OpenApiRestCall_610658
proc url_IssueCertificate_611417(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_IssueCertificate_611416(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611418 = header.getOrDefault("X-Amz-Target")
  valid_611418 = validateParameter(valid_611418, JString, required = true, default = newJString(
      "ACMPrivateCA.IssueCertificate"))
  if valid_611418 != nil:
    section.add "X-Amz-Target", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Signature")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Signature", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Content-Sha256", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Date")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Date", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Credential")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Credential", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Security-Token")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Security-Token", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Algorithm")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Algorithm", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-SignedHeaders", valid_611425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611427: Call_IssueCertificate_611415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uses your private certificate authority (CA) to issue a client certificate. This action returns the Amazon Resource Name (ARN) of the certificate. You can retrieve the certificate by calling the <a>GetCertificate</a> action and specifying the ARN. </p> <note> <p>You cannot use the ACM <b>ListCertificateAuthorities</b> action to retrieve the ARNs of the certificates that you issue by using ACM Private CA.</p> </note>
  ## 
  let valid = call_611427.validator(path, query, header, formData, body)
  let scheme = call_611427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611427.url(scheme.get, call_611427.host, call_611427.base,
                         call_611427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611427, url, valid)

proc call*(call_611428: Call_IssueCertificate_611415; body: JsonNode): Recallable =
  ## issueCertificate
  ## <p>Uses your private certificate authority (CA) to issue a client certificate. This action returns the Amazon Resource Name (ARN) of the certificate. You can retrieve the certificate by calling the <a>GetCertificate</a> action and specifying the ARN. </p> <note> <p>You cannot use the ACM <b>ListCertificateAuthorities</b> action to retrieve the ARNs of the certificates that you issue by using ACM Private CA.</p> </note>
  ##   body: JObject (required)
  var body_611429 = newJObject()
  if body != nil:
    body_611429 = body
  result = call_611428.call(nil, nil, nil, nil, body_611429)

var issueCertificate* = Call_IssueCertificate_611415(name: "issueCertificate",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.IssueCertificate",
    validator: validate_IssueCertificate_611416, base: "/",
    url: url_IssueCertificate_611417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCertificateAuthorities_611430 = ref object of OpenApiRestCall_610658
proc url_ListCertificateAuthorities_611432(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCertificateAuthorities_611431(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the private certificate authorities that you created by using the <a>CreateCertificateAuthority</a> action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611433 = query.getOrDefault("MaxResults")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "MaxResults", valid_611433
  var valid_611434 = query.getOrDefault("NextToken")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "NextToken", valid_611434
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611435 = header.getOrDefault("X-Amz-Target")
  valid_611435 = validateParameter(valid_611435, JString, required = true, default = newJString(
      "ACMPrivateCA.ListCertificateAuthorities"))
  if valid_611435 != nil:
    section.add "X-Amz-Target", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Signature")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Signature", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Content-Sha256", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Date")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Date", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Credential")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Credential", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-Security-Token")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Security-Token", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Algorithm")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Algorithm", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-SignedHeaders", valid_611442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611444: Call_ListCertificateAuthorities_611430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the private certificate authorities that you created by using the <a>CreateCertificateAuthority</a> action.
  ## 
  let valid = call_611444.validator(path, query, header, formData, body)
  let scheme = call_611444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611444.url(scheme.get, call_611444.host, call_611444.base,
                         call_611444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611444, url, valid)

proc call*(call_611445: Call_ListCertificateAuthorities_611430; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCertificateAuthorities
  ## Lists the private certificate authorities that you created by using the <a>CreateCertificateAuthority</a> action.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611446 = newJObject()
  var body_611447 = newJObject()
  add(query_611446, "MaxResults", newJString(MaxResults))
  add(query_611446, "NextToken", newJString(NextToken))
  if body != nil:
    body_611447 = body
  result = call_611445.call(nil, query_611446, nil, nil, body_611447)

var listCertificateAuthorities* = Call_ListCertificateAuthorities_611430(
    name: "listCertificateAuthorities", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.ListCertificateAuthorities",
    validator: validate_ListCertificateAuthorities_611431, base: "/",
    url: url_ListCertificateAuthorities_611432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPermissions_611449 = ref object of OpenApiRestCall_610658
proc url_ListPermissions_611451(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPermissions_611450(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists all the permissions, if any, that have been assigned by a private CA. Permissions can be granted with the <a>CreatePermission</a> action and revoked with the <a>DeletePermission</a> action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611452 = query.getOrDefault("MaxResults")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "MaxResults", valid_611452
  var valid_611453 = query.getOrDefault("NextToken")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "NextToken", valid_611453
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611454 = header.getOrDefault("X-Amz-Target")
  valid_611454 = validateParameter(valid_611454, JString, required = true, default = newJString(
      "ACMPrivateCA.ListPermissions"))
  if valid_611454 != nil:
    section.add "X-Amz-Target", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Signature")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Signature", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Content-Sha256", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Date")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Date", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-Credential")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Credential", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Security-Token")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Security-Token", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Algorithm")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Algorithm", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-SignedHeaders", valid_611461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611463: Call_ListPermissions_611449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the permissions, if any, that have been assigned by a private CA. Permissions can be granted with the <a>CreatePermission</a> action and revoked with the <a>DeletePermission</a> action.
  ## 
  let valid = call_611463.validator(path, query, header, formData, body)
  let scheme = call_611463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611463.url(scheme.get, call_611463.host, call_611463.base,
                         call_611463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611463, url, valid)

proc call*(call_611464: Call_ListPermissions_611449; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPermissions
  ## Lists all the permissions, if any, that have been assigned by a private CA. Permissions can be granted with the <a>CreatePermission</a> action and revoked with the <a>DeletePermission</a> action.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611465 = newJObject()
  var body_611466 = newJObject()
  add(query_611465, "MaxResults", newJString(MaxResults))
  add(query_611465, "NextToken", newJString(NextToken))
  if body != nil:
    body_611466 = body
  result = call_611464.call(nil, query_611465, nil, nil, body_611466)

var listPermissions* = Call_ListPermissions_611449(name: "listPermissions",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.ListPermissions",
    validator: validate_ListPermissions_611450, base: "/", url: url_ListPermissions_611451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_611467 = ref object of OpenApiRestCall_610658
proc url_ListTags_611469(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_611468(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the tags, if any, that are associated with your private CA. Tags are labels that you can use to identify and organize your CAs. Each tag consists of a key and an optional value. Call the <a>TagCertificateAuthority</a> action to add one or more tags to your CA. Call the <a>UntagCertificateAuthority</a> action to remove tags. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611470 = query.getOrDefault("MaxResults")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "MaxResults", valid_611470
  var valid_611471 = query.getOrDefault("NextToken")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "NextToken", valid_611471
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611472 = header.getOrDefault("X-Amz-Target")
  valid_611472 = validateParameter(valid_611472, JString, required = true,
                                 default = newJString("ACMPrivateCA.ListTags"))
  if valid_611472 != nil:
    section.add "X-Amz-Target", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Signature")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Signature", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Content-Sha256", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-Date")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Date", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Credential")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Credential", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Security-Token")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Security-Token", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Algorithm")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Algorithm", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-SignedHeaders", valid_611479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611481: Call_ListTags_611467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags, if any, that are associated with your private CA. Tags are labels that you can use to identify and organize your CAs. Each tag consists of a key and an optional value. Call the <a>TagCertificateAuthority</a> action to add one or more tags to your CA. Call the <a>UntagCertificateAuthority</a> action to remove tags. 
  ## 
  let valid = call_611481.validator(path, query, header, formData, body)
  let scheme = call_611481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611481.url(scheme.get, call_611481.host, call_611481.base,
                         call_611481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611481, url, valid)

proc call*(call_611482: Call_ListTags_611467; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTags
  ## Lists the tags, if any, that are associated with your private CA. Tags are labels that you can use to identify and organize your CAs. Each tag consists of a key and an optional value. Call the <a>TagCertificateAuthority</a> action to add one or more tags to your CA. Call the <a>UntagCertificateAuthority</a> action to remove tags. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611483 = newJObject()
  var body_611484 = newJObject()
  add(query_611483, "MaxResults", newJString(MaxResults))
  add(query_611483, "NextToken", newJString(NextToken))
  if body != nil:
    body_611484 = body
  result = call_611482.call(nil, query_611483, nil, nil, body_611484)

var listTags* = Call_ListTags_611467(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "acm-pca.amazonaws.com", route: "/#X-Amz-Target=ACMPrivateCA.ListTags",
                                  validator: validate_ListTags_611468, base: "/",
                                  url: url_ListTags_611469,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreCertificateAuthority_611485 = ref object of OpenApiRestCall_610658
proc url_RestoreCertificateAuthority_611487(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestoreCertificateAuthority_611486(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611488 = header.getOrDefault("X-Amz-Target")
  valid_611488 = validateParameter(valid_611488, JString, required = true, default = newJString(
      "ACMPrivateCA.RestoreCertificateAuthority"))
  if valid_611488 != nil:
    section.add "X-Amz-Target", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Signature")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Signature", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Content-Sha256", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-Date")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Date", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-Credential")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Credential", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-Security-Token")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-Security-Token", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Algorithm")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Algorithm", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-SignedHeaders", valid_611495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611497: Call_RestoreCertificateAuthority_611485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restores a certificate authority (CA) that is in the <code>DELETED</code> state. You can restore a CA during the period that you defined in the <b>PermanentDeletionTimeInDays</b> parameter of the <a>DeleteCertificateAuthority</a> action. Currently, you can specify 7 to 30 days. If you did not specify a <b>PermanentDeletionTimeInDays</b> value, by default you can restore the CA at any time in a 30 day period. You can check the time remaining in the restoration period of a private CA in the <code>DELETED</code> state by calling the <a>DescribeCertificateAuthority</a> or <a>ListCertificateAuthorities</a> actions. The status of a restored CA is set to its pre-deletion status when the <b>RestoreCertificateAuthority</b> action returns. To change its status to <code>ACTIVE</code>, call the <a>UpdateCertificateAuthority</a> action. If the private CA was in the <code>PENDING_CERTIFICATE</code> state at deletion, you must use the <a>ImportCertificateAuthorityCertificate</a> action to import a certificate authority into the private CA before it can be activated. You cannot restore a CA after the restoration period has ended.
  ## 
  let valid = call_611497.validator(path, query, header, formData, body)
  let scheme = call_611497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611497.url(scheme.get, call_611497.host, call_611497.base,
                         call_611497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611497, url, valid)

proc call*(call_611498: Call_RestoreCertificateAuthority_611485; body: JsonNode): Recallable =
  ## restoreCertificateAuthority
  ## Restores a certificate authority (CA) that is in the <code>DELETED</code> state. You can restore a CA during the period that you defined in the <b>PermanentDeletionTimeInDays</b> parameter of the <a>DeleteCertificateAuthority</a> action. Currently, you can specify 7 to 30 days. If you did not specify a <b>PermanentDeletionTimeInDays</b> value, by default you can restore the CA at any time in a 30 day period. You can check the time remaining in the restoration period of a private CA in the <code>DELETED</code> state by calling the <a>DescribeCertificateAuthority</a> or <a>ListCertificateAuthorities</a> actions. The status of a restored CA is set to its pre-deletion status when the <b>RestoreCertificateAuthority</b> action returns. To change its status to <code>ACTIVE</code>, call the <a>UpdateCertificateAuthority</a> action. If the private CA was in the <code>PENDING_CERTIFICATE</code> state at deletion, you must use the <a>ImportCertificateAuthorityCertificate</a> action to import a certificate authority into the private CA before it can be activated. You cannot restore a CA after the restoration period has ended.
  ##   body: JObject (required)
  var body_611499 = newJObject()
  if body != nil:
    body_611499 = body
  result = call_611498.call(nil, nil, nil, nil, body_611499)

var restoreCertificateAuthority* = Call_RestoreCertificateAuthority_611485(
    name: "restoreCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.RestoreCertificateAuthority",
    validator: validate_RestoreCertificateAuthority_611486, base: "/",
    url: url_RestoreCertificateAuthority_611487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeCertificate_611500 = ref object of OpenApiRestCall_610658
proc url_RevokeCertificate_611502(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RevokeCertificate_611501(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611503 = header.getOrDefault("X-Amz-Target")
  valid_611503 = validateParameter(valid_611503, JString, required = true, default = newJString(
      "ACMPrivateCA.RevokeCertificate"))
  if valid_611503 != nil:
    section.add "X-Amz-Target", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Signature")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Signature", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Content-Sha256", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Date")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Date", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Credential")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Credential", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-Security-Token")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Security-Token", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Algorithm")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Algorithm", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-SignedHeaders", valid_611510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611512: Call_RevokeCertificate_611500; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes a certificate that was issued inside ACM Private CA. If you enable a certificate revocation list (CRL) when you create or update your private CA, information about the revoked certificates will be included in the CRL. ACM Private CA writes the CRL to an S3 bucket that you specify. For more information about revocation, see the <a>CrlConfiguration</a> structure. ACM Private CA also writes revocation information to the audit report. For more information, see <a>CreateCertificateAuthorityAuditReport</a>. </p> <note> <p>You cannot revoke a root CA self-signed certificate.</p> </note>
  ## 
  let valid = call_611512.validator(path, query, header, formData, body)
  let scheme = call_611512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611512.url(scheme.get, call_611512.host, call_611512.base,
                         call_611512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611512, url, valid)

proc call*(call_611513: Call_RevokeCertificate_611500; body: JsonNode): Recallable =
  ## revokeCertificate
  ## <p>Revokes a certificate that was issued inside ACM Private CA. If you enable a certificate revocation list (CRL) when you create or update your private CA, information about the revoked certificates will be included in the CRL. ACM Private CA writes the CRL to an S3 bucket that you specify. For more information about revocation, see the <a>CrlConfiguration</a> structure. ACM Private CA also writes revocation information to the audit report. For more information, see <a>CreateCertificateAuthorityAuditReport</a>. </p> <note> <p>You cannot revoke a root CA self-signed certificate.</p> </note>
  ##   body: JObject (required)
  var body_611514 = newJObject()
  if body != nil:
    body_611514 = body
  result = call_611513.call(nil, nil, nil, nil, body_611514)

var revokeCertificate* = Call_RevokeCertificate_611500(name: "revokeCertificate",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.RevokeCertificate",
    validator: validate_RevokeCertificate_611501, base: "/",
    url: url_RevokeCertificate_611502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagCertificateAuthority_611515 = ref object of OpenApiRestCall_610658
proc url_TagCertificateAuthority_611517(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagCertificateAuthority_611516(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611518 = header.getOrDefault("X-Amz-Target")
  valid_611518 = validateParameter(valid_611518, JString, required = true, default = newJString(
      "ACMPrivateCA.TagCertificateAuthority"))
  if valid_611518 != nil:
    section.add "X-Amz-Target", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Signature")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Signature", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Content-Sha256", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Date")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Date", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Credential")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Credential", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-Security-Token")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Security-Token", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Algorithm")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Algorithm", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-SignedHeaders", valid_611525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611527: Call_TagCertificateAuthority_611515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to your private CA. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the private CA on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. You can apply a tag to just one private CA if you want to identify a specific characteristic of that CA, or you can apply the same tag to multiple private CAs if you want to filter for a common relationship among those CAs. To remove one or more tags, use the <a>UntagCertificateAuthority</a> action. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ## 
  let valid = call_611527.validator(path, query, header, formData, body)
  let scheme = call_611527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611527.url(scheme.get, call_611527.host, call_611527.base,
                         call_611527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611527, url, valid)

proc call*(call_611528: Call_TagCertificateAuthority_611515; body: JsonNode): Recallable =
  ## tagCertificateAuthority
  ## Adds one or more tags to your private CA. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the private CA on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. You can apply a tag to just one private CA if you want to identify a specific characteristic of that CA, or you can apply the same tag to multiple private CAs if you want to filter for a common relationship among those CAs. To remove one or more tags, use the <a>UntagCertificateAuthority</a> action. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ##   body: JObject (required)
  var body_611529 = newJObject()
  if body != nil:
    body_611529 = body
  result = call_611528.call(nil, nil, nil, nil, body_611529)

var tagCertificateAuthority* = Call_TagCertificateAuthority_611515(
    name: "tagCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.TagCertificateAuthority",
    validator: validate_TagCertificateAuthority_611516, base: "/",
    url: url_TagCertificateAuthority_611517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagCertificateAuthority_611530 = ref object of OpenApiRestCall_610658
proc url_UntagCertificateAuthority_611532(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagCertificateAuthority_611531(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611533 = header.getOrDefault("X-Amz-Target")
  valid_611533 = validateParameter(valid_611533, JString, required = true, default = newJString(
      "ACMPrivateCA.UntagCertificateAuthority"))
  if valid_611533 != nil:
    section.add "X-Amz-Target", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Signature")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Signature", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Content-Sha256", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Date")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Date", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Credential")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Credential", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-Security-Token")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Security-Token", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Algorithm")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Algorithm", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-SignedHeaders", valid_611540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611542: Call_UntagCertificateAuthority_611530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags from your private CA. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this action, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. To add tags to a private CA, use the <a>TagCertificateAuthority</a>. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ## 
  let valid = call_611542.validator(path, query, header, formData, body)
  let scheme = call_611542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611542.url(scheme.get, call_611542.host, call_611542.base,
                         call_611542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611542, url, valid)

proc call*(call_611543: Call_UntagCertificateAuthority_611530; body: JsonNode): Recallable =
  ## untagCertificateAuthority
  ## Remove one or more tags from your private CA. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this action, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. To add tags to a private CA, use the <a>TagCertificateAuthority</a>. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ##   body: JObject (required)
  var body_611544 = newJObject()
  if body != nil:
    body_611544 = body
  result = call_611543.call(nil, nil, nil, nil, body_611544)

var untagCertificateAuthority* = Call_UntagCertificateAuthority_611530(
    name: "untagCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.UntagCertificateAuthority",
    validator: validate_UntagCertificateAuthority_611531, base: "/",
    url: url_UntagCertificateAuthority_611532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCertificateAuthority_611545 = ref object of OpenApiRestCall_610658
proc url_UpdateCertificateAuthority_611547(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCertificateAuthority_611546(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611548 = header.getOrDefault("X-Amz-Target")
  valid_611548 = validateParameter(valid_611548, JString, required = true, default = newJString(
      "ACMPrivateCA.UpdateCertificateAuthority"))
  if valid_611548 != nil:
    section.add "X-Amz-Target", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Signature")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Signature", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Content-Sha256", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Date")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Date", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Credential")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Credential", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Security-Token")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Security-Token", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Algorithm")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Algorithm", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-SignedHeaders", valid_611555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611557: Call_UpdateCertificateAuthority_611545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status or configuration of a private certificate authority (CA). Your private CA must be in the <code>ACTIVE</code> or <code>DISABLED</code> state before you can update it. You can disable a private CA that is in the <code>ACTIVE</code> state or make a CA that is in the <code>DISABLED</code> state active again.
  ## 
  let valid = call_611557.validator(path, query, header, formData, body)
  let scheme = call_611557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611557.url(scheme.get, call_611557.host, call_611557.base,
                         call_611557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611557, url, valid)

proc call*(call_611558: Call_UpdateCertificateAuthority_611545; body: JsonNode): Recallable =
  ## updateCertificateAuthority
  ## Updates the status or configuration of a private certificate authority (CA). Your private CA must be in the <code>ACTIVE</code> or <code>DISABLED</code> state before you can update it. You can disable a private CA that is in the <code>ACTIVE</code> state or make a CA that is in the <code>DISABLED</code> state active again.
  ##   body: JObject (required)
  var body_611559 = newJObject()
  if body != nil:
    body_611559 = body
  result = call_611558.call(nil, nil, nil, nil, body_611559)

var updateCertificateAuthority* = Call_UpdateCertificateAuthority_611545(
    name: "updateCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.UpdateCertificateAuthority",
    validator: validate_UpdateCertificateAuthority_611546, base: "/",
    url: url_UpdateCertificateAuthority_611547,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
