
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAddListenerCertificates_601040 = ref object of OpenApiRestCall_600426
proc url_PostAddListenerCertificates_601042(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddListenerCertificates_601041(path: JsonNode; query: JsonNode;
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
  var valid_601043 = query.getOrDefault("Action")
  valid_601043 = validateParameter(valid_601043, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_601043 != nil:
    section.add "Action", valid_601043
  var valid_601044 = query.getOrDefault("Version")
  valid_601044 = validateParameter(valid_601044, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601044 != nil:
    section.add "Version", valid_601044
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
  var valid_601045 = header.getOrDefault("X-Amz-Date")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Date", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Security-Token")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Security-Token", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Content-Sha256", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Algorithm")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Algorithm", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Signature")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Signature", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-SignedHeaders", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Credential")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Credential", valid_601051
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_601052 = formData.getOrDefault("Certificates")
  valid_601052 = validateParameter(valid_601052, JArray, required = true, default = nil)
  if valid_601052 != nil:
    section.add "Certificates", valid_601052
  var valid_601053 = formData.getOrDefault("ListenerArn")
  valid_601053 = validateParameter(valid_601053, JString, required = true,
                                 default = nil)
  if valid_601053 != nil:
    section.add "ListenerArn", valid_601053
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601054: Call_PostAddListenerCertificates_601040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601054.validator(path, query, header, formData, body)
  let scheme = call_601054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601054.url(scheme.get, call_601054.host, call_601054.base,
                         call_601054.route, valid.getOrDefault("path"))
  result = hook(call_601054, url, valid)

proc call*(call_601055: Call_PostAddListenerCertificates_601040;
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
  var query_601056 = newJObject()
  var formData_601057 = newJObject()
  if Certificates != nil:
    formData_601057.add "Certificates", Certificates
  add(formData_601057, "ListenerArn", newJString(ListenerArn))
  add(query_601056, "Action", newJString(Action))
  add(query_601056, "Version", newJString(Version))
  result = call_601055.call(nil, query_601056, nil, formData_601057, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_601040(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_601041, base: "/",
    url: url_PostAddListenerCertificates_601042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_600768 = ref object of OpenApiRestCall_600426
proc url_GetAddListenerCertificates_600770(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddListenerCertificates_600769(path: JsonNode; query: JsonNode;
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
  var valid_600882 = query.getOrDefault("Certificates")
  valid_600882 = validateParameter(valid_600882, JArray, required = true, default = nil)
  if valid_600882 != nil:
    section.add "Certificates", valid_600882
  var valid_600896 = query.getOrDefault("Action")
  valid_600896 = validateParameter(valid_600896, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_600896 != nil:
    section.add "Action", valid_600896
  var valid_600897 = query.getOrDefault("ListenerArn")
  valid_600897 = validateParameter(valid_600897, JString, required = true,
                                 default = nil)
  if valid_600897 != nil:
    section.add "ListenerArn", valid_600897
  var valid_600898 = query.getOrDefault("Version")
  valid_600898 = validateParameter(valid_600898, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_600898 != nil:
    section.add "Version", valid_600898
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
  var valid_600899 = header.getOrDefault("X-Amz-Date")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Date", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Security-Token")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Security-Token", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Content-Sha256", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Algorithm")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Algorithm", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Signature")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Signature", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-SignedHeaders", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Credential")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Credential", valid_600905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600928: Call_GetAddListenerCertificates_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600928.validator(path, query, header, formData, body)
  let scheme = call_600928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600928.url(scheme.get, call_600928.host, call_600928.base,
                         call_600928.route, valid.getOrDefault("path"))
  result = hook(call_600928, url, valid)

proc call*(call_600999: Call_GetAddListenerCertificates_600768;
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
  var query_601000 = newJObject()
  if Certificates != nil:
    query_601000.add "Certificates", Certificates
  add(query_601000, "Action", newJString(Action))
  add(query_601000, "ListenerArn", newJString(ListenerArn))
  add(query_601000, "Version", newJString(Version))
  result = call_600999.call(nil, query_601000, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_600768(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_600769, base: "/",
    url: url_GetAddListenerCertificates_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_601075 = ref object of OpenApiRestCall_600426
proc url_PostAddTags_601077(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddTags_601076(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601078 = query.getOrDefault("Action")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_601078 != nil:
    section.add "Action", valid_601078
  var valid_601079 = query.getOrDefault("Version")
  valid_601079 = validateParameter(valid_601079, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601079 != nil:
    section.add "Version", valid_601079
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
  var valid_601080 = header.getOrDefault("X-Amz-Date")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Date", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Security-Token")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Security-Token", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Content-Sha256", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Algorithm")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Algorithm", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Signature")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Signature", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-SignedHeaders", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Credential")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Credential", valid_601086
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_601087 = formData.getOrDefault("ResourceArns")
  valid_601087 = validateParameter(valid_601087, JArray, required = true, default = nil)
  if valid_601087 != nil:
    section.add "ResourceArns", valid_601087
  var valid_601088 = formData.getOrDefault("Tags")
  valid_601088 = validateParameter(valid_601088, JArray, required = true, default = nil)
  if valid_601088 != nil:
    section.add "Tags", valid_601088
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601089: Call_PostAddTags_601075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_601089.validator(path, query, header, formData, body)
  let scheme = call_601089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601089.url(scheme.get, call_601089.host, call_601089.base,
                         call_601089.route, valid.getOrDefault("path"))
  result = hook(call_601089, url, valid)

proc call*(call_601090: Call_PostAddTags_601075; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601091 = newJObject()
  var formData_601092 = newJObject()
  if ResourceArns != nil:
    formData_601092.add "ResourceArns", ResourceArns
  if Tags != nil:
    formData_601092.add "Tags", Tags
  add(query_601091, "Action", newJString(Action))
  add(query_601091, "Version", newJString(Version))
  result = call_601090.call(nil, query_601091, nil, formData_601092, nil)

var postAddTags* = Call_PostAddTags_601075(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_601076,
                                        base: "/", url: url_PostAddTags_601077,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_601058 = ref object of OpenApiRestCall_600426
proc url_GetAddTags_601060(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddTags_601059(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601061 = query.getOrDefault("Tags")
  valid_601061 = validateParameter(valid_601061, JArray, required = true, default = nil)
  if valid_601061 != nil:
    section.add "Tags", valid_601061
  var valid_601062 = query.getOrDefault("Action")
  valid_601062 = validateParameter(valid_601062, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_601062 != nil:
    section.add "Action", valid_601062
  var valid_601063 = query.getOrDefault("ResourceArns")
  valid_601063 = validateParameter(valid_601063, JArray, required = true, default = nil)
  if valid_601063 != nil:
    section.add "ResourceArns", valid_601063
  var valid_601064 = query.getOrDefault("Version")
  valid_601064 = validateParameter(valid_601064, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601064 != nil:
    section.add "Version", valid_601064
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
  var valid_601065 = header.getOrDefault("X-Amz-Date")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Date", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Security-Token")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Security-Token", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Content-Sha256", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Algorithm")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Algorithm", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Signature")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Signature", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-SignedHeaders", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Credential")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Credential", valid_601071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601072: Call_GetAddTags_601058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_601072.validator(path, query, header, formData, body)
  let scheme = call_601072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601072.url(scheme.get, call_601072.host, call_601072.base,
                         call_601072.route, valid.getOrDefault("path"))
  result = hook(call_601072, url, valid)

proc call*(call_601073: Call_GetAddTags_601058; Tags: JsonNode;
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
  var query_601074 = newJObject()
  if Tags != nil:
    query_601074.add "Tags", Tags
  add(query_601074, "Action", newJString(Action))
  if ResourceArns != nil:
    query_601074.add "ResourceArns", ResourceArns
  add(query_601074, "Version", newJString(Version))
  result = call_601073.call(nil, query_601074, nil, nil, nil)

var getAddTags* = Call_GetAddTags_601058(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_601059,
                                      base: "/", url: url_GetAddTags_601060,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_601114 = ref object of OpenApiRestCall_600426
proc url_PostCreateListener_601116(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateListener_601115(path: JsonNode; query: JsonNode;
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
  var valid_601117 = query.getOrDefault("Action")
  valid_601117 = validateParameter(valid_601117, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_601117 != nil:
    section.add "Action", valid_601117
  var valid_601118 = query.getOrDefault("Version")
  valid_601118 = validateParameter(valid_601118, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601118 != nil:
    section.add "Version", valid_601118
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
  var valid_601119 = header.getOrDefault("X-Amz-Date")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Date", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Security-Token")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Security-Token", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Content-Sha256", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Algorithm")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Algorithm", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Signature")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Signature", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-SignedHeaders", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Credential")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Credential", valid_601125
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
  var valid_601126 = formData.getOrDefault("Certificates")
  valid_601126 = validateParameter(valid_601126, JArray, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "Certificates", valid_601126
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_601127 = formData.getOrDefault("LoadBalancerArn")
  valid_601127 = validateParameter(valid_601127, JString, required = true,
                                 default = nil)
  if valid_601127 != nil:
    section.add "LoadBalancerArn", valid_601127
  var valid_601128 = formData.getOrDefault("Port")
  valid_601128 = validateParameter(valid_601128, JInt, required = true, default = nil)
  if valid_601128 != nil:
    section.add "Port", valid_601128
  var valid_601129 = formData.getOrDefault("Protocol")
  valid_601129 = validateParameter(valid_601129, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_601129 != nil:
    section.add "Protocol", valid_601129
  var valid_601130 = formData.getOrDefault("SslPolicy")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "SslPolicy", valid_601130
  var valid_601131 = formData.getOrDefault("DefaultActions")
  valid_601131 = validateParameter(valid_601131, JArray, required = true, default = nil)
  if valid_601131 != nil:
    section.add "DefaultActions", valid_601131
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601132: Call_PostCreateListener_601114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601132.validator(path, query, header, formData, body)
  let scheme = call_601132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601132.url(scheme.get, call_601132.host, call_601132.base,
                         call_601132.route, valid.getOrDefault("path"))
  result = hook(call_601132, url, valid)

proc call*(call_601133: Call_PostCreateListener_601114; LoadBalancerArn: string;
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
  var query_601134 = newJObject()
  var formData_601135 = newJObject()
  if Certificates != nil:
    formData_601135.add "Certificates", Certificates
  add(formData_601135, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_601135, "Port", newJInt(Port))
  add(formData_601135, "Protocol", newJString(Protocol))
  add(query_601134, "Action", newJString(Action))
  add(formData_601135, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_601135.add "DefaultActions", DefaultActions
  add(query_601134, "Version", newJString(Version))
  result = call_601133.call(nil, query_601134, nil, formData_601135, nil)

var postCreateListener* = Call_PostCreateListener_601114(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_601115, base: "/",
    url: url_PostCreateListener_601116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_601093 = ref object of OpenApiRestCall_600426
proc url_GetCreateListener_601095(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateListener_601094(path: JsonNode; query: JsonNode;
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
  var valid_601096 = query.getOrDefault("DefaultActions")
  valid_601096 = validateParameter(valid_601096, JArray, required = true, default = nil)
  if valid_601096 != nil:
    section.add "DefaultActions", valid_601096
  var valid_601097 = query.getOrDefault("SslPolicy")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "SslPolicy", valid_601097
  var valid_601098 = query.getOrDefault("Protocol")
  valid_601098 = validateParameter(valid_601098, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_601098 != nil:
    section.add "Protocol", valid_601098
  var valid_601099 = query.getOrDefault("Certificates")
  valid_601099 = validateParameter(valid_601099, JArray, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "Certificates", valid_601099
  var valid_601100 = query.getOrDefault("Action")
  valid_601100 = validateParameter(valid_601100, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_601100 != nil:
    section.add "Action", valid_601100
  var valid_601101 = query.getOrDefault("LoadBalancerArn")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = nil)
  if valid_601101 != nil:
    section.add "LoadBalancerArn", valid_601101
  var valid_601102 = query.getOrDefault("Port")
  valid_601102 = validateParameter(valid_601102, JInt, required = true, default = nil)
  if valid_601102 != nil:
    section.add "Port", valid_601102
  var valid_601103 = query.getOrDefault("Version")
  valid_601103 = validateParameter(valid_601103, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601103 != nil:
    section.add "Version", valid_601103
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
  var valid_601104 = header.getOrDefault("X-Amz-Date")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Date", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Security-Token")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Security-Token", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Content-Sha256", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Algorithm")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Algorithm", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Signature")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Signature", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-SignedHeaders", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Credential")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Credential", valid_601110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601111: Call_GetCreateListener_601093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601111.validator(path, query, header, formData, body)
  let scheme = call_601111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601111.url(scheme.get, call_601111.host, call_601111.base,
                         call_601111.route, valid.getOrDefault("path"))
  result = hook(call_601111, url, valid)

proc call*(call_601112: Call_GetCreateListener_601093; DefaultActions: JsonNode;
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
  var query_601113 = newJObject()
  if DefaultActions != nil:
    query_601113.add "DefaultActions", DefaultActions
  add(query_601113, "SslPolicy", newJString(SslPolicy))
  add(query_601113, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_601113.add "Certificates", Certificates
  add(query_601113, "Action", newJString(Action))
  add(query_601113, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_601113, "Port", newJInt(Port))
  add(query_601113, "Version", newJString(Version))
  result = call_601112.call(nil, query_601113, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_601093(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_601094,
    base: "/", url: url_GetCreateListener_601095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_601159 = ref object of OpenApiRestCall_600426
proc url_PostCreateLoadBalancer_601161(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateLoadBalancer_601160(path: JsonNode; query: JsonNode;
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
  var valid_601162 = query.getOrDefault("Action")
  valid_601162 = validateParameter(valid_601162, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_601162 != nil:
    section.add "Action", valid_601162
  var valid_601163 = query.getOrDefault("Version")
  valid_601163 = validateParameter(valid_601163, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601163 != nil:
    section.add "Version", valid_601163
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
  var valid_601164 = header.getOrDefault("X-Amz-Date")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Date", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Security-Token")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Security-Token", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Content-Sha256", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Algorithm")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Algorithm", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Signature")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Signature", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-SignedHeaders", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Credential")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Credential", valid_601170
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
  var valid_601171 = formData.getOrDefault("Name")
  valid_601171 = validateParameter(valid_601171, JString, required = true,
                                 default = nil)
  if valid_601171 != nil:
    section.add "Name", valid_601171
  var valid_601172 = formData.getOrDefault("IpAddressType")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_601172 != nil:
    section.add "IpAddressType", valid_601172
  var valid_601173 = formData.getOrDefault("Tags")
  valid_601173 = validateParameter(valid_601173, JArray, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "Tags", valid_601173
  var valid_601174 = formData.getOrDefault("Type")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = newJString("application"))
  if valid_601174 != nil:
    section.add "Type", valid_601174
  var valid_601175 = formData.getOrDefault("Subnets")
  valid_601175 = validateParameter(valid_601175, JArray, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "Subnets", valid_601175
  var valid_601176 = formData.getOrDefault("SecurityGroups")
  valid_601176 = validateParameter(valid_601176, JArray, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "SecurityGroups", valid_601176
  var valid_601177 = formData.getOrDefault("SubnetMappings")
  valid_601177 = validateParameter(valid_601177, JArray, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "SubnetMappings", valid_601177
  var valid_601178 = formData.getOrDefault("Scheme")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_601178 != nil:
    section.add "Scheme", valid_601178
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601179: Call_PostCreateLoadBalancer_601159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601179.validator(path, query, header, formData, body)
  let scheme = call_601179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601179.url(scheme.get, call_601179.host, call_601179.base,
                         call_601179.route, valid.getOrDefault("path"))
  result = hook(call_601179, url, valid)

proc call*(call_601180: Call_PostCreateLoadBalancer_601159; Name: string;
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
  var query_601181 = newJObject()
  var formData_601182 = newJObject()
  add(formData_601182, "Name", newJString(Name))
  add(formData_601182, "IpAddressType", newJString(IpAddressType))
  if Tags != nil:
    formData_601182.add "Tags", Tags
  add(formData_601182, "Type", newJString(Type))
  add(query_601181, "Action", newJString(Action))
  if Subnets != nil:
    formData_601182.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_601182.add "SecurityGroups", SecurityGroups
  if SubnetMappings != nil:
    formData_601182.add "SubnetMappings", SubnetMappings
  add(formData_601182, "Scheme", newJString(Scheme))
  add(query_601181, "Version", newJString(Version))
  result = call_601180.call(nil, query_601181, nil, formData_601182, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_601159(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_601160, base: "/",
    url: url_PostCreateLoadBalancer_601161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_601136 = ref object of OpenApiRestCall_600426
proc url_GetCreateLoadBalancer_601138(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateLoadBalancer_601137(path: JsonNode; query: JsonNode;
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
  var valid_601139 = query.getOrDefault("Name")
  valid_601139 = validateParameter(valid_601139, JString, required = true,
                                 default = nil)
  if valid_601139 != nil:
    section.add "Name", valid_601139
  var valid_601140 = query.getOrDefault("SubnetMappings")
  valid_601140 = validateParameter(valid_601140, JArray, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "SubnetMappings", valid_601140
  var valid_601141 = query.getOrDefault("IpAddressType")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_601141 != nil:
    section.add "IpAddressType", valid_601141
  var valid_601142 = query.getOrDefault("Scheme")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_601142 != nil:
    section.add "Scheme", valid_601142
  var valid_601143 = query.getOrDefault("Tags")
  valid_601143 = validateParameter(valid_601143, JArray, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "Tags", valid_601143
  var valid_601144 = query.getOrDefault("Type")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = newJString("application"))
  if valid_601144 != nil:
    section.add "Type", valid_601144
  var valid_601145 = query.getOrDefault("Action")
  valid_601145 = validateParameter(valid_601145, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_601145 != nil:
    section.add "Action", valid_601145
  var valid_601146 = query.getOrDefault("Subnets")
  valid_601146 = validateParameter(valid_601146, JArray, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "Subnets", valid_601146
  var valid_601147 = query.getOrDefault("Version")
  valid_601147 = validateParameter(valid_601147, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601147 != nil:
    section.add "Version", valid_601147
  var valid_601148 = query.getOrDefault("SecurityGroups")
  valid_601148 = validateParameter(valid_601148, JArray, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "SecurityGroups", valid_601148
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
  var valid_601149 = header.getOrDefault("X-Amz-Date")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Date", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Security-Token")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Security-Token", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Content-Sha256", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Algorithm")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Algorithm", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Signature")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Signature", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-SignedHeaders", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Credential")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Credential", valid_601155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601156: Call_GetCreateLoadBalancer_601136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601156.validator(path, query, header, formData, body)
  let scheme = call_601156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601156.url(scheme.get, call_601156.host, call_601156.base,
                         call_601156.route, valid.getOrDefault("path"))
  result = hook(call_601156, url, valid)

proc call*(call_601157: Call_GetCreateLoadBalancer_601136; Name: string;
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
  var query_601158 = newJObject()
  add(query_601158, "Name", newJString(Name))
  if SubnetMappings != nil:
    query_601158.add "SubnetMappings", SubnetMappings
  add(query_601158, "IpAddressType", newJString(IpAddressType))
  add(query_601158, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_601158.add "Tags", Tags
  add(query_601158, "Type", newJString(Type))
  add(query_601158, "Action", newJString(Action))
  if Subnets != nil:
    query_601158.add "Subnets", Subnets
  add(query_601158, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_601158.add "SecurityGroups", SecurityGroups
  result = call_601157.call(nil, query_601158, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_601136(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_601137, base: "/",
    url: url_GetCreateLoadBalancer_601138, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_601202 = ref object of OpenApiRestCall_600426
proc url_PostCreateRule_601204(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateRule_601203(path: JsonNode; query: JsonNode;
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
  var valid_601205 = query.getOrDefault("Action")
  valid_601205 = validateParameter(valid_601205, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_601205 != nil:
    section.add "Action", valid_601205
  var valid_601206 = query.getOrDefault("Version")
  valid_601206 = validateParameter(valid_601206, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601206 != nil:
    section.add "Version", valid_601206
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
  var valid_601207 = header.getOrDefault("X-Amz-Date")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Date", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Security-Token")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Security-Token", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Content-Sha256", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Algorithm")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Algorithm", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Signature")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Signature", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-SignedHeaders", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Credential")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Credential", valid_601213
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
  var valid_601214 = formData.getOrDefault("ListenerArn")
  valid_601214 = validateParameter(valid_601214, JString, required = true,
                                 default = nil)
  if valid_601214 != nil:
    section.add "ListenerArn", valid_601214
  var valid_601215 = formData.getOrDefault("Actions")
  valid_601215 = validateParameter(valid_601215, JArray, required = true, default = nil)
  if valid_601215 != nil:
    section.add "Actions", valid_601215
  var valid_601216 = formData.getOrDefault("Conditions")
  valid_601216 = validateParameter(valid_601216, JArray, required = true, default = nil)
  if valid_601216 != nil:
    section.add "Conditions", valid_601216
  var valid_601217 = formData.getOrDefault("Priority")
  valid_601217 = validateParameter(valid_601217, JInt, required = true, default = nil)
  if valid_601217 != nil:
    section.add "Priority", valid_601217
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601218: Call_PostCreateRule_601202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_601218.validator(path, query, header, formData, body)
  let scheme = call_601218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601218.url(scheme.get, call_601218.host, call_601218.base,
                         call_601218.route, valid.getOrDefault("path"))
  result = hook(call_601218, url, valid)

proc call*(call_601219: Call_PostCreateRule_601202; ListenerArn: string;
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
  var query_601220 = newJObject()
  var formData_601221 = newJObject()
  add(formData_601221, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    formData_601221.add "Actions", Actions
  if Conditions != nil:
    formData_601221.add "Conditions", Conditions
  add(query_601220, "Action", newJString(Action))
  add(formData_601221, "Priority", newJInt(Priority))
  add(query_601220, "Version", newJString(Version))
  result = call_601219.call(nil, query_601220, nil, formData_601221, nil)

var postCreateRule* = Call_PostCreateRule_601202(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_601203,
    base: "/", url: url_PostCreateRule_601204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_601183 = ref object of OpenApiRestCall_600426
proc url_GetCreateRule_601185(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateRule_601184(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601186 = query.getOrDefault("Conditions")
  valid_601186 = validateParameter(valid_601186, JArray, required = true, default = nil)
  if valid_601186 != nil:
    section.add "Conditions", valid_601186
  var valid_601187 = query.getOrDefault("Action")
  valid_601187 = validateParameter(valid_601187, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_601187 != nil:
    section.add "Action", valid_601187
  var valid_601188 = query.getOrDefault("ListenerArn")
  valid_601188 = validateParameter(valid_601188, JString, required = true,
                                 default = nil)
  if valid_601188 != nil:
    section.add "ListenerArn", valid_601188
  var valid_601189 = query.getOrDefault("Actions")
  valid_601189 = validateParameter(valid_601189, JArray, required = true, default = nil)
  if valid_601189 != nil:
    section.add "Actions", valid_601189
  var valid_601190 = query.getOrDefault("Priority")
  valid_601190 = validateParameter(valid_601190, JInt, required = true, default = nil)
  if valid_601190 != nil:
    section.add "Priority", valid_601190
  var valid_601191 = query.getOrDefault("Version")
  valid_601191 = validateParameter(valid_601191, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601191 != nil:
    section.add "Version", valid_601191
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
  var valid_601192 = header.getOrDefault("X-Amz-Date")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Date", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Security-Token")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Security-Token", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Content-Sha256", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Algorithm")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Algorithm", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Signature")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Signature", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-SignedHeaders", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Credential")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Credential", valid_601198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601199: Call_GetCreateRule_601183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"))
  result = hook(call_601199, url, valid)

proc call*(call_601200: Call_GetCreateRule_601183; Conditions: JsonNode;
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
  var query_601201 = newJObject()
  if Conditions != nil:
    query_601201.add "Conditions", Conditions
  add(query_601201, "Action", newJString(Action))
  add(query_601201, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    query_601201.add "Actions", Actions
  add(query_601201, "Priority", newJInt(Priority))
  add(query_601201, "Version", newJString(Version))
  result = call_601200.call(nil, query_601201, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_601183(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_601184,
    base: "/", url: url_GetCreateRule_601185, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_601251 = ref object of OpenApiRestCall_600426
proc url_PostCreateTargetGroup_601253(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateTargetGroup_601252(path: JsonNode; query: JsonNode;
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
  var valid_601254 = query.getOrDefault("Action")
  valid_601254 = validateParameter(valid_601254, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_601254 != nil:
    section.add "Action", valid_601254
  var valid_601255 = query.getOrDefault("Version")
  valid_601255 = validateParameter(valid_601255, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601255 != nil:
    section.add "Version", valid_601255
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
  var valid_601256 = header.getOrDefault("X-Amz-Date")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Date", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Security-Token")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Security-Token", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Content-Sha256", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Algorithm")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Algorithm", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Signature")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Signature", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-SignedHeaders", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Credential")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Credential", valid_601262
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
  var valid_601263 = formData.getOrDefault("Name")
  valid_601263 = validateParameter(valid_601263, JString, required = true,
                                 default = nil)
  if valid_601263 != nil:
    section.add "Name", valid_601263
  var valid_601264 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_601264 = validateParameter(valid_601264, JInt, required = false, default = nil)
  if valid_601264 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_601264
  var valid_601265 = formData.getOrDefault("Port")
  valid_601265 = validateParameter(valid_601265, JInt, required = false, default = nil)
  if valid_601265 != nil:
    section.add "Port", valid_601265
  var valid_601266 = formData.getOrDefault("Protocol")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_601266 != nil:
    section.add "Protocol", valid_601266
  var valid_601267 = formData.getOrDefault("HealthCheckPort")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "HealthCheckPort", valid_601267
  var valid_601268 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_601268 = validateParameter(valid_601268, JInt, required = false, default = nil)
  if valid_601268 != nil:
    section.add "UnhealthyThresholdCount", valid_601268
  var valid_601269 = formData.getOrDefault("HealthCheckEnabled")
  valid_601269 = validateParameter(valid_601269, JBool, required = false, default = nil)
  if valid_601269 != nil:
    section.add "HealthCheckEnabled", valid_601269
  var valid_601270 = formData.getOrDefault("HealthCheckPath")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "HealthCheckPath", valid_601270
  var valid_601271 = formData.getOrDefault("TargetType")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = newJString("instance"))
  if valid_601271 != nil:
    section.add "TargetType", valid_601271
  var valid_601272 = formData.getOrDefault("VpcId")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "VpcId", valid_601272
  var valid_601273 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_601273 = validateParameter(valid_601273, JInt, required = false, default = nil)
  if valid_601273 != nil:
    section.add "HealthCheckIntervalSeconds", valid_601273
  var valid_601274 = formData.getOrDefault("HealthyThresholdCount")
  valid_601274 = validateParameter(valid_601274, JInt, required = false, default = nil)
  if valid_601274 != nil:
    section.add "HealthyThresholdCount", valid_601274
  var valid_601275 = formData.getOrDefault("HealthCheckProtocol")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_601275 != nil:
    section.add "HealthCheckProtocol", valid_601275
  var valid_601276 = formData.getOrDefault("Matcher.HttpCode")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "Matcher.HttpCode", valid_601276
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601277: Call_PostCreateTargetGroup_601251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601277.validator(path, query, header, formData, body)
  let scheme = call_601277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601277.url(scheme.get, call_601277.host, call_601277.base,
                         call_601277.route, valid.getOrDefault("path"))
  result = hook(call_601277, url, valid)

proc call*(call_601278: Call_PostCreateTargetGroup_601251; Name: string;
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
  var query_601279 = newJObject()
  var formData_601280 = newJObject()
  add(formData_601280, "Name", newJString(Name))
  add(formData_601280, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_601280, "Port", newJInt(Port))
  add(formData_601280, "Protocol", newJString(Protocol))
  add(formData_601280, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_601280, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_601280, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_601280, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_601280, "TargetType", newJString(TargetType))
  add(query_601279, "Action", newJString(Action))
  add(formData_601280, "VpcId", newJString(VpcId))
  add(formData_601280, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_601280, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_601280, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_601280, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_601279, "Version", newJString(Version))
  result = call_601278.call(nil, query_601279, nil, formData_601280, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_601251(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_601252, base: "/",
    url: url_PostCreateTargetGroup_601253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_601222 = ref object of OpenApiRestCall_600426
proc url_GetCreateTargetGroup_601224(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateTargetGroup_601223(path: JsonNode; query: JsonNode;
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
  var valid_601225 = query.getOrDefault("HealthCheckEnabled")
  valid_601225 = validateParameter(valid_601225, JBool, required = false, default = nil)
  if valid_601225 != nil:
    section.add "HealthCheckEnabled", valid_601225
  var valid_601226 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_601226 = validateParameter(valid_601226, JInt, required = false, default = nil)
  if valid_601226 != nil:
    section.add "HealthCheckIntervalSeconds", valid_601226
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_601227 = query.getOrDefault("Name")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = nil)
  if valid_601227 != nil:
    section.add "Name", valid_601227
  var valid_601228 = query.getOrDefault("HealthCheckPort")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "HealthCheckPort", valid_601228
  var valid_601229 = query.getOrDefault("Protocol")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_601229 != nil:
    section.add "Protocol", valid_601229
  var valid_601230 = query.getOrDefault("VpcId")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "VpcId", valid_601230
  var valid_601231 = query.getOrDefault("Action")
  valid_601231 = validateParameter(valid_601231, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_601231 != nil:
    section.add "Action", valid_601231
  var valid_601232 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_601232 = validateParameter(valid_601232, JInt, required = false, default = nil)
  if valid_601232 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_601232
  var valid_601233 = query.getOrDefault("Matcher.HttpCode")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "Matcher.HttpCode", valid_601233
  var valid_601234 = query.getOrDefault("UnhealthyThresholdCount")
  valid_601234 = validateParameter(valid_601234, JInt, required = false, default = nil)
  if valid_601234 != nil:
    section.add "UnhealthyThresholdCount", valid_601234
  var valid_601235 = query.getOrDefault("TargetType")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = newJString("instance"))
  if valid_601235 != nil:
    section.add "TargetType", valid_601235
  var valid_601236 = query.getOrDefault("Port")
  valid_601236 = validateParameter(valid_601236, JInt, required = false, default = nil)
  if valid_601236 != nil:
    section.add "Port", valid_601236
  var valid_601237 = query.getOrDefault("HealthCheckProtocol")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_601237 != nil:
    section.add "HealthCheckProtocol", valid_601237
  var valid_601238 = query.getOrDefault("HealthyThresholdCount")
  valid_601238 = validateParameter(valid_601238, JInt, required = false, default = nil)
  if valid_601238 != nil:
    section.add "HealthyThresholdCount", valid_601238
  var valid_601239 = query.getOrDefault("Version")
  valid_601239 = validateParameter(valid_601239, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601239 != nil:
    section.add "Version", valid_601239
  var valid_601240 = query.getOrDefault("HealthCheckPath")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "HealthCheckPath", valid_601240
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
  var valid_601241 = header.getOrDefault("X-Amz-Date")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Date", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Security-Token")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Security-Token", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Content-Sha256", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Algorithm")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Algorithm", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Signature")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Signature", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-SignedHeaders", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Credential")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Credential", valid_601247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601248: Call_GetCreateTargetGroup_601222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601248.validator(path, query, header, formData, body)
  let scheme = call_601248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601248.url(scheme.get, call_601248.host, call_601248.base,
                         call_601248.route, valid.getOrDefault("path"))
  result = hook(call_601248, url, valid)

proc call*(call_601249: Call_GetCreateTargetGroup_601222; Name: string;
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
  var query_601250 = newJObject()
  add(query_601250, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_601250, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_601250, "Name", newJString(Name))
  add(query_601250, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_601250, "Protocol", newJString(Protocol))
  add(query_601250, "VpcId", newJString(VpcId))
  add(query_601250, "Action", newJString(Action))
  add(query_601250, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_601250, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_601250, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_601250, "TargetType", newJString(TargetType))
  add(query_601250, "Port", newJInt(Port))
  add(query_601250, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_601250, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_601250, "Version", newJString(Version))
  add(query_601250, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_601249.call(nil, query_601250, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_601222(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_601223,
    base: "/", url: url_GetCreateTargetGroup_601224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_601297 = ref object of OpenApiRestCall_600426
proc url_PostDeleteListener_601299(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteListener_601298(path: JsonNode; query: JsonNode;
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
  var valid_601300 = query.getOrDefault("Action")
  valid_601300 = validateParameter(valid_601300, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_601300 != nil:
    section.add "Action", valid_601300
  var valid_601301 = query.getOrDefault("Version")
  valid_601301 = validateParameter(valid_601301, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601301 != nil:
    section.add "Version", valid_601301
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
  var valid_601302 = header.getOrDefault("X-Amz-Date")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Date", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Security-Token")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Security-Token", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Content-Sha256", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Algorithm")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Algorithm", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Signature")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Signature", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-SignedHeaders", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Credential")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Credential", valid_601308
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_601309 = formData.getOrDefault("ListenerArn")
  valid_601309 = validateParameter(valid_601309, JString, required = true,
                                 default = nil)
  if valid_601309 != nil:
    section.add "ListenerArn", valid_601309
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601310: Call_PostDeleteListener_601297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_601310.validator(path, query, header, formData, body)
  let scheme = call_601310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601310.url(scheme.get, call_601310.host, call_601310.base,
                         call_601310.route, valid.getOrDefault("path"))
  result = hook(call_601310, url, valid)

proc call*(call_601311: Call_PostDeleteListener_601297; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601312 = newJObject()
  var formData_601313 = newJObject()
  add(formData_601313, "ListenerArn", newJString(ListenerArn))
  add(query_601312, "Action", newJString(Action))
  add(query_601312, "Version", newJString(Version))
  result = call_601311.call(nil, query_601312, nil, formData_601313, nil)

var postDeleteListener* = Call_PostDeleteListener_601297(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_601298, base: "/",
    url: url_PostDeleteListener_601299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_601281 = ref object of OpenApiRestCall_600426
proc url_GetDeleteListener_601283(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteListener_601282(path: JsonNode; query: JsonNode;
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
  var valid_601284 = query.getOrDefault("Action")
  valid_601284 = validateParameter(valid_601284, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_601284 != nil:
    section.add "Action", valid_601284
  var valid_601285 = query.getOrDefault("ListenerArn")
  valid_601285 = validateParameter(valid_601285, JString, required = true,
                                 default = nil)
  if valid_601285 != nil:
    section.add "ListenerArn", valid_601285
  var valid_601286 = query.getOrDefault("Version")
  valid_601286 = validateParameter(valid_601286, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601286 != nil:
    section.add "Version", valid_601286
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
  var valid_601287 = header.getOrDefault("X-Amz-Date")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Date", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Security-Token")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Security-Token", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Content-Sha256", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Algorithm")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Algorithm", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Signature")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Signature", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-SignedHeaders", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Credential")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Credential", valid_601293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601294: Call_GetDeleteListener_601281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_601294.validator(path, query, header, formData, body)
  let scheme = call_601294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601294.url(scheme.get, call_601294.host, call_601294.base,
                         call_601294.route, valid.getOrDefault("path"))
  result = hook(call_601294, url, valid)

proc call*(call_601295: Call_GetDeleteListener_601281; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  var query_601296 = newJObject()
  add(query_601296, "Action", newJString(Action))
  add(query_601296, "ListenerArn", newJString(ListenerArn))
  add(query_601296, "Version", newJString(Version))
  result = call_601295.call(nil, query_601296, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_601281(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_601282,
    base: "/", url: url_GetDeleteListener_601283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_601330 = ref object of OpenApiRestCall_600426
proc url_PostDeleteLoadBalancer_601332(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteLoadBalancer_601331(path: JsonNode; query: JsonNode;
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
  var valid_601333 = query.getOrDefault("Action")
  valid_601333 = validateParameter(valid_601333, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_601333 != nil:
    section.add "Action", valid_601333
  var valid_601334 = query.getOrDefault("Version")
  valid_601334 = validateParameter(valid_601334, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601334 != nil:
    section.add "Version", valid_601334
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
  var valid_601335 = header.getOrDefault("X-Amz-Date")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Date", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Security-Token")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Security-Token", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Content-Sha256", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Algorithm")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Algorithm", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Signature")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Signature", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-SignedHeaders", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Credential")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Credential", valid_601341
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_601342 = formData.getOrDefault("LoadBalancerArn")
  valid_601342 = validateParameter(valid_601342, JString, required = true,
                                 default = nil)
  if valid_601342 != nil:
    section.add "LoadBalancerArn", valid_601342
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601343: Call_PostDeleteLoadBalancer_601330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_601343.validator(path, query, header, formData, body)
  let scheme = call_601343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601343.url(scheme.get, call_601343.host, call_601343.base,
                         call_601343.route, valid.getOrDefault("path"))
  result = hook(call_601343, url, valid)

proc call*(call_601344: Call_PostDeleteLoadBalancer_601330;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601345 = newJObject()
  var formData_601346 = newJObject()
  add(formData_601346, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_601345, "Action", newJString(Action))
  add(query_601345, "Version", newJString(Version))
  result = call_601344.call(nil, query_601345, nil, formData_601346, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_601330(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_601331, base: "/",
    url: url_PostDeleteLoadBalancer_601332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_601314 = ref object of OpenApiRestCall_600426
proc url_GetDeleteLoadBalancer_601316(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteLoadBalancer_601315(path: JsonNode; query: JsonNode;
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
  var valid_601317 = query.getOrDefault("Action")
  valid_601317 = validateParameter(valid_601317, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_601317 != nil:
    section.add "Action", valid_601317
  var valid_601318 = query.getOrDefault("LoadBalancerArn")
  valid_601318 = validateParameter(valid_601318, JString, required = true,
                                 default = nil)
  if valid_601318 != nil:
    section.add "LoadBalancerArn", valid_601318
  var valid_601319 = query.getOrDefault("Version")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601319 != nil:
    section.add "Version", valid_601319
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
  var valid_601320 = header.getOrDefault("X-Amz-Date")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Date", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Security-Token")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Security-Token", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Content-Sha256", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Algorithm")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Algorithm", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Signature")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Signature", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-SignedHeaders", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Credential")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Credential", valid_601326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601327: Call_GetDeleteLoadBalancer_601314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_601327.validator(path, query, header, formData, body)
  let scheme = call_601327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601327.url(scheme.get, call_601327.host, call_601327.base,
                         call_601327.route, valid.getOrDefault("path"))
  result = hook(call_601327, url, valid)

proc call*(call_601328: Call_GetDeleteLoadBalancer_601314; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_601329 = newJObject()
  add(query_601329, "Action", newJString(Action))
  add(query_601329, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_601329, "Version", newJString(Version))
  result = call_601328.call(nil, query_601329, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_601314(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_601315, base: "/",
    url: url_GetDeleteLoadBalancer_601316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_601363 = ref object of OpenApiRestCall_600426
proc url_PostDeleteRule_601365(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteRule_601364(path: JsonNode; query: JsonNode;
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
  var valid_601366 = query.getOrDefault("Action")
  valid_601366 = validateParameter(valid_601366, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_601366 != nil:
    section.add "Action", valid_601366
  var valid_601367 = query.getOrDefault("Version")
  valid_601367 = validateParameter(valid_601367, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601367 != nil:
    section.add "Version", valid_601367
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
  var valid_601368 = header.getOrDefault("X-Amz-Date")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Date", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Security-Token")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Security-Token", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Content-Sha256", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Algorithm")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Algorithm", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Signature")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Signature", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-SignedHeaders", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Credential")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Credential", valid_601374
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_601375 = formData.getOrDefault("RuleArn")
  valid_601375 = validateParameter(valid_601375, JString, required = true,
                                 default = nil)
  if valid_601375 != nil:
    section.add "RuleArn", valid_601375
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601376: Call_PostDeleteRule_601363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_601376.validator(path, query, header, formData, body)
  let scheme = call_601376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601376.url(scheme.get, call_601376.host, call_601376.base,
                         call_601376.route, valid.getOrDefault("path"))
  result = hook(call_601376, url, valid)

proc call*(call_601377: Call_PostDeleteRule_601363; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601378 = newJObject()
  var formData_601379 = newJObject()
  add(formData_601379, "RuleArn", newJString(RuleArn))
  add(query_601378, "Action", newJString(Action))
  add(query_601378, "Version", newJString(Version))
  result = call_601377.call(nil, query_601378, nil, formData_601379, nil)

var postDeleteRule* = Call_PostDeleteRule_601363(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_601364,
    base: "/", url: url_PostDeleteRule_601365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_601347 = ref object of OpenApiRestCall_600426
proc url_GetDeleteRule_601349(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteRule_601348(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601350 = query.getOrDefault("Action")
  valid_601350 = validateParameter(valid_601350, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_601350 != nil:
    section.add "Action", valid_601350
  var valid_601351 = query.getOrDefault("RuleArn")
  valid_601351 = validateParameter(valid_601351, JString, required = true,
                                 default = nil)
  if valid_601351 != nil:
    section.add "RuleArn", valid_601351
  var valid_601352 = query.getOrDefault("Version")
  valid_601352 = validateParameter(valid_601352, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601352 != nil:
    section.add "Version", valid_601352
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
  var valid_601353 = header.getOrDefault("X-Amz-Date")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Date", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Security-Token")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Security-Token", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Content-Sha256", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Algorithm")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Algorithm", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Signature")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Signature", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-SignedHeaders", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Credential")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Credential", valid_601359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601360: Call_GetDeleteRule_601347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_601360.validator(path, query, header, formData, body)
  let scheme = call_601360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601360.url(scheme.get, call_601360.host, call_601360.base,
                         call_601360.route, valid.getOrDefault("path"))
  result = hook(call_601360, url, valid)

proc call*(call_601361: Call_GetDeleteRule_601347; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   Action: string (required)
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Version: string (required)
  var query_601362 = newJObject()
  add(query_601362, "Action", newJString(Action))
  add(query_601362, "RuleArn", newJString(RuleArn))
  add(query_601362, "Version", newJString(Version))
  result = call_601361.call(nil, query_601362, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_601347(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_601348,
    base: "/", url: url_GetDeleteRule_601349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_601396 = ref object of OpenApiRestCall_600426
proc url_PostDeleteTargetGroup_601398(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteTargetGroup_601397(path: JsonNode; query: JsonNode;
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
  var valid_601399 = query.getOrDefault("Action")
  valid_601399 = validateParameter(valid_601399, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_601399 != nil:
    section.add "Action", valid_601399
  var valid_601400 = query.getOrDefault("Version")
  valid_601400 = validateParameter(valid_601400, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601400 != nil:
    section.add "Version", valid_601400
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
  var valid_601401 = header.getOrDefault("X-Amz-Date")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Date", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Security-Token")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Security-Token", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Content-Sha256", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Algorithm")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Algorithm", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Signature")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Signature", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-SignedHeaders", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Credential")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Credential", valid_601407
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_601408 = formData.getOrDefault("TargetGroupArn")
  valid_601408 = validateParameter(valid_601408, JString, required = true,
                                 default = nil)
  if valid_601408 != nil:
    section.add "TargetGroupArn", valid_601408
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601409: Call_PostDeleteTargetGroup_601396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_601409.validator(path, query, header, formData, body)
  let scheme = call_601409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601409.url(scheme.get, call_601409.host, call_601409.base,
                         call_601409.route, valid.getOrDefault("path"))
  result = hook(call_601409, url, valid)

proc call*(call_601410: Call_PostDeleteTargetGroup_601396; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_601411 = newJObject()
  var formData_601412 = newJObject()
  add(query_601411, "Action", newJString(Action))
  add(formData_601412, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_601411, "Version", newJString(Version))
  result = call_601410.call(nil, query_601411, nil, formData_601412, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_601396(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_601397, base: "/",
    url: url_PostDeleteTargetGroup_601398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_601380 = ref object of OpenApiRestCall_600426
proc url_GetDeleteTargetGroup_601382(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteTargetGroup_601381(path: JsonNode; query: JsonNode;
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
  var valid_601383 = query.getOrDefault("TargetGroupArn")
  valid_601383 = validateParameter(valid_601383, JString, required = true,
                                 default = nil)
  if valid_601383 != nil:
    section.add "TargetGroupArn", valid_601383
  var valid_601384 = query.getOrDefault("Action")
  valid_601384 = validateParameter(valid_601384, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_601384 != nil:
    section.add "Action", valid_601384
  var valid_601385 = query.getOrDefault("Version")
  valid_601385 = validateParameter(valid_601385, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601385 != nil:
    section.add "Version", valid_601385
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
  var valid_601386 = header.getOrDefault("X-Amz-Date")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Date", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Security-Token")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Security-Token", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Content-Sha256", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Algorithm")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Algorithm", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Signature")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Signature", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-SignedHeaders", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Credential")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Credential", valid_601392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601393: Call_GetDeleteTargetGroup_601380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_601393.validator(path, query, header, formData, body)
  let scheme = call_601393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601393.url(scheme.get, call_601393.host, call_601393.base,
                         call_601393.route, valid.getOrDefault("path"))
  result = hook(call_601393, url, valid)

proc call*(call_601394: Call_GetDeleteTargetGroup_601380; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601395 = newJObject()
  add(query_601395, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_601395, "Action", newJString(Action))
  add(query_601395, "Version", newJString(Version))
  result = call_601394.call(nil, query_601395, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_601380(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_601381,
    base: "/", url: url_GetDeleteTargetGroup_601382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_601430 = ref object of OpenApiRestCall_600426
proc url_PostDeregisterTargets_601432(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeregisterTargets_601431(path: JsonNode; query: JsonNode;
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
  var valid_601433 = query.getOrDefault("Action")
  valid_601433 = validateParameter(valid_601433, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_601433 != nil:
    section.add "Action", valid_601433
  var valid_601434 = query.getOrDefault("Version")
  valid_601434 = validateParameter(valid_601434, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601434 != nil:
    section.add "Version", valid_601434
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
  var valid_601435 = header.getOrDefault("X-Amz-Date")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Date", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Security-Token")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Security-Token", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Content-Sha256", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Algorithm")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Algorithm", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Signature")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Signature", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-SignedHeaders", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Credential")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Credential", valid_601441
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_601442 = formData.getOrDefault("Targets")
  valid_601442 = validateParameter(valid_601442, JArray, required = true, default = nil)
  if valid_601442 != nil:
    section.add "Targets", valid_601442
  var valid_601443 = formData.getOrDefault("TargetGroupArn")
  valid_601443 = validateParameter(valid_601443, JString, required = true,
                                 default = nil)
  if valid_601443 != nil:
    section.add "TargetGroupArn", valid_601443
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601444: Call_PostDeregisterTargets_601430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_601444.validator(path, query, header, formData, body)
  let scheme = call_601444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601444.url(scheme.get, call_601444.host, call_601444.base,
                         call_601444.route, valid.getOrDefault("path"))
  result = hook(call_601444, url, valid)

proc call*(call_601445: Call_PostDeregisterTargets_601430; Targets: JsonNode;
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
  var query_601446 = newJObject()
  var formData_601447 = newJObject()
  if Targets != nil:
    formData_601447.add "Targets", Targets
  add(query_601446, "Action", newJString(Action))
  add(formData_601447, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_601446, "Version", newJString(Version))
  result = call_601445.call(nil, query_601446, nil, formData_601447, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_601430(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_601431, base: "/",
    url: url_PostDeregisterTargets_601432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_601413 = ref object of OpenApiRestCall_600426
proc url_GetDeregisterTargets_601415(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeregisterTargets_601414(path: JsonNode; query: JsonNode;
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
  var valid_601416 = query.getOrDefault("Targets")
  valid_601416 = validateParameter(valid_601416, JArray, required = true, default = nil)
  if valid_601416 != nil:
    section.add "Targets", valid_601416
  var valid_601417 = query.getOrDefault("TargetGroupArn")
  valid_601417 = validateParameter(valid_601417, JString, required = true,
                                 default = nil)
  if valid_601417 != nil:
    section.add "TargetGroupArn", valid_601417
  var valid_601418 = query.getOrDefault("Action")
  valid_601418 = validateParameter(valid_601418, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_601418 != nil:
    section.add "Action", valid_601418
  var valid_601419 = query.getOrDefault("Version")
  valid_601419 = validateParameter(valid_601419, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601419 != nil:
    section.add "Version", valid_601419
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
  var valid_601420 = header.getOrDefault("X-Amz-Date")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Date", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Security-Token")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Security-Token", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Content-Sha256", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Algorithm")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Algorithm", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Signature")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Signature", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-SignedHeaders", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Credential")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Credential", valid_601426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601427: Call_GetDeregisterTargets_601413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_601427.validator(path, query, header, formData, body)
  let scheme = call_601427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601427.url(scheme.get, call_601427.host, call_601427.base,
                         call_601427.route, valid.getOrDefault("path"))
  result = hook(call_601427, url, valid)

proc call*(call_601428: Call_GetDeregisterTargets_601413; Targets: JsonNode;
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
  var query_601429 = newJObject()
  if Targets != nil:
    query_601429.add "Targets", Targets
  add(query_601429, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_601429, "Action", newJString(Action))
  add(query_601429, "Version", newJString(Version))
  result = call_601428.call(nil, query_601429, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_601413(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_601414,
    base: "/", url: url_GetDeregisterTargets_601415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_601465 = ref object of OpenApiRestCall_600426
proc url_PostDescribeAccountLimits_601467(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAccountLimits_601466(path: JsonNode; query: JsonNode;
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
  var valid_601468 = query.getOrDefault("Action")
  valid_601468 = validateParameter(valid_601468, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_601468 != nil:
    section.add "Action", valid_601468
  var valid_601469 = query.getOrDefault("Version")
  valid_601469 = validateParameter(valid_601469, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601469 != nil:
    section.add "Version", valid_601469
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
  var valid_601470 = header.getOrDefault("X-Amz-Date")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Date", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Security-Token")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Security-Token", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Content-Sha256", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-Algorithm")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Algorithm", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Signature")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Signature", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-SignedHeaders", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Credential")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Credential", valid_601476
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_601477 = formData.getOrDefault("Marker")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "Marker", valid_601477
  var valid_601478 = formData.getOrDefault("PageSize")
  valid_601478 = validateParameter(valid_601478, JInt, required = false, default = nil)
  if valid_601478 != nil:
    section.add "PageSize", valid_601478
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601479: Call_PostDescribeAccountLimits_601465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601479.validator(path, query, header, formData, body)
  let scheme = call_601479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601479.url(scheme.get, call_601479.host, call_601479.base,
                         call_601479.route, valid.getOrDefault("path"))
  result = hook(call_601479, url, valid)

proc call*(call_601480: Call_PostDescribeAccountLimits_601465; Marker: string = "";
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
  var query_601481 = newJObject()
  var formData_601482 = newJObject()
  add(formData_601482, "Marker", newJString(Marker))
  add(query_601481, "Action", newJString(Action))
  add(formData_601482, "PageSize", newJInt(PageSize))
  add(query_601481, "Version", newJString(Version))
  result = call_601480.call(nil, query_601481, nil, formData_601482, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_601465(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_601466, base: "/",
    url: url_PostDescribeAccountLimits_601467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_601448 = ref object of OpenApiRestCall_600426
proc url_GetDescribeAccountLimits_601450(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAccountLimits_601449(path: JsonNode; query: JsonNode;
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
  var valid_601451 = query.getOrDefault("PageSize")
  valid_601451 = validateParameter(valid_601451, JInt, required = false, default = nil)
  if valid_601451 != nil:
    section.add "PageSize", valid_601451
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601452 = query.getOrDefault("Action")
  valid_601452 = validateParameter(valid_601452, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_601452 != nil:
    section.add "Action", valid_601452
  var valid_601453 = query.getOrDefault("Marker")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "Marker", valid_601453
  var valid_601454 = query.getOrDefault("Version")
  valid_601454 = validateParameter(valid_601454, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601454 != nil:
    section.add "Version", valid_601454
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
  var valid_601455 = header.getOrDefault("X-Amz-Date")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Date", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Security-Token")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Security-Token", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Content-Sha256", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Algorithm")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Algorithm", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Signature")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Signature", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-SignedHeaders", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Credential")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Credential", valid_601461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601462: Call_GetDescribeAccountLimits_601448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601462.validator(path, query, header, formData, body)
  let scheme = call_601462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601462.url(scheme.get, call_601462.host, call_601462.base,
                         call_601462.route, valid.getOrDefault("path"))
  result = hook(call_601462, url, valid)

proc call*(call_601463: Call_GetDescribeAccountLimits_601448; PageSize: int = 0;
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
  var query_601464 = newJObject()
  add(query_601464, "PageSize", newJInt(PageSize))
  add(query_601464, "Action", newJString(Action))
  add(query_601464, "Marker", newJString(Marker))
  add(query_601464, "Version", newJString(Version))
  result = call_601463.call(nil, query_601464, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_601448(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_601449, base: "/",
    url: url_GetDescribeAccountLimits_601450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_601501 = ref object of OpenApiRestCall_600426
proc url_PostDescribeListenerCertificates_601503(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeListenerCertificates_601502(path: JsonNode;
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
  var valid_601504 = query.getOrDefault("Action")
  valid_601504 = validateParameter(valid_601504, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_601504 != nil:
    section.add "Action", valid_601504
  var valid_601505 = query.getOrDefault("Version")
  valid_601505 = validateParameter(valid_601505, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601505 != nil:
    section.add "Version", valid_601505
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
  var valid_601506 = header.getOrDefault("X-Amz-Date")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Date", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-Security-Token")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Security-Token", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Content-Sha256", valid_601508
  var valid_601509 = header.getOrDefault("X-Amz-Algorithm")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Algorithm", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-Signature")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-Signature", valid_601510
  var valid_601511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-SignedHeaders", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Credential")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Credential", valid_601512
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
  var valid_601513 = formData.getOrDefault("ListenerArn")
  valid_601513 = validateParameter(valid_601513, JString, required = true,
                                 default = nil)
  if valid_601513 != nil:
    section.add "ListenerArn", valid_601513
  var valid_601514 = formData.getOrDefault("Marker")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "Marker", valid_601514
  var valid_601515 = formData.getOrDefault("PageSize")
  valid_601515 = validateParameter(valid_601515, JInt, required = false, default = nil)
  if valid_601515 != nil:
    section.add "PageSize", valid_601515
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601516: Call_PostDescribeListenerCertificates_601501;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601516.validator(path, query, header, formData, body)
  let scheme = call_601516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601516.url(scheme.get, call_601516.host, call_601516.base,
                         call_601516.route, valid.getOrDefault("path"))
  result = hook(call_601516, url, valid)

proc call*(call_601517: Call_PostDescribeListenerCertificates_601501;
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
  var query_601518 = newJObject()
  var formData_601519 = newJObject()
  add(formData_601519, "ListenerArn", newJString(ListenerArn))
  add(formData_601519, "Marker", newJString(Marker))
  add(query_601518, "Action", newJString(Action))
  add(formData_601519, "PageSize", newJInt(PageSize))
  add(query_601518, "Version", newJString(Version))
  result = call_601517.call(nil, query_601518, nil, formData_601519, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_601501(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_601502, base: "/",
    url: url_PostDescribeListenerCertificates_601503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_601483 = ref object of OpenApiRestCall_600426
proc url_GetDescribeListenerCertificates_601485(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeListenerCertificates_601484(path: JsonNode;
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
  var valid_601486 = query.getOrDefault("PageSize")
  valid_601486 = validateParameter(valid_601486, JInt, required = false, default = nil)
  if valid_601486 != nil:
    section.add "PageSize", valid_601486
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601487 = query.getOrDefault("Action")
  valid_601487 = validateParameter(valid_601487, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_601487 != nil:
    section.add "Action", valid_601487
  var valid_601488 = query.getOrDefault("Marker")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "Marker", valid_601488
  var valid_601489 = query.getOrDefault("ListenerArn")
  valid_601489 = validateParameter(valid_601489, JString, required = true,
                                 default = nil)
  if valid_601489 != nil:
    section.add "ListenerArn", valid_601489
  var valid_601490 = query.getOrDefault("Version")
  valid_601490 = validateParameter(valid_601490, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601490 != nil:
    section.add "Version", valid_601490
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
  var valid_601491 = header.getOrDefault("X-Amz-Date")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Date", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Security-Token")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Security-Token", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Content-Sha256", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-Algorithm")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Algorithm", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Signature")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Signature", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-SignedHeaders", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Credential")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Credential", valid_601497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601498: Call_GetDescribeListenerCertificates_601483;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601498.validator(path, query, header, formData, body)
  let scheme = call_601498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601498.url(scheme.get, call_601498.host, call_601498.base,
                         call_601498.route, valid.getOrDefault("path"))
  result = hook(call_601498, url, valid)

proc call*(call_601499: Call_GetDescribeListenerCertificates_601483;
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
  var query_601500 = newJObject()
  add(query_601500, "PageSize", newJInt(PageSize))
  add(query_601500, "Action", newJString(Action))
  add(query_601500, "Marker", newJString(Marker))
  add(query_601500, "ListenerArn", newJString(ListenerArn))
  add(query_601500, "Version", newJString(Version))
  result = call_601499.call(nil, query_601500, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_601483(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_601484, base: "/",
    url: url_GetDescribeListenerCertificates_601485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_601539 = ref object of OpenApiRestCall_600426
proc url_PostDescribeListeners_601541(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeListeners_601540(path: JsonNode; query: JsonNode;
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
  var valid_601542 = query.getOrDefault("Action")
  valid_601542 = validateParameter(valid_601542, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_601542 != nil:
    section.add "Action", valid_601542
  var valid_601543 = query.getOrDefault("Version")
  valid_601543 = validateParameter(valid_601543, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601543 != nil:
    section.add "Version", valid_601543
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
  var valid_601544 = header.getOrDefault("X-Amz-Date")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Date", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Security-Token")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Security-Token", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Content-Sha256", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Algorithm")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Algorithm", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-Signature")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Signature", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-SignedHeaders", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-Credential")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Credential", valid_601550
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
  var valid_601551 = formData.getOrDefault("LoadBalancerArn")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "LoadBalancerArn", valid_601551
  var valid_601552 = formData.getOrDefault("Marker")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "Marker", valid_601552
  var valid_601553 = formData.getOrDefault("PageSize")
  valid_601553 = validateParameter(valid_601553, JInt, required = false, default = nil)
  if valid_601553 != nil:
    section.add "PageSize", valid_601553
  var valid_601554 = formData.getOrDefault("ListenerArns")
  valid_601554 = validateParameter(valid_601554, JArray, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "ListenerArns", valid_601554
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601555: Call_PostDescribeListeners_601539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_601555.validator(path, query, header, formData, body)
  let scheme = call_601555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601555.url(scheme.get, call_601555.host, call_601555.base,
                         call_601555.route, valid.getOrDefault("path"))
  result = hook(call_601555, url, valid)

proc call*(call_601556: Call_PostDescribeListeners_601539;
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
  var query_601557 = newJObject()
  var formData_601558 = newJObject()
  add(formData_601558, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_601558, "Marker", newJString(Marker))
  add(query_601557, "Action", newJString(Action))
  add(formData_601558, "PageSize", newJInt(PageSize))
  if ListenerArns != nil:
    formData_601558.add "ListenerArns", ListenerArns
  add(query_601557, "Version", newJString(Version))
  result = call_601556.call(nil, query_601557, nil, formData_601558, nil)

var postDescribeListeners* = Call_PostDescribeListeners_601539(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_601540, base: "/",
    url: url_PostDescribeListeners_601541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_601520 = ref object of OpenApiRestCall_600426
proc url_GetDescribeListeners_601522(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeListeners_601521(path: JsonNode; query: JsonNode;
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
  var valid_601523 = query.getOrDefault("ListenerArns")
  valid_601523 = validateParameter(valid_601523, JArray, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "ListenerArns", valid_601523
  var valid_601524 = query.getOrDefault("PageSize")
  valid_601524 = validateParameter(valid_601524, JInt, required = false, default = nil)
  if valid_601524 != nil:
    section.add "PageSize", valid_601524
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601525 = query.getOrDefault("Action")
  valid_601525 = validateParameter(valid_601525, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_601525 != nil:
    section.add "Action", valid_601525
  var valid_601526 = query.getOrDefault("Marker")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "Marker", valid_601526
  var valid_601527 = query.getOrDefault("LoadBalancerArn")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "LoadBalancerArn", valid_601527
  var valid_601528 = query.getOrDefault("Version")
  valid_601528 = validateParameter(valid_601528, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601528 != nil:
    section.add "Version", valid_601528
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
  var valid_601529 = header.getOrDefault("X-Amz-Date")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Date", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Security-Token")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Security-Token", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Content-Sha256", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Algorithm")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Algorithm", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Signature")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Signature", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-SignedHeaders", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Credential")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Credential", valid_601535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601536: Call_GetDescribeListeners_601520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_601536.validator(path, query, header, formData, body)
  let scheme = call_601536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601536.url(scheme.get, call_601536.host, call_601536.base,
                         call_601536.route, valid.getOrDefault("path"))
  result = hook(call_601536, url, valid)

proc call*(call_601537: Call_GetDescribeListeners_601520;
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
  var query_601538 = newJObject()
  if ListenerArns != nil:
    query_601538.add "ListenerArns", ListenerArns
  add(query_601538, "PageSize", newJInt(PageSize))
  add(query_601538, "Action", newJString(Action))
  add(query_601538, "Marker", newJString(Marker))
  add(query_601538, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_601538, "Version", newJString(Version))
  result = call_601537.call(nil, query_601538, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_601520(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_601521,
    base: "/", url: url_GetDescribeListeners_601522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_601575 = ref object of OpenApiRestCall_600426
proc url_PostDescribeLoadBalancerAttributes_601577(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancerAttributes_601576(path: JsonNode;
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
  var valid_601578 = query.getOrDefault("Action")
  valid_601578 = validateParameter(valid_601578, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_601578 != nil:
    section.add "Action", valid_601578
  var valid_601579 = query.getOrDefault("Version")
  valid_601579 = validateParameter(valid_601579, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601579 != nil:
    section.add "Version", valid_601579
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
  var valid_601580 = header.getOrDefault("X-Amz-Date")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Date", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Security-Token")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Security-Token", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Content-Sha256", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Algorithm")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Algorithm", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Signature")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Signature", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-SignedHeaders", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-Credential")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Credential", valid_601586
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_601587 = formData.getOrDefault("LoadBalancerArn")
  valid_601587 = validateParameter(valid_601587, JString, required = true,
                                 default = nil)
  if valid_601587 != nil:
    section.add "LoadBalancerArn", valid_601587
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601588: Call_PostDescribeLoadBalancerAttributes_601575;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601588.validator(path, query, header, formData, body)
  let scheme = call_601588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601588.url(scheme.get, call_601588.host, call_601588.base,
                         call_601588.route, valid.getOrDefault("path"))
  result = hook(call_601588, url, valid)

proc call*(call_601589: Call_PostDescribeLoadBalancerAttributes_601575;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601590 = newJObject()
  var formData_601591 = newJObject()
  add(formData_601591, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_601590, "Action", newJString(Action))
  add(query_601590, "Version", newJString(Version))
  result = call_601589.call(nil, query_601590, nil, formData_601591, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_601575(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_601576, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_601577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_601559 = ref object of OpenApiRestCall_600426
proc url_GetDescribeLoadBalancerAttributes_601561(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancerAttributes_601560(path: JsonNode;
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
  var valid_601562 = query.getOrDefault("Action")
  valid_601562 = validateParameter(valid_601562, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_601562 != nil:
    section.add "Action", valid_601562
  var valid_601563 = query.getOrDefault("LoadBalancerArn")
  valid_601563 = validateParameter(valid_601563, JString, required = true,
                                 default = nil)
  if valid_601563 != nil:
    section.add "LoadBalancerArn", valid_601563
  var valid_601564 = query.getOrDefault("Version")
  valid_601564 = validateParameter(valid_601564, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601564 != nil:
    section.add "Version", valid_601564
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
  var valid_601565 = header.getOrDefault("X-Amz-Date")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Date", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Security-Token")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Security-Token", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Content-Sha256", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Algorithm")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Algorithm", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-Signature")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-Signature", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-SignedHeaders", valid_601570
  var valid_601571 = header.getOrDefault("X-Amz-Credential")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Credential", valid_601571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601572: Call_GetDescribeLoadBalancerAttributes_601559;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601572.validator(path, query, header, formData, body)
  let scheme = call_601572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601572.url(scheme.get, call_601572.host, call_601572.base,
                         call_601572.route, valid.getOrDefault("path"))
  result = hook(call_601572, url, valid)

proc call*(call_601573: Call_GetDescribeLoadBalancerAttributes_601559;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_601574 = newJObject()
  add(query_601574, "Action", newJString(Action))
  add(query_601574, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_601574, "Version", newJString(Version))
  result = call_601573.call(nil, query_601574, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_601559(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_601560, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_601561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_601611 = ref object of OpenApiRestCall_600426
proc url_PostDescribeLoadBalancers_601613(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancers_601612(path: JsonNode; query: JsonNode;
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
  var valid_601614 = query.getOrDefault("Action")
  valid_601614 = validateParameter(valid_601614, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_601614 != nil:
    section.add "Action", valid_601614
  var valid_601615 = query.getOrDefault("Version")
  valid_601615 = validateParameter(valid_601615, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601615 != nil:
    section.add "Version", valid_601615
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
  var valid_601616 = header.getOrDefault("X-Amz-Date")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Date", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-Security-Token")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Security-Token", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Content-Sha256", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-Algorithm")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Algorithm", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Signature")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Signature", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-SignedHeaders", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Credential")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Credential", valid_601622
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
  var valid_601623 = formData.getOrDefault("Names")
  valid_601623 = validateParameter(valid_601623, JArray, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "Names", valid_601623
  var valid_601624 = formData.getOrDefault("Marker")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "Marker", valid_601624
  var valid_601625 = formData.getOrDefault("LoadBalancerArns")
  valid_601625 = validateParameter(valid_601625, JArray, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "LoadBalancerArns", valid_601625
  var valid_601626 = formData.getOrDefault("PageSize")
  valid_601626 = validateParameter(valid_601626, JInt, required = false, default = nil)
  if valid_601626 != nil:
    section.add "PageSize", valid_601626
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601627: Call_PostDescribeLoadBalancers_601611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_601627.validator(path, query, header, formData, body)
  let scheme = call_601627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601627.url(scheme.get, call_601627.host, call_601627.base,
                         call_601627.route, valid.getOrDefault("path"))
  result = hook(call_601627, url, valid)

proc call*(call_601628: Call_PostDescribeLoadBalancers_601611;
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
  var query_601629 = newJObject()
  var formData_601630 = newJObject()
  if Names != nil:
    formData_601630.add "Names", Names
  add(formData_601630, "Marker", newJString(Marker))
  add(query_601629, "Action", newJString(Action))
  if LoadBalancerArns != nil:
    formData_601630.add "LoadBalancerArns", LoadBalancerArns
  add(formData_601630, "PageSize", newJInt(PageSize))
  add(query_601629, "Version", newJString(Version))
  result = call_601628.call(nil, query_601629, nil, formData_601630, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_601611(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_601612, base: "/",
    url: url_PostDescribeLoadBalancers_601613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_601592 = ref object of OpenApiRestCall_600426
proc url_GetDescribeLoadBalancers_601594(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancers_601593(path: JsonNode; query: JsonNode;
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
  var valid_601595 = query.getOrDefault("Names")
  valid_601595 = validateParameter(valid_601595, JArray, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "Names", valid_601595
  var valid_601596 = query.getOrDefault("PageSize")
  valid_601596 = validateParameter(valid_601596, JInt, required = false, default = nil)
  if valid_601596 != nil:
    section.add "PageSize", valid_601596
  var valid_601597 = query.getOrDefault("LoadBalancerArns")
  valid_601597 = validateParameter(valid_601597, JArray, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "LoadBalancerArns", valid_601597
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601598 = query.getOrDefault("Action")
  valid_601598 = validateParameter(valid_601598, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_601598 != nil:
    section.add "Action", valid_601598
  var valid_601599 = query.getOrDefault("Marker")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "Marker", valid_601599
  var valid_601600 = query.getOrDefault("Version")
  valid_601600 = validateParameter(valid_601600, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601600 != nil:
    section.add "Version", valid_601600
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
  var valid_601601 = header.getOrDefault("X-Amz-Date")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Date", valid_601601
  var valid_601602 = header.getOrDefault("X-Amz-Security-Token")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-Security-Token", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Content-Sha256", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-Algorithm")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Algorithm", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Signature")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Signature", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-SignedHeaders", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Credential")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Credential", valid_601607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601608: Call_GetDescribeLoadBalancers_601592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_601608.validator(path, query, header, formData, body)
  let scheme = call_601608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601608.url(scheme.get, call_601608.host, call_601608.base,
                         call_601608.route, valid.getOrDefault("path"))
  result = hook(call_601608, url, valid)

proc call*(call_601609: Call_GetDescribeLoadBalancers_601592;
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
  var query_601610 = newJObject()
  if Names != nil:
    query_601610.add "Names", Names
  add(query_601610, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_601610.add "LoadBalancerArns", LoadBalancerArns
  add(query_601610, "Action", newJString(Action))
  add(query_601610, "Marker", newJString(Marker))
  add(query_601610, "Version", newJString(Version))
  result = call_601609.call(nil, query_601610, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_601592(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_601593, base: "/",
    url: url_GetDescribeLoadBalancers_601594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_601650 = ref object of OpenApiRestCall_600426
proc url_PostDescribeRules_601652(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeRules_601651(path: JsonNode; query: JsonNode;
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
  var valid_601653 = query.getOrDefault("Action")
  valid_601653 = validateParameter(valid_601653, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_601653 != nil:
    section.add "Action", valid_601653
  var valid_601654 = query.getOrDefault("Version")
  valid_601654 = validateParameter(valid_601654, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601654 != nil:
    section.add "Version", valid_601654
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
  var valid_601655 = header.getOrDefault("X-Amz-Date")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-Date", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-Security-Token")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Security-Token", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-Content-Sha256", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-Algorithm")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Algorithm", valid_601658
  var valid_601659 = header.getOrDefault("X-Amz-Signature")
  valid_601659 = validateParameter(valid_601659, JString, required = false,
                                 default = nil)
  if valid_601659 != nil:
    section.add "X-Amz-Signature", valid_601659
  var valid_601660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "X-Amz-SignedHeaders", valid_601660
  var valid_601661 = header.getOrDefault("X-Amz-Credential")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Credential", valid_601661
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
  var valid_601662 = formData.getOrDefault("ListenerArn")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "ListenerArn", valid_601662
  var valid_601663 = formData.getOrDefault("RuleArns")
  valid_601663 = validateParameter(valid_601663, JArray, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "RuleArns", valid_601663
  var valid_601664 = formData.getOrDefault("Marker")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "Marker", valid_601664
  var valid_601665 = formData.getOrDefault("PageSize")
  valid_601665 = validateParameter(valid_601665, JInt, required = false, default = nil)
  if valid_601665 != nil:
    section.add "PageSize", valid_601665
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601666: Call_PostDescribeRules_601650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_601666.validator(path, query, header, formData, body)
  let scheme = call_601666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601666.url(scheme.get, call_601666.host, call_601666.base,
                         call_601666.route, valid.getOrDefault("path"))
  result = hook(call_601666, url, valid)

proc call*(call_601667: Call_PostDescribeRules_601650; ListenerArn: string = "";
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
  var query_601668 = newJObject()
  var formData_601669 = newJObject()
  add(formData_601669, "ListenerArn", newJString(ListenerArn))
  if RuleArns != nil:
    formData_601669.add "RuleArns", RuleArns
  add(formData_601669, "Marker", newJString(Marker))
  add(query_601668, "Action", newJString(Action))
  add(formData_601669, "PageSize", newJInt(PageSize))
  add(query_601668, "Version", newJString(Version))
  result = call_601667.call(nil, query_601668, nil, formData_601669, nil)

var postDescribeRules* = Call_PostDescribeRules_601650(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_601651,
    base: "/", url: url_PostDescribeRules_601652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_601631 = ref object of OpenApiRestCall_600426
proc url_GetDescribeRules_601633(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeRules_601632(path: JsonNode; query: JsonNode;
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
  var valid_601634 = query.getOrDefault("PageSize")
  valid_601634 = validateParameter(valid_601634, JInt, required = false, default = nil)
  if valid_601634 != nil:
    section.add "PageSize", valid_601634
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601635 = query.getOrDefault("Action")
  valid_601635 = validateParameter(valid_601635, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_601635 != nil:
    section.add "Action", valid_601635
  var valid_601636 = query.getOrDefault("Marker")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "Marker", valid_601636
  var valid_601637 = query.getOrDefault("ListenerArn")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "ListenerArn", valid_601637
  var valid_601638 = query.getOrDefault("Version")
  valid_601638 = validateParameter(valid_601638, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601638 != nil:
    section.add "Version", valid_601638
  var valid_601639 = query.getOrDefault("RuleArns")
  valid_601639 = validateParameter(valid_601639, JArray, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "RuleArns", valid_601639
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
  var valid_601640 = header.getOrDefault("X-Amz-Date")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-Date", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-Security-Token")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-Security-Token", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-Content-Sha256", valid_601642
  var valid_601643 = header.getOrDefault("X-Amz-Algorithm")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "X-Amz-Algorithm", valid_601643
  var valid_601644 = header.getOrDefault("X-Amz-Signature")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "X-Amz-Signature", valid_601644
  var valid_601645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "X-Amz-SignedHeaders", valid_601645
  var valid_601646 = header.getOrDefault("X-Amz-Credential")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = nil)
  if valid_601646 != nil:
    section.add "X-Amz-Credential", valid_601646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601647: Call_GetDescribeRules_601631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_601647.validator(path, query, header, formData, body)
  let scheme = call_601647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601647.url(scheme.get, call_601647.host, call_601647.base,
                         call_601647.route, valid.getOrDefault("path"))
  result = hook(call_601647, url, valid)

proc call*(call_601648: Call_GetDescribeRules_601631; PageSize: int = 0;
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
  var query_601649 = newJObject()
  add(query_601649, "PageSize", newJInt(PageSize))
  add(query_601649, "Action", newJString(Action))
  add(query_601649, "Marker", newJString(Marker))
  add(query_601649, "ListenerArn", newJString(ListenerArn))
  add(query_601649, "Version", newJString(Version))
  if RuleArns != nil:
    query_601649.add "RuleArns", RuleArns
  result = call_601648.call(nil, query_601649, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_601631(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_601632,
    base: "/", url: url_GetDescribeRules_601633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_601688 = ref object of OpenApiRestCall_600426
proc url_PostDescribeSSLPolicies_601690(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeSSLPolicies_601689(path: JsonNode; query: JsonNode;
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
  var valid_601691 = query.getOrDefault("Action")
  valid_601691 = validateParameter(valid_601691, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_601691 != nil:
    section.add "Action", valid_601691
  var valid_601692 = query.getOrDefault("Version")
  valid_601692 = validateParameter(valid_601692, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601692 != nil:
    section.add "Version", valid_601692
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
  var valid_601693 = header.getOrDefault("X-Amz-Date")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Date", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-Security-Token")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Security-Token", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Content-Sha256", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Algorithm")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Algorithm", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Signature")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Signature", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-SignedHeaders", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Credential")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Credential", valid_601699
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_601700 = formData.getOrDefault("Names")
  valid_601700 = validateParameter(valid_601700, JArray, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "Names", valid_601700
  var valid_601701 = formData.getOrDefault("Marker")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "Marker", valid_601701
  var valid_601702 = formData.getOrDefault("PageSize")
  valid_601702 = validateParameter(valid_601702, JInt, required = false, default = nil)
  if valid_601702 != nil:
    section.add "PageSize", valid_601702
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601703: Call_PostDescribeSSLPolicies_601688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601703.validator(path, query, header, formData, body)
  let scheme = call_601703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601703.url(scheme.get, call_601703.host, call_601703.base,
                         call_601703.route, valid.getOrDefault("path"))
  result = hook(call_601703, url, valid)

proc call*(call_601704: Call_PostDescribeSSLPolicies_601688; Names: JsonNode = nil;
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
  var query_601705 = newJObject()
  var formData_601706 = newJObject()
  if Names != nil:
    formData_601706.add "Names", Names
  add(formData_601706, "Marker", newJString(Marker))
  add(query_601705, "Action", newJString(Action))
  add(formData_601706, "PageSize", newJInt(PageSize))
  add(query_601705, "Version", newJString(Version))
  result = call_601704.call(nil, query_601705, nil, formData_601706, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_601688(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_601689, base: "/",
    url: url_PostDescribeSSLPolicies_601690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_601670 = ref object of OpenApiRestCall_600426
proc url_GetDescribeSSLPolicies_601672(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeSSLPolicies_601671(path: JsonNode; query: JsonNode;
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
  var valid_601673 = query.getOrDefault("Names")
  valid_601673 = validateParameter(valid_601673, JArray, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "Names", valid_601673
  var valid_601674 = query.getOrDefault("PageSize")
  valid_601674 = validateParameter(valid_601674, JInt, required = false, default = nil)
  if valid_601674 != nil:
    section.add "PageSize", valid_601674
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601675 = query.getOrDefault("Action")
  valid_601675 = validateParameter(valid_601675, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_601675 != nil:
    section.add "Action", valid_601675
  var valid_601676 = query.getOrDefault("Marker")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "Marker", valid_601676
  var valid_601677 = query.getOrDefault("Version")
  valid_601677 = validateParameter(valid_601677, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601677 != nil:
    section.add "Version", valid_601677
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
  var valid_601678 = header.getOrDefault("X-Amz-Date")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Date", valid_601678
  var valid_601679 = header.getOrDefault("X-Amz-Security-Token")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Security-Token", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Content-Sha256", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Algorithm")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Algorithm", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Signature")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Signature", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-SignedHeaders", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Credential")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Credential", valid_601684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601685: Call_GetDescribeSSLPolicies_601670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601685.validator(path, query, header, formData, body)
  let scheme = call_601685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601685.url(scheme.get, call_601685.host, call_601685.base,
                         call_601685.route, valid.getOrDefault("path"))
  result = hook(call_601685, url, valid)

proc call*(call_601686: Call_GetDescribeSSLPolicies_601670; Names: JsonNode = nil;
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
  var query_601687 = newJObject()
  if Names != nil:
    query_601687.add "Names", Names
  add(query_601687, "PageSize", newJInt(PageSize))
  add(query_601687, "Action", newJString(Action))
  add(query_601687, "Marker", newJString(Marker))
  add(query_601687, "Version", newJString(Version))
  result = call_601686.call(nil, query_601687, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_601670(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_601671, base: "/",
    url: url_GetDescribeSSLPolicies_601672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_601723 = ref object of OpenApiRestCall_600426
proc url_PostDescribeTags_601725(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTags_601724(path: JsonNode; query: JsonNode;
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
  var valid_601726 = query.getOrDefault("Action")
  valid_601726 = validateParameter(valid_601726, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_601726 != nil:
    section.add "Action", valid_601726
  var valid_601727 = query.getOrDefault("Version")
  valid_601727 = validateParameter(valid_601727, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601727 != nil:
    section.add "Version", valid_601727
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
  var valid_601728 = header.getOrDefault("X-Amz-Date")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Date", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-Security-Token")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Security-Token", valid_601729
  var valid_601730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Content-Sha256", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Algorithm")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Algorithm", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-Signature")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-Signature", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-SignedHeaders", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-Credential")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-Credential", valid_601734
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_601735 = formData.getOrDefault("ResourceArns")
  valid_601735 = validateParameter(valid_601735, JArray, required = true, default = nil)
  if valid_601735 != nil:
    section.add "ResourceArns", valid_601735
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601736: Call_PostDescribeTags_601723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_601736.validator(path, query, header, formData, body)
  let scheme = call_601736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601736.url(scheme.get, call_601736.host, call_601736.base,
                         call_601736.route, valid.getOrDefault("path"))
  result = hook(call_601736, url, valid)

proc call*(call_601737: Call_PostDescribeTags_601723; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601738 = newJObject()
  var formData_601739 = newJObject()
  if ResourceArns != nil:
    formData_601739.add "ResourceArns", ResourceArns
  add(query_601738, "Action", newJString(Action))
  add(query_601738, "Version", newJString(Version))
  result = call_601737.call(nil, query_601738, nil, formData_601739, nil)

var postDescribeTags* = Call_PostDescribeTags_601723(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_601724,
    base: "/", url: url_PostDescribeTags_601725,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_601707 = ref object of OpenApiRestCall_600426
proc url_GetDescribeTags_601709(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTags_601708(path: JsonNode; query: JsonNode;
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
  var valid_601710 = query.getOrDefault("Action")
  valid_601710 = validateParameter(valid_601710, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_601710 != nil:
    section.add "Action", valid_601710
  var valid_601711 = query.getOrDefault("ResourceArns")
  valid_601711 = validateParameter(valid_601711, JArray, required = true, default = nil)
  if valid_601711 != nil:
    section.add "ResourceArns", valid_601711
  var valid_601712 = query.getOrDefault("Version")
  valid_601712 = validateParameter(valid_601712, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601712 != nil:
    section.add "Version", valid_601712
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
  var valid_601713 = header.getOrDefault("X-Amz-Date")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-Date", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Security-Token")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Security-Token", valid_601714
  var valid_601715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-Content-Sha256", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-Algorithm")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Algorithm", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-Signature")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-Signature", valid_601717
  var valid_601718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-SignedHeaders", valid_601718
  var valid_601719 = header.getOrDefault("X-Amz-Credential")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "X-Amz-Credential", valid_601719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601720: Call_GetDescribeTags_601707; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_601720.validator(path, query, header, formData, body)
  let scheme = call_601720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601720.url(scheme.get, call_601720.host, call_601720.base,
                         call_601720.route, valid.getOrDefault("path"))
  result = hook(call_601720, url, valid)

proc call*(call_601721: Call_GetDescribeTags_601707; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   Action: string (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Version: string (required)
  var query_601722 = newJObject()
  add(query_601722, "Action", newJString(Action))
  if ResourceArns != nil:
    query_601722.add "ResourceArns", ResourceArns
  add(query_601722, "Version", newJString(Version))
  result = call_601721.call(nil, query_601722, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_601707(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_601708,
    base: "/", url: url_GetDescribeTags_601709, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_601756 = ref object of OpenApiRestCall_600426
proc url_PostDescribeTargetGroupAttributes_601758(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTargetGroupAttributes_601757(path: JsonNode;
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
  var valid_601759 = query.getOrDefault("Action")
  valid_601759 = validateParameter(valid_601759, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_601759 != nil:
    section.add "Action", valid_601759
  var valid_601760 = query.getOrDefault("Version")
  valid_601760 = validateParameter(valid_601760, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601760 != nil:
    section.add "Version", valid_601760
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
  var valid_601761 = header.getOrDefault("X-Amz-Date")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Date", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-Security-Token")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-Security-Token", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Content-Sha256", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Algorithm")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Algorithm", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-Signature")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Signature", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-SignedHeaders", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-Credential")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-Credential", valid_601767
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_601768 = formData.getOrDefault("TargetGroupArn")
  valid_601768 = validateParameter(valid_601768, JString, required = true,
                                 default = nil)
  if valid_601768 != nil:
    section.add "TargetGroupArn", valid_601768
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601769: Call_PostDescribeTargetGroupAttributes_601756;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601769.validator(path, query, header, formData, body)
  let scheme = call_601769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601769.url(scheme.get, call_601769.host, call_601769.base,
                         call_601769.route, valid.getOrDefault("path"))
  result = hook(call_601769, url, valid)

proc call*(call_601770: Call_PostDescribeTargetGroupAttributes_601756;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_601771 = newJObject()
  var formData_601772 = newJObject()
  add(query_601771, "Action", newJString(Action))
  add(formData_601772, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_601771, "Version", newJString(Version))
  result = call_601770.call(nil, query_601771, nil, formData_601772, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_601756(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_601757, base: "/",
    url: url_PostDescribeTargetGroupAttributes_601758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_601740 = ref object of OpenApiRestCall_600426
proc url_GetDescribeTargetGroupAttributes_601742(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTargetGroupAttributes_601741(path: JsonNode;
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
  var valid_601743 = query.getOrDefault("TargetGroupArn")
  valid_601743 = validateParameter(valid_601743, JString, required = true,
                                 default = nil)
  if valid_601743 != nil:
    section.add "TargetGroupArn", valid_601743
  var valid_601744 = query.getOrDefault("Action")
  valid_601744 = validateParameter(valid_601744, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_601744 != nil:
    section.add "Action", valid_601744
  var valid_601745 = query.getOrDefault("Version")
  valid_601745 = validateParameter(valid_601745, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601745 != nil:
    section.add "Version", valid_601745
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
  var valid_601746 = header.getOrDefault("X-Amz-Date")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Date", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-Security-Token")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Security-Token", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-Content-Sha256", valid_601748
  var valid_601749 = header.getOrDefault("X-Amz-Algorithm")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "X-Amz-Algorithm", valid_601749
  var valid_601750 = header.getOrDefault("X-Amz-Signature")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "X-Amz-Signature", valid_601750
  var valid_601751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-SignedHeaders", valid_601751
  var valid_601752 = header.getOrDefault("X-Amz-Credential")
  valid_601752 = validateParameter(valid_601752, JString, required = false,
                                 default = nil)
  if valid_601752 != nil:
    section.add "X-Amz-Credential", valid_601752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601753: Call_GetDescribeTargetGroupAttributes_601740;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601753.validator(path, query, header, formData, body)
  let scheme = call_601753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601753.url(scheme.get, call_601753.host, call_601753.base,
                         call_601753.route, valid.getOrDefault("path"))
  result = hook(call_601753, url, valid)

proc call*(call_601754: Call_GetDescribeTargetGroupAttributes_601740;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601755 = newJObject()
  add(query_601755, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_601755, "Action", newJString(Action))
  add(query_601755, "Version", newJString(Version))
  result = call_601754.call(nil, query_601755, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_601740(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_601741, base: "/",
    url: url_GetDescribeTargetGroupAttributes_601742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_601793 = ref object of OpenApiRestCall_600426
proc url_PostDescribeTargetGroups_601795(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTargetGroups_601794(path: JsonNode; query: JsonNode;
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
  var valid_601796 = query.getOrDefault("Action")
  valid_601796 = validateParameter(valid_601796, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_601796 != nil:
    section.add "Action", valid_601796
  var valid_601797 = query.getOrDefault("Version")
  valid_601797 = validateParameter(valid_601797, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601797 != nil:
    section.add "Version", valid_601797
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
  var valid_601798 = header.getOrDefault("X-Amz-Date")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Date", valid_601798
  var valid_601799 = header.getOrDefault("X-Amz-Security-Token")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "X-Amz-Security-Token", valid_601799
  var valid_601800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Content-Sha256", valid_601800
  var valid_601801 = header.getOrDefault("X-Amz-Algorithm")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-Algorithm", valid_601801
  var valid_601802 = header.getOrDefault("X-Amz-Signature")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "X-Amz-Signature", valid_601802
  var valid_601803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601803 = validateParameter(valid_601803, JString, required = false,
                                 default = nil)
  if valid_601803 != nil:
    section.add "X-Amz-SignedHeaders", valid_601803
  var valid_601804 = header.getOrDefault("X-Amz-Credential")
  valid_601804 = validateParameter(valid_601804, JString, required = false,
                                 default = nil)
  if valid_601804 != nil:
    section.add "X-Amz-Credential", valid_601804
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
  var valid_601805 = formData.getOrDefault("LoadBalancerArn")
  valid_601805 = validateParameter(valid_601805, JString, required = false,
                                 default = nil)
  if valid_601805 != nil:
    section.add "LoadBalancerArn", valid_601805
  var valid_601806 = formData.getOrDefault("TargetGroupArns")
  valid_601806 = validateParameter(valid_601806, JArray, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "TargetGroupArns", valid_601806
  var valid_601807 = formData.getOrDefault("Names")
  valid_601807 = validateParameter(valid_601807, JArray, required = false,
                                 default = nil)
  if valid_601807 != nil:
    section.add "Names", valid_601807
  var valid_601808 = formData.getOrDefault("Marker")
  valid_601808 = validateParameter(valid_601808, JString, required = false,
                                 default = nil)
  if valid_601808 != nil:
    section.add "Marker", valid_601808
  var valid_601809 = formData.getOrDefault("PageSize")
  valid_601809 = validateParameter(valid_601809, JInt, required = false, default = nil)
  if valid_601809 != nil:
    section.add "PageSize", valid_601809
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601810: Call_PostDescribeTargetGroups_601793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_601810.validator(path, query, header, formData, body)
  let scheme = call_601810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601810.url(scheme.get, call_601810.host, call_601810.base,
                         call_601810.route, valid.getOrDefault("path"))
  result = hook(call_601810, url, valid)

proc call*(call_601811: Call_PostDescribeTargetGroups_601793;
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
  var query_601812 = newJObject()
  var formData_601813 = newJObject()
  add(formData_601813, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    formData_601813.add "TargetGroupArns", TargetGroupArns
  if Names != nil:
    formData_601813.add "Names", Names
  add(formData_601813, "Marker", newJString(Marker))
  add(query_601812, "Action", newJString(Action))
  add(formData_601813, "PageSize", newJInt(PageSize))
  add(query_601812, "Version", newJString(Version))
  result = call_601811.call(nil, query_601812, nil, formData_601813, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_601793(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_601794, base: "/",
    url: url_PostDescribeTargetGroups_601795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_601773 = ref object of OpenApiRestCall_600426
proc url_GetDescribeTargetGroups_601775(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTargetGroups_601774(path: JsonNode; query: JsonNode;
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
  var valid_601776 = query.getOrDefault("Names")
  valid_601776 = validateParameter(valid_601776, JArray, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "Names", valid_601776
  var valid_601777 = query.getOrDefault("PageSize")
  valid_601777 = validateParameter(valid_601777, JInt, required = false, default = nil)
  if valid_601777 != nil:
    section.add "PageSize", valid_601777
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601778 = query.getOrDefault("Action")
  valid_601778 = validateParameter(valid_601778, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_601778 != nil:
    section.add "Action", valid_601778
  var valid_601779 = query.getOrDefault("Marker")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "Marker", valid_601779
  var valid_601780 = query.getOrDefault("LoadBalancerArn")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "LoadBalancerArn", valid_601780
  var valid_601781 = query.getOrDefault("TargetGroupArns")
  valid_601781 = validateParameter(valid_601781, JArray, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "TargetGroupArns", valid_601781
  var valid_601782 = query.getOrDefault("Version")
  valid_601782 = validateParameter(valid_601782, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601782 != nil:
    section.add "Version", valid_601782
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
  var valid_601783 = header.getOrDefault("X-Amz-Date")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-Date", valid_601783
  var valid_601784 = header.getOrDefault("X-Amz-Security-Token")
  valid_601784 = validateParameter(valid_601784, JString, required = false,
                                 default = nil)
  if valid_601784 != nil:
    section.add "X-Amz-Security-Token", valid_601784
  var valid_601785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601785 = validateParameter(valid_601785, JString, required = false,
                                 default = nil)
  if valid_601785 != nil:
    section.add "X-Amz-Content-Sha256", valid_601785
  var valid_601786 = header.getOrDefault("X-Amz-Algorithm")
  valid_601786 = validateParameter(valid_601786, JString, required = false,
                                 default = nil)
  if valid_601786 != nil:
    section.add "X-Amz-Algorithm", valid_601786
  var valid_601787 = header.getOrDefault("X-Amz-Signature")
  valid_601787 = validateParameter(valid_601787, JString, required = false,
                                 default = nil)
  if valid_601787 != nil:
    section.add "X-Amz-Signature", valid_601787
  var valid_601788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601788 = validateParameter(valid_601788, JString, required = false,
                                 default = nil)
  if valid_601788 != nil:
    section.add "X-Amz-SignedHeaders", valid_601788
  var valid_601789 = header.getOrDefault("X-Amz-Credential")
  valid_601789 = validateParameter(valid_601789, JString, required = false,
                                 default = nil)
  if valid_601789 != nil:
    section.add "X-Amz-Credential", valid_601789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601790: Call_GetDescribeTargetGroups_601773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_601790.validator(path, query, header, formData, body)
  let scheme = call_601790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601790.url(scheme.get, call_601790.host, call_601790.base,
                         call_601790.route, valid.getOrDefault("path"))
  result = hook(call_601790, url, valid)

proc call*(call_601791: Call_GetDescribeTargetGroups_601773; Names: JsonNode = nil;
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
  var query_601792 = newJObject()
  if Names != nil:
    query_601792.add "Names", Names
  add(query_601792, "PageSize", newJInt(PageSize))
  add(query_601792, "Action", newJString(Action))
  add(query_601792, "Marker", newJString(Marker))
  add(query_601792, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    query_601792.add "TargetGroupArns", TargetGroupArns
  add(query_601792, "Version", newJString(Version))
  result = call_601791.call(nil, query_601792, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_601773(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_601774, base: "/",
    url: url_GetDescribeTargetGroups_601775, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_601831 = ref object of OpenApiRestCall_600426
proc url_PostDescribeTargetHealth_601833(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTargetHealth_601832(path: JsonNode; query: JsonNode;
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
  var valid_601834 = query.getOrDefault("Action")
  valid_601834 = validateParameter(valid_601834, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_601834 != nil:
    section.add "Action", valid_601834
  var valid_601835 = query.getOrDefault("Version")
  valid_601835 = validateParameter(valid_601835, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601835 != nil:
    section.add "Version", valid_601835
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
  var valid_601836 = header.getOrDefault("X-Amz-Date")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Date", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-Security-Token")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Security-Token", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Content-Sha256", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Algorithm")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Algorithm", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-Signature")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-Signature", valid_601840
  var valid_601841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-SignedHeaders", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Credential")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Credential", valid_601842
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_601843 = formData.getOrDefault("Targets")
  valid_601843 = validateParameter(valid_601843, JArray, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "Targets", valid_601843
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_601844 = formData.getOrDefault("TargetGroupArn")
  valid_601844 = validateParameter(valid_601844, JString, required = true,
                                 default = nil)
  if valid_601844 != nil:
    section.add "TargetGroupArn", valid_601844
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601845: Call_PostDescribeTargetHealth_601831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_601845.validator(path, query, header, formData, body)
  let scheme = call_601845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601845.url(scheme.get, call_601845.host, call_601845.base,
                         call_601845.route, valid.getOrDefault("path"))
  result = hook(call_601845, url, valid)

proc call*(call_601846: Call_PostDescribeTargetHealth_601831;
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
  var query_601847 = newJObject()
  var formData_601848 = newJObject()
  if Targets != nil:
    formData_601848.add "Targets", Targets
  add(query_601847, "Action", newJString(Action))
  add(formData_601848, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_601847, "Version", newJString(Version))
  result = call_601846.call(nil, query_601847, nil, formData_601848, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_601831(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_601832, base: "/",
    url: url_PostDescribeTargetHealth_601833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_601814 = ref object of OpenApiRestCall_600426
proc url_GetDescribeTargetHealth_601816(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTargetHealth_601815(path: JsonNode; query: JsonNode;
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
  var valid_601817 = query.getOrDefault("Targets")
  valid_601817 = validateParameter(valid_601817, JArray, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "Targets", valid_601817
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_601818 = query.getOrDefault("TargetGroupArn")
  valid_601818 = validateParameter(valid_601818, JString, required = true,
                                 default = nil)
  if valid_601818 != nil:
    section.add "TargetGroupArn", valid_601818
  var valid_601819 = query.getOrDefault("Action")
  valid_601819 = validateParameter(valid_601819, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_601819 != nil:
    section.add "Action", valid_601819
  var valid_601820 = query.getOrDefault("Version")
  valid_601820 = validateParameter(valid_601820, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601820 != nil:
    section.add "Version", valid_601820
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
  var valid_601821 = header.getOrDefault("X-Amz-Date")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Date", valid_601821
  var valid_601822 = header.getOrDefault("X-Amz-Security-Token")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-Security-Token", valid_601822
  var valid_601823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "X-Amz-Content-Sha256", valid_601823
  var valid_601824 = header.getOrDefault("X-Amz-Algorithm")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "X-Amz-Algorithm", valid_601824
  var valid_601825 = header.getOrDefault("X-Amz-Signature")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "X-Amz-Signature", valid_601825
  var valid_601826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-SignedHeaders", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-Credential")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Credential", valid_601827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601828: Call_GetDescribeTargetHealth_601814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_601828.validator(path, query, header, formData, body)
  let scheme = call_601828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601828.url(scheme.get, call_601828.host, call_601828.base,
                         call_601828.route, valid.getOrDefault("path"))
  result = hook(call_601828, url, valid)

proc call*(call_601829: Call_GetDescribeTargetHealth_601814;
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
  var query_601830 = newJObject()
  if Targets != nil:
    query_601830.add "Targets", Targets
  add(query_601830, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_601830, "Action", newJString(Action))
  add(query_601830, "Version", newJString(Version))
  result = call_601829.call(nil, query_601830, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_601814(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_601815, base: "/",
    url: url_GetDescribeTargetHealth_601816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_601870 = ref object of OpenApiRestCall_600426
proc url_PostModifyListener_601872(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyListener_601871(path: JsonNode; query: JsonNode;
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
  var valid_601873 = query.getOrDefault("Action")
  valid_601873 = validateParameter(valid_601873, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_601873 != nil:
    section.add "Action", valid_601873
  var valid_601874 = query.getOrDefault("Version")
  valid_601874 = validateParameter(valid_601874, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601874 != nil:
    section.add "Version", valid_601874
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
  var valid_601875 = header.getOrDefault("X-Amz-Date")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-Date", valid_601875
  var valid_601876 = header.getOrDefault("X-Amz-Security-Token")
  valid_601876 = validateParameter(valid_601876, JString, required = false,
                                 default = nil)
  if valid_601876 != nil:
    section.add "X-Amz-Security-Token", valid_601876
  var valid_601877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "X-Amz-Content-Sha256", valid_601877
  var valid_601878 = header.getOrDefault("X-Amz-Algorithm")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "X-Amz-Algorithm", valid_601878
  var valid_601879 = header.getOrDefault("X-Amz-Signature")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "X-Amz-Signature", valid_601879
  var valid_601880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601880 = validateParameter(valid_601880, JString, required = false,
                                 default = nil)
  if valid_601880 != nil:
    section.add "X-Amz-SignedHeaders", valid_601880
  var valid_601881 = header.getOrDefault("X-Amz-Credential")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "X-Amz-Credential", valid_601881
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
  var valid_601882 = formData.getOrDefault("Certificates")
  valid_601882 = validateParameter(valid_601882, JArray, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "Certificates", valid_601882
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_601883 = formData.getOrDefault("ListenerArn")
  valid_601883 = validateParameter(valid_601883, JString, required = true,
                                 default = nil)
  if valid_601883 != nil:
    section.add "ListenerArn", valid_601883
  var valid_601884 = formData.getOrDefault("Port")
  valid_601884 = validateParameter(valid_601884, JInt, required = false, default = nil)
  if valid_601884 != nil:
    section.add "Port", valid_601884
  var valid_601885 = formData.getOrDefault("Protocol")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_601885 != nil:
    section.add "Protocol", valid_601885
  var valid_601886 = formData.getOrDefault("SslPolicy")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "SslPolicy", valid_601886
  var valid_601887 = formData.getOrDefault("DefaultActions")
  valid_601887 = validateParameter(valid_601887, JArray, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "DefaultActions", valid_601887
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601888: Call_PostModifyListener_601870; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_601888.validator(path, query, header, formData, body)
  let scheme = call_601888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601888.url(scheme.get, call_601888.host, call_601888.base,
                         call_601888.route, valid.getOrDefault("path"))
  result = hook(call_601888, url, valid)

proc call*(call_601889: Call_PostModifyListener_601870; ListenerArn: string;
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
  var query_601890 = newJObject()
  var formData_601891 = newJObject()
  if Certificates != nil:
    formData_601891.add "Certificates", Certificates
  add(formData_601891, "ListenerArn", newJString(ListenerArn))
  add(formData_601891, "Port", newJInt(Port))
  add(formData_601891, "Protocol", newJString(Protocol))
  add(query_601890, "Action", newJString(Action))
  add(formData_601891, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_601891.add "DefaultActions", DefaultActions
  add(query_601890, "Version", newJString(Version))
  result = call_601889.call(nil, query_601890, nil, formData_601891, nil)

var postModifyListener* = Call_PostModifyListener_601870(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_601871, base: "/",
    url: url_PostModifyListener_601872, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_601849 = ref object of OpenApiRestCall_600426
proc url_GetModifyListener_601851(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyListener_601850(path: JsonNode; query: JsonNode;
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
  var valid_601852 = query.getOrDefault("DefaultActions")
  valid_601852 = validateParameter(valid_601852, JArray, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "DefaultActions", valid_601852
  var valid_601853 = query.getOrDefault("SslPolicy")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "SslPolicy", valid_601853
  var valid_601854 = query.getOrDefault("Protocol")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_601854 != nil:
    section.add "Protocol", valid_601854
  var valid_601855 = query.getOrDefault("Certificates")
  valid_601855 = validateParameter(valid_601855, JArray, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "Certificates", valid_601855
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601856 = query.getOrDefault("Action")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_601856 != nil:
    section.add "Action", valid_601856
  var valid_601857 = query.getOrDefault("ListenerArn")
  valid_601857 = validateParameter(valid_601857, JString, required = true,
                                 default = nil)
  if valid_601857 != nil:
    section.add "ListenerArn", valid_601857
  var valid_601858 = query.getOrDefault("Port")
  valid_601858 = validateParameter(valid_601858, JInt, required = false, default = nil)
  if valid_601858 != nil:
    section.add "Port", valid_601858
  var valid_601859 = query.getOrDefault("Version")
  valid_601859 = validateParameter(valid_601859, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601859 != nil:
    section.add "Version", valid_601859
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
  var valid_601860 = header.getOrDefault("X-Amz-Date")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Date", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Security-Token")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Security-Token", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Content-Sha256", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Algorithm")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Algorithm", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Signature")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Signature", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-SignedHeaders", valid_601865
  var valid_601866 = header.getOrDefault("X-Amz-Credential")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-Credential", valid_601866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601867: Call_GetModifyListener_601849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_601867.validator(path, query, header, formData, body)
  let scheme = call_601867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601867.url(scheme.get, call_601867.host, call_601867.base,
                         call_601867.route, valid.getOrDefault("path"))
  result = hook(call_601867, url, valid)

proc call*(call_601868: Call_GetModifyListener_601849; ListenerArn: string;
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
  var query_601869 = newJObject()
  if DefaultActions != nil:
    query_601869.add "DefaultActions", DefaultActions
  add(query_601869, "SslPolicy", newJString(SslPolicy))
  add(query_601869, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_601869.add "Certificates", Certificates
  add(query_601869, "Action", newJString(Action))
  add(query_601869, "ListenerArn", newJString(ListenerArn))
  add(query_601869, "Port", newJInt(Port))
  add(query_601869, "Version", newJString(Version))
  result = call_601868.call(nil, query_601869, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_601849(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_601850,
    base: "/", url: url_GetModifyListener_601851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_601909 = ref object of OpenApiRestCall_600426
proc url_PostModifyLoadBalancerAttributes_601911(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyLoadBalancerAttributes_601910(path: JsonNode;
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
  var valid_601912 = query.getOrDefault("Action")
  valid_601912 = validateParameter(valid_601912, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_601912 != nil:
    section.add "Action", valid_601912
  var valid_601913 = query.getOrDefault("Version")
  valid_601913 = validateParameter(valid_601913, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601913 != nil:
    section.add "Version", valid_601913
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
  var valid_601914 = header.getOrDefault("X-Amz-Date")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-Date", valid_601914
  var valid_601915 = header.getOrDefault("X-Amz-Security-Token")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Security-Token", valid_601915
  var valid_601916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-Content-Sha256", valid_601916
  var valid_601917 = header.getOrDefault("X-Amz-Algorithm")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Algorithm", valid_601917
  var valid_601918 = header.getOrDefault("X-Amz-Signature")
  valid_601918 = validateParameter(valid_601918, JString, required = false,
                                 default = nil)
  if valid_601918 != nil:
    section.add "X-Amz-Signature", valid_601918
  var valid_601919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-SignedHeaders", valid_601919
  var valid_601920 = header.getOrDefault("X-Amz-Credential")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "X-Amz-Credential", valid_601920
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_601921 = formData.getOrDefault("LoadBalancerArn")
  valid_601921 = validateParameter(valid_601921, JString, required = true,
                                 default = nil)
  if valid_601921 != nil:
    section.add "LoadBalancerArn", valid_601921
  var valid_601922 = formData.getOrDefault("Attributes")
  valid_601922 = validateParameter(valid_601922, JArray, required = true, default = nil)
  if valid_601922 != nil:
    section.add "Attributes", valid_601922
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601923: Call_PostModifyLoadBalancerAttributes_601909;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_601923.validator(path, query, header, formData, body)
  let scheme = call_601923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601923.url(scheme.get, call_601923.host, call_601923.base,
                         call_601923.route, valid.getOrDefault("path"))
  result = hook(call_601923, url, valid)

proc call*(call_601924: Call_PostModifyLoadBalancerAttributes_601909;
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
  var query_601925 = newJObject()
  var formData_601926 = newJObject()
  add(formData_601926, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    formData_601926.add "Attributes", Attributes
  add(query_601925, "Action", newJString(Action))
  add(query_601925, "Version", newJString(Version))
  result = call_601924.call(nil, query_601925, nil, formData_601926, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_601909(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_601910, base: "/",
    url: url_PostModifyLoadBalancerAttributes_601911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_601892 = ref object of OpenApiRestCall_600426
proc url_GetModifyLoadBalancerAttributes_601894(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyLoadBalancerAttributes_601893(path: JsonNode;
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
  var valid_601895 = query.getOrDefault("Attributes")
  valid_601895 = validateParameter(valid_601895, JArray, required = true, default = nil)
  if valid_601895 != nil:
    section.add "Attributes", valid_601895
  var valid_601896 = query.getOrDefault("Action")
  valid_601896 = validateParameter(valid_601896, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_601896 != nil:
    section.add "Action", valid_601896
  var valid_601897 = query.getOrDefault("LoadBalancerArn")
  valid_601897 = validateParameter(valid_601897, JString, required = true,
                                 default = nil)
  if valid_601897 != nil:
    section.add "LoadBalancerArn", valid_601897
  var valid_601898 = query.getOrDefault("Version")
  valid_601898 = validateParameter(valid_601898, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601898 != nil:
    section.add "Version", valid_601898
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
  var valid_601899 = header.getOrDefault("X-Amz-Date")
  valid_601899 = validateParameter(valid_601899, JString, required = false,
                                 default = nil)
  if valid_601899 != nil:
    section.add "X-Amz-Date", valid_601899
  var valid_601900 = header.getOrDefault("X-Amz-Security-Token")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "X-Amz-Security-Token", valid_601900
  var valid_601901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "X-Amz-Content-Sha256", valid_601901
  var valid_601902 = header.getOrDefault("X-Amz-Algorithm")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "X-Amz-Algorithm", valid_601902
  var valid_601903 = header.getOrDefault("X-Amz-Signature")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "X-Amz-Signature", valid_601903
  var valid_601904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-SignedHeaders", valid_601904
  var valid_601905 = header.getOrDefault("X-Amz-Credential")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "X-Amz-Credential", valid_601905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601906: Call_GetModifyLoadBalancerAttributes_601892;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_601906.validator(path, query, header, formData, body)
  let scheme = call_601906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601906.url(scheme.get, call_601906.host, call_601906.base,
                         call_601906.route, valid.getOrDefault("path"))
  result = hook(call_601906, url, valid)

proc call*(call_601907: Call_GetModifyLoadBalancerAttributes_601892;
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
  var query_601908 = newJObject()
  if Attributes != nil:
    query_601908.add "Attributes", Attributes
  add(query_601908, "Action", newJString(Action))
  add(query_601908, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_601908, "Version", newJString(Version))
  result = call_601907.call(nil, query_601908, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_601892(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_601893, base: "/",
    url: url_GetModifyLoadBalancerAttributes_601894,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_601945 = ref object of OpenApiRestCall_600426
proc url_PostModifyRule_601947(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyRule_601946(path: JsonNode; query: JsonNode;
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
  var valid_601948 = query.getOrDefault("Action")
  valid_601948 = validateParameter(valid_601948, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_601948 != nil:
    section.add "Action", valid_601948
  var valid_601949 = query.getOrDefault("Version")
  valid_601949 = validateParameter(valid_601949, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601949 != nil:
    section.add "Version", valid_601949
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
  var valid_601950 = header.getOrDefault("X-Amz-Date")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Date", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Security-Token")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Security-Token", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-Content-Sha256", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-Algorithm")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-Algorithm", valid_601953
  var valid_601954 = header.getOrDefault("X-Amz-Signature")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "X-Amz-Signature", valid_601954
  var valid_601955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "X-Amz-SignedHeaders", valid_601955
  var valid_601956 = header.getOrDefault("X-Amz-Credential")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "X-Amz-Credential", valid_601956
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
  var valid_601957 = formData.getOrDefault("RuleArn")
  valid_601957 = validateParameter(valid_601957, JString, required = true,
                                 default = nil)
  if valid_601957 != nil:
    section.add "RuleArn", valid_601957
  var valid_601958 = formData.getOrDefault("Actions")
  valid_601958 = validateParameter(valid_601958, JArray, required = false,
                                 default = nil)
  if valid_601958 != nil:
    section.add "Actions", valid_601958
  var valid_601959 = formData.getOrDefault("Conditions")
  valid_601959 = validateParameter(valid_601959, JArray, required = false,
                                 default = nil)
  if valid_601959 != nil:
    section.add "Conditions", valid_601959
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601960: Call_PostModifyRule_601945; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_601960.validator(path, query, header, formData, body)
  let scheme = call_601960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601960.url(scheme.get, call_601960.host, call_601960.base,
                         call_601960.route, valid.getOrDefault("path"))
  result = hook(call_601960, url, valid)

proc call*(call_601961: Call_PostModifyRule_601945; RuleArn: string;
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
  var query_601962 = newJObject()
  var formData_601963 = newJObject()
  add(formData_601963, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    formData_601963.add "Actions", Actions
  if Conditions != nil:
    formData_601963.add "Conditions", Conditions
  add(query_601962, "Action", newJString(Action))
  add(query_601962, "Version", newJString(Version))
  result = call_601961.call(nil, query_601962, nil, formData_601963, nil)

var postModifyRule* = Call_PostModifyRule_601945(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_601946,
    base: "/", url: url_PostModifyRule_601947, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_601927 = ref object of OpenApiRestCall_600426
proc url_GetModifyRule_601929(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyRule_601928(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601930 = query.getOrDefault("Conditions")
  valid_601930 = validateParameter(valid_601930, JArray, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "Conditions", valid_601930
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601931 = query.getOrDefault("Action")
  valid_601931 = validateParameter(valid_601931, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_601931 != nil:
    section.add "Action", valid_601931
  var valid_601932 = query.getOrDefault("RuleArn")
  valid_601932 = validateParameter(valid_601932, JString, required = true,
                                 default = nil)
  if valid_601932 != nil:
    section.add "RuleArn", valid_601932
  var valid_601933 = query.getOrDefault("Actions")
  valid_601933 = validateParameter(valid_601933, JArray, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "Actions", valid_601933
  var valid_601934 = query.getOrDefault("Version")
  valid_601934 = validateParameter(valid_601934, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601934 != nil:
    section.add "Version", valid_601934
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
  var valid_601935 = header.getOrDefault("X-Amz-Date")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Date", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-Security-Token")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-Security-Token", valid_601936
  var valid_601937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "X-Amz-Content-Sha256", valid_601937
  var valid_601938 = header.getOrDefault("X-Amz-Algorithm")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "X-Amz-Algorithm", valid_601938
  var valid_601939 = header.getOrDefault("X-Amz-Signature")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "X-Amz-Signature", valid_601939
  var valid_601940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601940 = validateParameter(valid_601940, JString, required = false,
                                 default = nil)
  if valid_601940 != nil:
    section.add "X-Amz-SignedHeaders", valid_601940
  var valid_601941 = header.getOrDefault("X-Amz-Credential")
  valid_601941 = validateParameter(valid_601941, JString, required = false,
                                 default = nil)
  if valid_601941 != nil:
    section.add "X-Amz-Credential", valid_601941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601942: Call_GetModifyRule_601927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_601942.validator(path, query, header, formData, body)
  let scheme = call_601942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601942.url(scheme.get, call_601942.host, call_601942.base,
                         call_601942.route, valid.getOrDefault("path"))
  result = hook(call_601942, url, valid)

proc call*(call_601943: Call_GetModifyRule_601927; RuleArn: string;
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
  var query_601944 = newJObject()
  if Conditions != nil:
    query_601944.add "Conditions", Conditions
  add(query_601944, "Action", newJString(Action))
  add(query_601944, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_601944.add "Actions", Actions
  add(query_601944, "Version", newJString(Version))
  result = call_601943.call(nil, query_601944, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_601927(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_601928,
    base: "/", url: url_GetModifyRule_601929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_601989 = ref object of OpenApiRestCall_600426
proc url_PostModifyTargetGroup_601991(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyTargetGroup_601990(path: JsonNode; query: JsonNode;
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
  var valid_601992 = query.getOrDefault("Action")
  valid_601992 = validateParameter(valid_601992, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_601992 != nil:
    section.add "Action", valid_601992
  var valid_601993 = query.getOrDefault("Version")
  valid_601993 = validateParameter(valid_601993, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601993 != nil:
    section.add "Version", valid_601993
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
  var valid_601994 = header.getOrDefault("X-Amz-Date")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Date", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Security-Token")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Security-Token", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Content-Sha256", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-Algorithm")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Algorithm", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Signature")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Signature", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-SignedHeaders", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Credential")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Credential", valid_602000
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
  var valid_602001 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_602001 = validateParameter(valid_602001, JInt, required = false, default = nil)
  if valid_602001 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_602001
  var valid_602002 = formData.getOrDefault("HealthCheckPort")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "HealthCheckPort", valid_602002
  var valid_602003 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_602003 = validateParameter(valid_602003, JInt, required = false, default = nil)
  if valid_602003 != nil:
    section.add "UnhealthyThresholdCount", valid_602003
  var valid_602004 = formData.getOrDefault("HealthCheckPath")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "HealthCheckPath", valid_602004
  var valid_602005 = formData.getOrDefault("HealthCheckEnabled")
  valid_602005 = validateParameter(valid_602005, JBool, required = false, default = nil)
  if valid_602005 != nil:
    section.add "HealthCheckEnabled", valid_602005
  var valid_602006 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_602006 = validateParameter(valid_602006, JInt, required = false, default = nil)
  if valid_602006 != nil:
    section.add "HealthCheckIntervalSeconds", valid_602006
  var valid_602007 = formData.getOrDefault("HealthyThresholdCount")
  valid_602007 = validateParameter(valid_602007, JInt, required = false, default = nil)
  if valid_602007 != nil:
    section.add "HealthyThresholdCount", valid_602007
  var valid_602008 = formData.getOrDefault("HealthCheckProtocol")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_602008 != nil:
    section.add "HealthCheckProtocol", valid_602008
  var valid_602009 = formData.getOrDefault("Matcher.HttpCode")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "Matcher.HttpCode", valid_602009
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_602010 = formData.getOrDefault("TargetGroupArn")
  valid_602010 = validateParameter(valid_602010, JString, required = true,
                                 default = nil)
  if valid_602010 != nil:
    section.add "TargetGroupArn", valid_602010
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602011: Call_PostModifyTargetGroup_601989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_602011.validator(path, query, header, formData, body)
  let scheme = call_602011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602011.url(scheme.get, call_602011.host, call_602011.base,
                         call_602011.route, valid.getOrDefault("path"))
  result = hook(call_602011, url, valid)

proc call*(call_602012: Call_PostModifyTargetGroup_601989; TargetGroupArn: string;
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
  var query_602013 = newJObject()
  var formData_602014 = newJObject()
  add(formData_602014, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_602014, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_602014, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_602014, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_602014, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_602013, "Action", newJString(Action))
  add(formData_602014, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_602014, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_602014, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_602014, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(formData_602014, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602013, "Version", newJString(Version))
  result = call_602012.call(nil, query_602013, nil, formData_602014, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_601989(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_601990, base: "/",
    url: url_PostModifyTargetGroup_601991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_601964 = ref object of OpenApiRestCall_600426
proc url_GetModifyTargetGroup_601966(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyTargetGroup_601965(path: JsonNode; query: JsonNode;
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
  var valid_601967 = query.getOrDefault("HealthCheckEnabled")
  valid_601967 = validateParameter(valid_601967, JBool, required = false, default = nil)
  if valid_601967 != nil:
    section.add "HealthCheckEnabled", valid_601967
  var valid_601968 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_601968 = validateParameter(valid_601968, JInt, required = false, default = nil)
  if valid_601968 != nil:
    section.add "HealthCheckIntervalSeconds", valid_601968
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_601969 = query.getOrDefault("TargetGroupArn")
  valid_601969 = validateParameter(valid_601969, JString, required = true,
                                 default = nil)
  if valid_601969 != nil:
    section.add "TargetGroupArn", valid_601969
  var valid_601970 = query.getOrDefault("HealthCheckPort")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "HealthCheckPort", valid_601970
  var valid_601971 = query.getOrDefault("Action")
  valid_601971 = validateParameter(valid_601971, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_601971 != nil:
    section.add "Action", valid_601971
  var valid_601972 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_601972 = validateParameter(valid_601972, JInt, required = false, default = nil)
  if valid_601972 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_601972
  var valid_601973 = query.getOrDefault("Matcher.HttpCode")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "Matcher.HttpCode", valid_601973
  var valid_601974 = query.getOrDefault("UnhealthyThresholdCount")
  valid_601974 = validateParameter(valid_601974, JInt, required = false, default = nil)
  if valid_601974 != nil:
    section.add "UnhealthyThresholdCount", valid_601974
  var valid_601975 = query.getOrDefault("HealthCheckProtocol")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_601975 != nil:
    section.add "HealthCheckProtocol", valid_601975
  var valid_601976 = query.getOrDefault("HealthyThresholdCount")
  valid_601976 = validateParameter(valid_601976, JInt, required = false, default = nil)
  if valid_601976 != nil:
    section.add "HealthyThresholdCount", valid_601976
  var valid_601977 = query.getOrDefault("Version")
  valid_601977 = validateParameter(valid_601977, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_601977 != nil:
    section.add "Version", valid_601977
  var valid_601978 = query.getOrDefault("HealthCheckPath")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "HealthCheckPath", valid_601978
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
  var valid_601979 = header.getOrDefault("X-Amz-Date")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "X-Amz-Date", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-Security-Token")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-Security-Token", valid_601980
  var valid_601981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-Content-Sha256", valid_601981
  var valid_601982 = header.getOrDefault("X-Amz-Algorithm")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-Algorithm", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-Signature")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-Signature", valid_601983
  var valid_601984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "X-Amz-SignedHeaders", valid_601984
  var valid_601985 = header.getOrDefault("X-Amz-Credential")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "X-Amz-Credential", valid_601985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601986: Call_GetModifyTargetGroup_601964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_601986.validator(path, query, header, formData, body)
  let scheme = call_601986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601986.url(scheme.get, call_601986.host, call_601986.base,
                         call_601986.route, valid.getOrDefault("path"))
  result = hook(call_601986, url, valid)

proc call*(call_601987: Call_GetModifyTargetGroup_601964; TargetGroupArn: string;
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
  var query_601988 = newJObject()
  add(query_601988, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_601988, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_601988, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_601988, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_601988, "Action", newJString(Action))
  add(query_601988, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_601988, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_601988, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_601988, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_601988, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_601988, "Version", newJString(Version))
  add(query_601988, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_601987.call(nil, query_601988, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_601964(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_601965,
    base: "/", url: url_GetModifyTargetGroup_601966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_602032 = ref object of OpenApiRestCall_600426
proc url_PostModifyTargetGroupAttributes_602034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyTargetGroupAttributes_602033(path: JsonNode;
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
  var valid_602035 = query.getOrDefault("Action")
  valid_602035 = validateParameter(valid_602035, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_602035 != nil:
    section.add "Action", valid_602035
  var valid_602036 = query.getOrDefault("Version")
  valid_602036 = validateParameter(valid_602036, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602036 != nil:
    section.add "Version", valid_602036
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
  var valid_602037 = header.getOrDefault("X-Amz-Date")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Date", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Security-Token")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Security-Token", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Content-Sha256", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Algorithm")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Algorithm", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Signature")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Signature", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-SignedHeaders", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Credential")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Credential", valid_602043
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_602044 = formData.getOrDefault("Attributes")
  valid_602044 = validateParameter(valid_602044, JArray, required = true, default = nil)
  if valid_602044 != nil:
    section.add "Attributes", valid_602044
  var valid_602045 = formData.getOrDefault("TargetGroupArn")
  valid_602045 = validateParameter(valid_602045, JString, required = true,
                                 default = nil)
  if valid_602045 != nil:
    section.add "TargetGroupArn", valid_602045
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602046: Call_PostModifyTargetGroupAttributes_602032;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_602046.validator(path, query, header, formData, body)
  let scheme = call_602046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602046.url(scheme.get, call_602046.host, call_602046.base,
                         call_602046.route, valid.getOrDefault("path"))
  result = hook(call_602046, url, valid)

proc call*(call_602047: Call_PostModifyTargetGroupAttributes_602032;
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
  var query_602048 = newJObject()
  var formData_602049 = newJObject()
  if Attributes != nil:
    formData_602049.add "Attributes", Attributes
  add(query_602048, "Action", newJString(Action))
  add(formData_602049, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602048, "Version", newJString(Version))
  result = call_602047.call(nil, query_602048, nil, formData_602049, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_602032(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_602033, base: "/",
    url: url_PostModifyTargetGroupAttributes_602034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_602015 = ref object of OpenApiRestCall_600426
proc url_GetModifyTargetGroupAttributes_602017(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyTargetGroupAttributes_602016(path: JsonNode;
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
  var valid_602018 = query.getOrDefault("TargetGroupArn")
  valid_602018 = validateParameter(valid_602018, JString, required = true,
                                 default = nil)
  if valid_602018 != nil:
    section.add "TargetGroupArn", valid_602018
  var valid_602019 = query.getOrDefault("Attributes")
  valid_602019 = validateParameter(valid_602019, JArray, required = true, default = nil)
  if valid_602019 != nil:
    section.add "Attributes", valid_602019
  var valid_602020 = query.getOrDefault("Action")
  valid_602020 = validateParameter(valid_602020, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_602020 != nil:
    section.add "Action", valid_602020
  var valid_602021 = query.getOrDefault("Version")
  valid_602021 = validateParameter(valid_602021, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602021 != nil:
    section.add "Version", valid_602021
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
  var valid_602022 = header.getOrDefault("X-Amz-Date")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Date", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Security-Token")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Security-Token", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Content-Sha256", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Algorithm")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Algorithm", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Signature")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Signature", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-SignedHeaders", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Credential")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Credential", valid_602028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602029: Call_GetModifyTargetGroupAttributes_602015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_602029.validator(path, query, header, formData, body)
  let scheme = call_602029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602029.url(scheme.get, call_602029.host, call_602029.base,
                         call_602029.route, valid.getOrDefault("path"))
  result = hook(call_602029, url, valid)

proc call*(call_602030: Call_GetModifyTargetGroupAttributes_602015;
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
  var query_602031 = newJObject()
  add(query_602031, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_602031.add "Attributes", Attributes
  add(query_602031, "Action", newJString(Action))
  add(query_602031, "Version", newJString(Version))
  result = call_602030.call(nil, query_602031, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_602015(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_602016, base: "/",
    url: url_GetModifyTargetGroupAttributes_602017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_602067 = ref object of OpenApiRestCall_600426
proc url_PostRegisterTargets_602069(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRegisterTargets_602068(path: JsonNode; query: JsonNode;
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
  var valid_602070 = query.getOrDefault("Action")
  valid_602070 = validateParameter(valid_602070, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_602070 != nil:
    section.add "Action", valid_602070
  var valid_602071 = query.getOrDefault("Version")
  valid_602071 = validateParameter(valid_602071, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602071 != nil:
    section.add "Version", valid_602071
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
  var valid_602072 = header.getOrDefault("X-Amz-Date")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Date", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Security-Token")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Security-Token", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Content-Sha256", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Algorithm")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Algorithm", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Signature")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Signature", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-SignedHeaders", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_602079 = formData.getOrDefault("Targets")
  valid_602079 = validateParameter(valid_602079, JArray, required = true, default = nil)
  if valid_602079 != nil:
    section.add "Targets", valid_602079
  var valid_602080 = formData.getOrDefault("TargetGroupArn")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = nil)
  if valid_602080 != nil:
    section.add "TargetGroupArn", valid_602080
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602081: Call_PostRegisterTargets_602067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_602081.validator(path, query, header, formData, body)
  let scheme = call_602081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602081.url(scheme.get, call_602081.host, call_602081.base,
                         call_602081.route, valid.getOrDefault("path"))
  result = hook(call_602081, url, valid)

proc call*(call_602082: Call_PostRegisterTargets_602067; Targets: JsonNode;
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
  var query_602083 = newJObject()
  var formData_602084 = newJObject()
  if Targets != nil:
    formData_602084.add "Targets", Targets
  add(query_602083, "Action", newJString(Action))
  add(formData_602084, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602083, "Version", newJString(Version))
  result = call_602082.call(nil, query_602083, nil, formData_602084, nil)

var postRegisterTargets* = Call_PostRegisterTargets_602067(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_602068, base: "/",
    url: url_PostRegisterTargets_602069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_602050 = ref object of OpenApiRestCall_600426
proc url_GetRegisterTargets_602052(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRegisterTargets_602051(path: JsonNode; query: JsonNode;
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
  var valid_602053 = query.getOrDefault("Targets")
  valid_602053 = validateParameter(valid_602053, JArray, required = true, default = nil)
  if valid_602053 != nil:
    section.add "Targets", valid_602053
  var valid_602054 = query.getOrDefault("TargetGroupArn")
  valid_602054 = validateParameter(valid_602054, JString, required = true,
                                 default = nil)
  if valid_602054 != nil:
    section.add "TargetGroupArn", valid_602054
  var valid_602055 = query.getOrDefault("Action")
  valid_602055 = validateParameter(valid_602055, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_602055 != nil:
    section.add "Action", valid_602055
  var valid_602056 = query.getOrDefault("Version")
  valid_602056 = validateParameter(valid_602056, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602056 != nil:
    section.add "Version", valid_602056
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
  var valid_602057 = header.getOrDefault("X-Amz-Date")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Date", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Security-Token")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Security-Token", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Content-Sha256", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Algorithm")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Algorithm", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Signature")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Signature", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-SignedHeaders", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602064: Call_GetRegisterTargets_602050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_602064.validator(path, query, header, formData, body)
  let scheme = call_602064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602064.url(scheme.get, call_602064.host, call_602064.base,
                         call_602064.route, valid.getOrDefault("path"))
  result = hook(call_602064, url, valid)

proc call*(call_602065: Call_GetRegisterTargets_602050; Targets: JsonNode;
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
  var query_602066 = newJObject()
  if Targets != nil:
    query_602066.add "Targets", Targets
  add(query_602066, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_602066, "Action", newJString(Action))
  add(query_602066, "Version", newJString(Version))
  result = call_602065.call(nil, query_602066, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_602050(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_602051, base: "/",
    url: url_GetRegisterTargets_602052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_602102 = ref object of OpenApiRestCall_600426
proc url_PostRemoveListenerCertificates_602104(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveListenerCertificates_602103(path: JsonNode;
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
  var valid_602105 = query.getOrDefault("Action")
  valid_602105 = validateParameter(valid_602105, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_602105 != nil:
    section.add "Action", valid_602105
  var valid_602106 = query.getOrDefault("Version")
  valid_602106 = validateParameter(valid_602106, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602106 != nil:
    section.add "Version", valid_602106
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
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Security-Token")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Security-Token", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Content-Sha256", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Signature")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Signature", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-SignedHeaders", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Credential")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Credential", valid_602113
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_602114 = formData.getOrDefault("Certificates")
  valid_602114 = validateParameter(valid_602114, JArray, required = true, default = nil)
  if valid_602114 != nil:
    section.add "Certificates", valid_602114
  var valid_602115 = formData.getOrDefault("ListenerArn")
  valid_602115 = validateParameter(valid_602115, JString, required = true,
                                 default = nil)
  if valid_602115 != nil:
    section.add "ListenerArn", valid_602115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602116: Call_PostRemoveListenerCertificates_602102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_602116.validator(path, query, header, formData, body)
  let scheme = call_602116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602116.url(scheme.get, call_602116.host, call_602116.base,
                         call_602116.route, valid.getOrDefault("path"))
  result = hook(call_602116, url, valid)

proc call*(call_602117: Call_PostRemoveListenerCertificates_602102;
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
  var query_602118 = newJObject()
  var formData_602119 = newJObject()
  if Certificates != nil:
    formData_602119.add "Certificates", Certificates
  add(formData_602119, "ListenerArn", newJString(ListenerArn))
  add(query_602118, "Action", newJString(Action))
  add(query_602118, "Version", newJString(Version))
  result = call_602117.call(nil, query_602118, nil, formData_602119, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_602102(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_602103, base: "/",
    url: url_PostRemoveListenerCertificates_602104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_602085 = ref object of OpenApiRestCall_600426
proc url_GetRemoveListenerCertificates_602087(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveListenerCertificates_602086(path: JsonNode; query: JsonNode;
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
  var valid_602088 = query.getOrDefault("Certificates")
  valid_602088 = validateParameter(valid_602088, JArray, required = true, default = nil)
  if valid_602088 != nil:
    section.add "Certificates", valid_602088
  var valid_602089 = query.getOrDefault("Action")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_602089 != nil:
    section.add "Action", valid_602089
  var valid_602090 = query.getOrDefault("ListenerArn")
  valid_602090 = validateParameter(valid_602090, JString, required = true,
                                 default = nil)
  if valid_602090 != nil:
    section.add "ListenerArn", valid_602090
  var valid_602091 = query.getOrDefault("Version")
  valid_602091 = validateParameter(valid_602091, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602091 != nil:
    section.add "Version", valid_602091
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
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Security-Token")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Security-Token", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Content-Sha256", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Signature")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Signature", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-SignedHeaders", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Credential")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Credential", valid_602098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602099: Call_GetRemoveListenerCertificates_602085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_602099.validator(path, query, header, formData, body)
  let scheme = call_602099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602099.url(scheme.get, call_602099.host, call_602099.base,
                         call_602099.route, valid.getOrDefault("path"))
  result = hook(call_602099, url, valid)

proc call*(call_602100: Call_GetRemoveListenerCertificates_602085;
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
  var query_602101 = newJObject()
  if Certificates != nil:
    query_602101.add "Certificates", Certificates
  add(query_602101, "Action", newJString(Action))
  add(query_602101, "ListenerArn", newJString(ListenerArn))
  add(query_602101, "Version", newJString(Version))
  result = call_602100.call(nil, query_602101, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_602085(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_602086, base: "/",
    url: url_GetRemoveListenerCertificates_602087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_602137 = ref object of OpenApiRestCall_600426
proc url_PostRemoveTags_602139(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTags_602138(path: JsonNode; query: JsonNode;
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
  var valid_602140 = query.getOrDefault("Action")
  valid_602140 = validateParameter(valid_602140, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_602140 != nil:
    section.add "Action", valid_602140
  var valid_602141 = query.getOrDefault("Version")
  valid_602141 = validateParameter(valid_602141, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602141 != nil:
    section.add "Version", valid_602141
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
  var valid_602142 = header.getOrDefault("X-Amz-Date")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Date", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Security-Token")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Security-Token", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Content-Sha256", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Algorithm")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Algorithm", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Signature")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Signature", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-SignedHeaders", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Credential")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Credential", valid_602148
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_602149 = formData.getOrDefault("ResourceArns")
  valid_602149 = validateParameter(valid_602149, JArray, required = true, default = nil)
  if valid_602149 != nil:
    section.add "ResourceArns", valid_602149
  var valid_602150 = formData.getOrDefault("TagKeys")
  valid_602150 = validateParameter(valid_602150, JArray, required = true, default = nil)
  if valid_602150 != nil:
    section.add "TagKeys", valid_602150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602151: Call_PostRemoveTags_602137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_602151.validator(path, query, header, formData, body)
  let scheme = call_602151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602151.url(scheme.get, call_602151.host, call_602151.base,
                         call_602151.route, valid.getOrDefault("path"))
  result = hook(call_602151, url, valid)

proc call*(call_602152: Call_PostRemoveTags_602137; ResourceArns: JsonNode;
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
  var query_602153 = newJObject()
  var formData_602154 = newJObject()
  if ResourceArns != nil:
    formData_602154.add "ResourceArns", ResourceArns
  add(query_602153, "Action", newJString(Action))
  if TagKeys != nil:
    formData_602154.add "TagKeys", TagKeys
  add(query_602153, "Version", newJString(Version))
  result = call_602152.call(nil, query_602153, nil, formData_602154, nil)

var postRemoveTags* = Call_PostRemoveTags_602137(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_602138,
    base: "/", url: url_PostRemoveTags_602139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_602120 = ref object of OpenApiRestCall_600426
proc url_GetRemoveTags_602122(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTags_602121(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602123 = query.getOrDefault("Action")
  valid_602123 = validateParameter(valid_602123, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_602123 != nil:
    section.add "Action", valid_602123
  var valid_602124 = query.getOrDefault("ResourceArns")
  valid_602124 = validateParameter(valid_602124, JArray, required = true, default = nil)
  if valid_602124 != nil:
    section.add "ResourceArns", valid_602124
  var valid_602125 = query.getOrDefault("TagKeys")
  valid_602125 = validateParameter(valid_602125, JArray, required = true, default = nil)
  if valid_602125 != nil:
    section.add "TagKeys", valid_602125
  var valid_602126 = query.getOrDefault("Version")
  valid_602126 = validateParameter(valid_602126, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602126 != nil:
    section.add "Version", valid_602126
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
  var valid_602127 = header.getOrDefault("X-Amz-Date")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Date", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Security-Token")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Security-Token", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Content-Sha256", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Algorithm")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Algorithm", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Signature")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Signature", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-SignedHeaders", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Credential")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Credential", valid_602133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602134: Call_GetRemoveTags_602120; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_602134.validator(path, query, header, formData, body)
  let scheme = call_602134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602134.url(scheme.get, call_602134.host, call_602134.base,
                         call_602134.route, valid.getOrDefault("path"))
  result = hook(call_602134, url, valid)

proc call*(call_602135: Call_GetRemoveTags_602120; ResourceArns: JsonNode;
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
  var query_602136 = newJObject()
  add(query_602136, "Action", newJString(Action))
  if ResourceArns != nil:
    query_602136.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_602136.add "TagKeys", TagKeys
  add(query_602136, "Version", newJString(Version))
  result = call_602135.call(nil, query_602136, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_602120(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_602121,
    base: "/", url: url_GetRemoveTags_602122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_602172 = ref object of OpenApiRestCall_600426
proc url_PostSetIpAddressType_602174(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetIpAddressType_602173(path: JsonNode; query: JsonNode;
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
  var valid_602175 = query.getOrDefault("Action")
  valid_602175 = validateParameter(valid_602175, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_602175 != nil:
    section.add "Action", valid_602175
  var valid_602176 = query.getOrDefault("Version")
  valid_602176 = validateParameter(valid_602176, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602176 != nil:
    section.add "Version", valid_602176
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
  var valid_602177 = header.getOrDefault("X-Amz-Date")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Date", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Security-Token")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Security-Token", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Content-Sha256", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Algorithm")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Algorithm", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Signature")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Signature", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-SignedHeaders", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Credential")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Credential", valid_602183
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_602184 = formData.getOrDefault("LoadBalancerArn")
  valid_602184 = validateParameter(valid_602184, JString, required = true,
                                 default = nil)
  if valid_602184 != nil:
    section.add "LoadBalancerArn", valid_602184
  var valid_602185 = formData.getOrDefault("IpAddressType")
  valid_602185 = validateParameter(valid_602185, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_602185 != nil:
    section.add "IpAddressType", valid_602185
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602186: Call_PostSetIpAddressType_602172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_602186.validator(path, query, header, formData, body)
  let scheme = call_602186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602186.url(scheme.get, call_602186.host, call_602186.base,
                         call_602186.route, valid.getOrDefault("path"))
  result = hook(call_602186, url, valid)

proc call*(call_602187: Call_PostSetIpAddressType_602172; LoadBalancerArn: string;
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
  var query_602188 = newJObject()
  var formData_602189 = newJObject()
  add(formData_602189, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_602189, "IpAddressType", newJString(IpAddressType))
  add(query_602188, "Action", newJString(Action))
  add(query_602188, "Version", newJString(Version))
  result = call_602187.call(nil, query_602188, nil, formData_602189, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_602172(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_602173,
    base: "/", url: url_PostSetIpAddressType_602174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_602155 = ref object of OpenApiRestCall_600426
proc url_GetSetIpAddressType_602157(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetIpAddressType_602156(path: JsonNode; query: JsonNode;
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
  var valid_602158 = query.getOrDefault("IpAddressType")
  valid_602158 = validateParameter(valid_602158, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_602158 != nil:
    section.add "IpAddressType", valid_602158
  var valid_602159 = query.getOrDefault("Action")
  valid_602159 = validateParameter(valid_602159, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_602159 != nil:
    section.add "Action", valid_602159
  var valid_602160 = query.getOrDefault("LoadBalancerArn")
  valid_602160 = validateParameter(valid_602160, JString, required = true,
                                 default = nil)
  if valid_602160 != nil:
    section.add "LoadBalancerArn", valid_602160
  var valid_602161 = query.getOrDefault("Version")
  valid_602161 = validateParameter(valid_602161, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602161 != nil:
    section.add "Version", valid_602161
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
  var valid_602162 = header.getOrDefault("X-Amz-Date")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Date", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Security-Token")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Security-Token", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Content-Sha256", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Algorithm")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Algorithm", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Signature")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Signature", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-SignedHeaders", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Credential")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Credential", valid_602168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602169: Call_GetSetIpAddressType_602155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_602169.validator(path, query, header, formData, body)
  let scheme = call_602169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602169.url(scheme.get, call_602169.host, call_602169.base,
                         call_602169.route, valid.getOrDefault("path"))
  result = hook(call_602169, url, valid)

proc call*(call_602170: Call_GetSetIpAddressType_602155; LoadBalancerArn: string;
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
  var query_602171 = newJObject()
  add(query_602171, "IpAddressType", newJString(IpAddressType))
  add(query_602171, "Action", newJString(Action))
  add(query_602171, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_602171, "Version", newJString(Version))
  result = call_602170.call(nil, query_602171, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_602155(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_602156,
    base: "/", url: url_GetSetIpAddressType_602157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_602206 = ref object of OpenApiRestCall_600426
proc url_PostSetRulePriorities_602208(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetRulePriorities_602207(path: JsonNode; query: JsonNode;
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
  var valid_602209 = query.getOrDefault("Action")
  valid_602209 = validateParameter(valid_602209, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_602209 != nil:
    section.add "Action", valid_602209
  var valid_602210 = query.getOrDefault("Version")
  valid_602210 = validateParameter(valid_602210, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602210 != nil:
    section.add "Version", valid_602210
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
  var valid_602211 = header.getOrDefault("X-Amz-Date")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Date", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Security-Token")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Security-Token", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Content-Sha256", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Algorithm")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Algorithm", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Signature")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Signature", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-SignedHeaders", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Credential")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Credential", valid_602217
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_602218 = formData.getOrDefault("RulePriorities")
  valid_602218 = validateParameter(valid_602218, JArray, required = true, default = nil)
  if valid_602218 != nil:
    section.add "RulePriorities", valid_602218
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602219: Call_PostSetRulePriorities_602206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_602219.validator(path, query, header, formData, body)
  let scheme = call_602219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602219.url(scheme.get, call_602219.host, call_602219.base,
                         call_602219.route, valid.getOrDefault("path"))
  result = hook(call_602219, url, valid)

proc call*(call_602220: Call_PostSetRulePriorities_602206;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602221 = newJObject()
  var formData_602222 = newJObject()
  if RulePriorities != nil:
    formData_602222.add "RulePriorities", RulePriorities
  add(query_602221, "Action", newJString(Action))
  add(query_602221, "Version", newJString(Version))
  result = call_602220.call(nil, query_602221, nil, formData_602222, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_602206(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_602207, base: "/",
    url: url_PostSetRulePriorities_602208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_602190 = ref object of OpenApiRestCall_600426
proc url_GetSetRulePriorities_602192(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetRulePriorities_602191(path: JsonNode; query: JsonNode;
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
  var valid_602193 = query.getOrDefault("RulePriorities")
  valid_602193 = validateParameter(valid_602193, JArray, required = true, default = nil)
  if valid_602193 != nil:
    section.add "RulePriorities", valid_602193
  var valid_602194 = query.getOrDefault("Action")
  valid_602194 = validateParameter(valid_602194, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_602194 != nil:
    section.add "Action", valid_602194
  var valid_602195 = query.getOrDefault("Version")
  valid_602195 = validateParameter(valid_602195, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602195 != nil:
    section.add "Version", valid_602195
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
  var valid_602196 = header.getOrDefault("X-Amz-Date")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Date", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Security-Token")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Security-Token", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Content-Sha256", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Algorithm")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Algorithm", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Signature")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Signature", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-SignedHeaders", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Credential")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Credential", valid_602202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_GetSetRulePriorities_602190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"))
  result = hook(call_602203, url, valid)

proc call*(call_602204: Call_GetSetRulePriorities_602190; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602205 = newJObject()
  if RulePriorities != nil:
    query_602205.add "RulePriorities", RulePriorities
  add(query_602205, "Action", newJString(Action))
  add(query_602205, "Version", newJString(Version))
  result = call_602204.call(nil, query_602205, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_602190(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_602191,
    base: "/", url: url_GetSetRulePriorities_602192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_602240 = ref object of OpenApiRestCall_600426
proc url_PostSetSecurityGroups_602242(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSecurityGroups_602241(path: JsonNode; query: JsonNode;
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
  var valid_602243 = query.getOrDefault("Action")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_602243 != nil:
    section.add "Action", valid_602243
  var valid_602244 = query.getOrDefault("Version")
  valid_602244 = validateParameter(valid_602244, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602244 != nil:
    section.add "Version", valid_602244
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
  var valid_602245 = header.getOrDefault("X-Amz-Date")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Date", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Security-Token")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Security-Token", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Content-Sha256", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Algorithm")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Algorithm", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Signature")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Signature", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-SignedHeaders", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Credential")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Credential", valid_602251
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_602252 = formData.getOrDefault("LoadBalancerArn")
  valid_602252 = validateParameter(valid_602252, JString, required = true,
                                 default = nil)
  if valid_602252 != nil:
    section.add "LoadBalancerArn", valid_602252
  var valid_602253 = formData.getOrDefault("SecurityGroups")
  valid_602253 = validateParameter(valid_602253, JArray, required = true, default = nil)
  if valid_602253 != nil:
    section.add "SecurityGroups", valid_602253
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602254: Call_PostSetSecurityGroups_602240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_602254.validator(path, query, header, formData, body)
  let scheme = call_602254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602254.url(scheme.get, call_602254.host, call_602254.base,
                         call_602254.route, valid.getOrDefault("path"))
  result = hook(call_602254, url, valid)

proc call*(call_602255: Call_PostSetSecurityGroups_602240; LoadBalancerArn: string;
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
  var query_602256 = newJObject()
  var formData_602257 = newJObject()
  add(formData_602257, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_602256, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_602257.add "SecurityGroups", SecurityGroups
  add(query_602256, "Version", newJString(Version))
  result = call_602255.call(nil, query_602256, nil, formData_602257, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_602240(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_602241, base: "/",
    url: url_PostSetSecurityGroups_602242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_602223 = ref object of OpenApiRestCall_600426
proc url_GetSetSecurityGroups_602225(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSecurityGroups_602224(path: JsonNode; query: JsonNode;
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
  var valid_602226 = query.getOrDefault("Action")
  valid_602226 = validateParameter(valid_602226, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_602226 != nil:
    section.add "Action", valid_602226
  var valid_602227 = query.getOrDefault("LoadBalancerArn")
  valid_602227 = validateParameter(valid_602227, JString, required = true,
                                 default = nil)
  if valid_602227 != nil:
    section.add "LoadBalancerArn", valid_602227
  var valid_602228 = query.getOrDefault("Version")
  valid_602228 = validateParameter(valid_602228, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602228 != nil:
    section.add "Version", valid_602228
  var valid_602229 = query.getOrDefault("SecurityGroups")
  valid_602229 = validateParameter(valid_602229, JArray, required = true, default = nil)
  if valid_602229 != nil:
    section.add "SecurityGroups", valid_602229
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
  var valid_602230 = header.getOrDefault("X-Amz-Date")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Date", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Security-Token")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Security-Token", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Content-Sha256", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Algorithm")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Algorithm", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Signature")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Signature", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-SignedHeaders", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Credential")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Credential", valid_602236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602237: Call_GetSetSecurityGroups_602223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_602237.validator(path, query, header, formData, body)
  let scheme = call_602237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602237.url(scheme.get, call_602237.host, call_602237.base,
                         call_602237.route, valid.getOrDefault("path"))
  result = hook(call_602237, url, valid)

proc call*(call_602238: Call_GetSetSecurityGroups_602223; LoadBalancerArn: string;
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
  var query_602239 = newJObject()
  add(query_602239, "Action", newJString(Action))
  add(query_602239, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_602239, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_602239.add "SecurityGroups", SecurityGroups
  result = call_602238.call(nil, query_602239, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_602223(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_602224,
    base: "/", url: url_GetSetSecurityGroups_602225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_602276 = ref object of OpenApiRestCall_600426
proc url_PostSetSubnets_602278(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSubnets_602277(path: JsonNode; query: JsonNode;
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
  var valid_602279 = query.getOrDefault("Action")
  valid_602279 = validateParameter(valid_602279, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_602279 != nil:
    section.add "Action", valid_602279
  var valid_602280 = query.getOrDefault("Version")
  valid_602280 = validateParameter(valid_602280, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602280 != nil:
    section.add "Version", valid_602280
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
  var valid_602281 = header.getOrDefault("X-Amz-Date")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Date", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Security-Token")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Security-Token", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Content-Sha256", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Algorithm")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Algorithm", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Signature")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Signature", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-SignedHeaders", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Credential")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Credential", valid_602287
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
  var valid_602288 = formData.getOrDefault("LoadBalancerArn")
  valid_602288 = validateParameter(valid_602288, JString, required = true,
                                 default = nil)
  if valid_602288 != nil:
    section.add "LoadBalancerArn", valid_602288
  var valid_602289 = formData.getOrDefault("Subnets")
  valid_602289 = validateParameter(valid_602289, JArray, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "Subnets", valid_602289
  var valid_602290 = formData.getOrDefault("SubnetMappings")
  valid_602290 = validateParameter(valid_602290, JArray, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "SubnetMappings", valid_602290
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602291: Call_PostSetSubnets_602276; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_602291.validator(path, query, header, formData, body)
  let scheme = call_602291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602291.url(scheme.get, call_602291.host, call_602291.base,
                         call_602291.route, valid.getOrDefault("path"))
  result = hook(call_602291, url, valid)

proc call*(call_602292: Call_PostSetSubnets_602276; LoadBalancerArn: string;
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
  var query_602293 = newJObject()
  var formData_602294 = newJObject()
  add(formData_602294, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_602293, "Action", newJString(Action))
  if Subnets != nil:
    formData_602294.add "Subnets", Subnets
  if SubnetMappings != nil:
    formData_602294.add "SubnetMappings", SubnetMappings
  add(query_602293, "Version", newJString(Version))
  result = call_602292.call(nil, query_602293, nil, formData_602294, nil)

var postSetSubnets* = Call_PostSetSubnets_602276(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_602277,
    base: "/", url: url_PostSetSubnets_602278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_602258 = ref object of OpenApiRestCall_600426
proc url_GetSetSubnets_602260(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSubnets_602259(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602261 = query.getOrDefault("SubnetMappings")
  valid_602261 = validateParameter(valid_602261, JArray, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "SubnetMappings", valid_602261
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602262 = query.getOrDefault("Action")
  valid_602262 = validateParameter(valid_602262, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_602262 != nil:
    section.add "Action", valid_602262
  var valid_602263 = query.getOrDefault("LoadBalancerArn")
  valid_602263 = validateParameter(valid_602263, JString, required = true,
                                 default = nil)
  if valid_602263 != nil:
    section.add "LoadBalancerArn", valid_602263
  var valid_602264 = query.getOrDefault("Subnets")
  valid_602264 = validateParameter(valid_602264, JArray, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "Subnets", valid_602264
  var valid_602265 = query.getOrDefault("Version")
  valid_602265 = validateParameter(valid_602265, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602265 != nil:
    section.add "Version", valid_602265
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
  var valid_602266 = header.getOrDefault("X-Amz-Date")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Date", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Security-Token")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Security-Token", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Content-Sha256", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Algorithm")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Algorithm", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Signature")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Signature", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-SignedHeaders", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Credential")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Credential", valid_602272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602273: Call_GetSetSubnets_602258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_602273.validator(path, query, header, formData, body)
  let scheme = call_602273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602273.url(scheme.get, call_602273.host, call_602273.base,
                         call_602273.route, valid.getOrDefault("path"))
  result = hook(call_602273, url, valid)

proc call*(call_602274: Call_GetSetSubnets_602258; LoadBalancerArn: string;
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
  var query_602275 = newJObject()
  if SubnetMappings != nil:
    query_602275.add "SubnetMappings", SubnetMappings
  add(query_602275, "Action", newJString(Action))
  add(query_602275, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Subnets != nil:
    query_602275.add "Subnets", Subnets
  add(query_602275, "Version", newJString(Version))
  result = call_602274.call(nil, query_602275, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_602258(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_602259,
    base: "/", url: url_GetSetSubnets_602260, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
