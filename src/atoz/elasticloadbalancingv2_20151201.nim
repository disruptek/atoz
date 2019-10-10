
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Elastic Load Balancing
## version: 2015-12-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Elastic Load Balancing</fullname> <p>A load balancer distributes incoming traffic across targets, such as your EC2 instances. This enables you to increase the availability of your application. The load balancer also monitors the health of its registered targets and ensures that it routes traffic only to healthy targets. You configure your load balancer to accept incoming traffic by specifying one or more listeners, which are configured with a protocol and port number for connections from clients to the load balancer. You configure a target group with a protocol and port number for connections from the load balancer to the targets, and with health check settings to be used when checking the health status of the targets.</p> <p>Elastic Load Balancing supports the following types of load balancers: Application Load Balancers, Network Load Balancers, and Classic Load Balancers. This reference covers Application Load Balancers and Network Load Balancers.</p> <p>An Application Load Balancer makes routing and load balancing decisions at the application layer (HTTP/HTTPS). A Network Load Balancer makes routing and load balancing decisions at the transport layer (TCP/TLS). Both Application Load Balancers and Network Load Balancers can route requests to one or more ports on each EC2 instance or container instance in your virtual private cloud (VPC). For more information, see the <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/">Elastic Load Balancing User Guide</a>.</p> <p>All Elastic Load Balancing operations are idempotent, which means that they complete at most one time. If you repeat an operation, it succeeds.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/elasticloadbalancing/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "elasticloadbalancing.ap-northeast-1.amazonaws.com", "ap-southeast-1": "elasticloadbalancing.ap-southeast-1.amazonaws.com", "us-west-2": "elasticloadbalancing.us-west-2.amazonaws.com", "eu-west-2": "elasticloadbalancing.eu-west-2.amazonaws.com", "ap-northeast-3": "elasticloadbalancing.ap-northeast-3.amazonaws.com", "eu-central-1": "elasticloadbalancing.eu-central-1.amazonaws.com", "us-east-2": "elasticloadbalancing.us-east-2.amazonaws.com", "us-east-1": "elasticloadbalancing.us-east-1.amazonaws.com", "cn-northwest-1": "elasticloadbalancing.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "elasticloadbalancing.ap-south-1.amazonaws.com", "eu-north-1": "elasticloadbalancing.eu-north-1.amazonaws.com", "ap-northeast-2": "elasticloadbalancing.ap-northeast-2.amazonaws.com", "us-west-1": "elasticloadbalancing.us-west-1.amazonaws.com", "us-gov-east-1": "elasticloadbalancing.us-gov-east-1.amazonaws.com", "eu-west-3": "elasticloadbalancing.eu-west-3.amazonaws.com", "cn-north-1": "elasticloadbalancing.cn-north-1.amazonaws.com.cn", "sa-east-1": "elasticloadbalancing.sa-east-1.amazonaws.com", "eu-west-1": "elasticloadbalancing.eu-west-1.amazonaws.com", "us-gov-west-1": "elasticloadbalancing.us-gov-west-1.amazonaws.com", "ap-southeast-2": "elasticloadbalancing.ap-southeast-2.amazonaws.com", "ca-central-1": "elasticloadbalancing.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "elasticloadbalancing.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "elasticloadbalancing.ap-southeast-1.amazonaws.com",
      "us-west-2": "elasticloadbalancing.us-west-2.amazonaws.com",
      "eu-west-2": "elasticloadbalancing.eu-west-2.amazonaws.com",
      "ap-northeast-3": "elasticloadbalancing.ap-northeast-3.amazonaws.com",
      "eu-central-1": "elasticloadbalancing.eu-central-1.amazonaws.com",
      "us-east-2": "elasticloadbalancing.us-east-2.amazonaws.com",
      "us-east-1": "elasticloadbalancing.us-east-1.amazonaws.com",
      "cn-northwest-1": "elasticloadbalancing.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "elasticloadbalancing.ap-south-1.amazonaws.com",
      "eu-north-1": "elasticloadbalancing.eu-north-1.amazonaws.com",
      "ap-northeast-2": "elasticloadbalancing.ap-northeast-2.amazonaws.com",
      "us-west-1": "elasticloadbalancing.us-west-1.amazonaws.com",
      "us-gov-east-1": "elasticloadbalancing.us-gov-east-1.amazonaws.com",
      "eu-west-3": "elasticloadbalancing.eu-west-3.amazonaws.com",
      "cn-north-1": "elasticloadbalancing.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "elasticloadbalancing.sa-east-1.amazonaws.com",
      "eu-west-1": "elasticloadbalancing.eu-west-1.amazonaws.com",
      "us-gov-west-1": "elasticloadbalancing.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "elasticloadbalancing.ap-southeast-2.amazonaws.com",
      "ca-central-1": "elasticloadbalancing.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "elasticloadbalancingv2"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddListenerCertificates_603075 = ref object of OpenApiRestCall_602466
proc url_PostAddListenerCertificates_603077(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddListenerCertificates_603076(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603078 = query.getOrDefault("Action")
  valid_603078 = validateParameter(valid_603078, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_603078 != nil:
    section.add "Action", valid_603078
  var valid_603079 = query.getOrDefault("Version")
  valid_603079 = validateParameter(valid_603079, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603079 != nil:
    section.add "Version", valid_603079
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603080 = header.getOrDefault("X-Amz-Date")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Date", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Security-Token")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Security-Token", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Content-Sha256", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Algorithm")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Algorithm", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Signature")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Signature", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-SignedHeaders", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Credential")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Credential", valid_603086
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_603087 = formData.getOrDefault("Certificates")
  valid_603087 = validateParameter(valid_603087, JArray, required = true, default = nil)
  if valid_603087 != nil:
    section.add "Certificates", valid_603087
  var valid_603088 = formData.getOrDefault("ListenerArn")
  valid_603088 = validateParameter(valid_603088, JString, required = true,
                                 default = nil)
  if valid_603088 != nil:
    section.add "ListenerArn", valid_603088
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603089: Call_PostAddListenerCertificates_603075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603089.validator(path, query, header, formData, body)
  let scheme = call_603089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603089.url(scheme.get, call_603089.host, call_603089.base,
                         call_603089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603089, url, valid)

proc call*(call_603090: Call_PostAddListenerCertificates_603075;
          Certificates: JsonNode; ListenerArn: string;
          Action: string = "AddListenerCertificates"; Version: string = "2015-12-01"): Recallable =
  ## postAddListenerCertificates
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603091 = newJObject()
  var formData_603092 = newJObject()
  if Certificates != nil:
    formData_603092.add "Certificates", Certificates
  add(formData_603092, "ListenerArn", newJString(ListenerArn))
  add(query_603091, "Action", newJString(Action))
  add(query_603091, "Version", newJString(Version))
  result = call_603090.call(nil, query_603091, nil, formData_603092, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_603075(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_603076, base: "/",
    url: url_PostAddListenerCertificates_603077,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_602803 = ref object of OpenApiRestCall_602466
proc url_GetAddListenerCertificates_602805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddListenerCertificates_602804(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: JString (required)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Certificates` field"
  var valid_602917 = query.getOrDefault("Certificates")
  valid_602917 = validateParameter(valid_602917, JArray, required = true, default = nil)
  if valid_602917 != nil:
    section.add "Certificates", valid_602917
  var valid_602931 = query.getOrDefault("Action")
  valid_602931 = validateParameter(valid_602931, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_602931 != nil:
    section.add "Action", valid_602931
  var valid_602932 = query.getOrDefault("ListenerArn")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = nil)
  if valid_602932 != nil:
    section.add "ListenerArn", valid_602932
  var valid_602933 = query.getOrDefault("Version")
  valid_602933 = validateParameter(valid_602933, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602933 != nil:
    section.add "Version", valid_602933
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602934 = header.getOrDefault("X-Amz-Date")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Date", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Security-Token")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Security-Token", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Content-Sha256", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Algorithm")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Algorithm", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Signature")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Signature", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-SignedHeaders", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Credential")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Credential", valid_602940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602963: Call_GetAddListenerCertificates_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602963.validator(path, query, header, formData, body)
  let scheme = call_602963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602963.url(scheme.get, call_602963.host, call_602963.base,
                         call_602963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602963, url, valid)

proc call*(call_603034: Call_GetAddListenerCertificates_602803;
          Certificates: JsonNode; ListenerArn: string;
          Action: string = "AddListenerCertificates"; Version: string = "2015-12-01"): Recallable =
  ## getAddListenerCertificates
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  var query_603035 = newJObject()
  if Certificates != nil:
    query_603035.add "Certificates", Certificates
  add(query_603035, "Action", newJString(Action))
  add(query_603035, "ListenerArn", newJString(ListenerArn))
  add(query_603035, "Version", newJString(Version))
  result = call_603034.call(nil, query_603035, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_602803(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_602804, base: "/",
    url: url_GetAddListenerCertificates_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_603110 = ref object of OpenApiRestCall_602466
proc url_PostAddTags_603112(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTags_603111(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603113 = query.getOrDefault("Action")
  valid_603113 = validateParameter(valid_603113, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_603113 != nil:
    section.add "Action", valid_603113
  var valid_603114 = query.getOrDefault("Version")
  valid_603114 = validateParameter(valid_603114, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603114 != nil:
    section.add "Version", valid_603114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603115 = header.getOrDefault("X-Amz-Date")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Date", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Security-Token")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Security-Token", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Content-Sha256", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Algorithm")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Algorithm", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Signature")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Signature", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-SignedHeaders", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Credential")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Credential", valid_603121
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_603122 = formData.getOrDefault("ResourceArns")
  valid_603122 = validateParameter(valid_603122, JArray, required = true, default = nil)
  if valid_603122 != nil:
    section.add "ResourceArns", valid_603122
  var valid_603123 = formData.getOrDefault("Tags")
  valid_603123 = validateParameter(valid_603123, JArray, required = true, default = nil)
  if valid_603123 != nil:
    section.add "Tags", valid_603123
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603124: Call_PostAddTags_603110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_603124.validator(path, query, header, formData, body)
  let scheme = call_603124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603124.url(scheme.get, call_603124.host, call_603124.base,
                         call_603124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603124, url, valid)

proc call*(call_603125: Call_PostAddTags_603110; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603126 = newJObject()
  var formData_603127 = newJObject()
  if ResourceArns != nil:
    formData_603127.add "ResourceArns", ResourceArns
  if Tags != nil:
    formData_603127.add "Tags", Tags
  add(query_603126, "Action", newJString(Action))
  add(query_603126, "Version", newJString(Version))
  result = call_603125.call(nil, query_603126, nil, formData_603127, nil)

var postAddTags* = Call_PostAddTags_603110(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_603111,
                                        base: "/", url: url_PostAddTags_603112,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_603093 = ref object of OpenApiRestCall_602466
proc url_GetAddTags_603095(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTags_603094(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Action: JString (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_603096 = query.getOrDefault("Tags")
  valid_603096 = validateParameter(valid_603096, JArray, required = true, default = nil)
  if valid_603096 != nil:
    section.add "Tags", valid_603096
  var valid_603097 = query.getOrDefault("Action")
  valid_603097 = validateParameter(valid_603097, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_603097 != nil:
    section.add "Action", valid_603097
  var valid_603098 = query.getOrDefault("ResourceArns")
  valid_603098 = validateParameter(valid_603098, JArray, required = true, default = nil)
  if valid_603098 != nil:
    section.add "ResourceArns", valid_603098
  var valid_603099 = query.getOrDefault("Version")
  valid_603099 = validateParameter(valid_603099, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603099 != nil:
    section.add "Version", valid_603099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603100 = header.getOrDefault("X-Amz-Date")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Date", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Security-Token")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Security-Token", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Content-Sha256", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Algorithm")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Algorithm", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Signature")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Signature", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-SignedHeaders", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Credential")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Credential", valid_603106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603107: Call_GetAddTags_603093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_603107.validator(path, query, header, formData, body)
  let scheme = call_603107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603107.url(scheme.get, call_603107.host, call_603107.base,
                         call_603107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603107, url, valid)

proc call*(call_603108: Call_GetAddTags_603093; Tags: JsonNode;
          ResourceArns: JsonNode; Action: string = "AddTags";
          Version: string = "2015-12-01"): Recallable =
  ## getAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Action: string (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Version: string (required)
  var query_603109 = newJObject()
  if Tags != nil:
    query_603109.add "Tags", Tags
  add(query_603109, "Action", newJString(Action))
  if ResourceArns != nil:
    query_603109.add "ResourceArns", ResourceArns
  add(query_603109, "Version", newJString(Version))
  result = call_603108.call(nil, query_603109, nil, nil, nil)

var getAddTags* = Call_GetAddTags_603093(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_603094,
                                      base: "/", url: url_GetAddTags_603095,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_603149 = ref object of OpenApiRestCall_602466
proc url_PostCreateListener_603151(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateListener_603150(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603152 = query.getOrDefault("Action")
  valid_603152 = validateParameter(valid_603152, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_603152 != nil:
    section.add "Action", valid_603152
  var valid_603153 = query.getOrDefault("Version")
  valid_603153 = validateParameter(valid_603153, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603153 != nil:
    section.add "Version", valid_603153
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603154 = header.getOrDefault("X-Amz-Date")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Date", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Security-Token")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Security-Token", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Content-Sha256", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Algorithm")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Algorithm", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Signature")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Signature", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-SignedHeaders", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Credential")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Credential", valid_603160
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Port: JInt (required)
  ##       : The port on which the load balancer is listening.
  ##   Protocol: JString (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  section = newJObject()
  var valid_603161 = formData.getOrDefault("Certificates")
  valid_603161 = validateParameter(valid_603161, JArray, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "Certificates", valid_603161
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_603162 = formData.getOrDefault("LoadBalancerArn")
  valid_603162 = validateParameter(valid_603162, JString, required = true,
                                 default = nil)
  if valid_603162 != nil:
    section.add "LoadBalancerArn", valid_603162
  var valid_603163 = formData.getOrDefault("Port")
  valid_603163 = validateParameter(valid_603163, JInt, required = true, default = nil)
  if valid_603163 != nil:
    section.add "Port", valid_603163
  var valid_603164 = formData.getOrDefault("Protocol")
  valid_603164 = validateParameter(valid_603164, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_603164 != nil:
    section.add "Protocol", valid_603164
  var valid_603165 = formData.getOrDefault("SslPolicy")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "SslPolicy", valid_603165
  var valid_603166 = formData.getOrDefault("DefaultActions")
  valid_603166 = validateParameter(valid_603166, JArray, required = true, default = nil)
  if valid_603166 != nil:
    section.add "DefaultActions", valid_603166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603167: Call_PostCreateListener_603149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603167.validator(path, query, header, formData, body)
  let scheme = call_603167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603167.url(scheme.get, call_603167.host, call_603167.base,
                         call_603167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603167, url, valid)

proc call*(call_603168: Call_PostCreateListener_603149; LoadBalancerArn: string;
          Port: int; DefaultActions: JsonNode; Certificates: JsonNode = nil;
          Protocol: string = "HTTP"; Action: string = "CreateListener";
          SslPolicy: string = ""; Version: string = "2015-12-01"): Recallable =
  ## postCreateListener
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Port: int (required)
  ##       : The port on which the load balancer is listening.
  ##   Protocol: string (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Action: string (required)
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Version: string (required)
  var query_603169 = newJObject()
  var formData_603170 = newJObject()
  if Certificates != nil:
    formData_603170.add "Certificates", Certificates
  add(formData_603170, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_603170, "Port", newJInt(Port))
  add(formData_603170, "Protocol", newJString(Protocol))
  add(query_603169, "Action", newJString(Action))
  add(formData_603170, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_603170.add "DefaultActions", DefaultActions
  add(query_603169, "Version", newJString(Version))
  result = call_603168.call(nil, query_603169, nil, formData_603170, nil)

var postCreateListener* = Call_PostCreateListener_603149(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_603150, base: "/",
    url: url_PostCreateListener_603151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_603128 = ref object of OpenApiRestCall_602466
proc url_GetCreateListener_603130(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateListener_603129(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   Protocol: JString (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Port: JInt (required)
  ##       : The port on which the load balancer is listening.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DefaultActions` field"
  var valid_603131 = query.getOrDefault("DefaultActions")
  valid_603131 = validateParameter(valid_603131, JArray, required = true, default = nil)
  if valid_603131 != nil:
    section.add "DefaultActions", valid_603131
  var valid_603132 = query.getOrDefault("SslPolicy")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "SslPolicy", valid_603132
  var valid_603133 = query.getOrDefault("Protocol")
  valid_603133 = validateParameter(valid_603133, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_603133 != nil:
    section.add "Protocol", valid_603133
  var valid_603134 = query.getOrDefault("Certificates")
  valid_603134 = validateParameter(valid_603134, JArray, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "Certificates", valid_603134
  var valid_603135 = query.getOrDefault("Action")
  valid_603135 = validateParameter(valid_603135, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_603135 != nil:
    section.add "Action", valid_603135
  var valid_603136 = query.getOrDefault("LoadBalancerArn")
  valid_603136 = validateParameter(valid_603136, JString, required = true,
                                 default = nil)
  if valid_603136 != nil:
    section.add "LoadBalancerArn", valid_603136
  var valid_603137 = query.getOrDefault("Port")
  valid_603137 = validateParameter(valid_603137, JInt, required = true, default = nil)
  if valid_603137 != nil:
    section.add "Port", valid_603137
  var valid_603138 = query.getOrDefault("Version")
  valid_603138 = validateParameter(valid_603138, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603138 != nil:
    section.add "Version", valid_603138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603139 = header.getOrDefault("X-Amz-Date")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Date", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Security-Token")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Security-Token", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Content-Sha256", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Algorithm")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Algorithm", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Signature")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Signature", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-SignedHeaders", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Credential")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Credential", valid_603145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603146: Call_GetCreateListener_603128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603146.validator(path, query, header, formData, body)
  let scheme = call_603146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603146.url(scheme.get, call_603146.host, call_603146.base,
                         call_603146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603146, url, valid)

proc call*(call_603147: Call_GetCreateListener_603128; DefaultActions: JsonNode;
          LoadBalancerArn: string; Port: int; SslPolicy: string = "";
          Protocol: string = "HTTP"; Certificates: JsonNode = nil;
          Action: string = "CreateListener"; Version: string = "2015-12-01"): Recallable =
  ## getCreateListener
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   DefaultActions: JArray (required)
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which ciphers and protocols are supported. The default is the current predefined security policy.
  ##   Protocol: string (required)
  ##           : The protocol for connections from clients to the load balancer. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, and TCP_UDP.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list for the listener, use <a>AddListenerCertificates</a>.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Port: int (required)
  ##       : The port on which the load balancer is listening.
  ##   Version: string (required)
  var query_603148 = newJObject()
  if DefaultActions != nil:
    query_603148.add "DefaultActions", DefaultActions
  add(query_603148, "SslPolicy", newJString(SslPolicy))
  add(query_603148, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_603148.add "Certificates", Certificates
  add(query_603148, "Action", newJString(Action))
  add(query_603148, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603148, "Port", newJInt(Port))
  add(query_603148, "Version", newJString(Version))
  result = call_603147.call(nil, query_603148, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_603128(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_603129,
    base: "/", url: url_GetCreateListener_603130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_603194 = ref object of OpenApiRestCall_602466
proc url_PostCreateLoadBalancer_603196(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancer_603195(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603197 = query.getOrDefault("Action")
  valid_603197 = validateParameter(valid_603197, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_603197 != nil:
    section.add "Action", valid_603197
  var valid_603198 = query.getOrDefault("Version")
  valid_603198 = validateParameter(valid_603198, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603198 != nil:
    section.add "Version", valid_603198
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603199 = header.getOrDefault("X-Amz-Date")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Date", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Security-Token")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Security-Token", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Content-Sha256", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Algorithm")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Algorithm", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Signature")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Signature", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-SignedHeaders", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Credential")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Credential", valid_603205
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   IpAddressType: JString
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Type: JString
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your load balancer.</p>
  ##   Scheme: JString
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can only route requests from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_603206 = formData.getOrDefault("Name")
  valid_603206 = validateParameter(valid_603206, JString, required = true,
                                 default = nil)
  if valid_603206 != nil:
    section.add "Name", valid_603206
  var valid_603207 = formData.getOrDefault("IpAddressType")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_603207 != nil:
    section.add "IpAddressType", valid_603207
  var valid_603208 = formData.getOrDefault("Tags")
  valid_603208 = validateParameter(valid_603208, JArray, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "Tags", valid_603208
  var valid_603209 = formData.getOrDefault("Type")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = newJString("application"))
  if valid_603209 != nil:
    section.add "Type", valid_603209
  var valid_603210 = formData.getOrDefault("Subnets")
  valid_603210 = validateParameter(valid_603210, JArray, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "Subnets", valid_603210
  var valid_603211 = formData.getOrDefault("SecurityGroups")
  valid_603211 = validateParameter(valid_603211, JArray, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "SecurityGroups", valid_603211
  var valid_603212 = formData.getOrDefault("SubnetMappings")
  valid_603212 = validateParameter(valid_603212, JArray, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "SubnetMappings", valid_603212
  var valid_603213 = formData.getOrDefault("Scheme")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_603213 != nil:
    section.add "Scheme", valid_603213
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603214: Call_PostCreateLoadBalancer_603194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603214.validator(path, query, header, formData, body)
  let scheme = call_603214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603214.url(scheme.get, call_603214.host, call_603214.base,
                         call_603214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603214, url, valid)

proc call*(call_603215: Call_PostCreateLoadBalancer_603194; Name: string;
          IpAddressType: string = "ipv4"; Tags: JsonNode = nil;
          Type: string = "application"; Action: string = "CreateLoadBalancer";
          Subnets: JsonNode = nil; SecurityGroups: JsonNode = nil;
          SubnetMappings: JsonNode = nil; Scheme: string = "internet-facing";
          Version: string = "2015-12-01"): Recallable =
  ## postCreateLoadBalancer
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Name: string (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   IpAddressType: string
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Type: string
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Action: string (required)
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your load balancer.</p>
  ##   Scheme: string
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can only route requests from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  ##   Version: string (required)
  var query_603216 = newJObject()
  var formData_603217 = newJObject()
  add(formData_603217, "Name", newJString(Name))
  add(formData_603217, "IpAddressType", newJString(IpAddressType))
  if Tags != nil:
    formData_603217.add "Tags", Tags
  add(formData_603217, "Type", newJString(Type))
  add(query_603216, "Action", newJString(Action))
  if Subnets != nil:
    formData_603217.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_603217.add "SecurityGroups", SecurityGroups
  if SubnetMappings != nil:
    formData_603217.add "SubnetMappings", SubnetMappings
  add(formData_603217, "Scheme", newJString(Scheme))
  add(query_603216, "Version", newJString(Version))
  result = call_603215.call(nil, query_603216, nil, formData_603217, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_603194(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_603195, base: "/",
    url: url_PostCreateLoadBalancer_603196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_603171 = ref object of OpenApiRestCall_602466
proc url_GetCreateLoadBalancer_603173(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancer_603172(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Name: JString (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your load balancer.</p>
  ##   IpAddressType: JString
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   Scheme: JString
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can only route requests from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Type: JString
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Action: JString (required)
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   Version: JString (required)
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_603174 = query.getOrDefault("Name")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = nil)
  if valid_603174 != nil:
    section.add "Name", valid_603174
  var valid_603175 = query.getOrDefault("SubnetMappings")
  valid_603175 = validateParameter(valid_603175, JArray, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "SubnetMappings", valid_603175
  var valid_603176 = query.getOrDefault("IpAddressType")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_603176 != nil:
    section.add "IpAddressType", valid_603176
  var valid_603177 = query.getOrDefault("Scheme")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_603177 != nil:
    section.add "Scheme", valid_603177
  var valid_603178 = query.getOrDefault("Tags")
  valid_603178 = validateParameter(valid_603178, JArray, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "Tags", valid_603178
  var valid_603179 = query.getOrDefault("Type")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = newJString("application"))
  if valid_603179 != nil:
    section.add "Type", valid_603179
  var valid_603180 = query.getOrDefault("Action")
  valid_603180 = validateParameter(valid_603180, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_603180 != nil:
    section.add "Action", valid_603180
  var valid_603181 = query.getOrDefault("Subnets")
  valid_603181 = validateParameter(valid_603181, JArray, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "Subnets", valid_603181
  var valid_603182 = query.getOrDefault("Version")
  valid_603182 = validateParameter(valid_603182, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603182 != nil:
    section.add "Version", valid_603182
  var valid_603183 = query.getOrDefault("SecurityGroups")
  valid_603183 = validateParameter(valid_603183, JArray, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "SecurityGroups", valid_603183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603184 = header.getOrDefault("X-Amz-Date")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Date", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Security-Token")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Security-Token", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Content-Sha256", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Algorithm")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Algorithm", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Signature")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Signature", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-SignedHeaders", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Credential")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Credential", valid_603190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603191: Call_GetCreateLoadBalancer_603171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603191.validator(path, query, header, formData, body)
  let scheme = call_603191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603191.url(scheme.get, call_603191.host, call_603191.base,
                         call_603191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603191, url, valid)

proc call*(call_603192: Call_GetCreateLoadBalancer_603171; Name: string;
          SubnetMappings: JsonNode = nil; IpAddressType: string = "ipv4";
          Scheme: string = "internet-facing"; Tags: JsonNode = nil;
          Type: string = "application"; Action: string = "CreateLoadBalancer";
          Subnets: JsonNode = nil; Version: string = "2015-12-01";
          SecurityGroups: JsonNode = nil): Recallable =
  ## getCreateLoadBalancer
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Name: string (required)
  ##       : <p>The name of the load balancer.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, must not begin or end with a hyphen, and must not begin with "internal-".</p>
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones. You cannot specify Elastic IP addresses for your subnets.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones. You can specify one Elastic IP address per subnet if you need static IP addresses for your load balancer.</p>
  ##   IpAddressType: string
  ##                : [Application Load Balancers] The type of IP addresses used by the subnets for your load balancer. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>.
  ##   Scheme: string
  ##         : <p>The nodes of an Internet-facing load balancer have public IP addresses. The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes. Therefore, Internet-facing load balancers can route requests from clients over the internet.</p> <p>The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can only route requests from clients with access to the VPC for the load balancer.</p> <p>The default is an Internet-facing load balancer.</p>
  ##   Tags: JArray
  ##       : One or more tags to assign to the load balancer.
  ##   Type: string
  ##       : The type of load balancer. The default is <code>application</code>.
  ##   Action: string (required)
  ##   Subnets: JArray
  ##          : <p>The IDs of the public subnets. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>[Application Load Balancers] You must specify subnets from at least two Availability Zones.</p> <p>[Network Load Balancers] You can specify subnets from one or more Availability Zones.</p>
  ##   Version: string (required)
  ##   SecurityGroups: JArray
  ##                 : [Application Load Balancers] The IDs of the security groups for the load balancer.
  var query_603193 = newJObject()
  add(query_603193, "Name", newJString(Name))
  if SubnetMappings != nil:
    query_603193.add "SubnetMappings", SubnetMappings
  add(query_603193, "IpAddressType", newJString(IpAddressType))
  add(query_603193, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_603193.add "Tags", Tags
  add(query_603193, "Type", newJString(Type))
  add(query_603193, "Action", newJString(Action))
  if Subnets != nil:
    query_603193.add "Subnets", Subnets
  add(query_603193, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_603193.add "SecurityGroups", SecurityGroups
  result = call_603192.call(nil, query_603193, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_603171(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_603172, base: "/",
    url: url_GetCreateLoadBalancer_603173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_603237 = ref object of OpenApiRestCall_602466
proc url_PostCreateRule_603239(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateRule_603238(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603240 = query.getOrDefault("Action")
  valid_603240 = validateParameter(valid_603240, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_603240 != nil:
    section.add "Action", valid_603240
  var valid_603241 = query.getOrDefault("Version")
  valid_603241 = validateParameter(valid_603241, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603241 != nil:
    section.add "Version", valid_603241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_603244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Content-Sha256", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Algorithm")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Algorithm", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Signature")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Signature", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-SignedHeaders", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Credential")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Credential", valid_603248
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Priority: JInt (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_603249 = formData.getOrDefault("ListenerArn")
  valid_603249 = validateParameter(valid_603249, JString, required = true,
                                 default = nil)
  if valid_603249 != nil:
    section.add "ListenerArn", valid_603249
  var valid_603250 = formData.getOrDefault("Actions")
  valid_603250 = validateParameter(valid_603250, JArray, required = true, default = nil)
  if valid_603250 != nil:
    section.add "Actions", valid_603250
  var valid_603251 = formData.getOrDefault("Conditions")
  valid_603251 = validateParameter(valid_603251, JArray, required = true, default = nil)
  if valid_603251 != nil:
    section.add "Conditions", valid_603251
  var valid_603252 = formData.getOrDefault("Priority")
  valid_603252 = validateParameter(valid_603252, JInt, required = true, default = nil)
  if valid_603252 != nil:
    section.add "Priority", valid_603252
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603253: Call_PostCreateRule_603237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_603253.validator(path, query, header, formData, body)
  let scheme = call_603253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603253.url(scheme.get, call_603253.host, call_603253.base,
                         call_603253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603253, url, valid)

proc call*(call_603254: Call_PostCreateRule_603237; ListenerArn: string;
          Actions: JsonNode; Conditions: JsonNode; Priority: int;
          Action: string = "CreateRule"; Version: string = "2015-12-01"): Recallable =
  ## postCreateRule
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: string (required)
  ##   Priority: int (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Version: string (required)
  var query_603255 = newJObject()
  var formData_603256 = newJObject()
  add(formData_603256, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    formData_603256.add "Actions", Actions
  if Conditions != nil:
    formData_603256.add "Conditions", Conditions
  add(query_603255, "Action", newJString(Action))
  add(formData_603256, "Priority", newJInt(Priority))
  add(query_603255, "Version", newJString(Version))
  result = call_603254.call(nil, query_603255, nil, formData_603256, nil)

var postCreateRule* = Call_PostCreateRule_603237(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_603238,
    base: "/", url: url_PostCreateRule_603239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_603218 = ref object of OpenApiRestCall_602466
proc url_GetCreateRule_603220(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateRule_603219(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: JString (required)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Priority: JInt (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Conditions` field"
  var valid_603221 = query.getOrDefault("Conditions")
  valid_603221 = validateParameter(valid_603221, JArray, required = true, default = nil)
  if valid_603221 != nil:
    section.add "Conditions", valid_603221
  var valid_603222 = query.getOrDefault("Action")
  valid_603222 = validateParameter(valid_603222, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_603222 != nil:
    section.add "Action", valid_603222
  var valid_603223 = query.getOrDefault("ListenerArn")
  valid_603223 = validateParameter(valid_603223, JString, required = true,
                                 default = nil)
  if valid_603223 != nil:
    section.add "ListenerArn", valid_603223
  var valid_603224 = query.getOrDefault("Actions")
  valid_603224 = validateParameter(valid_603224, JArray, required = true, default = nil)
  if valid_603224 != nil:
    section.add "Actions", valid_603224
  var valid_603225 = query.getOrDefault("Priority")
  valid_603225 = validateParameter(valid_603225, JInt, required = true, default = nil)
  if valid_603225 != nil:
    section.add "Priority", valid_603225
  var valid_603226 = query.getOrDefault("Version")
  valid_603226 = validateParameter(valid_603226, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603226 != nil:
    section.add "Version", valid_603226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603227 = header.getOrDefault("X-Amz-Date")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Date", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Security-Token")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Security-Token", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Content-Sha256", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Algorithm")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Algorithm", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Signature")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Signature", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-SignedHeaders", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Credential")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Credential", valid_603233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_GetCreateRule_603218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_GetCreateRule_603218; Conditions: JsonNode;
          ListenerArn: string; Actions: JsonNode; Priority: int;
          Action: string = "CreateRule"; Version: string = "2015-12-01"): Recallable =
  ## getCreateRule
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ##   Conditions: JArray (required)
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Actions: JArray (required)
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Priority: int (required)
  ##           : The rule priority. A listener can't have multiple rules with the same priority.
  ##   Version: string (required)
  var query_603236 = newJObject()
  if Conditions != nil:
    query_603236.add "Conditions", Conditions
  add(query_603236, "Action", newJString(Action))
  add(query_603236, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    query_603236.add "Actions", Actions
  add(query_603236, "Priority", newJInt(Priority))
  add(query_603236, "Version", newJString(Version))
  result = call_603235.call(nil, query_603236, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_603218(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_603219,
    base: "/", url: url_GetCreateRule_603220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_603286 = ref object of OpenApiRestCall_602466
proc url_PostCreateTargetGroup_603288(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateTargetGroup_603287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603289 = query.getOrDefault("Action")
  valid_603289 = validateParameter(valid_603289, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_603289 != nil:
    section.add "Action", valid_603289
  var valid_603290 = query.getOrDefault("Version")
  valid_603290 = validateParameter(valid_603290, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603290 != nil:
    section.add "Version", valid_603290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603291 = header.getOrDefault("X-Amz-Date")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Date", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Security-Token")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Security-Token", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Content-Sha256", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Algorithm")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Algorithm", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Signature")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Signature", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-SignedHeaders", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Credential")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Credential", valid_603297
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   Port: JInt
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   Protocol: JString
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  ##   TargetType: JString
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   VpcId: JString
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   HealthCheckProtocol: JString
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_603298 = formData.getOrDefault("Name")
  valid_603298 = validateParameter(valid_603298, JString, required = true,
                                 default = nil)
  if valid_603298 != nil:
    section.add "Name", valid_603298
  var valid_603299 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_603299 = validateParameter(valid_603299, JInt, required = false, default = nil)
  if valid_603299 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_603299
  var valid_603300 = formData.getOrDefault("Port")
  valid_603300 = validateParameter(valid_603300, JInt, required = false, default = nil)
  if valid_603300 != nil:
    section.add "Port", valid_603300
  var valid_603301 = formData.getOrDefault("Protocol")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603301 != nil:
    section.add "Protocol", valid_603301
  var valid_603302 = formData.getOrDefault("HealthCheckPort")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "HealthCheckPort", valid_603302
  var valid_603303 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_603303 = validateParameter(valid_603303, JInt, required = false, default = nil)
  if valid_603303 != nil:
    section.add "UnhealthyThresholdCount", valid_603303
  var valid_603304 = formData.getOrDefault("HealthCheckEnabled")
  valid_603304 = validateParameter(valid_603304, JBool, required = false, default = nil)
  if valid_603304 != nil:
    section.add "HealthCheckEnabled", valid_603304
  var valid_603305 = formData.getOrDefault("HealthCheckPath")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "HealthCheckPath", valid_603305
  var valid_603306 = formData.getOrDefault("TargetType")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = newJString("instance"))
  if valid_603306 != nil:
    section.add "TargetType", valid_603306
  var valid_603307 = formData.getOrDefault("VpcId")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "VpcId", valid_603307
  var valid_603308 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_603308 = validateParameter(valid_603308, JInt, required = false, default = nil)
  if valid_603308 != nil:
    section.add "HealthCheckIntervalSeconds", valid_603308
  var valid_603309 = formData.getOrDefault("HealthyThresholdCount")
  valid_603309 = validateParameter(valid_603309, JInt, required = false, default = nil)
  if valid_603309 != nil:
    section.add "HealthyThresholdCount", valid_603309
  var valid_603310 = formData.getOrDefault("HealthCheckProtocol")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603310 != nil:
    section.add "HealthCheckProtocol", valid_603310
  var valid_603311 = formData.getOrDefault("Matcher.HttpCode")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "Matcher.HttpCode", valid_603311
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603312: Call_PostCreateTargetGroup_603286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603312.validator(path, query, header, formData, body)
  let scheme = call_603312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603312.url(scheme.get, call_603312.host, call_603312.base,
                         call_603312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603312, url, valid)

proc call*(call_603313: Call_PostCreateTargetGroup_603286; Name: string;
          HealthCheckTimeoutSeconds: int = 0; Port: int = 0; Protocol: string = "HTTP";
          HealthCheckPort: string = ""; UnhealthyThresholdCount: int = 0;
          HealthCheckEnabled: bool = false; HealthCheckPath: string = "";
          TargetType: string = "instance"; Action: string = "CreateTargetGroup";
          VpcId: string = ""; HealthCheckIntervalSeconds: int = 0;
          HealthyThresholdCount: int = 0; HealthCheckProtocol: string = "HTTP";
          MatcherHttpCode: string = ""; Version: string = "2015-12-01"): Recallable =
  ## postCreateTargetGroup
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Name: string (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  ##   HealthCheckTimeoutSeconds: int
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   Port: int
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   Protocol: string
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  ##   TargetType: string
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   Action: string (required)
  ##   VpcId: string
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   HealthCheckIntervalSeconds: int
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   HealthCheckProtocol: string
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   Version: string (required)
  var query_603314 = newJObject()
  var formData_603315 = newJObject()
  add(formData_603315, "Name", newJString(Name))
  add(formData_603315, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_603315, "Port", newJInt(Port))
  add(formData_603315, "Protocol", newJString(Protocol))
  add(formData_603315, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_603315, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_603315, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_603315, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_603315, "TargetType", newJString(TargetType))
  add(query_603314, "Action", newJString(Action))
  add(formData_603315, "VpcId", newJString(VpcId))
  add(formData_603315, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_603315, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_603315, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_603315, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_603314, "Version", newJString(Version))
  result = call_603313.call(nil, query_603314, nil, formData_603315, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_603286(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_603287, base: "/",
    url: url_PostCreateTargetGroup_603288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_603257 = ref object of OpenApiRestCall_602466
proc url_GetCreateTargetGroup_603259(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateTargetGroup_603258(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   Name: JString (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   Protocol: JString
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   VpcId: JString
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   Action: JString (required)
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   TargetType: JString
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   Port: JInt
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckProtocol: JString
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   Version: JString (required)
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  section = newJObject()
  var valid_603260 = query.getOrDefault("HealthCheckEnabled")
  valid_603260 = validateParameter(valid_603260, JBool, required = false, default = nil)
  if valid_603260 != nil:
    section.add "HealthCheckEnabled", valid_603260
  var valid_603261 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_603261 = validateParameter(valid_603261, JInt, required = false, default = nil)
  if valid_603261 != nil:
    section.add "HealthCheckIntervalSeconds", valid_603261
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_603262 = query.getOrDefault("Name")
  valid_603262 = validateParameter(valid_603262, JString, required = true,
                                 default = nil)
  if valid_603262 != nil:
    section.add "Name", valid_603262
  var valid_603263 = query.getOrDefault("HealthCheckPort")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "HealthCheckPort", valid_603263
  var valid_603264 = query.getOrDefault("Protocol")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603264 != nil:
    section.add "Protocol", valid_603264
  var valid_603265 = query.getOrDefault("VpcId")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "VpcId", valid_603265
  var valid_603266 = query.getOrDefault("Action")
  valid_603266 = validateParameter(valid_603266, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_603266 != nil:
    section.add "Action", valid_603266
  var valid_603267 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_603267 = validateParameter(valid_603267, JInt, required = false, default = nil)
  if valid_603267 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_603267
  var valid_603268 = query.getOrDefault("Matcher.HttpCode")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "Matcher.HttpCode", valid_603268
  var valid_603269 = query.getOrDefault("UnhealthyThresholdCount")
  valid_603269 = validateParameter(valid_603269, JInt, required = false, default = nil)
  if valid_603269 != nil:
    section.add "UnhealthyThresholdCount", valid_603269
  var valid_603270 = query.getOrDefault("TargetType")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = newJString("instance"))
  if valid_603270 != nil:
    section.add "TargetType", valid_603270
  var valid_603271 = query.getOrDefault("Port")
  valid_603271 = validateParameter(valid_603271, JInt, required = false, default = nil)
  if valid_603271 != nil:
    section.add "Port", valid_603271
  var valid_603272 = query.getOrDefault("HealthCheckProtocol")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603272 != nil:
    section.add "HealthCheckProtocol", valid_603272
  var valid_603273 = query.getOrDefault("HealthyThresholdCount")
  valid_603273 = validateParameter(valid_603273, JInt, required = false, default = nil)
  if valid_603273 != nil:
    section.add "HealthyThresholdCount", valid_603273
  var valid_603274 = query.getOrDefault("Version")
  valid_603274 = validateParameter(valid_603274, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603274 != nil:
    section.add "Version", valid_603274
  var valid_603275 = query.getOrDefault("HealthCheckPath")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "HealthCheckPath", valid_603275
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603276 = header.getOrDefault("X-Amz-Date")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Date", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Security-Token")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Security-Token", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Content-Sha256", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Algorithm")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Algorithm", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Signature")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Signature", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-SignedHeaders", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Credential")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Credential", valid_603282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603283: Call_GetCreateTargetGroup_603257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603283.validator(path, query, header, formData, body)
  let scheme = call_603283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603283.url(scheme.get, call_603283.host, call_603283.base,
                         call_603283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603283, url, valid)

proc call*(call_603284: Call_GetCreateTargetGroup_603257; Name: string;
          HealthCheckEnabled: bool = false; HealthCheckIntervalSeconds: int = 0;
          HealthCheckPort: string = ""; Protocol: string = "HTTP"; VpcId: string = "";
          Action: string = "CreateTargetGroup"; HealthCheckTimeoutSeconds: int = 0;
          MatcherHttpCode: string = ""; UnhealthyThresholdCount: int = 0;
          TargetType: string = "instance"; Port: int = 0;
          HealthCheckProtocol: string = "HTTP"; HealthyThresholdCount: int = 0;
          Version: string = "2015-12-01"; HealthCheckPath: string = ""): Recallable =
  ## getCreateTargetGroup
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled. If the target type is <code>lambda</code>, health checks are disabled by default but can be enabled. If the target type is <code>instance</code> or <code>ip</code>, health checks are always enabled and cannot be disabled.
  ##   HealthCheckIntervalSeconds: int
  ##                             : The approximate amount of time, in seconds, between health checks of an individual target. For HTTP and HTTPS health checks, the range is 5–300 seconds. For TCP health checks, the supported values are 10 and 30 seconds. If the target type is <code>instance</code> or <code>ip</code>, the default is 30 seconds. If the target type is <code>lambda</code>, the default is 35 seconds.
  ##   Name: string (required)
  ##       : <p>The name of the target group.</p> <p>This name must be unique per region per account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen.</p>
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets. The default is <code>traffic-port</code>, which is the port on which each target receives traffic from the load balancer.
  ##   Protocol: string
  ##           : The protocol to use for routing traffic to the targets. For Application Load Balancers, the supported protocols are HTTP and HTTPS. For Network Load Balancers, the supported protocols are TCP, TLS, UDP, or TCP_UDP. A TCP_UDP listener must be associated with a TCP_UDP target group. If the target is a Lambda function, this parameter does not apply.
  ##   VpcId: string
  ##        : The identifier of the virtual private cloud (VPC). If the target is a Lambda function, this parameter does not apply. Otherwise, this parameter is required.
  ##   Action: string (required)
  ##   HealthCheckTimeoutSeconds: int
  ##                            : The amount of time, in seconds, during which no response from a target means a failed health check. For target groups with a protocol of HTTP or HTTPS, the default is 5 seconds. For target groups with a protocol of TCP or TLS, this value must be 6 seconds for HTTP health checks and 10 seconds for TCP and HTTPS health checks. If the target type is <code>lambda</code>, the default is 30 seconds.
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering a target unhealthy. For target groups with a protocol of HTTP or HTTPS, the default is 2. For target groups with a protocol of TCP or TLS, this value must be the same as the healthy threshold count. If the target type is <code>lambda</code>, the default is 2.
  ##   TargetType: string
  ##             : <p>The type of target that you must specify when registering targets with this target group. You can't specify targets for a target group using more than one target type.</p> <ul> <li> <p> <code>instance</code> - Targets are specified by instance ID. This is the default value. If the target group protocol is UDP or TCP_UDP, the target type must be <code>instance</code>.</p> </li> <li> <p> <code>ip</code> - Targets are specified by IP address. You can specify IP addresses from the subnets of the virtual private cloud (VPC) for the target group, the RFC 1918 range (10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16), and the RFC 6598 range (100.64.0.0/10). You can't specify publicly routable IP addresses.</p> </li> <li> <p> <code>lambda</code> - The target groups contains a single Lambda function.</p> </li> </ul>
  ##   Port: int
  ##       : The port on which the targets receive traffic. This port is used unless you specify a port override when registering the target. If the target is a Lambda function, this parameter does not apply.
  ##   HealthCheckProtocol: string
  ##                      : The protocol the load balancer uses when performing health checks on targets. For Application Load Balancers, the default is HTTP. For Network Load Balancers, the default is TCP. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy. For target groups with a protocol of HTTP or HTTPS, the default is 5. For target groups with a protocol of TCP or TLS, the default is 3. If the target type is <code>lambda</code>, the default is 5.
  ##   Version: string (required)
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination on the targets for health checks. The default is /.
  var query_603285 = newJObject()
  add(query_603285, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_603285, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_603285, "Name", newJString(Name))
  add(query_603285, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_603285, "Protocol", newJString(Protocol))
  add(query_603285, "VpcId", newJString(VpcId))
  add(query_603285, "Action", newJString(Action))
  add(query_603285, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_603285, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_603285, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_603285, "TargetType", newJString(TargetType))
  add(query_603285, "Port", newJInt(Port))
  add(query_603285, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_603285, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_603285, "Version", newJString(Version))
  add(query_603285, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_603284.call(nil, query_603285, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_603257(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_603258,
    base: "/", url: url_GetCreateTargetGroup_603259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_603332 = ref object of OpenApiRestCall_602466
proc url_PostDeleteListener_603334(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteListener_603333(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603335 = query.getOrDefault("Action")
  valid_603335 = validateParameter(valid_603335, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_603335 != nil:
    section.add "Action", valid_603335
  var valid_603336 = query.getOrDefault("Version")
  valid_603336 = validateParameter(valid_603336, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603336 != nil:
    section.add "Version", valid_603336
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603337 = header.getOrDefault("X-Amz-Date")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Date", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Security-Token")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Security-Token", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Content-Sha256", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Algorithm")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Algorithm", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Signature")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Signature", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-SignedHeaders", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Credential")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Credential", valid_603343
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_603344 = formData.getOrDefault("ListenerArn")
  valid_603344 = validateParameter(valid_603344, JString, required = true,
                                 default = nil)
  if valid_603344 != nil:
    section.add "ListenerArn", valid_603344
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603345: Call_PostDeleteListener_603332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_603345.validator(path, query, header, formData, body)
  let scheme = call_603345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603345.url(scheme.get, call_603345.host, call_603345.base,
                         call_603345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603345, url, valid)

proc call*(call_603346: Call_PostDeleteListener_603332; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603347 = newJObject()
  var formData_603348 = newJObject()
  add(formData_603348, "ListenerArn", newJString(ListenerArn))
  add(query_603347, "Action", newJString(Action))
  add(query_603347, "Version", newJString(Version))
  result = call_603346.call(nil, query_603347, nil, formData_603348, nil)

var postDeleteListener* = Call_PostDeleteListener_603332(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_603333, base: "/",
    url: url_PostDeleteListener_603334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_603316 = ref object of OpenApiRestCall_602466
proc url_GetDeleteListener_603318(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteListener_603317(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603319 = query.getOrDefault("Action")
  valid_603319 = validateParameter(valid_603319, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_603319 != nil:
    section.add "Action", valid_603319
  var valid_603320 = query.getOrDefault("ListenerArn")
  valid_603320 = validateParameter(valid_603320, JString, required = true,
                                 default = nil)
  if valid_603320 != nil:
    section.add "ListenerArn", valid_603320
  var valid_603321 = query.getOrDefault("Version")
  valid_603321 = validateParameter(valid_603321, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603321 != nil:
    section.add "Version", valid_603321
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603322 = header.getOrDefault("X-Amz-Date")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Date", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Security-Token")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Security-Token", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Content-Sha256", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Algorithm")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Algorithm", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Signature")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Signature", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-SignedHeaders", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Credential")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Credential", valid_603328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603329: Call_GetDeleteListener_603316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_603329.validator(path, query, header, formData, body)
  let scheme = call_603329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603329.url(scheme.get, call_603329.host, call_603329.base,
                         call_603329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603329, url, valid)

proc call*(call_603330: Call_GetDeleteListener_603316; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  var query_603331 = newJObject()
  add(query_603331, "Action", newJString(Action))
  add(query_603331, "ListenerArn", newJString(ListenerArn))
  add(query_603331, "Version", newJString(Version))
  result = call_603330.call(nil, query_603331, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_603316(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_603317,
    base: "/", url: url_GetDeleteListener_603318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_603365 = ref object of OpenApiRestCall_602466
proc url_PostDeleteLoadBalancer_603367(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancer_603366(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603368 = query.getOrDefault("Action")
  valid_603368 = validateParameter(valid_603368, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_603368 != nil:
    section.add "Action", valid_603368
  var valid_603369 = query.getOrDefault("Version")
  valid_603369 = validateParameter(valid_603369, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603369 != nil:
    section.add "Version", valid_603369
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603370 = header.getOrDefault("X-Amz-Date")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Date", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Security-Token")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Security-Token", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Content-Sha256", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Algorithm")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Algorithm", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Signature")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Signature", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-SignedHeaders", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Credential")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Credential", valid_603376
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_603377 = formData.getOrDefault("LoadBalancerArn")
  valid_603377 = validateParameter(valid_603377, JString, required = true,
                                 default = nil)
  if valid_603377 != nil:
    section.add "LoadBalancerArn", valid_603377
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603378: Call_PostDeleteLoadBalancer_603365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_603378.validator(path, query, header, formData, body)
  let scheme = call_603378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603378.url(scheme.get, call_603378.host, call_603378.base,
                         call_603378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603378, url, valid)

proc call*(call_603379: Call_PostDeleteLoadBalancer_603365;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603380 = newJObject()
  var formData_603381 = newJObject()
  add(formData_603381, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603380, "Action", newJString(Action))
  add(query_603380, "Version", newJString(Version))
  result = call_603379.call(nil, query_603380, nil, formData_603381, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_603365(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_603366, base: "/",
    url: url_PostDeleteLoadBalancer_603367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_603349 = ref object of OpenApiRestCall_602466
proc url_GetDeleteLoadBalancer_603351(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancer_603350(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603352 = query.getOrDefault("Action")
  valid_603352 = validateParameter(valid_603352, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_603352 != nil:
    section.add "Action", valid_603352
  var valid_603353 = query.getOrDefault("LoadBalancerArn")
  valid_603353 = validateParameter(valid_603353, JString, required = true,
                                 default = nil)
  if valid_603353 != nil:
    section.add "LoadBalancerArn", valid_603353
  var valid_603354 = query.getOrDefault("Version")
  valid_603354 = validateParameter(valid_603354, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603354 != nil:
    section.add "Version", valid_603354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_603357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Content-Sha256", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Algorithm")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Algorithm", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Signature")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Signature", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-SignedHeaders", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Credential")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Credential", valid_603361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603362: Call_GetDeleteLoadBalancer_603349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_603362.validator(path, query, header, formData, body)
  let scheme = call_603362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603362.url(scheme.get, call_603362.host, call_603362.base,
                         call_603362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603362, url, valid)

proc call*(call_603363: Call_GetDeleteLoadBalancer_603349; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_603364 = newJObject()
  add(query_603364, "Action", newJString(Action))
  add(query_603364, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603364, "Version", newJString(Version))
  result = call_603363.call(nil, query_603364, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_603349(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_603350, base: "/",
    url: url_GetDeleteLoadBalancer_603351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_603398 = ref object of OpenApiRestCall_602466
proc url_PostDeleteRule_603400(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteRule_603399(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes the specified rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603401 = query.getOrDefault("Action")
  valid_603401 = validateParameter(valid_603401, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_603401 != nil:
    section.add "Action", valid_603401
  var valid_603402 = query.getOrDefault("Version")
  valid_603402 = validateParameter(valid_603402, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603402 != nil:
    section.add "Version", valid_603402
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603403 = header.getOrDefault("X-Amz-Date")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Date", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Security-Token")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Security-Token", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Content-Sha256", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Algorithm")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Algorithm", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Signature")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Signature", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-SignedHeaders", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Credential")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Credential", valid_603409
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_603410 = formData.getOrDefault("RuleArn")
  valid_603410 = validateParameter(valid_603410, JString, required = true,
                                 default = nil)
  if valid_603410 != nil:
    section.add "RuleArn", valid_603410
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603411: Call_PostDeleteRule_603398; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_603411.validator(path, query, header, formData, body)
  let scheme = call_603411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603411.url(scheme.get, call_603411.host, call_603411.base,
                         call_603411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603411, url, valid)

proc call*(call_603412: Call_PostDeleteRule_603398; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603413 = newJObject()
  var formData_603414 = newJObject()
  add(formData_603414, "RuleArn", newJString(RuleArn))
  add(query_603413, "Action", newJString(Action))
  add(query_603413, "Version", newJString(Version))
  result = call_603412.call(nil, query_603413, nil, formData_603414, nil)

var postDeleteRule* = Call_PostDeleteRule_603398(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_603399,
    base: "/", url: url_PostDeleteRule_603400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_603382 = ref object of OpenApiRestCall_602466
proc url_GetDeleteRule_603384(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteRule_603383(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603385 = query.getOrDefault("Action")
  valid_603385 = validateParameter(valid_603385, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_603385 != nil:
    section.add "Action", valid_603385
  var valid_603386 = query.getOrDefault("RuleArn")
  valid_603386 = validateParameter(valid_603386, JString, required = true,
                                 default = nil)
  if valid_603386 != nil:
    section.add "RuleArn", valid_603386
  var valid_603387 = query.getOrDefault("Version")
  valid_603387 = validateParameter(valid_603387, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603387 != nil:
    section.add "Version", valid_603387
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603388 = header.getOrDefault("X-Amz-Date")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Date", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Security-Token")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Security-Token", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Content-Sha256", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Algorithm")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Algorithm", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Signature")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Signature", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-SignedHeaders", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Credential")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Credential", valid_603394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603395: Call_GetDeleteRule_603382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_603395.validator(path, query, header, formData, body)
  let scheme = call_603395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603395.url(scheme.get, call_603395.host, call_603395.base,
                         call_603395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603395, url, valid)

proc call*(call_603396: Call_GetDeleteRule_603382; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   Action: string (required)
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Version: string (required)
  var query_603397 = newJObject()
  add(query_603397, "Action", newJString(Action))
  add(query_603397, "RuleArn", newJString(RuleArn))
  add(query_603397, "Version", newJString(Version))
  result = call_603396.call(nil, query_603397, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_603382(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_603383,
    base: "/", url: url_GetDeleteRule_603384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_603431 = ref object of OpenApiRestCall_602466
proc url_PostDeleteTargetGroup_603433(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteTargetGroup_603432(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603434 = query.getOrDefault("Action")
  valid_603434 = validateParameter(valid_603434, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_603434 != nil:
    section.add "Action", valid_603434
  var valid_603435 = query.getOrDefault("Version")
  valid_603435 = validateParameter(valid_603435, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603435 != nil:
    section.add "Version", valid_603435
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603436 = header.getOrDefault("X-Amz-Date")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Date", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Security-Token")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Security-Token", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Content-Sha256", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Algorithm")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Algorithm", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Signature")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Signature", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-SignedHeaders", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Credential")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Credential", valid_603442
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_603443 = formData.getOrDefault("TargetGroupArn")
  valid_603443 = validateParameter(valid_603443, JString, required = true,
                                 default = nil)
  if valid_603443 != nil:
    section.add "TargetGroupArn", valid_603443
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603444: Call_PostDeleteTargetGroup_603431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_603444.validator(path, query, header, formData, body)
  let scheme = call_603444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603444.url(scheme.get, call_603444.host, call_603444.base,
                         call_603444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603444, url, valid)

proc call*(call_603445: Call_PostDeleteTargetGroup_603431; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_603446 = newJObject()
  var formData_603447 = newJObject()
  add(query_603446, "Action", newJString(Action))
  add(formData_603447, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603446, "Version", newJString(Version))
  result = call_603445.call(nil, query_603446, nil, formData_603447, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_603431(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_603432, base: "/",
    url: url_PostDeleteTargetGroup_603433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_603415 = ref object of OpenApiRestCall_602466
proc url_GetDeleteTargetGroup_603417(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteTargetGroup_603416(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_603418 = query.getOrDefault("TargetGroupArn")
  valid_603418 = validateParameter(valid_603418, JString, required = true,
                                 default = nil)
  if valid_603418 != nil:
    section.add "TargetGroupArn", valid_603418
  var valid_603419 = query.getOrDefault("Action")
  valid_603419 = validateParameter(valid_603419, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_603419 != nil:
    section.add "Action", valid_603419
  var valid_603420 = query.getOrDefault("Version")
  valid_603420 = validateParameter(valid_603420, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603420 != nil:
    section.add "Version", valid_603420
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603421 = header.getOrDefault("X-Amz-Date")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Date", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Security-Token")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Security-Token", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Content-Sha256", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Algorithm")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Algorithm", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Signature")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Signature", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-SignedHeaders", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Credential")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Credential", valid_603427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603428: Call_GetDeleteTargetGroup_603415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_603428.validator(path, query, header, formData, body)
  let scheme = call_603428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603428.url(scheme.get, call_603428.host, call_603428.base,
                         call_603428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603428, url, valid)

proc call*(call_603429: Call_GetDeleteTargetGroup_603415; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603430 = newJObject()
  add(query_603430, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603430, "Action", newJString(Action))
  add(query_603430, "Version", newJString(Version))
  result = call_603429.call(nil, query_603430, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_603415(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_603416,
    base: "/", url: url_GetDeleteTargetGroup_603417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_603465 = ref object of OpenApiRestCall_602466
proc url_PostDeregisterTargets_603467(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeregisterTargets_603466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603468 = query.getOrDefault("Action")
  valid_603468 = validateParameter(valid_603468, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_603468 != nil:
    section.add "Action", valid_603468
  var valid_603469 = query.getOrDefault("Version")
  valid_603469 = validateParameter(valid_603469, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603469 != nil:
    section.add "Version", valid_603469
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603470 = header.getOrDefault("X-Amz-Date")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Date", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Security-Token")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Security-Token", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Content-Sha256", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Algorithm")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Algorithm", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Signature")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Signature", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-SignedHeaders", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Credential")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Credential", valid_603476
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_603477 = formData.getOrDefault("Targets")
  valid_603477 = validateParameter(valid_603477, JArray, required = true, default = nil)
  if valid_603477 != nil:
    section.add "Targets", valid_603477
  var valid_603478 = formData.getOrDefault("TargetGroupArn")
  valid_603478 = validateParameter(valid_603478, JString, required = true,
                                 default = nil)
  if valid_603478 != nil:
    section.add "TargetGroupArn", valid_603478
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603479: Call_PostDeregisterTargets_603465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_603479.validator(path, query, header, formData, body)
  let scheme = call_603479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603479.url(scheme.get, call_603479.host, call_603479.base,
                         call_603479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603479, url, valid)

proc call*(call_603480: Call_PostDeregisterTargets_603465; Targets: JsonNode;
          TargetGroupArn: string; Action: string = "DeregisterTargets";
          Version: string = "2015-12-01"): Recallable =
  ## postDeregisterTargets
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_603481 = newJObject()
  var formData_603482 = newJObject()
  if Targets != nil:
    formData_603482.add "Targets", Targets
  add(query_603481, "Action", newJString(Action))
  add(formData_603482, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603481, "Version", newJString(Version))
  result = call_603480.call(nil, query_603481, nil, formData_603482, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_603465(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_603466, base: "/",
    url: url_PostDeregisterTargets_603467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_603448 = ref object of OpenApiRestCall_602466
proc url_GetDeregisterTargets_603450(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeregisterTargets_603449(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Targets` field"
  var valid_603451 = query.getOrDefault("Targets")
  valid_603451 = validateParameter(valid_603451, JArray, required = true, default = nil)
  if valid_603451 != nil:
    section.add "Targets", valid_603451
  var valid_603452 = query.getOrDefault("TargetGroupArn")
  valid_603452 = validateParameter(valid_603452, JString, required = true,
                                 default = nil)
  if valid_603452 != nil:
    section.add "TargetGroupArn", valid_603452
  var valid_603453 = query.getOrDefault("Action")
  valid_603453 = validateParameter(valid_603453, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_603453 != nil:
    section.add "Action", valid_603453
  var valid_603454 = query.getOrDefault("Version")
  valid_603454 = validateParameter(valid_603454, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603454 != nil:
    section.add "Version", valid_603454
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603455 = header.getOrDefault("X-Amz-Date")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Date", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Security-Token")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Security-Token", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Content-Sha256", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Algorithm")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Algorithm", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Signature")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Signature", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-SignedHeaders", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Credential")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Credential", valid_603461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603462: Call_GetDeregisterTargets_603448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_603462.validator(path, query, header, formData, body)
  let scheme = call_603462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603462.url(scheme.get, call_603462.host, call_603462.base,
                         call_603462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603462, url, valid)

proc call*(call_603463: Call_GetDeregisterTargets_603448; Targets: JsonNode;
          TargetGroupArn: string; Action: string = "DeregisterTargets";
          Version: string = "2015-12-01"): Recallable =
  ## getDeregisterTargets
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603464 = newJObject()
  if Targets != nil:
    query_603464.add "Targets", Targets
  add(query_603464, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603464, "Action", newJString(Action))
  add(query_603464, "Version", newJString(Version))
  result = call_603463.call(nil, query_603464, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_603448(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_603449,
    base: "/", url: url_GetDeregisterTargets_603450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_603500 = ref object of OpenApiRestCall_602466
proc url_PostDescribeAccountLimits_603502(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAccountLimits_603501(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603503 = query.getOrDefault("Action")
  valid_603503 = validateParameter(valid_603503, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_603503 != nil:
    section.add "Action", valid_603503
  var valid_603504 = query.getOrDefault("Version")
  valid_603504 = validateParameter(valid_603504, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603504 != nil:
    section.add "Version", valid_603504
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603505 = header.getOrDefault("X-Amz-Date")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Date", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Security-Token")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Security-Token", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Content-Sha256", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Algorithm")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Algorithm", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Signature")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Signature", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-SignedHeaders", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Credential")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Credential", valid_603511
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_603512 = formData.getOrDefault("Marker")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "Marker", valid_603512
  var valid_603513 = formData.getOrDefault("PageSize")
  valid_603513 = validateParameter(valid_603513, JInt, required = false, default = nil)
  if valid_603513 != nil:
    section.add "PageSize", valid_603513
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603514: Call_PostDescribeAccountLimits_603500; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603514.validator(path, query, header, formData, body)
  let scheme = call_603514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603514.url(scheme.get, call_603514.host, call_603514.base,
                         call_603514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603514, url, valid)

proc call*(call_603515: Call_PostDescribeAccountLimits_603500; Marker: string = "";
          Action: string = "DescribeAccountLimits"; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_603516 = newJObject()
  var formData_603517 = newJObject()
  add(formData_603517, "Marker", newJString(Marker))
  add(query_603516, "Action", newJString(Action))
  add(formData_603517, "PageSize", newJInt(PageSize))
  add(query_603516, "Version", newJString(Version))
  result = call_603515.call(nil, query_603516, nil, formData_603517, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_603500(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_603501, base: "/",
    url: url_PostDescribeAccountLimits_603502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_603483 = ref object of OpenApiRestCall_602466
proc url_GetDescribeAccountLimits_603485(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAccountLimits_603484(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603486 = query.getOrDefault("PageSize")
  valid_603486 = validateParameter(valid_603486, JInt, required = false, default = nil)
  if valid_603486 != nil:
    section.add "PageSize", valid_603486
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603487 = query.getOrDefault("Action")
  valid_603487 = validateParameter(valid_603487, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_603487 != nil:
    section.add "Action", valid_603487
  var valid_603488 = query.getOrDefault("Marker")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "Marker", valid_603488
  var valid_603489 = query.getOrDefault("Version")
  valid_603489 = validateParameter(valid_603489, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603489 != nil:
    section.add "Version", valid_603489
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603490 = header.getOrDefault("X-Amz-Date")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Date", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Security-Token")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Security-Token", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Content-Sha256", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Algorithm")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Algorithm", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Signature")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Signature", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-SignedHeaders", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Credential")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Credential", valid_603496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603497: Call_GetDescribeAccountLimits_603483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603497.validator(path, query, header, formData, body)
  let scheme = call_603497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603497.url(scheme.get, call_603497.host, call_603497.base,
                         call_603497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603497, url, valid)

proc call*(call_603498: Call_GetDescribeAccountLimits_603483; PageSize: int = 0;
          Action: string = "DescribeAccountLimits"; Marker: string = "";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: string (required)
  var query_603499 = newJObject()
  add(query_603499, "PageSize", newJInt(PageSize))
  add(query_603499, "Action", newJString(Action))
  add(query_603499, "Marker", newJString(Marker))
  add(query_603499, "Version", newJString(Version))
  result = call_603498.call(nil, query_603499, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_603483(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_603484, base: "/",
    url: url_GetDescribeAccountLimits_603485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_603536 = ref object of OpenApiRestCall_602466
proc url_PostDescribeListenerCertificates_603538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeListenerCertificates_603537(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603539 = query.getOrDefault("Action")
  valid_603539 = validateParameter(valid_603539, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_603539 != nil:
    section.add "Action", valid_603539
  var valid_603540 = query.getOrDefault("Version")
  valid_603540 = validateParameter(valid_603540, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603540 != nil:
    section.add "Version", valid_603540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603541 = header.getOrDefault("X-Amz-Date")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Date", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Security-Token")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Security-Token", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Content-Sha256", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Algorithm")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Algorithm", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Signature")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Signature", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-SignedHeaders", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Credential")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Credential", valid_603547
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Names (ARN) of the listener.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_603548 = formData.getOrDefault("ListenerArn")
  valid_603548 = validateParameter(valid_603548, JString, required = true,
                                 default = nil)
  if valid_603548 != nil:
    section.add "ListenerArn", valid_603548
  var valid_603549 = formData.getOrDefault("Marker")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "Marker", valid_603549
  var valid_603550 = formData.getOrDefault("PageSize")
  valid_603550 = validateParameter(valid_603550, JInt, required = false, default = nil)
  if valid_603550 != nil:
    section.add "PageSize", valid_603550
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603551: Call_PostDescribeListenerCertificates_603536;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603551.validator(path, query, header, formData, body)
  let scheme = call_603551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603551.url(scheme.get, call_603551.host, call_603551.base,
                         call_603551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603551, url, valid)

proc call*(call_603552: Call_PostDescribeListenerCertificates_603536;
          ListenerArn: string; Marker: string = "";
          Action: string = "DescribeListenerCertificates"; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeListenerCertificates
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Names (ARN) of the listener.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_603553 = newJObject()
  var formData_603554 = newJObject()
  add(formData_603554, "ListenerArn", newJString(ListenerArn))
  add(formData_603554, "Marker", newJString(Marker))
  add(query_603553, "Action", newJString(Action))
  add(formData_603554, "PageSize", newJInt(PageSize))
  add(query_603553, "Version", newJString(Version))
  result = call_603552.call(nil, query_603553, nil, formData_603554, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_603536(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_603537, base: "/",
    url: url_PostDescribeListenerCertificates_603538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_603518 = ref object of OpenApiRestCall_602466
proc url_GetDescribeListenerCertificates_603520(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeListenerCertificates_603519(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Names (ARN) of the listener.
  ##   Version: JString (required)
  section = newJObject()
  var valid_603521 = query.getOrDefault("PageSize")
  valid_603521 = validateParameter(valid_603521, JInt, required = false, default = nil)
  if valid_603521 != nil:
    section.add "PageSize", valid_603521
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603522 = query.getOrDefault("Action")
  valid_603522 = validateParameter(valid_603522, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_603522 != nil:
    section.add "Action", valid_603522
  var valid_603523 = query.getOrDefault("Marker")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "Marker", valid_603523
  var valid_603524 = query.getOrDefault("ListenerArn")
  valid_603524 = validateParameter(valid_603524, JString, required = true,
                                 default = nil)
  if valid_603524 != nil:
    section.add "ListenerArn", valid_603524
  var valid_603525 = query.getOrDefault("Version")
  valid_603525 = validateParameter(valid_603525, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603525 != nil:
    section.add "Version", valid_603525
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603526 = header.getOrDefault("X-Amz-Date")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Date", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Security-Token")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Security-Token", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Content-Sha256", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Algorithm")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Algorithm", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Signature")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Signature", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-SignedHeaders", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Credential")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Credential", valid_603532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603533: Call_GetDescribeListenerCertificates_603518;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603533.validator(path, query, header, formData, body)
  let scheme = call_603533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603533.url(scheme.get, call_603533.host, call_603533.base,
                         call_603533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603533, url, valid)

proc call*(call_603534: Call_GetDescribeListenerCertificates_603518;
          ListenerArn: string; PageSize: int = 0;
          Action: string = "DescribeListenerCertificates"; Marker: string = "";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeListenerCertificates
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Names (ARN) of the listener.
  ##   Version: string (required)
  var query_603535 = newJObject()
  add(query_603535, "PageSize", newJInt(PageSize))
  add(query_603535, "Action", newJString(Action))
  add(query_603535, "Marker", newJString(Marker))
  add(query_603535, "ListenerArn", newJString(ListenerArn))
  add(query_603535, "Version", newJString(Version))
  result = call_603534.call(nil, query_603535, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_603518(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_603519, base: "/",
    url: url_GetDescribeListenerCertificates_603520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_603574 = ref object of OpenApiRestCall_602466
proc url_PostDescribeListeners_603576(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeListeners_603575(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603577 = query.getOrDefault("Action")
  valid_603577 = validateParameter(valid_603577, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_603577 != nil:
    section.add "Action", valid_603577
  var valid_603578 = query.getOrDefault("Version")
  valid_603578 = validateParameter(valid_603578, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603578 != nil:
    section.add "Version", valid_603578
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603579 = header.getOrDefault("X-Amz-Date")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Date", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Security-Token")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Security-Token", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Content-Sha256", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Algorithm")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Algorithm", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Signature")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Signature", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-SignedHeaders", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Credential")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Credential", valid_603585
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  section = newJObject()
  var valid_603586 = formData.getOrDefault("LoadBalancerArn")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "LoadBalancerArn", valid_603586
  var valid_603587 = formData.getOrDefault("Marker")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "Marker", valid_603587
  var valid_603588 = formData.getOrDefault("PageSize")
  valid_603588 = validateParameter(valid_603588, JInt, required = false, default = nil)
  if valid_603588 != nil:
    section.add "PageSize", valid_603588
  var valid_603589 = formData.getOrDefault("ListenerArns")
  valid_603589 = validateParameter(valid_603589, JArray, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "ListenerArns", valid_603589
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603590: Call_PostDescribeListeners_603574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_603590.validator(path, query, header, formData, body)
  let scheme = call_603590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603590.url(scheme.get, call_603590.host, call_603590.base,
                         call_603590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603590, url, valid)

proc call*(call_603591: Call_PostDescribeListeners_603574;
          LoadBalancerArn: string = ""; Marker: string = "";
          Action: string = "DescribeListeners"; PageSize: int = 0;
          ListenerArns: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## postDescribeListeners
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  ##   Version: string (required)
  var query_603592 = newJObject()
  var formData_603593 = newJObject()
  add(formData_603593, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_603593, "Marker", newJString(Marker))
  add(query_603592, "Action", newJString(Action))
  add(formData_603593, "PageSize", newJInt(PageSize))
  if ListenerArns != nil:
    formData_603593.add "ListenerArns", ListenerArns
  add(query_603592, "Version", newJString(Version))
  result = call_603591.call(nil, query_603592, nil, formData_603593, nil)

var postDescribeListeners* = Call_PostDescribeListeners_603574(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_603575, base: "/",
    url: url_PostDescribeListeners_603576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_603555 = ref object of OpenApiRestCall_602466
proc url_GetDescribeListeners_603557(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeListeners_603556(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  var valid_603558 = query.getOrDefault("ListenerArns")
  valid_603558 = validateParameter(valid_603558, JArray, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "ListenerArns", valid_603558
  var valid_603559 = query.getOrDefault("PageSize")
  valid_603559 = validateParameter(valid_603559, JInt, required = false, default = nil)
  if valid_603559 != nil:
    section.add "PageSize", valid_603559
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603560 = query.getOrDefault("Action")
  valid_603560 = validateParameter(valid_603560, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_603560 != nil:
    section.add "Action", valid_603560
  var valid_603561 = query.getOrDefault("Marker")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "Marker", valid_603561
  var valid_603562 = query.getOrDefault("LoadBalancerArn")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "LoadBalancerArn", valid_603562
  var valid_603563 = query.getOrDefault("Version")
  valid_603563 = validateParameter(valid_603563, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603563 != nil:
    section.add "Version", valid_603563
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603564 = header.getOrDefault("X-Amz-Date")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Date", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Security-Token")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Security-Token", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Content-Sha256", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Algorithm")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Algorithm", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Signature")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Signature", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-SignedHeaders", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Credential")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Credential", valid_603570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603571: Call_GetDescribeListeners_603555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_603571.validator(path, query, header, formData, body)
  let scheme = call_603571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603571.url(scheme.get, call_603571.host, call_603571.base,
                         call_603571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603571, url, valid)

proc call*(call_603572: Call_GetDescribeListeners_603555;
          ListenerArns: JsonNode = nil; PageSize: int = 0;
          Action: string = "DescribeListeners"; Marker: string = "";
          LoadBalancerArn: string = ""; Version: string = "2015-12-01"): Recallable =
  ## getDescribeListeners
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ##   ListenerArns: JArray
  ##               : The Amazon Resource Names (ARN) of the listeners.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_603573 = newJObject()
  if ListenerArns != nil:
    query_603573.add "ListenerArns", ListenerArns
  add(query_603573, "PageSize", newJInt(PageSize))
  add(query_603573, "Action", newJString(Action))
  add(query_603573, "Marker", newJString(Marker))
  add(query_603573, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603573, "Version", newJString(Version))
  result = call_603572.call(nil, query_603573, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_603555(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_603556,
    base: "/", url: url_GetDescribeListeners_603557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_603610 = ref object of OpenApiRestCall_602466
proc url_PostDescribeLoadBalancerAttributes_603612(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_603611(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603613 = query.getOrDefault("Action")
  valid_603613 = validateParameter(valid_603613, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_603613 != nil:
    section.add "Action", valid_603613
  var valid_603614 = query.getOrDefault("Version")
  valid_603614 = validateParameter(valid_603614, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603614 != nil:
    section.add "Version", valid_603614
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603615 = header.getOrDefault("X-Amz-Date")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Date", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Security-Token")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Security-Token", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Content-Sha256", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Algorithm")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Algorithm", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Signature")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Signature", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-SignedHeaders", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Credential")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Credential", valid_603621
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_603622 = formData.getOrDefault("LoadBalancerArn")
  valid_603622 = validateParameter(valid_603622, JString, required = true,
                                 default = nil)
  if valid_603622 != nil:
    section.add "LoadBalancerArn", valid_603622
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603623: Call_PostDescribeLoadBalancerAttributes_603610;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603623.validator(path, query, header, formData, body)
  let scheme = call_603623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603623.url(scheme.get, call_603623.host, call_603623.base,
                         call_603623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603623, url, valid)

proc call*(call_603624: Call_PostDescribeLoadBalancerAttributes_603610;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603625 = newJObject()
  var formData_603626 = newJObject()
  add(formData_603626, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603625, "Action", newJString(Action))
  add(query_603625, "Version", newJString(Version))
  result = call_603624.call(nil, query_603625, nil, formData_603626, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_603610(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_603611, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_603612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_603594 = ref object of OpenApiRestCall_602466
proc url_GetDescribeLoadBalancerAttributes_603596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_603595(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603597 = query.getOrDefault("Action")
  valid_603597 = validateParameter(valid_603597, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_603597 != nil:
    section.add "Action", valid_603597
  var valid_603598 = query.getOrDefault("LoadBalancerArn")
  valid_603598 = validateParameter(valid_603598, JString, required = true,
                                 default = nil)
  if valid_603598 != nil:
    section.add "LoadBalancerArn", valid_603598
  var valid_603599 = query.getOrDefault("Version")
  valid_603599 = validateParameter(valid_603599, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603599 != nil:
    section.add "Version", valid_603599
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603600 = header.getOrDefault("X-Amz-Date")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Date", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Security-Token")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Security-Token", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Content-Sha256", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Algorithm")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Algorithm", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Signature")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Signature", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-SignedHeaders", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Credential")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Credential", valid_603606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603607: Call_GetDescribeLoadBalancerAttributes_603594;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603607.validator(path, query, header, formData, body)
  let scheme = call_603607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603607.url(scheme.get, call_603607.host, call_603607.base,
                         call_603607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603607, url, valid)

proc call*(call_603608: Call_GetDescribeLoadBalancerAttributes_603594;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_603609 = newJObject()
  add(query_603609, "Action", newJString(Action))
  add(query_603609, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603609, "Version", newJString(Version))
  result = call_603608.call(nil, query_603609, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_603594(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_603595, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_603596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_603646 = ref object of OpenApiRestCall_602466
proc url_PostDescribeLoadBalancers_603648(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancers_603647(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603649 = query.getOrDefault("Action")
  valid_603649 = validateParameter(valid_603649, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_603649 != nil:
    section.add "Action", valid_603649
  var valid_603650 = query.getOrDefault("Version")
  valid_603650 = validateParameter(valid_603650, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603650 != nil:
    section.add "Version", valid_603650
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603651 = header.getOrDefault("X-Amz-Date")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Date", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Security-Token")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Security-Token", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Content-Sha256", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Algorithm")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Algorithm", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Signature")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Signature", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-SignedHeaders", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Credential")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Credential", valid_603657
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the load balancers.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_603658 = formData.getOrDefault("Names")
  valid_603658 = validateParameter(valid_603658, JArray, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "Names", valid_603658
  var valid_603659 = formData.getOrDefault("Marker")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "Marker", valid_603659
  var valid_603660 = formData.getOrDefault("LoadBalancerArns")
  valid_603660 = validateParameter(valid_603660, JArray, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "LoadBalancerArns", valid_603660
  var valid_603661 = formData.getOrDefault("PageSize")
  valid_603661 = validateParameter(valid_603661, JInt, required = false, default = nil)
  if valid_603661 != nil:
    section.add "PageSize", valid_603661
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603662: Call_PostDescribeLoadBalancers_603646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_603662.validator(path, query, header, formData, body)
  let scheme = call_603662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603662.url(scheme.get, call_603662.host, call_603662.base,
                         call_603662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603662, url, valid)

proc call*(call_603663: Call_PostDescribeLoadBalancers_603646;
          Names: JsonNode = nil; Marker: string = "";
          Action: string = "DescribeLoadBalancers";
          LoadBalancerArns: JsonNode = nil; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancers
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ##   Names: JArray
  ##        : The names of the load balancers.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_603664 = newJObject()
  var formData_603665 = newJObject()
  if Names != nil:
    formData_603665.add "Names", Names
  add(formData_603665, "Marker", newJString(Marker))
  add(query_603664, "Action", newJString(Action))
  if LoadBalancerArns != nil:
    formData_603665.add "LoadBalancerArns", LoadBalancerArns
  add(formData_603665, "PageSize", newJInt(PageSize))
  add(query_603664, "Version", newJString(Version))
  result = call_603663.call(nil, query_603664, nil, formData_603665, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_603646(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_603647, base: "/",
    url: url_PostDescribeLoadBalancers_603648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_603627 = ref object of OpenApiRestCall_602466
proc url_GetDescribeLoadBalancers_603629(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancers_603628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Names: JArray
  ##        : The names of the load balancers.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603630 = query.getOrDefault("Names")
  valid_603630 = validateParameter(valid_603630, JArray, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "Names", valid_603630
  var valid_603631 = query.getOrDefault("PageSize")
  valid_603631 = validateParameter(valid_603631, JInt, required = false, default = nil)
  if valid_603631 != nil:
    section.add "PageSize", valid_603631
  var valid_603632 = query.getOrDefault("LoadBalancerArns")
  valid_603632 = validateParameter(valid_603632, JArray, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "LoadBalancerArns", valid_603632
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603633 = query.getOrDefault("Action")
  valid_603633 = validateParameter(valid_603633, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_603633 != nil:
    section.add "Action", valid_603633
  var valid_603634 = query.getOrDefault("Marker")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "Marker", valid_603634
  var valid_603635 = query.getOrDefault("Version")
  valid_603635 = validateParameter(valid_603635, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603635 != nil:
    section.add "Version", valid_603635
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603636 = header.getOrDefault("X-Amz-Date")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Date", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Security-Token")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Security-Token", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Content-Sha256", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-Algorithm")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Algorithm", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Signature")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Signature", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-SignedHeaders", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Credential")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Credential", valid_603642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603643: Call_GetDescribeLoadBalancers_603627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_603643.validator(path, query, header, formData, body)
  let scheme = call_603643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603643.url(scheme.get, call_603643.host, call_603643.base,
                         call_603643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603643, url, valid)

proc call*(call_603644: Call_GetDescribeLoadBalancers_603627;
          Names: JsonNode = nil; PageSize: int = 0; LoadBalancerArns: JsonNode = nil;
          Action: string = "DescribeLoadBalancers"; Marker: string = "";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancers
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ##   Names: JArray
  ##        : The names of the load balancers.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   LoadBalancerArns: JArray
  ##                   : The Amazon Resource Names (ARN) of the load balancers. You can specify up to 20 load balancers in a single call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: string (required)
  var query_603645 = newJObject()
  if Names != nil:
    query_603645.add "Names", Names
  add(query_603645, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_603645.add "LoadBalancerArns", LoadBalancerArns
  add(query_603645, "Action", newJString(Action))
  add(query_603645, "Marker", newJString(Marker))
  add(query_603645, "Version", newJString(Version))
  result = call_603644.call(nil, query_603645, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_603627(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_603628, base: "/",
    url: url_GetDescribeLoadBalancers_603629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_603685 = ref object of OpenApiRestCall_602466
proc url_PostDescribeRules_603687(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeRules_603686(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603688 = query.getOrDefault("Action")
  valid_603688 = validateParameter(valid_603688, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_603688 != nil:
    section.add "Action", valid_603688
  var valid_603689 = query.getOrDefault("Version")
  valid_603689 = validateParameter(valid_603689, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603689 != nil:
    section.add "Version", valid_603689
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603690 = header.getOrDefault("X-Amz-Date")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Date", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Security-Token")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Security-Token", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Content-Sha256", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Algorithm")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Algorithm", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Signature")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Signature", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-SignedHeaders", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-Credential")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Credential", valid_603696
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_603697 = formData.getOrDefault("ListenerArn")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "ListenerArn", valid_603697
  var valid_603698 = formData.getOrDefault("RuleArns")
  valid_603698 = validateParameter(valid_603698, JArray, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "RuleArns", valid_603698
  var valid_603699 = formData.getOrDefault("Marker")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "Marker", valid_603699
  var valid_603700 = formData.getOrDefault("PageSize")
  valid_603700 = validateParameter(valid_603700, JInt, required = false, default = nil)
  if valid_603700 != nil:
    section.add "PageSize", valid_603700
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603701: Call_PostDescribeRules_603685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_603701.validator(path, query, header, formData, body)
  let scheme = call_603701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603701.url(scheme.get, call_603701.host, call_603701.base,
                         call_603701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603701, url, valid)

proc call*(call_603702: Call_PostDescribeRules_603685; ListenerArn: string = "";
          RuleArns: JsonNode = nil; Marker: string = "";
          Action: string = "DescribeRules"; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeRules
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ##   ListenerArn: string
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_603703 = newJObject()
  var formData_603704 = newJObject()
  add(formData_603704, "ListenerArn", newJString(ListenerArn))
  if RuleArns != nil:
    formData_603704.add "RuleArns", RuleArns
  add(formData_603704, "Marker", newJString(Marker))
  add(query_603703, "Action", newJString(Action))
  add(formData_603704, "PageSize", newJInt(PageSize))
  add(query_603703, "Version", newJString(Version))
  result = call_603702.call(nil, query_603703, nil, formData_603704, nil)

var postDescribeRules* = Call_PostDescribeRules_603685(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_603686,
    base: "/", url: url_PostDescribeRules_603687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_603666 = ref object of OpenApiRestCall_602466
proc url_GetDescribeRules_603668(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeRules_603667(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: JString
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: JString (required)
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  section = newJObject()
  var valid_603669 = query.getOrDefault("PageSize")
  valid_603669 = validateParameter(valid_603669, JInt, required = false, default = nil)
  if valid_603669 != nil:
    section.add "PageSize", valid_603669
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603670 = query.getOrDefault("Action")
  valid_603670 = validateParameter(valid_603670, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_603670 != nil:
    section.add "Action", valid_603670
  var valid_603671 = query.getOrDefault("Marker")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "Marker", valid_603671
  var valid_603672 = query.getOrDefault("ListenerArn")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "ListenerArn", valid_603672
  var valid_603673 = query.getOrDefault("Version")
  valid_603673 = validateParameter(valid_603673, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603673 != nil:
    section.add "Version", valid_603673
  var valid_603674 = query.getOrDefault("RuleArns")
  valid_603674 = validateParameter(valid_603674, JArray, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "RuleArns", valid_603674
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603675 = header.getOrDefault("X-Amz-Date")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Date", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Security-Token")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Security-Token", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Content-Sha256", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Algorithm")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Algorithm", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-Signature")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Signature", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-SignedHeaders", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-Credential")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-Credential", valid_603681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603682: Call_GetDescribeRules_603666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_603682.validator(path, query, header, formData, body)
  let scheme = call_603682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603682.url(scheme.get, call_603682.host, call_603682.base,
                         call_603682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603682, url, valid)

proc call*(call_603683: Call_GetDescribeRules_603666; PageSize: int = 0;
          Action: string = "DescribeRules"; Marker: string = "";
          ListenerArn: string = ""; Version: string = "2015-12-01";
          RuleArns: JsonNode = nil): Recallable =
  ## getDescribeRules
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   ListenerArn: string
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  ##   RuleArns: JArray
  ##           : The Amazon Resource Names (ARN) of the rules.
  var query_603684 = newJObject()
  add(query_603684, "PageSize", newJInt(PageSize))
  add(query_603684, "Action", newJString(Action))
  add(query_603684, "Marker", newJString(Marker))
  add(query_603684, "ListenerArn", newJString(ListenerArn))
  add(query_603684, "Version", newJString(Version))
  if RuleArns != nil:
    query_603684.add "RuleArns", RuleArns
  result = call_603683.call(nil, query_603684, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_603666(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_603667,
    base: "/", url: url_GetDescribeRules_603668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_603723 = ref object of OpenApiRestCall_602466
proc url_PostDescribeSSLPolicies_603725(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeSSLPolicies_603724(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603726 = query.getOrDefault("Action")
  valid_603726 = validateParameter(valid_603726, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_603726 != nil:
    section.add "Action", valid_603726
  var valid_603727 = query.getOrDefault("Version")
  valid_603727 = validateParameter(valid_603727, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603727 != nil:
    section.add "Version", valid_603727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603728 = header.getOrDefault("X-Amz-Date")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Date", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Security-Token")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Security-Token", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Content-Sha256", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Algorithm")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Algorithm", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Signature")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Signature", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-SignedHeaders", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Credential")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Credential", valid_603734
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_603735 = formData.getOrDefault("Names")
  valid_603735 = validateParameter(valid_603735, JArray, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "Names", valid_603735
  var valid_603736 = formData.getOrDefault("Marker")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "Marker", valid_603736
  var valid_603737 = formData.getOrDefault("PageSize")
  valid_603737 = validateParameter(valid_603737, JInt, required = false, default = nil)
  if valid_603737 != nil:
    section.add "PageSize", valid_603737
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603738: Call_PostDescribeSSLPolicies_603723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603738.validator(path, query, header, formData, body)
  let scheme = call_603738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603738.url(scheme.get, call_603738.host, call_603738.base,
                         call_603738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603738, url, valid)

proc call*(call_603739: Call_PostDescribeSSLPolicies_603723; Names: JsonNode = nil;
          Marker: string = ""; Action: string = "DescribeSSLPolicies";
          PageSize: int = 0; Version: string = "2015-12-01"): Recallable =
  ## postDescribeSSLPolicies
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_603740 = newJObject()
  var formData_603741 = newJObject()
  if Names != nil:
    formData_603741.add "Names", Names
  add(formData_603741, "Marker", newJString(Marker))
  add(query_603740, "Action", newJString(Action))
  add(formData_603741, "PageSize", newJInt(PageSize))
  add(query_603740, "Version", newJString(Version))
  result = call_603739.call(nil, query_603740, nil, formData_603741, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_603723(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_603724, base: "/",
    url: url_PostDescribeSSLPolicies_603725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_603705 = ref object of OpenApiRestCall_602466
proc url_GetDescribeSSLPolicies_603707(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeSSLPolicies_603706(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603708 = query.getOrDefault("Names")
  valid_603708 = validateParameter(valid_603708, JArray, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "Names", valid_603708
  var valid_603709 = query.getOrDefault("PageSize")
  valid_603709 = validateParameter(valid_603709, JInt, required = false, default = nil)
  if valid_603709 != nil:
    section.add "PageSize", valid_603709
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603710 = query.getOrDefault("Action")
  valid_603710 = validateParameter(valid_603710, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_603710 != nil:
    section.add "Action", valid_603710
  var valid_603711 = query.getOrDefault("Marker")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "Marker", valid_603711
  var valid_603712 = query.getOrDefault("Version")
  valid_603712 = validateParameter(valid_603712, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603712 != nil:
    section.add "Version", valid_603712
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603713 = header.getOrDefault("X-Amz-Date")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Date", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-Security-Token")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-Security-Token", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Content-Sha256", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Algorithm")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Algorithm", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Signature")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Signature", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-SignedHeaders", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Credential")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Credential", valid_603719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603720: Call_GetDescribeSSLPolicies_603705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603720.validator(path, query, header, formData, body)
  let scheme = call_603720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603720.url(scheme.get, call_603720.host, call_603720.base,
                         call_603720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603720, url, valid)

proc call*(call_603721: Call_GetDescribeSSLPolicies_603705; Names: JsonNode = nil;
          PageSize: int = 0; Action: string = "DescribeSSLPolicies";
          Marker: string = ""; Version: string = "2015-12-01"): Recallable =
  ## getDescribeSSLPolicies
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ##   Names: JArray
  ##        : The names of the policies.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: string (required)
  var query_603722 = newJObject()
  if Names != nil:
    query_603722.add "Names", Names
  add(query_603722, "PageSize", newJInt(PageSize))
  add(query_603722, "Action", newJString(Action))
  add(query_603722, "Marker", newJString(Marker))
  add(query_603722, "Version", newJString(Version))
  result = call_603721.call(nil, query_603722, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_603705(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_603706, base: "/",
    url: url_GetDescribeSSLPolicies_603707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_603758 = ref object of OpenApiRestCall_602466
proc url_PostDescribeTags_603760(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTags_603759(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603761 = query.getOrDefault("Action")
  valid_603761 = validateParameter(valid_603761, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_603761 != nil:
    section.add "Action", valid_603761
  var valid_603762 = query.getOrDefault("Version")
  valid_603762 = validateParameter(valid_603762, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603762 != nil:
    section.add "Version", valid_603762
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603763 = header.getOrDefault("X-Amz-Date")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Date", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-Security-Token")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Security-Token", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Content-Sha256", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Algorithm")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Algorithm", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Signature")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Signature", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-SignedHeaders", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Credential")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Credential", valid_603769
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_603770 = formData.getOrDefault("ResourceArns")
  valid_603770 = validateParameter(valid_603770, JArray, required = true, default = nil)
  if valid_603770 != nil:
    section.add "ResourceArns", valid_603770
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603771: Call_PostDescribeTags_603758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_603771.validator(path, query, header, formData, body)
  let scheme = call_603771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603771.url(scheme.get, call_603771.host, call_603771.base,
                         call_603771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603771, url, valid)

proc call*(call_603772: Call_PostDescribeTags_603758; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603773 = newJObject()
  var formData_603774 = newJObject()
  if ResourceArns != nil:
    formData_603774.add "ResourceArns", ResourceArns
  add(query_603773, "Action", newJString(Action))
  add(query_603773, "Version", newJString(Version))
  result = call_603772.call(nil, query_603773, nil, formData_603774, nil)

var postDescribeTags* = Call_PostDescribeTags_603758(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_603759,
    base: "/", url: url_PostDescribeTags_603760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_603742 = ref object of OpenApiRestCall_602466
proc url_GetDescribeTags_603744(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTags_603743(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603745 = query.getOrDefault("Action")
  valid_603745 = validateParameter(valid_603745, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_603745 != nil:
    section.add "Action", valid_603745
  var valid_603746 = query.getOrDefault("ResourceArns")
  valid_603746 = validateParameter(valid_603746, JArray, required = true, default = nil)
  if valid_603746 != nil:
    section.add "ResourceArns", valid_603746
  var valid_603747 = query.getOrDefault("Version")
  valid_603747 = validateParameter(valid_603747, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603747 != nil:
    section.add "Version", valid_603747
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603748 = header.getOrDefault("X-Amz-Date")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Date", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Security-Token")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Security-Token", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Content-Sha256", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Algorithm")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Algorithm", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Signature")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Signature", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-SignedHeaders", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Credential")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Credential", valid_603754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603755: Call_GetDescribeTags_603742; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_603755.validator(path, query, header, formData, body)
  let scheme = call_603755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603755.url(scheme.get, call_603755.host, call_603755.base,
                         call_603755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603755, url, valid)

proc call*(call_603756: Call_GetDescribeTags_603742; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   Action: string (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Version: string (required)
  var query_603757 = newJObject()
  add(query_603757, "Action", newJString(Action))
  if ResourceArns != nil:
    query_603757.add "ResourceArns", ResourceArns
  add(query_603757, "Version", newJString(Version))
  result = call_603756.call(nil, query_603757, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_603742(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_603743,
    base: "/", url: url_GetDescribeTags_603744, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_603791 = ref object of OpenApiRestCall_602466
proc url_PostDescribeTargetGroupAttributes_603793(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTargetGroupAttributes_603792(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603794 = query.getOrDefault("Action")
  valid_603794 = validateParameter(valid_603794, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_603794 != nil:
    section.add "Action", valid_603794
  var valid_603795 = query.getOrDefault("Version")
  valid_603795 = validateParameter(valid_603795, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603795 != nil:
    section.add "Version", valid_603795
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603796 = header.getOrDefault("X-Amz-Date")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Date", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-Security-Token")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Security-Token", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Content-Sha256", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Algorithm")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Algorithm", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Signature")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Signature", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-SignedHeaders", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Credential")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Credential", valid_603802
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_603803 = formData.getOrDefault("TargetGroupArn")
  valid_603803 = validateParameter(valid_603803, JString, required = true,
                                 default = nil)
  if valid_603803 != nil:
    section.add "TargetGroupArn", valid_603803
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603804: Call_PostDescribeTargetGroupAttributes_603791;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603804.validator(path, query, header, formData, body)
  let scheme = call_603804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603804.url(scheme.get, call_603804.host, call_603804.base,
                         call_603804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603804, url, valid)

proc call*(call_603805: Call_PostDescribeTargetGroupAttributes_603791;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_603806 = newJObject()
  var formData_603807 = newJObject()
  add(query_603806, "Action", newJString(Action))
  add(formData_603807, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603806, "Version", newJString(Version))
  result = call_603805.call(nil, query_603806, nil, formData_603807, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_603791(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_603792, base: "/",
    url: url_PostDescribeTargetGroupAttributes_603793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_603775 = ref object of OpenApiRestCall_602466
proc url_GetDescribeTargetGroupAttributes_603777(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTargetGroupAttributes_603776(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_603778 = query.getOrDefault("TargetGroupArn")
  valid_603778 = validateParameter(valid_603778, JString, required = true,
                                 default = nil)
  if valid_603778 != nil:
    section.add "TargetGroupArn", valid_603778
  var valid_603779 = query.getOrDefault("Action")
  valid_603779 = validateParameter(valid_603779, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_603779 != nil:
    section.add "Action", valid_603779
  var valid_603780 = query.getOrDefault("Version")
  valid_603780 = validateParameter(valid_603780, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603780 != nil:
    section.add "Version", valid_603780
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603781 = header.getOrDefault("X-Amz-Date")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Date", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-Security-Token")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Security-Token", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Content-Sha256", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Algorithm")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Algorithm", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Signature")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Signature", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-SignedHeaders", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-Credential")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Credential", valid_603787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603788: Call_GetDescribeTargetGroupAttributes_603775;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603788.validator(path, query, header, formData, body)
  let scheme = call_603788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603788.url(scheme.get, call_603788.host, call_603788.base,
                         call_603788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603788, url, valid)

proc call*(call_603789: Call_GetDescribeTargetGroupAttributes_603775;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603790 = newJObject()
  add(query_603790, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603790, "Action", newJString(Action))
  add(query_603790, "Version", newJString(Version))
  result = call_603789.call(nil, query_603790, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_603775(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_603776, base: "/",
    url: url_GetDescribeTargetGroupAttributes_603777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_603828 = ref object of OpenApiRestCall_602466
proc url_PostDescribeTargetGroups_603830(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTargetGroups_603829(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603831 = query.getOrDefault("Action")
  valid_603831 = validateParameter(valid_603831, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_603831 != nil:
    section.add "Action", valid_603831
  var valid_603832 = query.getOrDefault("Version")
  valid_603832 = validateParameter(valid_603832, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603832 != nil:
    section.add "Version", valid_603832
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603833 = header.getOrDefault("X-Amz-Date")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Date", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Security-Token")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Security-Token", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Content-Sha256", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Algorithm")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Algorithm", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Signature")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Signature", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-SignedHeaders", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Credential")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Credential", valid_603839
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   Names: JArray
  ##        : The names of the target groups.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_603840 = formData.getOrDefault("LoadBalancerArn")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "LoadBalancerArn", valid_603840
  var valid_603841 = formData.getOrDefault("TargetGroupArns")
  valid_603841 = validateParameter(valid_603841, JArray, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "TargetGroupArns", valid_603841
  var valid_603842 = formData.getOrDefault("Names")
  valid_603842 = validateParameter(valid_603842, JArray, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "Names", valid_603842
  var valid_603843 = formData.getOrDefault("Marker")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "Marker", valid_603843
  var valid_603844 = formData.getOrDefault("PageSize")
  valid_603844 = validateParameter(valid_603844, JInt, required = false, default = nil)
  if valid_603844 != nil:
    section.add "PageSize", valid_603844
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603845: Call_PostDescribeTargetGroups_603828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_603845.validator(path, query, header, formData, body)
  let scheme = call_603845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603845.url(scheme.get, call_603845.host, call_603845.base,
                         call_603845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603845, url, valid)

proc call*(call_603846: Call_PostDescribeTargetGroups_603828;
          LoadBalancerArn: string = ""; TargetGroupArns: JsonNode = nil;
          Names: JsonNode = nil; Marker: string = "";
          Action: string = "DescribeTargetGroups"; PageSize: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroups
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   Names: JArray
  ##        : The names of the target groups.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_603847 = newJObject()
  var formData_603848 = newJObject()
  add(formData_603848, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    formData_603848.add "TargetGroupArns", TargetGroupArns
  if Names != nil:
    formData_603848.add "Names", Names
  add(formData_603848, "Marker", newJString(Marker))
  add(query_603847, "Action", newJString(Action))
  add(formData_603848, "PageSize", newJInt(PageSize))
  add(query_603847, "Version", newJString(Version))
  result = call_603846.call(nil, query_603847, nil, formData_603848, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_603828(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_603829, base: "/",
    url: url_PostDescribeTargetGroups_603830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_603808 = ref object of OpenApiRestCall_602466
proc url_GetDescribeTargetGroups_603810(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTargetGroups_603809(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Names: JArray
  ##        : The names of the target groups.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: JString
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   Version: JString (required)
  section = newJObject()
  var valid_603811 = query.getOrDefault("Names")
  valid_603811 = validateParameter(valid_603811, JArray, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "Names", valid_603811
  var valid_603812 = query.getOrDefault("PageSize")
  valid_603812 = validateParameter(valid_603812, JInt, required = false, default = nil)
  if valid_603812 != nil:
    section.add "PageSize", valid_603812
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603813 = query.getOrDefault("Action")
  valid_603813 = validateParameter(valid_603813, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_603813 != nil:
    section.add "Action", valid_603813
  var valid_603814 = query.getOrDefault("Marker")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "Marker", valid_603814
  var valid_603815 = query.getOrDefault("LoadBalancerArn")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "LoadBalancerArn", valid_603815
  var valid_603816 = query.getOrDefault("TargetGroupArns")
  valid_603816 = validateParameter(valid_603816, JArray, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "TargetGroupArns", valid_603816
  var valid_603817 = query.getOrDefault("Version")
  valid_603817 = validateParameter(valid_603817, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603817 != nil:
    section.add "Version", valid_603817
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603818 = header.getOrDefault("X-Amz-Date")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Date", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-Security-Token")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Security-Token", valid_603819
  var valid_603820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Content-Sha256", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Algorithm")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Algorithm", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Signature")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Signature", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-SignedHeaders", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Credential")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Credential", valid_603824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603825: Call_GetDescribeTargetGroups_603808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_603825.validator(path, query, header, formData, body)
  let scheme = call_603825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603825.url(scheme.get, call_603825.host, call_603825.base,
                         call_603825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603825, url, valid)

proc call*(call_603826: Call_GetDescribeTargetGroups_603808; Names: JsonNode = nil;
          PageSize: int = 0; Action: string = "DescribeTargetGroups";
          Marker: string = ""; LoadBalancerArn: string = "";
          TargetGroupArns: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroups
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ##   Names: JArray
  ##        : The names of the target groups.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerArn: string
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   TargetGroupArns: JArray
  ##                  : The Amazon Resource Names (ARN) of the target groups.
  ##   Version: string (required)
  var query_603827 = newJObject()
  if Names != nil:
    query_603827.add "Names", Names
  add(query_603827, "PageSize", newJInt(PageSize))
  add(query_603827, "Action", newJString(Action))
  add(query_603827, "Marker", newJString(Marker))
  add(query_603827, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    query_603827.add "TargetGroupArns", TargetGroupArns
  add(query_603827, "Version", newJString(Version))
  result = call_603826.call(nil, query_603827, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_603808(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_603809, base: "/",
    url: url_GetDescribeTargetGroups_603810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_603866 = ref object of OpenApiRestCall_602466
proc url_PostDescribeTargetHealth_603868(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTargetHealth_603867(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603869 = query.getOrDefault("Action")
  valid_603869 = validateParameter(valid_603869, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_603869 != nil:
    section.add "Action", valid_603869
  var valid_603870 = query.getOrDefault("Version")
  valid_603870 = validateParameter(valid_603870, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603870 != nil:
    section.add "Version", valid_603870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603871 = header.getOrDefault("X-Amz-Date")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Date", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Security-Token")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Security-Token", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Content-Sha256", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Algorithm")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Algorithm", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Signature")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Signature", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-SignedHeaders", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Credential")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Credential", valid_603877
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_603878 = formData.getOrDefault("Targets")
  valid_603878 = validateParameter(valid_603878, JArray, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "Targets", valid_603878
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_603879 = formData.getOrDefault("TargetGroupArn")
  valid_603879 = validateParameter(valid_603879, JString, required = true,
                                 default = nil)
  if valid_603879 != nil:
    section.add "TargetGroupArn", valid_603879
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603880: Call_PostDescribeTargetHealth_603866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_603880.validator(path, query, header, formData, body)
  let scheme = call_603880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603880.url(scheme.get, call_603880.host, call_603880.base,
                         call_603880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603880, url, valid)

proc call*(call_603881: Call_PostDescribeTargetHealth_603866;
          TargetGroupArn: string; Targets: JsonNode = nil;
          Action: string = "DescribeTargetHealth"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetHealth
  ## Describes the health of the specified targets or all of your targets.
  ##   Targets: JArray
  ##          : The targets.
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_603882 = newJObject()
  var formData_603883 = newJObject()
  if Targets != nil:
    formData_603883.add "Targets", Targets
  add(query_603882, "Action", newJString(Action))
  add(formData_603883, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603882, "Version", newJString(Version))
  result = call_603881.call(nil, query_603882, nil, formData_603883, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_603866(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_603867, base: "/",
    url: url_PostDescribeTargetHealth_603868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_603849 = ref object of OpenApiRestCall_602466
proc url_GetDescribeTargetHealth_603851(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTargetHealth_603850(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603852 = query.getOrDefault("Targets")
  valid_603852 = validateParameter(valid_603852, JArray, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "Targets", valid_603852
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_603853 = query.getOrDefault("TargetGroupArn")
  valid_603853 = validateParameter(valid_603853, JString, required = true,
                                 default = nil)
  if valid_603853 != nil:
    section.add "TargetGroupArn", valid_603853
  var valid_603854 = query.getOrDefault("Action")
  valid_603854 = validateParameter(valid_603854, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_603854 != nil:
    section.add "Action", valid_603854
  var valid_603855 = query.getOrDefault("Version")
  valid_603855 = validateParameter(valid_603855, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603855 != nil:
    section.add "Version", valid_603855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603856 = header.getOrDefault("X-Amz-Date")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Date", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-Security-Token")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Security-Token", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Content-Sha256", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Algorithm")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Algorithm", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Signature")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Signature", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-SignedHeaders", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Credential")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Credential", valid_603862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603863: Call_GetDescribeTargetHealth_603849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_603863.validator(path, query, header, formData, body)
  let scheme = call_603863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603863.url(scheme.get, call_603863.host, call_603863.base,
                         call_603863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603863, url, valid)

proc call*(call_603864: Call_GetDescribeTargetHealth_603849;
          TargetGroupArn: string; Targets: JsonNode = nil;
          Action: string = "DescribeTargetHealth"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetHealth
  ## Describes the health of the specified targets or all of your targets.
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603865 = newJObject()
  if Targets != nil:
    query_603865.add "Targets", Targets
  add(query_603865, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603865, "Action", newJString(Action))
  add(query_603865, "Version", newJString(Version))
  result = call_603864.call(nil, query_603865, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_603849(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_603850, base: "/",
    url: url_GetDescribeTargetHealth_603851, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_603905 = ref object of OpenApiRestCall_602466
proc url_PostModifyListener_603907(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyListener_603906(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603908 = query.getOrDefault("Action")
  valid_603908 = validateParameter(valid_603908, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_603908 != nil:
    section.add "Action", valid_603908
  var valid_603909 = query.getOrDefault("Version")
  valid_603909 = validateParameter(valid_603909, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603909 != nil:
    section.add "Version", valid_603909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603910 = header.getOrDefault("X-Amz-Date")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Date", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Security-Token")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Security-Token", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Content-Sha256", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Algorithm")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Algorithm", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Signature")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Signature", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-SignedHeaders", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-Credential")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Credential", valid_603916
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Port: JInt
  ##       : The port for connections from clients to the load balancer.
  ##   Protocol: JString
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  section = newJObject()
  var valid_603917 = formData.getOrDefault("Certificates")
  valid_603917 = validateParameter(valid_603917, JArray, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "Certificates", valid_603917
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_603918 = formData.getOrDefault("ListenerArn")
  valid_603918 = validateParameter(valid_603918, JString, required = true,
                                 default = nil)
  if valid_603918 != nil:
    section.add "ListenerArn", valid_603918
  var valid_603919 = formData.getOrDefault("Port")
  valid_603919 = validateParameter(valid_603919, JInt, required = false, default = nil)
  if valid_603919 != nil:
    section.add "Port", valid_603919
  var valid_603920 = formData.getOrDefault("Protocol")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603920 != nil:
    section.add "Protocol", valid_603920
  var valid_603921 = formData.getOrDefault("SslPolicy")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "SslPolicy", valid_603921
  var valid_603922 = formData.getOrDefault("DefaultActions")
  valid_603922 = validateParameter(valid_603922, JArray, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "DefaultActions", valid_603922
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603923: Call_PostModifyListener_603905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_603923.validator(path, query, header, formData, body)
  let scheme = call_603923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603923.url(scheme.get, call_603923.host, call_603923.base,
                         call_603923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603923, url, valid)

proc call*(call_603924: Call_PostModifyListener_603905; ListenerArn: string;
          Certificates: JsonNode = nil; Port: int = 0; Protocol: string = "HTTP";
          Action: string = "ModifyListener"; SslPolicy: string = "";
          DefaultActions: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## postModifyListener
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Port: int
  ##       : The port for connections from clients to the load balancer.
  ##   Protocol: string
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Action: string (required)
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Version: string (required)
  var query_603925 = newJObject()
  var formData_603926 = newJObject()
  if Certificates != nil:
    formData_603926.add "Certificates", Certificates
  add(formData_603926, "ListenerArn", newJString(ListenerArn))
  add(formData_603926, "Port", newJInt(Port))
  add(formData_603926, "Protocol", newJString(Protocol))
  add(query_603925, "Action", newJString(Action))
  add(formData_603926, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_603926.add "DefaultActions", DefaultActions
  add(query_603925, "Version", newJString(Version))
  result = call_603924.call(nil, query_603925, nil, formData_603926, nil)

var postModifyListener* = Call_PostModifyListener_603905(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_603906, base: "/",
    url: url_PostModifyListener_603907, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_603884 = ref object of OpenApiRestCall_602466
proc url_GetModifyListener_603886(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyListener_603885(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   SslPolicy: JString
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   Protocol: JString
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   Action: JString (required)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Port: JInt
  ##       : The port for connections from clients to the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  var valid_603887 = query.getOrDefault("DefaultActions")
  valid_603887 = validateParameter(valid_603887, JArray, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "DefaultActions", valid_603887
  var valid_603888 = query.getOrDefault("SslPolicy")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "SslPolicy", valid_603888
  var valid_603889 = query.getOrDefault("Protocol")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603889 != nil:
    section.add "Protocol", valid_603889
  var valid_603890 = query.getOrDefault("Certificates")
  valid_603890 = validateParameter(valid_603890, JArray, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "Certificates", valid_603890
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603891 = query.getOrDefault("Action")
  valid_603891 = validateParameter(valid_603891, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_603891 != nil:
    section.add "Action", valid_603891
  var valid_603892 = query.getOrDefault("ListenerArn")
  valid_603892 = validateParameter(valid_603892, JString, required = true,
                                 default = nil)
  if valid_603892 != nil:
    section.add "ListenerArn", valid_603892
  var valid_603893 = query.getOrDefault("Port")
  valid_603893 = validateParameter(valid_603893, JInt, required = false, default = nil)
  if valid_603893 != nil:
    section.add "Port", valid_603893
  var valid_603894 = query.getOrDefault("Version")
  valid_603894 = validateParameter(valid_603894, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603894 != nil:
    section.add "Version", valid_603894
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603895 = header.getOrDefault("X-Amz-Date")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-Date", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Security-Token")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Security-Token", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Content-Sha256", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Algorithm")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Algorithm", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Signature")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Signature", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-SignedHeaders", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Credential")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Credential", valid_603901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603902: Call_GetModifyListener_603884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_603902.validator(path, query, header, formData, body)
  let scheme = call_603902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603902.url(scheme.get, call_603902.host, call_603902.base,
                         call_603902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603902, url, valid)

proc call*(call_603903: Call_GetModifyListener_603884; ListenerArn: string;
          DefaultActions: JsonNode = nil; SslPolicy: string = "";
          Protocol: string = "HTTP"; Certificates: JsonNode = nil;
          Action: string = "ModifyListener"; Port: int = 0;
          Version: string = "2015-12-01"): Recallable =
  ## getModifyListener
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ##   DefaultActions: JArray
  ##                 : <p>The actions for the default rule. The rule must include one forward action or one or more fixed-response actions.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   SslPolicy: string
  ##            : [HTTPS and TLS listeners] The security policy that defines which protocols and ciphers are supported. For more information, see <a 
  ## href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.
  ##   Protocol: string
  ##           : The protocol for connections from clients to the load balancer. Application Load Balancers support the HTTP and HTTPS protocols. Network Load Balancers support the TCP, TLS, UDP, and TCP_UDP protocols.
  ##   Certificates: JArray
  ##               : <p>[HTTPS and TLS listeners] The default certificate for the listener. You must provide exactly one certificate. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.</p> <p>To create a certificate list, use <a>AddListenerCertificates</a>.</p>
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Port: int
  ##       : The port for connections from clients to the load balancer.
  ##   Version: string (required)
  var query_603904 = newJObject()
  if DefaultActions != nil:
    query_603904.add "DefaultActions", DefaultActions
  add(query_603904, "SslPolicy", newJString(SslPolicy))
  add(query_603904, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_603904.add "Certificates", Certificates
  add(query_603904, "Action", newJString(Action))
  add(query_603904, "ListenerArn", newJString(ListenerArn))
  add(query_603904, "Port", newJInt(Port))
  add(query_603904, "Version", newJString(Version))
  result = call_603903.call(nil, query_603904, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_603884(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_603885,
    base: "/", url: url_GetModifyListener_603886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_603944 = ref object of OpenApiRestCall_602466
proc url_PostModifyLoadBalancerAttributes_603946(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_603945(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603947 = query.getOrDefault("Action")
  valid_603947 = validateParameter(valid_603947, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_603947 != nil:
    section.add "Action", valid_603947
  var valid_603948 = query.getOrDefault("Version")
  valid_603948 = validateParameter(valid_603948, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603948 != nil:
    section.add "Version", valid_603948
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603949 = header.getOrDefault("X-Amz-Date")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Date", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Security-Token")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Security-Token", valid_603950
  var valid_603951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-Content-Sha256", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Algorithm")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Algorithm", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Signature")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Signature", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-SignedHeaders", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Credential")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Credential", valid_603955
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_603956 = formData.getOrDefault("LoadBalancerArn")
  valid_603956 = validateParameter(valid_603956, JString, required = true,
                                 default = nil)
  if valid_603956 != nil:
    section.add "LoadBalancerArn", valid_603956
  var valid_603957 = formData.getOrDefault("Attributes")
  valid_603957 = validateParameter(valid_603957, JArray, required = true, default = nil)
  if valid_603957 != nil:
    section.add "Attributes", valid_603957
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603958: Call_PostModifyLoadBalancerAttributes_603944;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_603958.validator(path, query, header, formData, body)
  let scheme = call_603958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603958.url(scheme.get, call_603958.host, call_603958.base,
                         call_603958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603958, url, valid)

proc call*(call_603959: Call_PostModifyLoadBalancerAttributes_603944;
          LoadBalancerArn: string; Attributes: JsonNode;
          Action: string = "ModifyLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postModifyLoadBalancerAttributes
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603960 = newJObject()
  var formData_603961 = newJObject()
  add(formData_603961, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    formData_603961.add "Attributes", Attributes
  add(query_603960, "Action", newJString(Action))
  add(query_603960, "Version", newJString(Version))
  result = call_603959.call(nil, query_603960, nil, formData_603961, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_603944(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_603945, base: "/",
    url: url_PostModifyLoadBalancerAttributes_603946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_603927 = ref object of OpenApiRestCall_602466
proc url_GetModifyLoadBalancerAttributes_603929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_603928(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Attributes` field"
  var valid_603930 = query.getOrDefault("Attributes")
  valid_603930 = validateParameter(valid_603930, JArray, required = true, default = nil)
  if valid_603930 != nil:
    section.add "Attributes", valid_603930
  var valid_603931 = query.getOrDefault("Action")
  valid_603931 = validateParameter(valid_603931, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_603931 != nil:
    section.add "Action", valid_603931
  var valid_603932 = query.getOrDefault("LoadBalancerArn")
  valid_603932 = validateParameter(valid_603932, JString, required = true,
                                 default = nil)
  if valid_603932 != nil:
    section.add "LoadBalancerArn", valid_603932
  var valid_603933 = query.getOrDefault("Version")
  valid_603933 = validateParameter(valid_603933, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603933 != nil:
    section.add "Version", valid_603933
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603934 = header.getOrDefault("X-Amz-Date")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Date", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-Security-Token")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Security-Token", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Content-Sha256", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Algorithm")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Algorithm", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Signature")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Signature", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-SignedHeaders", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Credential")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Credential", valid_603940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603941: Call_GetModifyLoadBalancerAttributes_603927;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_603941.validator(path, query, header, formData, body)
  let scheme = call_603941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603941.url(scheme.get, call_603941.host, call_603941.base,
                         call_603941.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603941, url, valid)

proc call*(call_603942: Call_GetModifyLoadBalancerAttributes_603927;
          Attributes: JsonNode; LoadBalancerArn: string;
          Action: string = "ModifyLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getModifyLoadBalancerAttributes
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_603943 = newJObject()
  if Attributes != nil:
    query_603943.add "Attributes", Attributes
  add(query_603943, "Action", newJString(Action))
  add(query_603943, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603943, "Version", newJString(Version))
  result = call_603942.call(nil, query_603943, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_603927(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_603928, base: "/",
    url: url_GetModifyLoadBalancerAttributes_603929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_603980 = ref object of OpenApiRestCall_602466
proc url_PostModifyRule_603982(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyRule_603981(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603983 = query.getOrDefault("Action")
  valid_603983 = validateParameter(valid_603983, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_603983 != nil:
    section.add "Action", valid_603983
  var valid_603984 = query.getOrDefault("Version")
  valid_603984 = validateParameter(valid_603984, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603984 != nil:
    section.add "Version", valid_603984
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603985 = header.getOrDefault("X-Amz-Date")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Date", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Security-Token")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Security-Token", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Content-Sha256", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Algorithm")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Algorithm", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-Signature")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Signature", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-SignedHeaders", valid_603990
  var valid_603991 = header.getOrDefault("X-Amz-Credential")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-Credential", valid_603991
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_603992 = formData.getOrDefault("RuleArn")
  valid_603992 = validateParameter(valid_603992, JString, required = true,
                                 default = nil)
  if valid_603992 != nil:
    section.add "RuleArn", valid_603992
  var valid_603993 = formData.getOrDefault("Actions")
  valid_603993 = validateParameter(valid_603993, JArray, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "Actions", valid_603993
  var valid_603994 = formData.getOrDefault("Conditions")
  valid_603994 = validateParameter(valid_603994, JArray, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "Conditions", valid_603994
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603995: Call_PostModifyRule_603980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_603995.validator(path, query, header, formData, body)
  let scheme = call_603995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603995.url(scheme.get, call_603995.host, call_603995.base,
                         call_603995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603995, url, valid)

proc call*(call_603996: Call_PostModifyRule_603980; RuleArn: string;
          Actions: JsonNode = nil; Conditions: JsonNode = nil;
          Action: string = "ModifyRule"; Version: string = "2015-12-01"): Recallable =
  ## postModifyRule
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603997 = newJObject()
  var formData_603998 = newJObject()
  add(formData_603998, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    formData_603998.add "Actions", Actions
  if Conditions != nil:
    formData_603998.add "Conditions", Conditions
  add(query_603997, "Action", newJString(Action))
  add(query_603997, "Version", newJString(Version))
  result = call_603996.call(nil, query_603997, nil, formData_603998, nil)

var postModifyRule* = Call_PostModifyRule_603980(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_603981,
    base: "/", url: url_PostModifyRule_603982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_603962 = ref object of OpenApiRestCall_602466
proc url_GetModifyRule_603964(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyRule_603963(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: JString (required)
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_603965 = query.getOrDefault("Conditions")
  valid_603965 = validateParameter(valid_603965, JArray, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "Conditions", valid_603965
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603966 = query.getOrDefault("Action")
  valid_603966 = validateParameter(valid_603966, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_603966 != nil:
    section.add "Action", valid_603966
  var valid_603967 = query.getOrDefault("RuleArn")
  valid_603967 = validateParameter(valid_603967, JString, required = true,
                                 default = nil)
  if valid_603967 != nil:
    section.add "RuleArn", valid_603967
  var valid_603968 = query.getOrDefault("Actions")
  valid_603968 = validateParameter(valid_603968, JArray, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "Actions", valid_603968
  var valid_603969 = query.getOrDefault("Version")
  valid_603969 = validateParameter(valid_603969, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603969 != nil:
    section.add "Version", valid_603969
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603970 = header.getOrDefault("X-Amz-Date")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Date", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Security-Token")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Security-Token", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Content-Sha256", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-Algorithm")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-Algorithm", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-Signature")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-Signature", valid_603974
  var valid_603975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "X-Amz-SignedHeaders", valid_603975
  var valid_603976 = header.getOrDefault("X-Amz-Credential")
  valid_603976 = validateParameter(valid_603976, JString, required = false,
                                 default = nil)
  if valid_603976 != nil:
    section.add "X-Amz-Credential", valid_603976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603977: Call_GetModifyRule_603962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_603977.validator(path, query, header, formData, body)
  let scheme = call_603977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603977.url(scheme.get, call_603977.host, call_603977.base,
                         call_603977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603977, url, valid)

proc call*(call_603978: Call_GetModifyRule_603962; RuleArn: string;
          Conditions: JsonNode = nil; Action: string = "ModifyRule";
          Actions: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## getModifyRule
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ##   Conditions: JArray
  ##             : The conditions. Each rule can include zero or one of the following conditions: <code>http-request-method</code>, <code>host-header</code>, <code>path-pattern</code>, and <code>source-ip</code>, and zero or more of the following conditions: <code>http-header</code> and <code>query-string</code>.
  ##   Action: string (required)
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Actions: JArray
  ##          : <p>The actions. Each rule must include exactly one of the following types of actions: <code>forward</code>, <code>fixed-response</code>, or <code>redirect</code>.</p> <p>If the action type is <code>forward</code>, you specify a target group. The protocol of the target group must be HTTP or HTTPS for an Application Load Balancer. The protocol of the target group must be TCP, TLS, UDP, or TCP_UDP for a Network Load Balancer.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-oidc</code>, you authenticate users through an identity provider that is OpenID Connect (OIDC) compliant.</p> <p>[HTTPS listeners] If the action type is <code>authenticate-cognito</code>, you authenticate users through the user pools supported by Amazon Cognito.</p> <p>[Application Load Balancer] If the action type is <code>redirect</code>, you redirect specified client requests from one URL to another.</p> <p>[Application Load Balancer] If the action type is <code>fixed-response</code>, you drop specified client requests and return a custom HTTP response.</p>
  ##   Version: string (required)
  var query_603979 = newJObject()
  if Conditions != nil:
    query_603979.add "Conditions", Conditions
  add(query_603979, "Action", newJString(Action))
  add(query_603979, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_603979.add "Actions", Actions
  add(query_603979, "Version", newJString(Version))
  result = call_603978.call(nil, query_603979, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_603962(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_603963,
    base: "/", url: url_GetModifyRule_603964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_604024 = ref object of OpenApiRestCall_602466
proc url_PostModifyTargetGroup_604026(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyTargetGroup_604025(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604027 = query.getOrDefault("Action")
  valid_604027 = validateParameter(valid_604027, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_604027 != nil:
    section.add "Action", valid_604027
  var valid_604028 = query.getOrDefault("Version")
  valid_604028 = validateParameter(valid_604028, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604028 != nil:
    section.add "Version", valid_604028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604029 = header.getOrDefault("X-Amz-Date")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "X-Amz-Date", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-Security-Token")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-Security-Token", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Content-Sha256", valid_604031
  var valid_604032 = header.getOrDefault("X-Amz-Algorithm")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "X-Amz-Algorithm", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-Signature")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Signature", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-SignedHeaders", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-Credential")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Credential", valid_604035
  result.add "header", section
  ## parameters in `formData` object:
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   HealthCheckProtocol: JString
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_604036 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_604036 = validateParameter(valid_604036, JInt, required = false, default = nil)
  if valid_604036 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_604036
  var valid_604037 = formData.getOrDefault("HealthCheckPort")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "HealthCheckPort", valid_604037
  var valid_604038 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_604038 = validateParameter(valid_604038, JInt, required = false, default = nil)
  if valid_604038 != nil:
    section.add "UnhealthyThresholdCount", valid_604038
  var valid_604039 = formData.getOrDefault("HealthCheckPath")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "HealthCheckPath", valid_604039
  var valid_604040 = formData.getOrDefault("HealthCheckEnabled")
  valid_604040 = validateParameter(valid_604040, JBool, required = false, default = nil)
  if valid_604040 != nil:
    section.add "HealthCheckEnabled", valid_604040
  var valid_604041 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_604041 = validateParameter(valid_604041, JInt, required = false, default = nil)
  if valid_604041 != nil:
    section.add "HealthCheckIntervalSeconds", valid_604041
  var valid_604042 = formData.getOrDefault("HealthyThresholdCount")
  valid_604042 = validateParameter(valid_604042, JInt, required = false, default = nil)
  if valid_604042 != nil:
    section.add "HealthyThresholdCount", valid_604042
  var valid_604043 = formData.getOrDefault("HealthCheckProtocol")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_604043 != nil:
    section.add "HealthCheckProtocol", valid_604043
  var valid_604044 = formData.getOrDefault("Matcher.HttpCode")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "Matcher.HttpCode", valid_604044
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_604045 = formData.getOrDefault("TargetGroupArn")
  valid_604045 = validateParameter(valid_604045, JString, required = true,
                                 default = nil)
  if valid_604045 != nil:
    section.add "TargetGroupArn", valid_604045
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604046: Call_PostModifyTargetGroup_604024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_604046.validator(path, query, header, formData, body)
  let scheme = call_604046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604046.url(scheme.get, call_604046.host, call_604046.base,
                         call_604046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604046, url, valid)

proc call*(call_604047: Call_PostModifyTargetGroup_604024; TargetGroupArn: string;
          HealthCheckTimeoutSeconds: int = 0; HealthCheckPort: string = "";
          UnhealthyThresholdCount: int = 0; HealthCheckPath: string = "";
          HealthCheckEnabled: bool = false; Action: string = "ModifyTargetGroup";
          HealthCheckIntervalSeconds: int = 0; HealthyThresholdCount: int = 0;
          HealthCheckProtocol: string = "HTTP"; MatcherHttpCode: string = "";
          Version: string = "2015-12-01"): Recallable =
  ## postModifyTargetGroup
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ##   HealthCheckTimeoutSeconds: int
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled.
  ##   Action: string (required)
  ##   HealthCheckIntervalSeconds: int
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   HealthCheckProtocol: string
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_604048 = newJObject()
  var formData_604049 = newJObject()
  add(formData_604049, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_604049, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_604049, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_604049, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_604049, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_604048, "Action", newJString(Action))
  add(formData_604049, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_604049, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_604049, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_604049, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(formData_604049, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_604048, "Version", newJString(Version))
  result = call_604047.call(nil, query_604048, nil, formData_604049, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_604024(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_604025, base: "/",
    url: url_PostModifyTargetGroup_604026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_603999 = ref object of OpenApiRestCall_602466
proc url_GetModifyTargetGroup_604001(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyTargetGroup_604000(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   HealthCheckEnabled: JBool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthCheckIntervalSeconds: JInt
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   HealthCheckPort: JString
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   Action: JString (required)
  ##   HealthCheckTimeoutSeconds: JInt
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   Matcher.HttpCode: JString
  ##                   : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   UnhealthyThresholdCount: JInt
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   HealthCheckProtocol: JString
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthyThresholdCount: JInt
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   Version: JString (required)
  ##   HealthCheckPath: JString
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  section = newJObject()
  var valid_604002 = query.getOrDefault("HealthCheckEnabled")
  valid_604002 = validateParameter(valid_604002, JBool, required = false, default = nil)
  if valid_604002 != nil:
    section.add "HealthCheckEnabled", valid_604002
  var valid_604003 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_604003 = validateParameter(valid_604003, JInt, required = false, default = nil)
  if valid_604003 != nil:
    section.add "HealthCheckIntervalSeconds", valid_604003
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_604004 = query.getOrDefault("TargetGroupArn")
  valid_604004 = validateParameter(valid_604004, JString, required = true,
                                 default = nil)
  if valid_604004 != nil:
    section.add "TargetGroupArn", valid_604004
  var valid_604005 = query.getOrDefault("HealthCheckPort")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "HealthCheckPort", valid_604005
  var valid_604006 = query.getOrDefault("Action")
  valid_604006 = validateParameter(valid_604006, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_604006 != nil:
    section.add "Action", valid_604006
  var valid_604007 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_604007 = validateParameter(valid_604007, JInt, required = false, default = nil)
  if valid_604007 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_604007
  var valid_604008 = query.getOrDefault("Matcher.HttpCode")
  valid_604008 = validateParameter(valid_604008, JString, required = false,
                                 default = nil)
  if valid_604008 != nil:
    section.add "Matcher.HttpCode", valid_604008
  var valid_604009 = query.getOrDefault("UnhealthyThresholdCount")
  valid_604009 = validateParameter(valid_604009, JInt, required = false, default = nil)
  if valid_604009 != nil:
    section.add "UnhealthyThresholdCount", valid_604009
  var valid_604010 = query.getOrDefault("HealthCheckProtocol")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_604010 != nil:
    section.add "HealthCheckProtocol", valid_604010
  var valid_604011 = query.getOrDefault("HealthyThresholdCount")
  valid_604011 = validateParameter(valid_604011, JInt, required = false, default = nil)
  if valid_604011 != nil:
    section.add "HealthyThresholdCount", valid_604011
  var valid_604012 = query.getOrDefault("Version")
  valid_604012 = validateParameter(valid_604012, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604012 != nil:
    section.add "Version", valid_604012
  var valid_604013 = query.getOrDefault("HealthCheckPath")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "HealthCheckPath", valid_604013
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604014 = header.getOrDefault("X-Amz-Date")
  valid_604014 = validateParameter(valid_604014, JString, required = false,
                                 default = nil)
  if valid_604014 != nil:
    section.add "X-Amz-Date", valid_604014
  var valid_604015 = header.getOrDefault("X-Amz-Security-Token")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "X-Amz-Security-Token", valid_604015
  var valid_604016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Content-Sha256", valid_604016
  var valid_604017 = header.getOrDefault("X-Amz-Algorithm")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Algorithm", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-Signature")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-Signature", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-SignedHeaders", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Credential")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Credential", valid_604020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604021: Call_GetModifyTargetGroup_603999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_604021.validator(path, query, header, formData, body)
  let scheme = call_604021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604021.url(scheme.get, call_604021.host, call_604021.base,
                         call_604021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604021, url, valid)

proc call*(call_604022: Call_GetModifyTargetGroup_603999; TargetGroupArn: string;
          HealthCheckEnabled: bool = false; HealthCheckIntervalSeconds: int = 0;
          HealthCheckPort: string = ""; Action: string = "ModifyTargetGroup";
          HealthCheckTimeoutSeconds: int = 0; MatcherHttpCode: string = "";
          UnhealthyThresholdCount: int = 0; HealthCheckProtocol: string = "HTTP";
          HealthyThresholdCount: int = 0; Version: string = "2015-12-01";
          HealthCheckPath: string = ""): Recallable =
  ## getModifyTargetGroup
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ##   HealthCheckEnabled: bool
  ##                     : Indicates whether health checks are enabled.
  ##   HealthCheckIntervalSeconds: int
  ##                             : <p>The approximate amount of time, in seconds, between health checks of an individual target. For Application Load Balancers, the range is 5 to 300 seconds. For Network Load Balancers, the supported values are 10 or 30 seconds.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   HealthCheckPort: string
  ##                  : The port the load balancer uses when performing health checks on targets.
  ##   Action: string (required)
  ##   HealthCheckTimeoutSeconds: int
  ##                            : <p>[HTTP/HTTPS health checks] The amount of time, in seconds, during which no response means a failed health check.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   MatcherHttpCode: string
  ##                  : Information to use when checking for a successful response from a target.
  ## <p>The HTTP codes.</p> <p>For Application Load Balancers, you can specify values between 200 and 499, and the default value is 200. You can specify multiple values (for example, "200,202") or a range of values (for example, "200-299").</p> <p>For Network Load Balancers, this is 200–399.</p>
  ##   UnhealthyThresholdCount: int
  ##                          : The number of consecutive health check failures required before considering the target unhealthy. For Network Load Balancers, this value must be the same as the healthy threshold count.
  ##   HealthCheckProtocol: string
  ##                      : <p>The protocol the load balancer uses when performing health checks on targets. The TCP protocol is supported for health checks only if the protocol of the target group is TCP, TLS, UDP, or TCP_UDP. The TLS, UDP, and TCP_UDP protocols are not supported for health checks.</p> <p>If the protocol of the target group is TCP, you can't modify this setting.</p>
  ##   HealthyThresholdCount: int
  ##                        : The number of consecutive health checks successes required before considering an unhealthy target healthy.
  ##   Version: string (required)
  ##   HealthCheckPath: string
  ##                  : [HTTP/HTTPS health checks] The ping path that is the destination for the health check request.
  var query_604023 = newJObject()
  add(query_604023, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_604023, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_604023, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_604023, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_604023, "Action", newJString(Action))
  add(query_604023, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_604023, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_604023, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_604023, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_604023, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_604023, "Version", newJString(Version))
  add(query_604023, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_604022.call(nil, query_604023, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_603999(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_604000,
    base: "/", url: url_GetModifyTargetGroup_604001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_604067 = ref object of OpenApiRestCall_602466
proc url_PostModifyTargetGroupAttributes_604069(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyTargetGroupAttributes_604068(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the specified attributes of the specified target group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604070 = query.getOrDefault("Action")
  valid_604070 = validateParameter(valid_604070, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_604070 != nil:
    section.add "Action", valid_604070
  var valid_604071 = query.getOrDefault("Version")
  valid_604071 = validateParameter(valid_604071, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604071 != nil:
    section.add "Version", valid_604071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604072 = header.getOrDefault("X-Amz-Date")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Date", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-Security-Token")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Security-Token", valid_604073
  var valid_604074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Content-Sha256", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Algorithm")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Algorithm", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Signature")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Signature", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-SignedHeaders", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-Credential")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Credential", valid_604078
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_604079 = formData.getOrDefault("Attributes")
  valid_604079 = validateParameter(valid_604079, JArray, required = true, default = nil)
  if valid_604079 != nil:
    section.add "Attributes", valid_604079
  var valid_604080 = formData.getOrDefault("TargetGroupArn")
  valid_604080 = validateParameter(valid_604080, JString, required = true,
                                 default = nil)
  if valid_604080 != nil:
    section.add "TargetGroupArn", valid_604080
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604081: Call_PostModifyTargetGroupAttributes_604067;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_604081.validator(path, query, header, formData, body)
  let scheme = call_604081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604081.url(scheme.get, call_604081.host, call_604081.base,
                         call_604081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604081, url, valid)

proc call*(call_604082: Call_PostModifyTargetGroupAttributes_604067;
          Attributes: JsonNode; TargetGroupArn: string;
          Action: string = "ModifyTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postModifyTargetGroupAttributes
  ## Modifies the specified attributes of the specified target group.
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_604083 = newJObject()
  var formData_604084 = newJObject()
  if Attributes != nil:
    formData_604084.add "Attributes", Attributes
  add(query_604083, "Action", newJString(Action))
  add(formData_604084, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_604083, "Version", newJString(Version))
  result = call_604082.call(nil, query_604083, nil, formData_604084, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_604067(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_604068, base: "/",
    url: url_PostModifyTargetGroupAttributes_604069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_604050 = ref object of OpenApiRestCall_602466
proc url_GetModifyTargetGroupAttributes_604052(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyTargetGroupAttributes_604051(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the specified attributes of the specified target group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_604053 = query.getOrDefault("TargetGroupArn")
  valid_604053 = validateParameter(valid_604053, JString, required = true,
                                 default = nil)
  if valid_604053 != nil:
    section.add "TargetGroupArn", valid_604053
  var valid_604054 = query.getOrDefault("Attributes")
  valid_604054 = validateParameter(valid_604054, JArray, required = true, default = nil)
  if valid_604054 != nil:
    section.add "Attributes", valid_604054
  var valid_604055 = query.getOrDefault("Action")
  valid_604055 = validateParameter(valid_604055, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_604055 != nil:
    section.add "Action", valid_604055
  var valid_604056 = query.getOrDefault("Version")
  valid_604056 = validateParameter(valid_604056, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604056 != nil:
    section.add "Version", valid_604056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604057 = header.getOrDefault("X-Amz-Date")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Date", valid_604057
  var valid_604058 = header.getOrDefault("X-Amz-Security-Token")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-Security-Token", valid_604058
  var valid_604059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "X-Amz-Content-Sha256", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-Algorithm")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Algorithm", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Signature")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Signature", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-SignedHeaders", valid_604062
  var valid_604063 = header.getOrDefault("X-Amz-Credential")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-Credential", valid_604063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604064: Call_GetModifyTargetGroupAttributes_604050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_604064.validator(path, query, header, formData, body)
  let scheme = call_604064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604064.url(scheme.get, call_604064.host, call_604064.base,
                         call_604064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604064, url, valid)

proc call*(call_604065: Call_GetModifyTargetGroupAttributes_604050;
          TargetGroupArn: string; Attributes: JsonNode;
          Action: string = "ModifyTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getModifyTargetGroupAttributes
  ## Modifies the specified attributes of the specified target group.
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604066 = newJObject()
  add(query_604066, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_604066.add "Attributes", Attributes
  add(query_604066, "Action", newJString(Action))
  add(query_604066, "Version", newJString(Version))
  result = call_604065.call(nil, query_604066, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_604050(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_604051, base: "/",
    url: url_GetModifyTargetGroupAttributes_604052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_604102 = ref object of OpenApiRestCall_602466
proc url_PostRegisterTargets_604104(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRegisterTargets_604103(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604105 = query.getOrDefault("Action")
  valid_604105 = validateParameter(valid_604105, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_604105 != nil:
    section.add "Action", valid_604105
  var valid_604106 = query.getOrDefault("Version")
  valid_604106 = validateParameter(valid_604106, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604106 != nil:
    section.add "Version", valid_604106
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604107 = header.getOrDefault("X-Amz-Date")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "X-Amz-Date", valid_604107
  var valid_604108 = header.getOrDefault("X-Amz-Security-Token")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Security-Token", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Content-Sha256", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-Algorithm")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Algorithm", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Signature")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Signature", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-SignedHeaders", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Credential")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Credential", valid_604113
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_604114 = formData.getOrDefault("Targets")
  valid_604114 = validateParameter(valid_604114, JArray, required = true, default = nil)
  if valid_604114 != nil:
    section.add "Targets", valid_604114
  var valid_604115 = formData.getOrDefault("TargetGroupArn")
  valid_604115 = validateParameter(valid_604115, JString, required = true,
                                 default = nil)
  if valid_604115 != nil:
    section.add "TargetGroupArn", valid_604115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604116: Call_PostRegisterTargets_604102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_604116.validator(path, query, header, formData, body)
  let scheme = call_604116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604116.url(scheme.get, call_604116.host, call_604116.base,
                         call_604116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604116, url, valid)

proc call*(call_604117: Call_PostRegisterTargets_604102; Targets: JsonNode;
          TargetGroupArn: string; Action: string = "RegisterTargets";
          Version: string = "2015-12-01"): Recallable =
  ## postRegisterTargets
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_604118 = newJObject()
  var formData_604119 = newJObject()
  if Targets != nil:
    formData_604119.add "Targets", Targets
  add(query_604118, "Action", newJString(Action))
  add(formData_604119, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_604118, "Version", newJString(Version))
  result = call_604117.call(nil, query_604118, nil, formData_604119, nil)

var postRegisterTargets* = Call_PostRegisterTargets_604102(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_604103, base: "/",
    url: url_PostRegisterTargets_604104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_604085 = ref object of OpenApiRestCall_602466
proc url_GetRegisterTargets_604087(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRegisterTargets_604086(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Targets` field"
  var valid_604088 = query.getOrDefault("Targets")
  valid_604088 = validateParameter(valid_604088, JArray, required = true, default = nil)
  if valid_604088 != nil:
    section.add "Targets", valid_604088
  var valid_604089 = query.getOrDefault("TargetGroupArn")
  valid_604089 = validateParameter(valid_604089, JString, required = true,
                                 default = nil)
  if valid_604089 != nil:
    section.add "TargetGroupArn", valid_604089
  var valid_604090 = query.getOrDefault("Action")
  valid_604090 = validateParameter(valid_604090, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_604090 != nil:
    section.add "Action", valid_604090
  var valid_604091 = query.getOrDefault("Version")
  valid_604091 = validateParameter(valid_604091, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604091 != nil:
    section.add "Version", valid_604091
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604092 = header.getOrDefault("X-Amz-Date")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "X-Amz-Date", valid_604092
  var valid_604093 = header.getOrDefault("X-Amz-Security-Token")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Security-Token", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Content-Sha256", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Algorithm")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Algorithm", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-Signature")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Signature", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-SignedHeaders", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-Credential")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-Credential", valid_604098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604099: Call_GetRegisterTargets_604085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_604099.validator(path, query, header, formData, body)
  let scheme = call_604099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604099.url(scheme.get, call_604099.host, call_604099.base,
                         call_604099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604099, url, valid)

proc call*(call_604100: Call_GetRegisterTargets_604085; Targets: JsonNode;
          TargetGroupArn: string; Action: string = "RegisterTargets";
          Version: string = "2015-12-01"): Recallable =
  ## getRegisterTargets
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604101 = newJObject()
  if Targets != nil:
    query_604101.add "Targets", Targets
  add(query_604101, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_604101, "Action", newJString(Action))
  add(query_604101, "Version", newJString(Version))
  result = call_604100.call(nil, query_604101, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_604085(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_604086, base: "/",
    url: url_GetRegisterTargets_604087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_604137 = ref object of OpenApiRestCall_602466
proc url_PostRemoveListenerCertificates_604139(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveListenerCertificates_604138(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604140 = query.getOrDefault("Action")
  valid_604140 = validateParameter(valid_604140, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_604140 != nil:
    section.add "Action", valid_604140
  var valid_604141 = query.getOrDefault("Version")
  valid_604141 = validateParameter(valid_604141, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604141 != nil:
    section.add "Version", valid_604141
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604142 = header.getOrDefault("X-Amz-Date")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Date", valid_604142
  var valid_604143 = header.getOrDefault("X-Amz-Security-Token")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Security-Token", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Content-Sha256", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Algorithm")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Algorithm", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Signature")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Signature", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-SignedHeaders", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-Credential")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-Credential", valid_604148
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_604149 = formData.getOrDefault("Certificates")
  valid_604149 = validateParameter(valid_604149, JArray, required = true, default = nil)
  if valid_604149 != nil:
    section.add "Certificates", valid_604149
  var valid_604150 = formData.getOrDefault("ListenerArn")
  valid_604150 = validateParameter(valid_604150, JString, required = true,
                                 default = nil)
  if valid_604150 != nil:
    section.add "ListenerArn", valid_604150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604151: Call_PostRemoveListenerCertificates_604137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_604151.validator(path, query, header, formData, body)
  let scheme = call_604151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604151.url(scheme.get, call_604151.host, call_604151.base,
                         call_604151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604151, url, valid)

proc call*(call_604152: Call_PostRemoveListenerCertificates_604137;
          Certificates: JsonNode; ListenerArn: string;
          Action: string = "RemoveListenerCertificates";
          Version: string = "2015-12-01"): Recallable =
  ## postRemoveListenerCertificates
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604153 = newJObject()
  var formData_604154 = newJObject()
  if Certificates != nil:
    formData_604154.add "Certificates", Certificates
  add(formData_604154, "ListenerArn", newJString(ListenerArn))
  add(query_604153, "Action", newJString(Action))
  add(query_604153, "Version", newJString(Version))
  result = call_604152.call(nil, query_604153, nil, formData_604154, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_604137(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_604138, base: "/",
    url: url_PostRemoveListenerCertificates_604139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_604120 = ref object of OpenApiRestCall_602466
proc url_GetRemoveListenerCertificates_604122(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveListenerCertificates_604121(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: JString (required)
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Certificates` field"
  var valid_604123 = query.getOrDefault("Certificates")
  valid_604123 = validateParameter(valid_604123, JArray, required = true, default = nil)
  if valid_604123 != nil:
    section.add "Certificates", valid_604123
  var valid_604124 = query.getOrDefault("Action")
  valid_604124 = validateParameter(valid_604124, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_604124 != nil:
    section.add "Action", valid_604124
  var valid_604125 = query.getOrDefault("ListenerArn")
  valid_604125 = validateParameter(valid_604125, JString, required = true,
                                 default = nil)
  if valid_604125 != nil:
    section.add "ListenerArn", valid_604125
  var valid_604126 = query.getOrDefault("Version")
  valid_604126 = validateParameter(valid_604126, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604126 != nil:
    section.add "Version", valid_604126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604127 = header.getOrDefault("X-Amz-Date")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Date", valid_604127
  var valid_604128 = header.getOrDefault("X-Amz-Security-Token")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-Security-Token", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Content-Sha256", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Algorithm")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Algorithm", valid_604130
  var valid_604131 = header.getOrDefault("X-Amz-Signature")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-Signature", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-SignedHeaders", valid_604132
  var valid_604133 = header.getOrDefault("X-Amz-Credential")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "X-Amz-Credential", valid_604133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604134: Call_GetRemoveListenerCertificates_604120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_604134.validator(path, query, header, formData, body)
  let scheme = call_604134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604134.url(scheme.get, call_604134.host, call_604134.base,
                         call_604134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604134, url, valid)

proc call*(call_604135: Call_GetRemoveListenerCertificates_604120;
          Certificates: JsonNode; ListenerArn: string;
          Action: string = "RemoveListenerCertificates";
          Version: string = "2015-12-01"): Recallable =
  ## getRemoveListenerCertificates
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  var query_604136 = newJObject()
  if Certificates != nil:
    query_604136.add "Certificates", Certificates
  add(query_604136, "Action", newJString(Action))
  add(query_604136, "ListenerArn", newJString(ListenerArn))
  add(query_604136, "Version", newJString(Version))
  result = call_604135.call(nil, query_604136, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_604120(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_604121, base: "/",
    url: url_GetRemoveListenerCertificates_604122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_604172 = ref object of OpenApiRestCall_602466
proc url_PostRemoveTags_604174(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTags_604173(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604175 = query.getOrDefault("Action")
  valid_604175 = validateParameter(valid_604175, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_604175 != nil:
    section.add "Action", valid_604175
  var valid_604176 = query.getOrDefault("Version")
  valid_604176 = validateParameter(valid_604176, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604176 != nil:
    section.add "Version", valid_604176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604177 = header.getOrDefault("X-Amz-Date")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-Date", valid_604177
  var valid_604178 = header.getOrDefault("X-Amz-Security-Token")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "X-Amz-Security-Token", valid_604178
  var valid_604179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "X-Amz-Content-Sha256", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-Algorithm")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-Algorithm", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Signature")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Signature", valid_604181
  var valid_604182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "X-Amz-SignedHeaders", valid_604182
  var valid_604183 = header.getOrDefault("X-Amz-Credential")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "X-Amz-Credential", valid_604183
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_604184 = formData.getOrDefault("ResourceArns")
  valid_604184 = validateParameter(valid_604184, JArray, required = true, default = nil)
  if valid_604184 != nil:
    section.add "ResourceArns", valid_604184
  var valid_604185 = formData.getOrDefault("TagKeys")
  valid_604185 = validateParameter(valid_604185, JArray, required = true, default = nil)
  if valid_604185 != nil:
    section.add "TagKeys", valid_604185
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604186: Call_PostRemoveTags_604172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_604186.validator(path, query, header, formData, body)
  let scheme = call_604186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604186.url(scheme.get, call_604186.host, call_604186.base,
                         call_604186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604186, url, valid)

proc call*(call_604187: Call_PostRemoveTags_604172; ResourceArns: JsonNode;
          TagKeys: JsonNode; Action: string = "RemoveTags";
          Version: string = "2015-12-01"): Recallable =
  ## postRemoveTags
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   Version: string (required)
  var query_604188 = newJObject()
  var formData_604189 = newJObject()
  if ResourceArns != nil:
    formData_604189.add "ResourceArns", ResourceArns
  add(query_604188, "Action", newJString(Action))
  if TagKeys != nil:
    formData_604189.add "TagKeys", TagKeys
  add(query_604188, "Version", newJString(Version))
  result = call_604187.call(nil, query_604188, nil, formData_604189, nil)

var postRemoveTags* = Call_PostRemoveTags_604172(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_604173,
    base: "/", url: url_PostRemoveTags_604174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_604155 = ref object of OpenApiRestCall_602466
proc url_GetRemoveTags_604157(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTags_604156(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604158 = query.getOrDefault("Action")
  valid_604158 = validateParameter(valid_604158, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_604158 != nil:
    section.add "Action", valid_604158
  var valid_604159 = query.getOrDefault("ResourceArns")
  valid_604159 = validateParameter(valid_604159, JArray, required = true, default = nil)
  if valid_604159 != nil:
    section.add "ResourceArns", valid_604159
  var valid_604160 = query.getOrDefault("TagKeys")
  valid_604160 = validateParameter(valid_604160, JArray, required = true, default = nil)
  if valid_604160 != nil:
    section.add "TagKeys", valid_604160
  var valid_604161 = query.getOrDefault("Version")
  valid_604161 = validateParameter(valid_604161, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604161 != nil:
    section.add "Version", valid_604161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604162 = header.getOrDefault("X-Amz-Date")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-Date", valid_604162
  var valid_604163 = header.getOrDefault("X-Amz-Security-Token")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "X-Amz-Security-Token", valid_604163
  var valid_604164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-Content-Sha256", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Algorithm")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Algorithm", valid_604165
  var valid_604166 = header.getOrDefault("X-Amz-Signature")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "X-Amz-Signature", valid_604166
  var valid_604167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "X-Amz-SignedHeaders", valid_604167
  var valid_604168 = header.getOrDefault("X-Amz-Credential")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-Credential", valid_604168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604169: Call_GetRemoveTags_604155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_604169.validator(path, query, header, formData, body)
  let scheme = call_604169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604169.url(scheme.get, call_604169.host, call_604169.base,
                         call_604169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604169, url, valid)

proc call*(call_604170: Call_GetRemoveTags_604155; ResourceArns: JsonNode;
          TagKeys: JsonNode; Action: string = "RemoveTags";
          Version: string = "2015-12-01"): Recallable =
  ## getRemoveTags
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ##   Action: string (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  ##   Version: string (required)
  var query_604171 = newJObject()
  add(query_604171, "Action", newJString(Action))
  if ResourceArns != nil:
    query_604171.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_604171.add "TagKeys", TagKeys
  add(query_604171, "Version", newJString(Version))
  result = call_604170.call(nil, query_604171, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_604155(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_604156,
    base: "/", url: url_GetRemoveTags_604157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_604207 = ref object of OpenApiRestCall_602466
proc url_PostSetIpAddressType_604209(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetIpAddressType_604208(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604210 = query.getOrDefault("Action")
  valid_604210 = validateParameter(valid_604210, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_604210 != nil:
    section.add "Action", valid_604210
  var valid_604211 = query.getOrDefault("Version")
  valid_604211 = validateParameter(valid_604211, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604211 != nil:
    section.add "Version", valid_604211
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604212 = header.getOrDefault("X-Amz-Date")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Date", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Security-Token")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Security-Token", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Content-Sha256", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Algorithm")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Algorithm", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Signature")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Signature", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-SignedHeaders", valid_604217
  var valid_604218 = header.getOrDefault("X-Amz-Credential")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "X-Amz-Credential", valid_604218
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_604219 = formData.getOrDefault("LoadBalancerArn")
  valid_604219 = validateParameter(valid_604219, JString, required = true,
                                 default = nil)
  if valid_604219 != nil:
    section.add "LoadBalancerArn", valid_604219
  var valid_604220 = formData.getOrDefault("IpAddressType")
  valid_604220 = validateParameter(valid_604220, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_604220 != nil:
    section.add "IpAddressType", valid_604220
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604221: Call_PostSetIpAddressType_604207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_604221.validator(path, query, header, formData, body)
  let scheme = call_604221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604221.url(scheme.get, call_604221.host, call_604221.base,
                         call_604221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604221, url, valid)

proc call*(call_604222: Call_PostSetIpAddressType_604207; LoadBalancerArn: string;
          IpAddressType: string = "ipv4"; Action: string = "SetIpAddressType";
          Version: string = "2015-12-01"): Recallable =
  ## postSetIpAddressType
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   IpAddressType: string (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604223 = newJObject()
  var formData_604224 = newJObject()
  add(formData_604224, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_604224, "IpAddressType", newJString(IpAddressType))
  add(query_604223, "Action", newJString(Action))
  add(query_604223, "Version", newJString(Version))
  result = call_604222.call(nil, query_604223, nil, formData_604224, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_604207(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_604208,
    base: "/", url: url_PostSetIpAddressType_604209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_604190 = ref object of OpenApiRestCall_602466
proc url_GetSetIpAddressType_604192(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetIpAddressType_604191(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `IpAddressType` field"
  var valid_604193 = query.getOrDefault("IpAddressType")
  valid_604193 = validateParameter(valid_604193, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_604193 != nil:
    section.add "IpAddressType", valid_604193
  var valid_604194 = query.getOrDefault("Action")
  valid_604194 = validateParameter(valid_604194, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_604194 != nil:
    section.add "Action", valid_604194
  var valid_604195 = query.getOrDefault("LoadBalancerArn")
  valid_604195 = validateParameter(valid_604195, JString, required = true,
                                 default = nil)
  if valid_604195 != nil:
    section.add "LoadBalancerArn", valid_604195
  var valid_604196 = query.getOrDefault("Version")
  valid_604196 = validateParameter(valid_604196, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604196 != nil:
    section.add "Version", valid_604196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604197 = header.getOrDefault("X-Amz-Date")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Date", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Security-Token")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Security-Token", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Content-Sha256", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-Algorithm")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Algorithm", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-Signature")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Signature", valid_604201
  var valid_604202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "X-Amz-SignedHeaders", valid_604202
  var valid_604203 = header.getOrDefault("X-Amz-Credential")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-Credential", valid_604203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604204: Call_GetSetIpAddressType_604190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_604204.validator(path, query, header, formData, body)
  let scheme = call_604204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604204.url(scheme.get, call_604204.host, call_604204.base,
                         call_604204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604204, url, valid)

proc call*(call_604205: Call_GetSetIpAddressType_604190; LoadBalancerArn: string;
          IpAddressType: string = "ipv4"; Action: string = "SetIpAddressType";
          Version: string = "2015-12-01"): Recallable =
  ## getSetIpAddressType
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ##   IpAddressType: string (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_604206 = newJObject()
  add(query_604206, "IpAddressType", newJString(IpAddressType))
  add(query_604206, "Action", newJString(Action))
  add(query_604206, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_604206, "Version", newJString(Version))
  result = call_604205.call(nil, query_604206, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_604190(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_604191,
    base: "/", url: url_GetSetIpAddressType_604192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_604241 = ref object of OpenApiRestCall_602466
proc url_PostSetRulePriorities_604243(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetRulePriorities_604242(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604244 = query.getOrDefault("Action")
  valid_604244 = validateParameter(valid_604244, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_604244 != nil:
    section.add "Action", valid_604244
  var valid_604245 = query.getOrDefault("Version")
  valid_604245 = validateParameter(valid_604245, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604245 != nil:
    section.add "Version", valid_604245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604246 = header.getOrDefault("X-Amz-Date")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Date", valid_604246
  var valid_604247 = header.getOrDefault("X-Amz-Security-Token")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Security-Token", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Content-Sha256", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-Algorithm")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Algorithm", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Signature")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Signature", valid_604250
  var valid_604251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "X-Amz-SignedHeaders", valid_604251
  var valid_604252 = header.getOrDefault("X-Amz-Credential")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "X-Amz-Credential", valid_604252
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_604253 = formData.getOrDefault("RulePriorities")
  valid_604253 = validateParameter(valid_604253, JArray, required = true, default = nil)
  if valid_604253 != nil:
    section.add "RulePriorities", valid_604253
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604254: Call_PostSetRulePriorities_604241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_604254.validator(path, query, header, formData, body)
  let scheme = call_604254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604254.url(scheme.get, call_604254.host, call_604254.base,
                         call_604254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604254, url, valid)

proc call*(call_604255: Call_PostSetRulePriorities_604241;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604256 = newJObject()
  var formData_604257 = newJObject()
  if RulePriorities != nil:
    formData_604257.add "RulePriorities", RulePriorities
  add(query_604256, "Action", newJString(Action))
  add(query_604256, "Version", newJString(Version))
  result = call_604255.call(nil, query_604256, nil, formData_604257, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_604241(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_604242, base: "/",
    url: url_PostSetRulePriorities_604243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_604225 = ref object of OpenApiRestCall_602466
proc url_GetSetRulePriorities_604227(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetRulePriorities_604226(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `RulePriorities` field"
  var valid_604228 = query.getOrDefault("RulePriorities")
  valid_604228 = validateParameter(valid_604228, JArray, required = true, default = nil)
  if valid_604228 != nil:
    section.add "RulePriorities", valid_604228
  var valid_604229 = query.getOrDefault("Action")
  valid_604229 = validateParameter(valid_604229, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_604229 != nil:
    section.add "Action", valid_604229
  var valid_604230 = query.getOrDefault("Version")
  valid_604230 = validateParameter(valid_604230, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604230 != nil:
    section.add "Version", valid_604230
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604231 = header.getOrDefault("X-Amz-Date")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Date", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-Security-Token")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-Security-Token", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Content-Sha256", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-Algorithm")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Algorithm", valid_604234
  var valid_604235 = header.getOrDefault("X-Amz-Signature")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "X-Amz-Signature", valid_604235
  var valid_604236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604236 = validateParameter(valid_604236, JString, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "X-Amz-SignedHeaders", valid_604236
  var valid_604237 = header.getOrDefault("X-Amz-Credential")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "X-Amz-Credential", valid_604237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604238: Call_GetSetRulePriorities_604225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_604238.validator(path, query, header, formData, body)
  let scheme = call_604238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604238.url(scheme.get, call_604238.host, call_604238.base,
                         call_604238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604238, url, valid)

proc call*(call_604239: Call_GetSetRulePriorities_604225; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604240 = newJObject()
  if RulePriorities != nil:
    query_604240.add "RulePriorities", RulePriorities
  add(query_604240, "Action", newJString(Action))
  add(query_604240, "Version", newJString(Version))
  result = call_604239.call(nil, query_604240, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_604225(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_604226,
    base: "/", url: url_GetSetRulePriorities_604227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_604275 = ref object of OpenApiRestCall_602466
proc url_PostSetSecurityGroups_604277(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSecurityGroups_604276(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604278 = query.getOrDefault("Action")
  valid_604278 = validateParameter(valid_604278, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_604278 != nil:
    section.add "Action", valid_604278
  var valid_604279 = query.getOrDefault("Version")
  valid_604279 = validateParameter(valid_604279, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604279 != nil:
    section.add "Version", valid_604279
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604280 = header.getOrDefault("X-Amz-Date")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Date", valid_604280
  var valid_604281 = header.getOrDefault("X-Amz-Security-Token")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-Security-Token", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Content-Sha256", valid_604282
  var valid_604283 = header.getOrDefault("X-Amz-Algorithm")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-Algorithm", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-Signature")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-Signature", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-SignedHeaders", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-Credential")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-Credential", valid_604286
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_604287 = formData.getOrDefault("LoadBalancerArn")
  valid_604287 = validateParameter(valid_604287, JString, required = true,
                                 default = nil)
  if valid_604287 != nil:
    section.add "LoadBalancerArn", valid_604287
  var valid_604288 = formData.getOrDefault("SecurityGroups")
  valid_604288 = validateParameter(valid_604288, JArray, required = true, default = nil)
  if valid_604288 != nil:
    section.add "SecurityGroups", valid_604288
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604289: Call_PostSetSecurityGroups_604275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_604289.validator(path, query, header, formData, body)
  let scheme = call_604289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604289.url(scheme.get, call_604289.host, call_604289.base,
                         call_604289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604289, url, valid)

proc call*(call_604290: Call_PostSetSecurityGroups_604275; LoadBalancerArn: string;
          SecurityGroups: JsonNode; Action: string = "SetSecurityGroups";
          Version: string = "2015-12-01"): Recallable =
  ## postSetSecurityGroups
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  ##   Version: string (required)
  var query_604291 = newJObject()
  var formData_604292 = newJObject()
  add(formData_604292, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_604291, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_604292.add "SecurityGroups", SecurityGroups
  add(query_604291, "Version", newJString(Version))
  result = call_604290.call(nil, query_604291, nil, formData_604292, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_604275(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_604276, base: "/",
    url: url_PostSetSecurityGroups_604277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_604258 = ref object of OpenApiRestCall_602466
proc url_GetSetSecurityGroups_604260(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSecurityGroups_604259(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: JString (required)
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604261 = query.getOrDefault("Action")
  valid_604261 = validateParameter(valid_604261, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_604261 != nil:
    section.add "Action", valid_604261
  var valid_604262 = query.getOrDefault("LoadBalancerArn")
  valid_604262 = validateParameter(valid_604262, JString, required = true,
                                 default = nil)
  if valid_604262 != nil:
    section.add "LoadBalancerArn", valid_604262
  var valid_604263 = query.getOrDefault("Version")
  valid_604263 = validateParameter(valid_604263, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604263 != nil:
    section.add "Version", valid_604263
  var valid_604264 = query.getOrDefault("SecurityGroups")
  valid_604264 = validateParameter(valid_604264, JArray, required = true, default = nil)
  if valid_604264 != nil:
    section.add "SecurityGroups", valid_604264
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604265 = header.getOrDefault("X-Amz-Date")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Date", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-Security-Token")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-Security-Token", valid_604266
  var valid_604267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-Content-Sha256", valid_604267
  var valid_604268 = header.getOrDefault("X-Amz-Algorithm")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-Algorithm", valid_604268
  var valid_604269 = header.getOrDefault("X-Amz-Signature")
  valid_604269 = validateParameter(valid_604269, JString, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "X-Amz-Signature", valid_604269
  var valid_604270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "X-Amz-SignedHeaders", valid_604270
  var valid_604271 = header.getOrDefault("X-Amz-Credential")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Credential", valid_604271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604272: Call_GetSetSecurityGroups_604258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_604272.validator(path, query, header, formData, body)
  let scheme = call_604272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604272.url(scheme.get, call_604272.host, call_604272.base,
                         call_604272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604272, url, valid)

proc call*(call_604273: Call_GetSetSecurityGroups_604258; LoadBalancerArn: string;
          SecurityGroups: JsonNode; Action: string = "SetSecurityGroups";
          Version: string = "2015-12-01"): Recallable =
  ## getSetSecurityGroups
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  var query_604274 = newJObject()
  add(query_604274, "Action", newJString(Action))
  add(query_604274, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_604274, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_604274.add "SecurityGroups", SecurityGroups
  result = call_604273.call(nil, query_604274, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_604258(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_604259,
    base: "/", url: url_GetSetSecurityGroups_604260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_604311 = ref object of OpenApiRestCall_602466
proc url_PostSetSubnets_604313(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSubnets_604312(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604314 = query.getOrDefault("Action")
  valid_604314 = validateParameter(valid_604314, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_604314 != nil:
    section.add "Action", valid_604314
  var valid_604315 = query.getOrDefault("Version")
  valid_604315 = validateParameter(valid_604315, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604315 != nil:
    section.add "Version", valid_604315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604316 = header.getOrDefault("X-Amz-Date")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Date", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Security-Token")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Security-Token", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-Content-Sha256", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-Algorithm")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-Algorithm", valid_604319
  var valid_604320 = header.getOrDefault("X-Amz-Signature")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "X-Amz-Signature", valid_604320
  var valid_604321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "X-Amz-SignedHeaders", valid_604321
  var valid_604322 = header.getOrDefault("X-Amz-Credential")
  valid_604322 = validateParameter(valid_604322, JString, required = false,
                                 default = nil)
  if valid_604322 != nil:
    section.add "X-Amz-Credential", valid_604322
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>You cannot specify Elastic IP addresses for your subnets.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_604323 = formData.getOrDefault("LoadBalancerArn")
  valid_604323 = validateParameter(valid_604323, JString, required = true,
                                 default = nil)
  if valid_604323 != nil:
    section.add "LoadBalancerArn", valid_604323
  var valid_604324 = formData.getOrDefault("Subnets")
  valid_604324 = validateParameter(valid_604324, JArray, required = false,
                                 default = nil)
  if valid_604324 != nil:
    section.add "Subnets", valid_604324
  var valid_604325 = formData.getOrDefault("SubnetMappings")
  valid_604325 = validateParameter(valid_604325, JArray, required = false,
                                 default = nil)
  if valid_604325 != nil:
    section.add "SubnetMappings", valid_604325
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604326: Call_PostSetSubnets_604311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_604326.validator(path, query, header, formData, body)
  let scheme = call_604326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604326.url(scheme.get, call_604326.host, call_604326.base,
                         call_604326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604326, url, valid)

proc call*(call_604327: Call_PostSetSubnets_604311; LoadBalancerArn: string;
          Action: string = "SetSubnets"; Subnets: JsonNode = nil;
          SubnetMappings: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## postSetSubnets
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>You cannot specify Elastic IP addresses for your subnets.</p>
  ##   Version: string (required)
  var query_604328 = newJObject()
  var formData_604329 = newJObject()
  add(formData_604329, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_604328, "Action", newJString(Action))
  if Subnets != nil:
    formData_604329.add "Subnets", Subnets
  if SubnetMappings != nil:
    formData_604329.add "SubnetMappings", SubnetMappings
  add(query_604328, "Version", newJString(Version))
  result = call_604327.call(nil, query_604328, nil, formData_604329, nil)

var postSetSubnets* = Call_PostSetSubnets_604311(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_604312,
    base: "/", url: url_PostSetSubnets_604313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_604293 = ref object of OpenApiRestCall_602466
proc url_GetSetSubnets_604295(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSubnets_604294(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>You cannot specify Elastic IP addresses for your subnets.</p>
  ##   Action: JString (required)
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   Version: JString (required)
  section = newJObject()
  var valid_604296 = query.getOrDefault("SubnetMappings")
  valid_604296 = validateParameter(valid_604296, JArray, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "SubnetMappings", valid_604296
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604297 = query.getOrDefault("Action")
  valid_604297 = validateParameter(valid_604297, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_604297 != nil:
    section.add "Action", valid_604297
  var valid_604298 = query.getOrDefault("LoadBalancerArn")
  valid_604298 = validateParameter(valid_604298, JString, required = true,
                                 default = nil)
  if valid_604298 != nil:
    section.add "LoadBalancerArn", valid_604298
  var valid_604299 = query.getOrDefault("Subnets")
  valid_604299 = validateParameter(valid_604299, JArray, required = false,
                                 default = nil)
  if valid_604299 != nil:
    section.add "Subnets", valid_604299
  var valid_604300 = query.getOrDefault("Version")
  valid_604300 = validateParameter(valid_604300, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604300 != nil:
    section.add "Version", valid_604300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604301 = header.getOrDefault("X-Amz-Date")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-Date", valid_604301
  var valid_604302 = header.getOrDefault("X-Amz-Security-Token")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-Security-Token", valid_604302
  var valid_604303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "X-Amz-Content-Sha256", valid_604303
  var valid_604304 = header.getOrDefault("X-Amz-Algorithm")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "X-Amz-Algorithm", valid_604304
  var valid_604305 = header.getOrDefault("X-Amz-Signature")
  valid_604305 = validateParameter(valid_604305, JString, required = false,
                                 default = nil)
  if valid_604305 != nil:
    section.add "X-Amz-Signature", valid_604305
  var valid_604306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "X-Amz-SignedHeaders", valid_604306
  var valid_604307 = header.getOrDefault("X-Amz-Credential")
  valid_604307 = validateParameter(valid_604307, JString, required = false,
                                 default = nil)
  if valid_604307 != nil:
    section.add "X-Amz-Credential", valid_604307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604308: Call_GetSetSubnets_604293; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_604308.validator(path, query, header, formData, body)
  let scheme = call_604308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604308.url(scheme.get, call_604308.host, call_604308.base,
                         call_604308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604308, url, valid)

proc call*(call_604309: Call_GetSetSubnets_604293; LoadBalancerArn: string;
          SubnetMappings: JsonNode = nil; Action: string = "SetSubnets";
          Subnets: JsonNode = nil; Version: string = "2015-12-01"): Recallable =
  ## getSetSubnets
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ##   SubnetMappings: JArray
  ##                 : <p>The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.</p> <p>You cannot specify Elastic IP addresses for your subnets.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Subnets: JArray
  ##          : The IDs of the public subnets. You must specify subnets from at least two Availability Zones. You can specify only one subnet per Availability Zone. You must specify either subnets or subnet mappings.
  ##   Version: string (required)
  var query_604310 = newJObject()
  if SubnetMappings != nil:
    query_604310.add "SubnetMappings", SubnetMappings
  add(query_604310, "Action", newJString(Action))
  add(query_604310, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Subnets != nil:
    query_604310.add "Subnets", Subnets
  add(query_604310, "Version", newJString(Version))
  result = call_604309.call(nil, query_604310, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_604293(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_604294,
    base: "/", url: url_GetSetSubnets_604295, schemes: {Scheme.Https, Scheme.Http})
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
