
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_CreateCertificateAuthority_599705 = ref object of OpenApiRestCall_599368
proc url_CreateCertificateAuthority_599707(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCertificateAuthority_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "ACMPrivateCA.CreateCertificateAuthority"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_CreateCertificateAuthority_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a root or subordinate private certificate authority (CA). You must specify the CA configuration, the certificate revocation list (CRL) configuration, the CA type, and an optional idempotency token to avoid accidental creation of multiple CAs. The CA configuration specifies the name of the algorithm and key size to be used to create the CA private key, the type of signing algorithm that the CA uses, and X.500 subject information. The CRL configuration specifies the CRL expiration period in days (the validity period of the CRL), the Amazon S3 bucket that will contain the CRL, and a CNAME alias for the S3 bucket that is included in certificates issued by the CA. If successful, this action returns the Amazon Resource Name (ARN) of the CA.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_CreateCertificateAuthority_599705; body: JsonNode): Recallable =
  ## createCertificateAuthority
  ## Creates a root or subordinate private certificate authority (CA). You must specify the CA configuration, the certificate revocation list (CRL) configuration, the CA type, and an optional idempotency token to avoid accidental creation of multiple CAs. The CA configuration specifies the name of the algorithm and key size to be used to create the CA private key, the type of signing algorithm that the CA uses, and X.500 subject information. The CRL configuration specifies the CRL expiration period in days (the validity period of the CRL), the Amazon S3 bucket that will contain the CRL, and a CNAME alias for the S3 bucket that is included in certificates issued by the CA. If successful, this action returns the Amazon Resource Name (ARN) of the CA.
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var createCertificateAuthority* = Call_CreateCertificateAuthority_599705(
    name: "createCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.CreateCertificateAuthority",
    validator: validate_CreateCertificateAuthority_599706, base: "/",
    url: url_CreateCertificateAuthority_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCertificateAuthorityAuditReport_599974 = ref object of OpenApiRestCall_599368
proc url_CreateCertificateAuthorityAuditReport_599976(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCertificateAuthorityAuditReport_599975(path: JsonNode;
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
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "ACMPrivateCA.CreateCertificateAuthorityAuditReport"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_CreateCertificateAuthorityAuditReport_599974;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates an audit report that lists every time that your CA private key is used. The report is saved in the Amazon S3 bucket that you specify on input. The <a>IssueCertificate</a> and <a>RevokeCertificate</a> actions use the private key.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_CreateCertificateAuthorityAuditReport_599974;
          body: JsonNode): Recallable =
  ## createCertificateAuthorityAuditReport
  ## Creates an audit report that lists every time that your CA private key is used. The report is saved in the Amazon S3 bucket that you specify on input. The <a>IssueCertificate</a> and <a>RevokeCertificate</a> actions use the private key.
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var createCertificateAuthorityAuditReport* = Call_CreateCertificateAuthorityAuditReport_599974(
    name: "createCertificateAuthorityAuditReport", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.CreateCertificateAuthorityAuditReport",
    validator: validate_CreateCertificateAuthorityAuditReport_599975, base: "/",
    url: url_CreateCertificateAuthorityAuditReport_599976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePermission_599989 = ref object of OpenApiRestCall_599368
proc url_CreatePermission_599991(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePermission_599990(path: JsonNode; query: JsonNode;
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
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "ACMPrivateCA.CreatePermission"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_CreatePermission_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns permissions from a private CA to a designated AWS service. Services are specified by their service principals and can be given permission to create and retrieve certificates on a private CA. Services can also be given permission to list the active permissions that the private CA has granted. For ACM to automatically renew your private CA's certificates, you must assign all possible permissions from the CA to the ACM service principal.</p> <p>At this time, you can only assign permissions to ACM (<code>acm.amazonaws.com</code>). Permissions can be revoked with the <a>DeletePermission</a> action and listed with the <a>ListPermissions</a> action.</p>
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_CreatePermission_599989; body: JsonNode): Recallable =
  ## createPermission
  ## <p>Assigns permissions from a private CA to a designated AWS service. Services are specified by their service principals and can be given permission to create and retrieve certificates on a private CA. Services can also be given permission to list the active permissions that the private CA has granted. For ACM to automatically renew your private CA's certificates, you must assign all possible permissions from the CA to the ACM service principal.</p> <p>At this time, you can only assign permissions to ACM (<code>acm.amazonaws.com</code>). Permissions can be revoked with the <a>DeletePermission</a> action and listed with the <a>ListPermissions</a> action.</p>
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var createPermission* = Call_CreatePermission_599989(name: "createPermission",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.CreatePermission",
    validator: validate_CreatePermission_599990, base: "/",
    url: url_CreatePermission_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCertificateAuthority_600004 = ref object of OpenApiRestCall_599368
proc url_DeleteCertificateAuthority_600006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCertificateAuthority_600005(path: JsonNode; query: JsonNode;
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
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "ACMPrivateCA.DeleteCertificateAuthority"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_DeleteCertificateAuthority_600004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a private certificate authority (CA). You must provide the Amazon Resource Name (ARN) of the private CA that you want to delete. You can find the ARN by calling the <a>ListCertificateAuthorities</a> action. </p> <note> <p>Deleting a CA will invalidate other CAs and certificates below it in your CA hierarchy.</p> </note> <p>Before you can delete a CA that you have created and activated, you must disable it. To do this, call the <a>UpdateCertificateAuthority</a> action and set the <b>CertificateAuthorityStatus</b> parameter to <code>DISABLED</code>. </p> <p>Additionally, you can delete a CA if you are waiting for it to be created (that is, the status of the CA is <code>CREATING</code>). You can also delete it if the CA has been created but you haven't yet imported the signed certificate into ACM Private CA (that is, the status of the CA is <code>PENDING_CERTIFICATE</code>). </p> <p>When you successfully call <a>DeleteCertificateAuthority</a>, the CA's status changes to <code>DELETED</code>. However, the CA won't be permanently deleted until the restoration period has passed. By default, if you do not set the <code>PermanentDeletionTimeInDays</code> parameter, the CA remains restorable for 30 days. You can set the parameter from 7 to 30 days. The <a>DescribeCertificateAuthority</a> action returns the time remaining in the restoration window of a private CA in the <code>DELETED</code> state. To restore an eligible CA, call the <a>RestoreCertificateAuthority</a> action.</p>
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_DeleteCertificateAuthority_600004; body: JsonNode): Recallable =
  ## deleteCertificateAuthority
  ## <p>Deletes a private certificate authority (CA). You must provide the Amazon Resource Name (ARN) of the private CA that you want to delete. You can find the ARN by calling the <a>ListCertificateAuthorities</a> action. </p> <note> <p>Deleting a CA will invalidate other CAs and certificates below it in your CA hierarchy.</p> </note> <p>Before you can delete a CA that you have created and activated, you must disable it. To do this, call the <a>UpdateCertificateAuthority</a> action and set the <b>CertificateAuthorityStatus</b> parameter to <code>DISABLED</code>. </p> <p>Additionally, you can delete a CA if you are waiting for it to be created (that is, the status of the CA is <code>CREATING</code>). You can also delete it if the CA has been created but you haven't yet imported the signed certificate into ACM Private CA (that is, the status of the CA is <code>PENDING_CERTIFICATE</code>). </p> <p>When you successfully call <a>DeleteCertificateAuthority</a>, the CA's status changes to <code>DELETED</code>. However, the CA won't be permanently deleted until the restoration period has passed. By default, if you do not set the <code>PermanentDeletionTimeInDays</code> parameter, the CA remains restorable for 30 days. You can set the parameter from 7 to 30 days. The <a>DescribeCertificateAuthority</a> action returns the time remaining in the restoration window of a private CA in the <code>DELETED</code> state. To restore an eligible CA, call the <a>RestoreCertificateAuthority</a> action.</p>
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var deleteCertificateAuthority* = Call_DeleteCertificateAuthority_600004(
    name: "deleteCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.DeleteCertificateAuthority",
    validator: validate_DeleteCertificateAuthority_600005, base: "/",
    url: url_DeleteCertificateAuthority_600006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePermission_600019 = ref object of OpenApiRestCall_599368
proc url_DeletePermission_600021(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePermission_600020(path: JsonNode; query: JsonNode;
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
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "ACMPrivateCA.DeletePermission"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_DeletePermission_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes permissions that a private CA assigned to a designated AWS service. Permissions can be created with the <a>CreatePermission</a> action and listed with the <a>ListPermissions</a> action. 
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_DeletePermission_600019; body: JsonNode): Recallable =
  ## deletePermission
  ## Revokes permissions that a private CA assigned to a designated AWS service. Permissions can be created with the <a>CreatePermission</a> action and listed with the <a>ListPermissions</a> action. 
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var deletePermission* = Call_DeletePermission_600019(name: "deletePermission",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.DeletePermission",
    validator: validate_DeletePermission_600020, base: "/",
    url: url_DeletePermission_600021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificateAuthority_600034 = ref object of OpenApiRestCall_599368
proc url_DescribeCertificateAuthority_600036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCertificateAuthority_600035(path: JsonNode; query: JsonNode;
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "ACMPrivateCA.DescribeCertificateAuthority"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_DescribeCertificateAuthority_600034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists information about your private certificate authority (CA). You specify the private CA on input by its ARN (Amazon Resource Name). The output contains the status of your CA. This can be any of the following: </p> <ul> <li> <p> <code>CREATING</code> - ACM Private CA is creating your private certificate authority.</p> </li> <li> <p> <code>PENDING_CERTIFICATE</code> - The certificate is pending. You must use your ACM Private CA-hosted or on-premises root or subordinate CA to sign your private CA CSR and then import it into PCA. </p> </li> <li> <p> <code>ACTIVE</code> - Your private CA is active.</p> </li> <li> <p> <code>DISABLED</code> - Your private CA has been disabled.</p> </li> <li> <p> <code>EXPIRED</code> - Your private CA certificate has expired.</p> </li> <li> <p> <code>FAILED</code> - Your private CA has failed. Your CA can fail because of problems such a network outage or backend AWS failure or other errors. A failed CA can never return to the pending state. You must create a new CA. </p> </li> <li> <p> <code>DELETED</code> - Your private CA is within the restoration period, after which it is permanently deleted. The length of time remaining in the CA's restoration period is also included in this action's output.</p> </li> </ul>
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_DescribeCertificateAuthority_600034; body: JsonNode): Recallable =
  ## describeCertificateAuthority
  ## <p>Lists information about your private certificate authority (CA). You specify the private CA on input by its ARN (Amazon Resource Name). The output contains the status of your CA. This can be any of the following: </p> <ul> <li> <p> <code>CREATING</code> - ACM Private CA is creating your private certificate authority.</p> </li> <li> <p> <code>PENDING_CERTIFICATE</code> - The certificate is pending. You must use your ACM Private CA-hosted or on-premises root or subordinate CA to sign your private CA CSR and then import it into PCA. </p> </li> <li> <p> <code>ACTIVE</code> - Your private CA is active.</p> </li> <li> <p> <code>DISABLED</code> - Your private CA has been disabled.</p> </li> <li> <p> <code>EXPIRED</code> - Your private CA certificate has expired.</p> </li> <li> <p> <code>FAILED</code> - Your private CA has failed. Your CA can fail because of problems such a network outage or backend AWS failure or other errors. A failed CA can never return to the pending state. You must create a new CA. </p> </li> <li> <p> <code>DELETED</code> - Your private CA is within the restoration period, after which it is permanently deleted. The length of time remaining in the CA's restoration period is also included in this action's output.</p> </li> </ul>
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var describeCertificateAuthority* = Call_DescribeCertificateAuthority_600034(
    name: "describeCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.DescribeCertificateAuthority",
    validator: validate_DescribeCertificateAuthority_600035, base: "/",
    url: url_DescribeCertificateAuthority_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificateAuthorityAuditReport_600049 = ref object of OpenApiRestCall_599368
proc url_DescribeCertificateAuthorityAuditReport_600051(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCertificateAuthorityAuditReport_600050(path: JsonNode;
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
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "ACMPrivateCA.DescribeCertificateAuthorityAuditReport"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_DescribeCertificateAuthorityAuditReport_600049;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists information about a specific audit report created by calling the <a>CreateCertificateAuthorityAuditReport</a> action. Audit information is created every time the certificate authority (CA) private key is used. The private key is used when you call the <a>IssueCertificate</a> action or the <a>RevokeCertificate</a> action. 
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_DescribeCertificateAuthorityAuditReport_600049;
          body: JsonNode): Recallable =
  ## describeCertificateAuthorityAuditReport
  ## Lists information about a specific audit report created by calling the <a>CreateCertificateAuthorityAuditReport</a> action. Audit information is created every time the certificate authority (CA) private key is used. The private key is used when you call the <a>IssueCertificate</a> action or the <a>RevokeCertificate</a> action. 
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var describeCertificateAuthorityAuditReport* = Call_DescribeCertificateAuthorityAuditReport_600049(
    name: "describeCertificateAuthorityAuditReport", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com", route: "/#X-Amz-Target=ACMPrivateCA.DescribeCertificateAuthorityAuditReport",
    validator: validate_DescribeCertificateAuthorityAuditReport_600050, base: "/",
    url: url_DescribeCertificateAuthorityAuditReport_600051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCertificate_600064 = ref object of OpenApiRestCall_599368
proc url_GetCertificate_600066(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCertificate_600065(path: JsonNode; query: JsonNode;
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
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "ACMPrivateCA.GetCertificate"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_GetCertificate_600064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a certificate from your private CA. The ARN of the certificate is returned when you call the <a>IssueCertificate</a> action. You must specify both the ARN of your private CA and the ARN of the issued certificate when calling the <b>GetCertificate</b> action. You can retrieve the certificate if it is in the <b>ISSUED</b> state. You can call the <a>CreateCertificateAuthorityAuditReport</a> action to create a report that contains information about all of the certificates issued and revoked by your private CA. 
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_GetCertificate_600064; body: JsonNode): Recallable =
  ## getCertificate
  ## Retrieves a certificate from your private CA. The ARN of the certificate is returned when you call the <a>IssueCertificate</a> action. You must specify both the ARN of your private CA and the ARN of the issued certificate when calling the <b>GetCertificate</b> action. You can retrieve the certificate if it is in the <b>ISSUED</b> state. You can call the <a>CreateCertificateAuthorityAuditReport</a> action to create a report that contains information about all of the certificates issued and revoked by your private CA. 
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var getCertificate* = Call_GetCertificate_600064(name: "getCertificate",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.GetCertificate",
    validator: validate_GetCertificate_600065, base: "/", url: url_GetCertificate_600066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCertificateAuthorityCertificate_600079 = ref object of OpenApiRestCall_599368
proc url_GetCertificateAuthorityCertificate_600081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCertificateAuthorityCertificate_600080(path: JsonNode;
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
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "ACMPrivateCA.GetCertificateAuthorityCertificate"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_GetCertificateAuthorityCertificate_600079;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the certificate and certificate chain for your private certificate authority (CA). Both the certificate and the chain are base64 PEM-encoded. The chain does not include the CA certificate. Each certificate in the chain signs the one before it. 
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_GetCertificateAuthorityCertificate_600079;
          body: JsonNode): Recallable =
  ## getCertificateAuthorityCertificate
  ## Retrieves the certificate and certificate chain for your private certificate authority (CA). Both the certificate and the chain are base64 PEM-encoded. The chain does not include the CA certificate. Each certificate in the chain signs the one before it. 
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var getCertificateAuthorityCertificate* = Call_GetCertificateAuthorityCertificate_600079(
    name: "getCertificateAuthorityCertificate", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.GetCertificateAuthorityCertificate",
    validator: validate_GetCertificateAuthorityCertificate_600080, base: "/",
    url: url_GetCertificateAuthorityCertificate_600081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCertificateAuthorityCsr_600094 = ref object of OpenApiRestCall_599368
proc url_GetCertificateAuthorityCsr_600096(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCertificateAuthorityCsr_600095(path: JsonNode; query: JsonNode;
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
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "ACMPrivateCA.GetCertificateAuthorityCsr"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_GetCertificateAuthorityCsr_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the certificate signing request (CSR) for your private certificate authority (CA). The CSR is created when you call the <a>CreateCertificateAuthority</a> action. Sign the CSR with your ACM Private CA-hosted or on-premises root or subordinate CA. Then import the signed certificate back into ACM Private CA by calling the <a>ImportCertificateAuthorityCertificate</a> action. The CSR is returned as a base64 PEM-encoded string. 
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_GetCertificateAuthorityCsr_600094; body: JsonNode): Recallable =
  ## getCertificateAuthorityCsr
  ## Retrieves the certificate signing request (CSR) for your private certificate authority (CA). The CSR is created when you call the <a>CreateCertificateAuthority</a> action. Sign the CSR with your ACM Private CA-hosted or on-premises root or subordinate CA. Then import the signed certificate back into ACM Private CA by calling the <a>ImportCertificateAuthorityCertificate</a> action. The CSR is returned as a base64 PEM-encoded string. 
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var getCertificateAuthorityCsr* = Call_GetCertificateAuthorityCsr_600094(
    name: "getCertificateAuthorityCsr", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.GetCertificateAuthorityCsr",
    validator: validate_GetCertificateAuthorityCsr_600095, base: "/",
    url: url_GetCertificateAuthorityCsr_600096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCertificateAuthorityCertificate_600109 = ref object of OpenApiRestCall_599368
proc url_ImportCertificateAuthorityCertificate_600111(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportCertificateAuthorityCertificate_600110(path: JsonNode;
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
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "ACMPrivateCA.ImportCertificateAuthorityCertificate"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_ImportCertificateAuthorityCertificate_600109;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Imports a signed private CA certificate into ACM Private CA. This action is used when you are using a chain of trust whose root is located outside ACM Private CA. Before you can call this action, the following preparations must in place:</p> <ol> <li> <p>In ACM Private CA, call the <a>CreateCertificateAuthority</a> action to create the private CA that that you plan to back with the imported certificate.</p> </li> <li> <p>Call the <a>GetCertificateAuthorityCsr</a> action to generate a certificate signing request (CSR).</p> </li> <li> <p>Sign the CSR using a root or intermediate CA hosted either by an on-premises PKI hierarchy or a commercial CA..</p> </li> <li> <p>Create a certificate chain and copy the signed certificate and the certificate chain to your working directory.</p> </li> </ol> <p>The following requirements apply when you import a CA certificate.</p> <ul> <li> <p>You cannot import a non-self-signed certificate for use as a root CA.</p> </li> <li> <p>You cannot import a self-signed certificate for use as a subordinate CA.</p> </li> <li> <p>Your certificate chain must not include the private CA certificate that you are importing.</p> </li> <li> <p>Your ACM Private CA-hosted or on-premises CA certificate must be the last certificate in your chain. The subordinate certificate, if any, that your root CA signed must be next to last. The subordinate certificate signed by the preceding subordinate CA must come next, and so on until your chain is built. </p> </li> <li> <p>The chain must be PEM-encoded.</p> </li> </ul>
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_ImportCertificateAuthorityCertificate_600109;
          body: JsonNode): Recallable =
  ## importCertificateAuthorityCertificate
  ## <p>Imports a signed private CA certificate into ACM Private CA. This action is used when you are using a chain of trust whose root is located outside ACM Private CA. Before you can call this action, the following preparations must in place:</p> <ol> <li> <p>In ACM Private CA, call the <a>CreateCertificateAuthority</a> action to create the private CA that that you plan to back with the imported certificate.</p> </li> <li> <p>Call the <a>GetCertificateAuthorityCsr</a> action to generate a certificate signing request (CSR).</p> </li> <li> <p>Sign the CSR using a root or intermediate CA hosted either by an on-premises PKI hierarchy or a commercial CA..</p> </li> <li> <p>Create a certificate chain and copy the signed certificate and the certificate chain to your working directory.</p> </li> </ol> <p>The following requirements apply when you import a CA certificate.</p> <ul> <li> <p>You cannot import a non-self-signed certificate for use as a root CA.</p> </li> <li> <p>You cannot import a self-signed certificate for use as a subordinate CA.</p> </li> <li> <p>Your certificate chain must not include the private CA certificate that you are importing.</p> </li> <li> <p>Your ACM Private CA-hosted or on-premises CA certificate must be the last certificate in your chain. The subordinate certificate, if any, that your root CA signed must be next to last. The subordinate certificate signed by the preceding subordinate CA must come next, and so on until your chain is built. </p> </li> <li> <p>The chain must be PEM-encoded.</p> </li> </ul>
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var importCertificateAuthorityCertificate* = Call_ImportCertificateAuthorityCertificate_600109(
    name: "importCertificateAuthorityCertificate", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.ImportCertificateAuthorityCertificate",
    validator: validate_ImportCertificateAuthorityCertificate_600110, base: "/",
    url: url_ImportCertificateAuthorityCertificate_600111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_IssueCertificate_600124 = ref object of OpenApiRestCall_599368
proc url_IssueCertificate_600126(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_IssueCertificate_600125(path: JsonNode; query: JsonNode;
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
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "ACMPrivateCA.IssueCertificate"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_IssueCertificate_600124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uses your private certificate authority (CA) to issue a client certificate. This action returns the Amazon Resource Name (ARN) of the certificate. You can retrieve the certificate by calling the <a>GetCertificate</a> action and specifying the ARN. </p> <note> <p>You cannot use the ACM <b>ListCertificateAuthorities</b> action to retrieve the ARNs of the certificates that you issue by using ACM Private CA.</p> </note>
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_IssueCertificate_600124; body: JsonNode): Recallable =
  ## issueCertificate
  ## <p>Uses your private certificate authority (CA) to issue a client certificate. This action returns the Amazon Resource Name (ARN) of the certificate. You can retrieve the certificate by calling the <a>GetCertificate</a> action and specifying the ARN. </p> <note> <p>You cannot use the ACM <b>ListCertificateAuthorities</b> action to retrieve the ARNs of the certificates that you issue by using ACM Private CA.</p> </note>
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var issueCertificate* = Call_IssueCertificate_600124(name: "issueCertificate",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.IssueCertificate",
    validator: validate_IssueCertificate_600125, base: "/",
    url: url_IssueCertificate_600126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCertificateAuthorities_600139 = ref object of OpenApiRestCall_599368
proc url_ListCertificateAuthorities_600141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCertificateAuthorities_600140(path: JsonNode; query: JsonNode;
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
  var valid_600142 = query.getOrDefault("NextToken")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "NextToken", valid_600142
  var valid_600143 = query.getOrDefault("MaxResults")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "MaxResults", valid_600143
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
  var valid_600144 = header.getOrDefault("X-Amz-Date")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Date", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Security-Token")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Security-Token", valid_600145
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600146 = header.getOrDefault("X-Amz-Target")
  valid_600146 = validateParameter(valid_600146, JString, required = true, default = newJString(
      "ACMPrivateCA.ListCertificateAuthorities"))
  if valid_600146 != nil:
    section.add "X-Amz-Target", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Content-Sha256", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Algorithm")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Algorithm", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Signature")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Signature", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-SignedHeaders", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Credential")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Credential", valid_600151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600153: Call_ListCertificateAuthorities_600139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the private certificate authorities that you created by using the <a>CreateCertificateAuthority</a> action.
  ## 
  let valid = call_600153.validator(path, query, header, formData, body)
  let scheme = call_600153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600153.url(scheme.get, call_600153.host, call_600153.base,
                         call_600153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600153, url, valid)

proc call*(call_600154: Call_ListCertificateAuthorities_600139; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCertificateAuthorities
  ## Lists the private certificate authorities that you created by using the <a>CreateCertificateAuthority</a> action.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600155 = newJObject()
  var body_600156 = newJObject()
  add(query_600155, "NextToken", newJString(NextToken))
  if body != nil:
    body_600156 = body
  add(query_600155, "MaxResults", newJString(MaxResults))
  result = call_600154.call(nil, query_600155, nil, nil, body_600156)

var listCertificateAuthorities* = Call_ListCertificateAuthorities_600139(
    name: "listCertificateAuthorities", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.ListCertificateAuthorities",
    validator: validate_ListCertificateAuthorities_600140, base: "/",
    url: url_ListCertificateAuthorities_600141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPermissions_600158 = ref object of OpenApiRestCall_599368
proc url_ListPermissions_600160(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPermissions_600159(path: JsonNode; query: JsonNode;
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
  var valid_600161 = query.getOrDefault("NextToken")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "NextToken", valid_600161
  var valid_600162 = query.getOrDefault("MaxResults")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "MaxResults", valid_600162
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
  var valid_600163 = header.getOrDefault("X-Amz-Date")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Date", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Security-Token")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Security-Token", valid_600164
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600165 = header.getOrDefault("X-Amz-Target")
  valid_600165 = validateParameter(valid_600165, JString, required = true, default = newJString(
      "ACMPrivateCA.ListPermissions"))
  if valid_600165 != nil:
    section.add "X-Amz-Target", valid_600165
  var valid_600166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-Content-Sha256", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-Algorithm")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Algorithm", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Signature")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Signature", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-SignedHeaders", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Credential")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Credential", valid_600170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600172: Call_ListPermissions_600158; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the permissions, if any, that have been assigned by a private CA. Permissions can be granted with the <a>CreatePermission</a> action and revoked with the <a>DeletePermission</a> action.
  ## 
  let valid = call_600172.validator(path, query, header, formData, body)
  let scheme = call_600172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600172.url(scheme.get, call_600172.host, call_600172.base,
                         call_600172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600172, url, valid)

proc call*(call_600173: Call_ListPermissions_600158; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPermissions
  ## Lists all the permissions, if any, that have been assigned by a private CA. Permissions can be granted with the <a>CreatePermission</a> action and revoked with the <a>DeletePermission</a> action.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600174 = newJObject()
  var body_600175 = newJObject()
  add(query_600174, "NextToken", newJString(NextToken))
  if body != nil:
    body_600175 = body
  add(query_600174, "MaxResults", newJString(MaxResults))
  result = call_600173.call(nil, query_600174, nil, nil, body_600175)

var listPermissions* = Call_ListPermissions_600158(name: "listPermissions",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.ListPermissions",
    validator: validate_ListPermissions_600159, base: "/", url: url_ListPermissions_600160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_600176 = ref object of OpenApiRestCall_599368
proc url_ListTags_600178(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_600177(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600179 = query.getOrDefault("NextToken")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "NextToken", valid_600179
  var valid_600180 = query.getOrDefault("MaxResults")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "MaxResults", valid_600180
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
  var valid_600181 = header.getOrDefault("X-Amz-Date")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Date", valid_600181
  var valid_600182 = header.getOrDefault("X-Amz-Security-Token")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Security-Token", valid_600182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600183 = header.getOrDefault("X-Amz-Target")
  valid_600183 = validateParameter(valid_600183, JString, required = true,
                                 default = newJString("ACMPrivateCA.ListTags"))
  if valid_600183 != nil:
    section.add "X-Amz-Target", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Content-Sha256", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Algorithm")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Algorithm", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Signature")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Signature", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-SignedHeaders", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Credential")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Credential", valid_600188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600190: Call_ListTags_600176; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags, if any, that are associated with your private CA. Tags are labels that you can use to identify and organize your CAs. Each tag consists of a key and an optional value. Call the <a>TagCertificateAuthority</a> action to add one or more tags to your CA. Call the <a>UntagCertificateAuthority</a> action to remove tags. 
  ## 
  let valid = call_600190.validator(path, query, header, formData, body)
  let scheme = call_600190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600190.url(scheme.get, call_600190.host, call_600190.base,
                         call_600190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600190, url, valid)

proc call*(call_600191: Call_ListTags_600176; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listTags
  ## Lists the tags, if any, that are associated with your private CA. Tags are labels that you can use to identify and organize your CAs. Each tag consists of a key and an optional value. Call the <a>TagCertificateAuthority</a> action to add one or more tags to your CA. Call the <a>UntagCertificateAuthority</a> action to remove tags. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600192 = newJObject()
  var body_600193 = newJObject()
  add(query_600192, "NextToken", newJString(NextToken))
  if body != nil:
    body_600193 = body
  add(query_600192, "MaxResults", newJString(MaxResults))
  result = call_600191.call(nil, query_600192, nil, nil, body_600193)

var listTags* = Call_ListTags_600176(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "acm-pca.amazonaws.com", route: "/#X-Amz-Target=ACMPrivateCA.ListTags",
                                  validator: validate_ListTags_600177, base: "/",
                                  url: url_ListTags_600178,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreCertificateAuthority_600194 = ref object of OpenApiRestCall_599368
proc url_RestoreCertificateAuthority_600196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestoreCertificateAuthority_600195(path: JsonNode; query: JsonNode;
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
  var valid_600197 = header.getOrDefault("X-Amz-Date")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Date", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Security-Token")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Security-Token", valid_600198
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600199 = header.getOrDefault("X-Amz-Target")
  valid_600199 = validateParameter(valid_600199, JString, required = true, default = newJString(
      "ACMPrivateCA.RestoreCertificateAuthority"))
  if valid_600199 != nil:
    section.add "X-Amz-Target", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Content-Sha256", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Algorithm")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Algorithm", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Signature")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Signature", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-SignedHeaders", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Credential")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Credential", valid_600204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600206: Call_RestoreCertificateAuthority_600194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restores a certificate authority (CA) that is in the <code>DELETED</code> state. You can restore a CA during the period that you defined in the <b>PermanentDeletionTimeInDays</b> parameter of the <a>DeleteCertificateAuthority</a> action. Currently, you can specify 7 to 30 days. If you did not specify a <b>PermanentDeletionTimeInDays</b> value, by default you can restore the CA at any time in a 30 day period. You can check the time remaining in the restoration period of a private CA in the <code>DELETED</code> state by calling the <a>DescribeCertificateAuthority</a> or <a>ListCertificateAuthorities</a> actions. The status of a restored CA is set to its pre-deletion status when the <b>RestoreCertificateAuthority</b> action returns. To change its status to <code>ACTIVE</code>, call the <a>UpdateCertificateAuthority</a> action. If the private CA was in the <code>PENDING_CERTIFICATE</code> state at deletion, you must use the <a>ImportCertificateAuthorityCertificate</a> action to import a certificate authority into the private CA before it can be activated. You cannot restore a CA after the restoration period has ended.
  ## 
  let valid = call_600206.validator(path, query, header, formData, body)
  let scheme = call_600206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600206.url(scheme.get, call_600206.host, call_600206.base,
                         call_600206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600206, url, valid)

proc call*(call_600207: Call_RestoreCertificateAuthority_600194; body: JsonNode): Recallable =
  ## restoreCertificateAuthority
  ## Restores a certificate authority (CA) that is in the <code>DELETED</code> state. You can restore a CA during the period that you defined in the <b>PermanentDeletionTimeInDays</b> parameter of the <a>DeleteCertificateAuthority</a> action. Currently, you can specify 7 to 30 days. If you did not specify a <b>PermanentDeletionTimeInDays</b> value, by default you can restore the CA at any time in a 30 day period. You can check the time remaining in the restoration period of a private CA in the <code>DELETED</code> state by calling the <a>DescribeCertificateAuthority</a> or <a>ListCertificateAuthorities</a> actions. The status of a restored CA is set to its pre-deletion status when the <b>RestoreCertificateAuthority</b> action returns. To change its status to <code>ACTIVE</code>, call the <a>UpdateCertificateAuthority</a> action. If the private CA was in the <code>PENDING_CERTIFICATE</code> state at deletion, you must use the <a>ImportCertificateAuthorityCertificate</a> action to import a certificate authority into the private CA before it can be activated. You cannot restore a CA after the restoration period has ended.
  ##   body: JObject (required)
  var body_600208 = newJObject()
  if body != nil:
    body_600208 = body
  result = call_600207.call(nil, nil, nil, nil, body_600208)

var restoreCertificateAuthority* = Call_RestoreCertificateAuthority_600194(
    name: "restoreCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.RestoreCertificateAuthority",
    validator: validate_RestoreCertificateAuthority_600195, base: "/",
    url: url_RestoreCertificateAuthority_600196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeCertificate_600209 = ref object of OpenApiRestCall_599368
proc url_RevokeCertificate_600211(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RevokeCertificate_600210(path: JsonNode; query: JsonNode;
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
  var valid_600212 = header.getOrDefault("X-Amz-Date")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Date", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Security-Token")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Security-Token", valid_600213
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600214 = header.getOrDefault("X-Amz-Target")
  valid_600214 = validateParameter(valid_600214, JString, required = true, default = newJString(
      "ACMPrivateCA.RevokeCertificate"))
  if valid_600214 != nil:
    section.add "X-Amz-Target", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Content-Sha256", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Algorithm")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Algorithm", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Signature")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Signature", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-SignedHeaders", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Credential")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Credential", valid_600219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600221: Call_RevokeCertificate_600209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes a certificate that was issued inside ACM Private CA. If you enable a certificate revocation list (CRL) when you create or update your private CA, information about the revoked certificates will be included in the CRL. ACM Private CA writes the CRL to an S3 bucket that you specify. For more information about revocation, see the <a>CrlConfiguration</a> structure. ACM Private CA also writes revocation information to the audit report. For more information, see <a>CreateCertificateAuthorityAuditReport</a>. </p> <note> <p>You cannot revoke a root CA self-signed certificate.</p> </note>
  ## 
  let valid = call_600221.validator(path, query, header, formData, body)
  let scheme = call_600221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600221.url(scheme.get, call_600221.host, call_600221.base,
                         call_600221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600221, url, valid)

proc call*(call_600222: Call_RevokeCertificate_600209; body: JsonNode): Recallable =
  ## revokeCertificate
  ## <p>Revokes a certificate that was issued inside ACM Private CA. If you enable a certificate revocation list (CRL) when you create or update your private CA, information about the revoked certificates will be included in the CRL. ACM Private CA writes the CRL to an S3 bucket that you specify. For more information about revocation, see the <a>CrlConfiguration</a> structure. ACM Private CA also writes revocation information to the audit report. For more information, see <a>CreateCertificateAuthorityAuditReport</a>. </p> <note> <p>You cannot revoke a root CA self-signed certificate.</p> </note>
  ##   body: JObject (required)
  var body_600223 = newJObject()
  if body != nil:
    body_600223 = body
  result = call_600222.call(nil, nil, nil, nil, body_600223)

var revokeCertificate* = Call_RevokeCertificate_600209(name: "revokeCertificate",
    meth: HttpMethod.HttpPost, host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.RevokeCertificate",
    validator: validate_RevokeCertificate_600210, base: "/",
    url: url_RevokeCertificate_600211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagCertificateAuthority_600224 = ref object of OpenApiRestCall_599368
proc url_TagCertificateAuthority_600226(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagCertificateAuthority_600225(path: JsonNode; query: JsonNode;
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
  var valid_600227 = header.getOrDefault("X-Amz-Date")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Date", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Security-Token")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Security-Token", valid_600228
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600229 = header.getOrDefault("X-Amz-Target")
  valid_600229 = validateParameter(valid_600229, JString, required = true, default = newJString(
      "ACMPrivateCA.TagCertificateAuthority"))
  if valid_600229 != nil:
    section.add "X-Amz-Target", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Content-Sha256", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Algorithm")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Algorithm", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Signature")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Signature", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-SignedHeaders", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Credential")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Credential", valid_600234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600236: Call_TagCertificateAuthority_600224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to your private CA. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the private CA on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. You can apply a tag to just one private CA if you want to identify a specific characteristic of that CA, or you can apply the same tag to multiple private CAs if you want to filter for a common relationship among those CAs. To remove one or more tags, use the <a>UntagCertificateAuthority</a> action. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ## 
  let valid = call_600236.validator(path, query, header, formData, body)
  let scheme = call_600236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600236.url(scheme.get, call_600236.host, call_600236.base,
                         call_600236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600236, url, valid)

proc call*(call_600237: Call_TagCertificateAuthority_600224; body: JsonNode): Recallable =
  ## tagCertificateAuthority
  ## Adds one or more tags to your private CA. Tags are labels that you can use to identify and organize your AWS resources. Each tag consists of a key and an optional value. You specify the private CA on input by its Amazon Resource Name (ARN). You specify the tag by using a key-value pair. You can apply a tag to just one private CA if you want to identify a specific characteristic of that CA, or you can apply the same tag to multiple private CAs if you want to filter for a common relationship among those CAs. To remove one or more tags, use the <a>UntagCertificateAuthority</a> action. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ##   body: JObject (required)
  var body_600238 = newJObject()
  if body != nil:
    body_600238 = body
  result = call_600237.call(nil, nil, nil, nil, body_600238)

var tagCertificateAuthority* = Call_TagCertificateAuthority_600224(
    name: "tagCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.TagCertificateAuthority",
    validator: validate_TagCertificateAuthority_600225, base: "/",
    url: url_TagCertificateAuthority_600226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagCertificateAuthority_600239 = ref object of OpenApiRestCall_599368
proc url_UntagCertificateAuthority_600241(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagCertificateAuthority_600240(path: JsonNode; query: JsonNode;
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
  var valid_600242 = header.getOrDefault("X-Amz-Date")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Date", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Security-Token")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Security-Token", valid_600243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600244 = header.getOrDefault("X-Amz-Target")
  valid_600244 = validateParameter(valid_600244, JString, required = true, default = newJString(
      "ACMPrivateCA.UntagCertificateAuthority"))
  if valid_600244 != nil:
    section.add "X-Amz-Target", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Content-Sha256", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Algorithm")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Algorithm", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Signature")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Signature", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-SignedHeaders", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Credential")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Credential", valid_600249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600251: Call_UntagCertificateAuthority_600239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags from your private CA. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this action, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. To add tags to a private CA, use the <a>TagCertificateAuthority</a>. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ## 
  let valid = call_600251.validator(path, query, header, formData, body)
  let scheme = call_600251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600251.url(scheme.get, call_600251.host, call_600251.base,
                         call_600251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600251, url, valid)

proc call*(call_600252: Call_UntagCertificateAuthority_600239; body: JsonNode): Recallable =
  ## untagCertificateAuthority
  ## Remove one or more tags from your private CA. A tag consists of a key-value pair. If you do not specify the value portion of the tag when calling this action, the tag will be removed regardless of value. If you specify a value, the tag is removed only if it is associated with the specified value. To add tags to a private CA, use the <a>TagCertificateAuthority</a>. Call the <a>ListTags</a> action to see what tags are associated with your CA. 
  ##   body: JObject (required)
  var body_600253 = newJObject()
  if body != nil:
    body_600253 = body
  result = call_600252.call(nil, nil, nil, nil, body_600253)

var untagCertificateAuthority* = Call_UntagCertificateAuthority_600239(
    name: "untagCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.UntagCertificateAuthority",
    validator: validate_UntagCertificateAuthority_600240, base: "/",
    url: url_UntagCertificateAuthority_600241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCertificateAuthority_600254 = ref object of OpenApiRestCall_599368
proc url_UpdateCertificateAuthority_600256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCertificateAuthority_600255(path: JsonNode; query: JsonNode;
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
  var valid_600257 = header.getOrDefault("X-Amz-Date")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Date", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Security-Token")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Security-Token", valid_600258
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600259 = header.getOrDefault("X-Amz-Target")
  valid_600259 = validateParameter(valid_600259, JString, required = true, default = newJString(
      "ACMPrivateCA.UpdateCertificateAuthority"))
  if valid_600259 != nil:
    section.add "X-Amz-Target", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Content-Sha256", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Algorithm")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Algorithm", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Signature")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Signature", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-SignedHeaders", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Credential")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Credential", valid_600264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600266: Call_UpdateCertificateAuthority_600254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status or configuration of a private certificate authority (CA). Your private CA must be in the <code>ACTIVE</code> or <code>DISABLED</code> state before you can update it. You can disable a private CA that is in the <code>ACTIVE</code> state or make a CA that is in the <code>DISABLED</code> state active again.
  ## 
  let valid = call_600266.validator(path, query, header, formData, body)
  let scheme = call_600266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600266.url(scheme.get, call_600266.host, call_600266.base,
                         call_600266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600266, url, valid)

proc call*(call_600267: Call_UpdateCertificateAuthority_600254; body: JsonNode): Recallable =
  ## updateCertificateAuthority
  ## Updates the status or configuration of a private certificate authority (CA). Your private CA must be in the <code>ACTIVE</code> or <code>DISABLED</code> state before you can update it. You can disable a private CA that is in the <code>ACTIVE</code> state or make a CA that is in the <code>DISABLED</code> state active again.
  ##   body: JObject (required)
  var body_600268 = newJObject()
  if body != nil:
    body_600268 = body
  result = call_600267.call(nil, nil, nil, nil, body_600268)

var updateCertificateAuthority* = Call_UpdateCertificateAuthority_600254(
    name: "updateCertificateAuthority", meth: HttpMethod.HttpPost,
    host: "acm-pca.amazonaws.com",
    route: "/#X-Amz-Target=ACMPrivateCA.UpdateCertificateAuthority",
    validator: validate_UpdateCertificateAuthority_600255, base: "/",
    url: url_UpdateCertificateAuthority_600256,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
