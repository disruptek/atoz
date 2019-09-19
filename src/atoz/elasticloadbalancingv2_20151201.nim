
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  Call_PostAddListenerCertificates_773205 = ref object of OpenApiRestCall_772597
proc url_PostAddListenerCertificates_773207(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddListenerCertificates_773206(path: JsonNode; query: JsonNode;
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
  var valid_773208 = query.getOrDefault("Action")
  valid_773208 = validateParameter(valid_773208, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_773208 != nil:
    section.add "Action", valid_773208
  var valid_773209 = query.getOrDefault("Version")
  valid_773209 = validateParameter(valid_773209, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773209 != nil:
    section.add "Version", valid_773209
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
  var valid_773210 = header.getOrDefault("X-Amz-Date")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Date", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Security-Token")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Security-Token", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Content-Sha256", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Algorithm")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Algorithm", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Signature")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Signature", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-SignedHeaders", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Credential")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Credential", valid_773216
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_773217 = formData.getOrDefault("Certificates")
  valid_773217 = validateParameter(valid_773217, JArray, required = true, default = nil)
  if valid_773217 != nil:
    section.add "Certificates", valid_773217
  var valid_773218 = formData.getOrDefault("ListenerArn")
  valid_773218 = validateParameter(valid_773218, JString, required = true,
                                 default = nil)
  if valid_773218 != nil:
    section.add "ListenerArn", valid_773218
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773219: Call_PostAddListenerCertificates_773205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773219.validator(path, query, header, formData, body)
  let scheme = call_773219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773219.url(scheme.get, call_773219.host, call_773219.base,
                         call_773219.route, valid.getOrDefault("path"))
  result = hook(call_773219, url, valid)

proc call*(call_773220: Call_PostAddListenerCertificates_773205;
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
  var query_773221 = newJObject()
  var formData_773222 = newJObject()
  if Certificates != nil:
    formData_773222.add "Certificates", Certificates
  add(formData_773222, "ListenerArn", newJString(ListenerArn))
  add(query_773221, "Action", newJString(Action))
  add(query_773221, "Version", newJString(Version))
  result = call_773220.call(nil, query_773221, nil, formData_773222, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_773205(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_773206, base: "/",
    url: url_PostAddListenerCertificates_773207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_772933 = ref object of OpenApiRestCall_772597
proc url_GetAddListenerCertificates_772935(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddListenerCertificates_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = query.getOrDefault("Certificates")
  valid_773047 = validateParameter(valid_773047, JArray, required = true, default = nil)
  if valid_773047 != nil:
    section.add "Certificates", valid_773047
  var valid_773061 = query.getOrDefault("Action")
  valid_773061 = validateParameter(valid_773061, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_773061 != nil:
    section.add "Action", valid_773061
  var valid_773062 = query.getOrDefault("ListenerArn")
  valid_773062 = validateParameter(valid_773062, JString, required = true,
                                 default = nil)
  if valid_773062 != nil:
    section.add "ListenerArn", valid_773062
  var valid_773063 = query.getOrDefault("Version")
  valid_773063 = validateParameter(valid_773063, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773063 != nil:
    section.add "Version", valid_773063
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
  var valid_773064 = header.getOrDefault("X-Amz-Date")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Date", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Security-Token")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Security-Token", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Content-Sha256", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Algorithm")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Algorithm", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-Signature")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-Signature", valid_773068
  var valid_773069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773069 = validateParameter(valid_773069, JString, required = false,
                                 default = nil)
  if valid_773069 != nil:
    section.add "X-Amz-SignedHeaders", valid_773069
  var valid_773070 = header.getOrDefault("X-Amz-Credential")
  valid_773070 = validateParameter(valid_773070, JString, required = false,
                                 default = nil)
  if valid_773070 != nil:
    section.add "X-Amz-Credential", valid_773070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773093: Call_GetAddListenerCertificates_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773093.validator(path, query, header, formData, body)
  let scheme = call_773093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773093.url(scheme.get, call_773093.host, call_773093.base,
                         call_773093.route, valid.getOrDefault("path"))
  result = hook(call_773093, url, valid)

proc call*(call_773164: Call_GetAddListenerCertificates_772933;
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
  var query_773165 = newJObject()
  if Certificates != nil:
    query_773165.add "Certificates", Certificates
  add(query_773165, "Action", newJString(Action))
  add(query_773165, "ListenerArn", newJString(ListenerArn))
  add(query_773165, "Version", newJString(Version))
  result = call_773164.call(nil, query_773165, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_772933(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_772934, base: "/",
    url: url_GetAddListenerCertificates_772935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_773240 = ref object of OpenApiRestCall_772597
proc url_PostAddTags_773242(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddTags_773241(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773243 = query.getOrDefault("Action")
  valid_773243 = validateParameter(valid_773243, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_773243 != nil:
    section.add "Action", valid_773243
  var valid_773244 = query.getOrDefault("Version")
  valid_773244 = validateParameter(valid_773244, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773244 != nil:
    section.add "Version", valid_773244
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
  var valid_773245 = header.getOrDefault("X-Amz-Date")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Date", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Security-Token")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Security-Token", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Content-Sha256", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Algorithm")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Algorithm", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Signature")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Signature", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-SignedHeaders", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Credential")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Credential", valid_773251
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_773252 = formData.getOrDefault("ResourceArns")
  valid_773252 = validateParameter(valid_773252, JArray, required = true, default = nil)
  if valid_773252 != nil:
    section.add "ResourceArns", valid_773252
  var valid_773253 = formData.getOrDefault("Tags")
  valid_773253 = validateParameter(valid_773253, JArray, required = true, default = nil)
  if valid_773253 != nil:
    section.add "Tags", valid_773253
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773254: Call_PostAddTags_773240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_773254.validator(path, query, header, formData, body)
  let scheme = call_773254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773254.url(scheme.get, call_773254.host, call_773254.base,
                         call_773254.route, valid.getOrDefault("path"))
  result = hook(call_773254, url, valid)

proc call*(call_773255: Call_PostAddTags_773240; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773256 = newJObject()
  var formData_773257 = newJObject()
  if ResourceArns != nil:
    formData_773257.add "ResourceArns", ResourceArns
  if Tags != nil:
    formData_773257.add "Tags", Tags
  add(query_773256, "Action", newJString(Action))
  add(query_773256, "Version", newJString(Version))
  result = call_773255.call(nil, query_773256, nil, formData_773257, nil)

var postAddTags* = Call_PostAddTags_773240(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_773241,
                                        base: "/", url: url_PostAddTags_773242,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_773223 = ref object of OpenApiRestCall_772597
proc url_GetAddTags_773225(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddTags_773224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773226 = query.getOrDefault("Tags")
  valid_773226 = validateParameter(valid_773226, JArray, required = true, default = nil)
  if valid_773226 != nil:
    section.add "Tags", valid_773226
  var valid_773227 = query.getOrDefault("Action")
  valid_773227 = validateParameter(valid_773227, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_773227 != nil:
    section.add "Action", valid_773227
  var valid_773228 = query.getOrDefault("ResourceArns")
  valid_773228 = validateParameter(valid_773228, JArray, required = true, default = nil)
  if valid_773228 != nil:
    section.add "ResourceArns", valid_773228
  var valid_773229 = query.getOrDefault("Version")
  valid_773229 = validateParameter(valid_773229, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773229 != nil:
    section.add "Version", valid_773229
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
  var valid_773230 = header.getOrDefault("X-Amz-Date")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Date", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Security-Token")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Security-Token", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Content-Sha256", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Algorithm")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Algorithm", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Signature")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Signature", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-SignedHeaders", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Credential")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Credential", valid_773236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773237: Call_GetAddTags_773223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_773237.validator(path, query, header, formData, body)
  let scheme = call_773237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773237.url(scheme.get, call_773237.host, call_773237.base,
                         call_773237.route, valid.getOrDefault("path"))
  result = hook(call_773237, url, valid)

proc call*(call_773238: Call_GetAddTags_773223; Tags: JsonNode;
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
  var query_773239 = newJObject()
  if Tags != nil:
    query_773239.add "Tags", Tags
  add(query_773239, "Action", newJString(Action))
  if ResourceArns != nil:
    query_773239.add "ResourceArns", ResourceArns
  add(query_773239, "Version", newJString(Version))
  result = call_773238.call(nil, query_773239, nil, nil, nil)

var getAddTags* = Call_GetAddTags_773223(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_773224,
                                      base: "/", url: url_GetAddTags_773225,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_773279 = ref object of OpenApiRestCall_772597
proc url_PostCreateListener_773281(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateListener_773280(path: JsonNode; query: JsonNode;
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
  var valid_773282 = query.getOrDefault("Action")
  valid_773282 = validateParameter(valid_773282, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_773282 != nil:
    section.add "Action", valid_773282
  var valid_773283 = query.getOrDefault("Version")
  valid_773283 = validateParameter(valid_773283, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773283 != nil:
    section.add "Version", valid_773283
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
  var valid_773284 = header.getOrDefault("X-Amz-Date")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Date", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Security-Token")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Security-Token", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Content-Sha256", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Algorithm")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Algorithm", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-Signature")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-Signature", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-SignedHeaders", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Credential")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Credential", valid_773290
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
  var valid_773291 = formData.getOrDefault("Certificates")
  valid_773291 = validateParameter(valid_773291, JArray, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "Certificates", valid_773291
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_773292 = formData.getOrDefault("LoadBalancerArn")
  valid_773292 = validateParameter(valid_773292, JString, required = true,
                                 default = nil)
  if valid_773292 != nil:
    section.add "LoadBalancerArn", valid_773292
  var valid_773293 = formData.getOrDefault("Port")
  valid_773293 = validateParameter(valid_773293, JInt, required = true, default = nil)
  if valid_773293 != nil:
    section.add "Port", valid_773293
  var valid_773294 = formData.getOrDefault("Protocol")
  valid_773294 = validateParameter(valid_773294, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_773294 != nil:
    section.add "Protocol", valid_773294
  var valid_773295 = formData.getOrDefault("SslPolicy")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "SslPolicy", valid_773295
  var valid_773296 = formData.getOrDefault("DefaultActions")
  valid_773296 = validateParameter(valid_773296, JArray, required = true, default = nil)
  if valid_773296 != nil:
    section.add "DefaultActions", valid_773296
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773297: Call_PostCreateListener_773279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773297.validator(path, query, header, formData, body)
  let scheme = call_773297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773297.url(scheme.get, call_773297.host, call_773297.base,
                         call_773297.route, valid.getOrDefault("path"))
  result = hook(call_773297, url, valid)

proc call*(call_773298: Call_PostCreateListener_773279; LoadBalancerArn: string;
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
  var query_773299 = newJObject()
  var formData_773300 = newJObject()
  if Certificates != nil:
    formData_773300.add "Certificates", Certificates
  add(formData_773300, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_773300, "Port", newJInt(Port))
  add(formData_773300, "Protocol", newJString(Protocol))
  add(query_773299, "Action", newJString(Action))
  add(formData_773300, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_773300.add "DefaultActions", DefaultActions
  add(query_773299, "Version", newJString(Version))
  result = call_773298.call(nil, query_773299, nil, formData_773300, nil)

var postCreateListener* = Call_PostCreateListener_773279(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_773280, base: "/",
    url: url_PostCreateListener_773281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_773258 = ref object of OpenApiRestCall_772597
proc url_GetCreateListener_773260(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateListener_773259(path: JsonNode; query: JsonNode;
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
  var valid_773261 = query.getOrDefault("DefaultActions")
  valid_773261 = validateParameter(valid_773261, JArray, required = true, default = nil)
  if valid_773261 != nil:
    section.add "DefaultActions", valid_773261
  var valid_773262 = query.getOrDefault("SslPolicy")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "SslPolicy", valid_773262
  var valid_773263 = query.getOrDefault("Protocol")
  valid_773263 = validateParameter(valid_773263, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_773263 != nil:
    section.add "Protocol", valid_773263
  var valid_773264 = query.getOrDefault("Certificates")
  valid_773264 = validateParameter(valid_773264, JArray, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "Certificates", valid_773264
  var valid_773265 = query.getOrDefault("Action")
  valid_773265 = validateParameter(valid_773265, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_773265 != nil:
    section.add "Action", valid_773265
  var valid_773266 = query.getOrDefault("LoadBalancerArn")
  valid_773266 = validateParameter(valid_773266, JString, required = true,
                                 default = nil)
  if valid_773266 != nil:
    section.add "LoadBalancerArn", valid_773266
  var valid_773267 = query.getOrDefault("Port")
  valid_773267 = validateParameter(valid_773267, JInt, required = true, default = nil)
  if valid_773267 != nil:
    section.add "Port", valid_773267
  var valid_773268 = query.getOrDefault("Version")
  valid_773268 = validateParameter(valid_773268, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773268 != nil:
    section.add "Version", valid_773268
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
  var valid_773269 = header.getOrDefault("X-Amz-Date")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Date", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Security-Token")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Security-Token", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Content-Sha256", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Algorithm")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Algorithm", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Signature")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Signature", valid_773273
  var valid_773274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-SignedHeaders", valid_773274
  var valid_773275 = header.getOrDefault("X-Amz-Credential")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-Credential", valid_773275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773276: Call_GetCreateListener_773258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773276.validator(path, query, header, formData, body)
  let scheme = call_773276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773276.url(scheme.get, call_773276.host, call_773276.base,
                         call_773276.route, valid.getOrDefault("path"))
  result = hook(call_773276, url, valid)

proc call*(call_773277: Call_GetCreateListener_773258; DefaultActions: JsonNode;
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
  var query_773278 = newJObject()
  if DefaultActions != nil:
    query_773278.add "DefaultActions", DefaultActions
  add(query_773278, "SslPolicy", newJString(SslPolicy))
  add(query_773278, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_773278.add "Certificates", Certificates
  add(query_773278, "Action", newJString(Action))
  add(query_773278, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_773278, "Port", newJInt(Port))
  add(query_773278, "Version", newJString(Version))
  result = call_773277.call(nil, query_773278, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_773258(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_773259,
    base: "/", url: url_GetCreateListener_773260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_773324 = ref object of OpenApiRestCall_772597
proc url_PostCreateLoadBalancer_773326(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateLoadBalancer_773325(path: JsonNode; query: JsonNode;
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
  var valid_773327 = query.getOrDefault("Action")
  valid_773327 = validateParameter(valid_773327, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_773327 != nil:
    section.add "Action", valid_773327
  var valid_773328 = query.getOrDefault("Version")
  valid_773328 = validateParameter(valid_773328, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773328 != nil:
    section.add "Version", valid_773328
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
  var valid_773329 = header.getOrDefault("X-Amz-Date")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Date", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Security-Token")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Security-Token", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Content-Sha256", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Algorithm")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Algorithm", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Signature")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Signature", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-SignedHeaders", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-Credential")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Credential", valid_773335
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
  var valid_773336 = formData.getOrDefault("Name")
  valid_773336 = validateParameter(valid_773336, JString, required = true,
                                 default = nil)
  if valid_773336 != nil:
    section.add "Name", valid_773336
  var valid_773337 = formData.getOrDefault("IpAddressType")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_773337 != nil:
    section.add "IpAddressType", valid_773337
  var valid_773338 = formData.getOrDefault("Tags")
  valid_773338 = validateParameter(valid_773338, JArray, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "Tags", valid_773338
  var valid_773339 = formData.getOrDefault("Type")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = newJString("application"))
  if valid_773339 != nil:
    section.add "Type", valid_773339
  var valid_773340 = formData.getOrDefault("Subnets")
  valid_773340 = validateParameter(valid_773340, JArray, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "Subnets", valid_773340
  var valid_773341 = formData.getOrDefault("SecurityGroups")
  valid_773341 = validateParameter(valid_773341, JArray, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "SecurityGroups", valid_773341
  var valid_773342 = formData.getOrDefault("SubnetMappings")
  valid_773342 = validateParameter(valid_773342, JArray, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "SubnetMappings", valid_773342
  var valid_773343 = formData.getOrDefault("Scheme")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_773343 != nil:
    section.add "Scheme", valid_773343
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773344: Call_PostCreateLoadBalancer_773324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773344.validator(path, query, header, formData, body)
  let scheme = call_773344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773344.url(scheme.get, call_773344.host, call_773344.base,
                         call_773344.route, valid.getOrDefault("path"))
  result = hook(call_773344, url, valid)

proc call*(call_773345: Call_PostCreateLoadBalancer_773324; Name: string;
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
  var query_773346 = newJObject()
  var formData_773347 = newJObject()
  add(formData_773347, "Name", newJString(Name))
  add(formData_773347, "IpAddressType", newJString(IpAddressType))
  if Tags != nil:
    formData_773347.add "Tags", Tags
  add(formData_773347, "Type", newJString(Type))
  add(query_773346, "Action", newJString(Action))
  if Subnets != nil:
    formData_773347.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_773347.add "SecurityGroups", SecurityGroups
  if SubnetMappings != nil:
    formData_773347.add "SubnetMappings", SubnetMappings
  add(formData_773347, "Scheme", newJString(Scheme))
  add(query_773346, "Version", newJString(Version))
  result = call_773345.call(nil, query_773346, nil, formData_773347, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_773324(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_773325, base: "/",
    url: url_PostCreateLoadBalancer_773326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_773301 = ref object of OpenApiRestCall_772597
proc url_GetCreateLoadBalancer_773303(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateLoadBalancer_773302(path: JsonNode; query: JsonNode;
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
  var valid_773304 = query.getOrDefault("Name")
  valid_773304 = validateParameter(valid_773304, JString, required = true,
                                 default = nil)
  if valid_773304 != nil:
    section.add "Name", valid_773304
  var valid_773305 = query.getOrDefault("SubnetMappings")
  valid_773305 = validateParameter(valid_773305, JArray, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "SubnetMappings", valid_773305
  var valid_773306 = query.getOrDefault("IpAddressType")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_773306 != nil:
    section.add "IpAddressType", valid_773306
  var valid_773307 = query.getOrDefault("Scheme")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_773307 != nil:
    section.add "Scheme", valid_773307
  var valid_773308 = query.getOrDefault("Tags")
  valid_773308 = validateParameter(valid_773308, JArray, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "Tags", valid_773308
  var valid_773309 = query.getOrDefault("Type")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = newJString("application"))
  if valid_773309 != nil:
    section.add "Type", valid_773309
  var valid_773310 = query.getOrDefault("Action")
  valid_773310 = validateParameter(valid_773310, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_773310 != nil:
    section.add "Action", valid_773310
  var valid_773311 = query.getOrDefault("Subnets")
  valid_773311 = validateParameter(valid_773311, JArray, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "Subnets", valid_773311
  var valid_773312 = query.getOrDefault("Version")
  valid_773312 = validateParameter(valid_773312, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773312 != nil:
    section.add "Version", valid_773312
  var valid_773313 = query.getOrDefault("SecurityGroups")
  valid_773313 = validateParameter(valid_773313, JArray, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "SecurityGroups", valid_773313
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
  var valid_773314 = header.getOrDefault("X-Amz-Date")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Date", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Security-Token")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Security-Token", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-Content-Sha256", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Algorithm")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Algorithm", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-Signature")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Signature", valid_773318
  var valid_773319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-SignedHeaders", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-Credential")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Credential", valid_773320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773321: Call_GetCreateLoadBalancer_773301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773321.validator(path, query, header, formData, body)
  let scheme = call_773321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773321.url(scheme.get, call_773321.host, call_773321.base,
                         call_773321.route, valid.getOrDefault("path"))
  result = hook(call_773321, url, valid)

proc call*(call_773322: Call_GetCreateLoadBalancer_773301; Name: string;
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
  var query_773323 = newJObject()
  add(query_773323, "Name", newJString(Name))
  if SubnetMappings != nil:
    query_773323.add "SubnetMappings", SubnetMappings
  add(query_773323, "IpAddressType", newJString(IpAddressType))
  add(query_773323, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_773323.add "Tags", Tags
  add(query_773323, "Type", newJString(Type))
  add(query_773323, "Action", newJString(Action))
  if Subnets != nil:
    query_773323.add "Subnets", Subnets
  add(query_773323, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_773323.add "SecurityGroups", SecurityGroups
  result = call_773322.call(nil, query_773323, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_773301(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_773302, base: "/",
    url: url_GetCreateLoadBalancer_773303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_773367 = ref object of OpenApiRestCall_772597
proc url_PostCreateRule_773369(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateRule_773368(path: JsonNode; query: JsonNode;
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
  var valid_773370 = query.getOrDefault("Action")
  valid_773370 = validateParameter(valid_773370, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_773370 != nil:
    section.add "Action", valid_773370
  var valid_773371 = query.getOrDefault("Version")
  valid_773371 = validateParameter(valid_773371, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773371 != nil:
    section.add "Version", valid_773371
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
  var valid_773372 = header.getOrDefault("X-Amz-Date")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Date", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Security-Token")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Security-Token", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Content-Sha256", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Algorithm")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Algorithm", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-Signature")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Signature", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-SignedHeaders", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-Credential")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-Credential", valid_773378
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
  var valid_773379 = formData.getOrDefault("ListenerArn")
  valid_773379 = validateParameter(valid_773379, JString, required = true,
                                 default = nil)
  if valid_773379 != nil:
    section.add "ListenerArn", valid_773379
  var valid_773380 = formData.getOrDefault("Actions")
  valid_773380 = validateParameter(valid_773380, JArray, required = true, default = nil)
  if valid_773380 != nil:
    section.add "Actions", valid_773380
  var valid_773381 = formData.getOrDefault("Conditions")
  valid_773381 = validateParameter(valid_773381, JArray, required = true, default = nil)
  if valid_773381 != nil:
    section.add "Conditions", valid_773381
  var valid_773382 = formData.getOrDefault("Priority")
  valid_773382 = validateParameter(valid_773382, JInt, required = true, default = nil)
  if valid_773382 != nil:
    section.add "Priority", valid_773382
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773383: Call_PostCreateRule_773367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_773383.validator(path, query, header, formData, body)
  let scheme = call_773383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773383.url(scheme.get, call_773383.host, call_773383.base,
                         call_773383.route, valid.getOrDefault("path"))
  result = hook(call_773383, url, valid)

proc call*(call_773384: Call_PostCreateRule_773367; ListenerArn: string;
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
  var query_773385 = newJObject()
  var formData_773386 = newJObject()
  add(formData_773386, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    formData_773386.add "Actions", Actions
  if Conditions != nil:
    formData_773386.add "Conditions", Conditions
  add(query_773385, "Action", newJString(Action))
  add(formData_773386, "Priority", newJInt(Priority))
  add(query_773385, "Version", newJString(Version))
  result = call_773384.call(nil, query_773385, nil, formData_773386, nil)

var postCreateRule* = Call_PostCreateRule_773367(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_773368,
    base: "/", url: url_PostCreateRule_773369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_773348 = ref object of OpenApiRestCall_772597
proc url_GetCreateRule_773350(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateRule_773349(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773351 = query.getOrDefault("Conditions")
  valid_773351 = validateParameter(valid_773351, JArray, required = true, default = nil)
  if valid_773351 != nil:
    section.add "Conditions", valid_773351
  var valid_773352 = query.getOrDefault("Action")
  valid_773352 = validateParameter(valid_773352, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_773352 != nil:
    section.add "Action", valid_773352
  var valid_773353 = query.getOrDefault("ListenerArn")
  valid_773353 = validateParameter(valid_773353, JString, required = true,
                                 default = nil)
  if valid_773353 != nil:
    section.add "ListenerArn", valid_773353
  var valid_773354 = query.getOrDefault("Actions")
  valid_773354 = validateParameter(valid_773354, JArray, required = true, default = nil)
  if valid_773354 != nil:
    section.add "Actions", valid_773354
  var valid_773355 = query.getOrDefault("Priority")
  valid_773355 = validateParameter(valid_773355, JInt, required = true, default = nil)
  if valid_773355 != nil:
    section.add "Priority", valid_773355
  var valid_773356 = query.getOrDefault("Version")
  valid_773356 = validateParameter(valid_773356, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773356 != nil:
    section.add "Version", valid_773356
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
  var valid_773357 = header.getOrDefault("X-Amz-Date")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Date", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Security-Token")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Security-Token", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Content-Sha256", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Algorithm")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Algorithm", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Signature")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Signature", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-SignedHeaders", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-Credential")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Credential", valid_773363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773364: Call_GetCreateRule_773348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_773364.validator(path, query, header, formData, body)
  let scheme = call_773364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773364.url(scheme.get, call_773364.host, call_773364.base,
                         call_773364.route, valid.getOrDefault("path"))
  result = hook(call_773364, url, valid)

proc call*(call_773365: Call_GetCreateRule_773348; Conditions: JsonNode;
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
  var query_773366 = newJObject()
  if Conditions != nil:
    query_773366.add "Conditions", Conditions
  add(query_773366, "Action", newJString(Action))
  add(query_773366, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    query_773366.add "Actions", Actions
  add(query_773366, "Priority", newJInt(Priority))
  add(query_773366, "Version", newJString(Version))
  result = call_773365.call(nil, query_773366, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_773348(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_773349,
    base: "/", url: url_GetCreateRule_773350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_773416 = ref object of OpenApiRestCall_772597
proc url_PostCreateTargetGroup_773418(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateTargetGroup_773417(path: JsonNode; query: JsonNode;
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
  var valid_773419 = query.getOrDefault("Action")
  valid_773419 = validateParameter(valid_773419, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_773419 != nil:
    section.add "Action", valid_773419
  var valid_773420 = query.getOrDefault("Version")
  valid_773420 = validateParameter(valid_773420, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773420 != nil:
    section.add "Version", valid_773420
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
  var valid_773421 = header.getOrDefault("X-Amz-Date")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Date", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Security-Token")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Security-Token", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Content-Sha256", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Algorithm")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Algorithm", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Signature")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Signature", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-SignedHeaders", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-Credential")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Credential", valid_773427
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
  var valid_773428 = formData.getOrDefault("Name")
  valid_773428 = validateParameter(valid_773428, JString, required = true,
                                 default = nil)
  if valid_773428 != nil:
    section.add "Name", valid_773428
  var valid_773429 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_773429 = validateParameter(valid_773429, JInt, required = false, default = nil)
  if valid_773429 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_773429
  var valid_773430 = formData.getOrDefault("Port")
  valid_773430 = validateParameter(valid_773430, JInt, required = false, default = nil)
  if valid_773430 != nil:
    section.add "Port", valid_773430
  var valid_773431 = formData.getOrDefault("Protocol")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_773431 != nil:
    section.add "Protocol", valid_773431
  var valid_773432 = formData.getOrDefault("HealthCheckPort")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "HealthCheckPort", valid_773432
  var valid_773433 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_773433 = validateParameter(valid_773433, JInt, required = false, default = nil)
  if valid_773433 != nil:
    section.add "UnhealthyThresholdCount", valid_773433
  var valid_773434 = formData.getOrDefault("HealthCheckEnabled")
  valid_773434 = validateParameter(valid_773434, JBool, required = false, default = nil)
  if valid_773434 != nil:
    section.add "HealthCheckEnabled", valid_773434
  var valid_773435 = formData.getOrDefault("HealthCheckPath")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "HealthCheckPath", valid_773435
  var valid_773436 = formData.getOrDefault("TargetType")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = newJString("instance"))
  if valid_773436 != nil:
    section.add "TargetType", valid_773436
  var valid_773437 = formData.getOrDefault("VpcId")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "VpcId", valid_773437
  var valid_773438 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_773438 = validateParameter(valid_773438, JInt, required = false, default = nil)
  if valid_773438 != nil:
    section.add "HealthCheckIntervalSeconds", valid_773438
  var valid_773439 = formData.getOrDefault("HealthyThresholdCount")
  valid_773439 = validateParameter(valid_773439, JInt, required = false, default = nil)
  if valid_773439 != nil:
    section.add "HealthyThresholdCount", valid_773439
  var valid_773440 = formData.getOrDefault("HealthCheckProtocol")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_773440 != nil:
    section.add "HealthCheckProtocol", valid_773440
  var valid_773441 = formData.getOrDefault("Matcher.HttpCode")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "Matcher.HttpCode", valid_773441
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773442: Call_PostCreateTargetGroup_773416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773442.validator(path, query, header, formData, body)
  let scheme = call_773442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773442.url(scheme.get, call_773442.host, call_773442.base,
                         call_773442.route, valid.getOrDefault("path"))
  result = hook(call_773442, url, valid)

proc call*(call_773443: Call_PostCreateTargetGroup_773416; Name: string;
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
  var query_773444 = newJObject()
  var formData_773445 = newJObject()
  add(formData_773445, "Name", newJString(Name))
  add(formData_773445, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_773445, "Port", newJInt(Port))
  add(formData_773445, "Protocol", newJString(Protocol))
  add(formData_773445, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_773445, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_773445, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_773445, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_773445, "TargetType", newJString(TargetType))
  add(query_773444, "Action", newJString(Action))
  add(formData_773445, "VpcId", newJString(VpcId))
  add(formData_773445, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_773445, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_773445, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_773445, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_773444, "Version", newJString(Version))
  result = call_773443.call(nil, query_773444, nil, formData_773445, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_773416(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_773417, base: "/",
    url: url_PostCreateTargetGroup_773418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_773387 = ref object of OpenApiRestCall_772597
proc url_GetCreateTargetGroup_773389(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateTargetGroup_773388(path: JsonNode; query: JsonNode;
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
  var valid_773390 = query.getOrDefault("HealthCheckEnabled")
  valid_773390 = validateParameter(valid_773390, JBool, required = false, default = nil)
  if valid_773390 != nil:
    section.add "HealthCheckEnabled", valid_773390
  var valid_773391 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_773391 = validateParameter(valid_773391, JInt, required = false, default = nil)
  if valid_773391 != nil:
    section.add "HealthCheckIntervalSeconds", valid_773391
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_773392 = query.getOrDefault("Name")
  valid_773392 = validateParameter(valid_773392, JString, required = true,
                                 default = nil)
  if valid_773392 != nil:
    section.add "Name", valid_773392
  var valid_773393 = query.getOrDefault("HealthCheckPort")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "HealthCheckPort", valid_773393
  var valid_773394 = query.getOrDefault("Protocol")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_773394 != nil:
    section.add "Protocol", valid_773394
  var valid_773395 = query.getOrDefault("VpcId")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "VpcId", valid_773395
  var valid_773396 = query.getOrDefault("Action")
  valid_773396 = validateParameter(valid_773396, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_773396 != nil:
    section.add "Action", valid_773396
  var valid_773397 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_773397 = validateParameter(valid_773397, JInt, required = false, default = nil)
  if valid_773397 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_773397
  var valid_773398 = query.getOrDefault("Matcher.HttpCode")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "Matcher.HttpCode", valid_773398
  var valid_773399 = query.getOrDefault("UnhealthyThresholdCount")
  valid_773399 = validateParameter(valid_773399, JInt, required = false, default = nil)
  if valid_773399 != nil:
    section.add "UnhealthyThresholdCount", valid_773399
  var valid_773400 = query.getOrDefault("TargetType")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = newJString("instance"))
  if valid_773400 != nil:
    section.add "TargetType", valid_773400
  var valid_773401 = query.getOrDefault("Port")
  valid_773401 = validateParameter(valid_773401, JInt, required = false, default = nil)
  if valid_773401 != nil:
    section.add "Port", valid_773401
  var valid_773402 = query.getOrDefault("HealthCheckProtocol")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_773402 != nil:
    section.add "HealthCheckProtocol", valid_773402
  var valid_773403 = query.getOrDefault("HealthyThresholdCount")
  valid_773403 = validateParameter(valid_773403, JInt, required = false, default = nil)
  if valid_773403 != nil:
    section.add "HealthyThresholdCount", valid_773403
  var valid_773404 = query.getOrDefault("Version")
  valid_773404 = validateParameter(valid_773404, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773404 != nil:
    section.add "Version", valid_773404
  var valid_773405 = query.getOrDefault("HealthCheckPath")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "HealthCheckPath", valid_773405
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
  var valid_773406 = header.getOrDefault("X-Amz-Date")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Date", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Security-Token")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Security-Token", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Content-Sha256", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-Algorithm")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Algorithm", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-Signature")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-Signature", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-SignedHeaders", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Credential")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Credential", valid_773412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773413: Call_GetCreateTargetGroup_773387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773413.validator(path, query, header, formData, body)
  let scheme = call_773413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773413.url(scheme.get, call_773413.host, call_773413.base,
                         call_773413.route, valid.getOrDefault("path"))
  result = hook(call_773413, url, valid)

proc call*(call_773414: Call_GetCreateTargetGroup_773387; Name: string;
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
  var query_773415 = newJObject()
  add(query_773415, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_773415, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_773415, "Name", newJString(Name))
  add(query_773415, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_773415, "Protocol", newJString(Protocol))
  add(query_773415, "VpcId", newJString(VpcId))
  add(query_773415, "Action", newJString(Action))
  add(query_773415, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_773415, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_773415, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_773415, "TargetType", newJString(TargetType))
  add(query_773415, "Port", newJInt(Port))
  add(query_773415, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_773415, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_773415, "Version", newJString(Version))
  add(query_773415, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_773414.call(nil, query_773415, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_773387(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_773388,
    base: "/", url: url_GetCreateTargetGroup_773389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_773462 = ref object of OpenApiRestCall_772597
proc url_PostDeleteListener_773464(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteListener_773463(path: JsonNode; query: JsonNode;
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
  var valid_773465 = query.getOrDefault("Action")
  valid_773465 = validateParameter(valid_773465, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_773465 != nil:
    section.add "Action", valid_773465
  var valid_773466 = query.getOrDefault("Version")
  valid_773466 = validateParameter(valid_773466, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773466 != nil:
    section.add "Version", valid_773466
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
  var valid_773467 = header.getOrDefault("X-Amz-Date")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Date", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Security-Token")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Security-Token", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Content-Sha256", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Algorithm")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Algorithm", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Signature")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Signature", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-SignedHeaders", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Credential")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Credential", valid_773473
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_773474 = formData.getOrDefault("ListenerArn")
  valid_773474 = validateParameter(valid_773474, JString, required = true,
                                 default = nil)
  if valid_773474 != nil:
    section.add "ListenerArn", valid_773474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773475: Call_PostDeleteListener_773462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_773475.validator(path, query, header, formData, body)
  let scheme = call_773475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773475.url(scheme.get, call_773475.host, call_773475.base,
                         call_773475.route, valid.getOrDefault("path"))
  result = hook(call_773475, url, valid)

proc call*(call_773476: Call_PostDeleteListener_773462; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773477 = newJObject()
  var formData_773478 = newJObject()
  add(formData_773478, "ListenerArn", newJString(ListenerArn))
  add(query_773477, "Action", newJString(Action))
  add(query_773477, "Version", newJString(Version))
  result = call_773476.call(nil, query_773477, nil, formData_773478, nil)

var postDeleteListener* = Call_PostDeleteListener_773462(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_773463, base: "/",
    url: url_PostDeleteListener_773464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_773446 = ref object of OpenApiRestCall_772597
proc url_GetDeleteListener_773448(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteListener_773447(path: JsonNode; query: JsonNode;
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
  var valid_773449 = query.getOrDefault("Action")
  valid_773449 = validateParameter(valid_773449, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_773449 != nil:
    section.add "Action", valid_773449
  var valid_773450 = query.getOrDefault("ListenerArn")
  valid_773450 = validateParameter(valid_773450, JString, required = true,
                                 default = nil)
  if valid_773450 != nil:
    section.add "ListenerArn", valid_773450
  var valid_773451 = query.getOrDefault("Version")
  valid_773451 = validateParameter(valid_773451, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773451 != nil:
    section.add "Version", valid_773451
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
  var valid_773452 = header.getOrDefault("X-Amz-Date")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Date", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Security-Token")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Security-Token", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Content-Sha256", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Algorithm")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Algorithm", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Signature")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Signature", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-SignedHeaders", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Credential")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Credential", valid_773458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773459: Call_GetDeleteListener_773446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_773459.validator(path, query, header, formData, body)
  let scheme = call_773459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773459.url(scheme.get, call_773459.host, call_773459.base,
                         call_773459.route, valid.getOrDefault("path"))
  result = hook(call_773459, url, valid)

proc call*(call_773460: Call_GetDeleteListener_773446; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  var query_773461 = newJObject()
  add(query_773461, "Action", newJString(Action))
  add(query_773461, "ListenerArn", newJString(ListenerArn))
  add(query_773461, "Version", newJString(Version))
  result = call_773460.call(nil, query_773461, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_773446(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_773447,
    base: "/", url: url_GetDeleteListener_773448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_773495 = ref object of OpenApiRestCall_772597
proc url_PostDeleteLoadBalancer_773497(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteLoadBalancer_773496(path: JsonNode; query: JsonNode;
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
  var valid_773498 = query.getOrDefault("Action")
  valid_773498 = validateParameter(valid_773498, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_773498 != nil:
    section.add "Action", valid_773498
  var valid_773499 = query.getOrDefault("Version")
  valid_773499 = validateParameter(valid_773499, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773499 != nil:
    section.add "Version", valid_773499
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
  var valid_773500 = header.getOrDefault("X-Amz-Date")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Date", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Security-Token")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Security-Token", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Content-Sha256", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Algorithm")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Algorithm", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Signature")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Signature", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-SignedHeaders", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-Credential")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Credential", valid_773506
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_773507 = formData.getOrDefault("LoadBalancerArn")
  valid_773507 = validateParameter(valid_773507, JString, required = true,
                                 default = nil)
  if valid_773507 != nil:
    section.add "LoadBalancerArn", valid_773507
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773508: Call_PostDeleteLoadBalancer_773495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_773508.validator(path, query, header, formData, body)
  let scheme = call_773508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773508.url(scheme.get, call_773508.host, call_773508.base,
                         call_773508.route, valid.getOrDefault("path"))
  result = hook(call_773508, url, valid)

proc call*(call_773509: Call_PostDeleteLoadBalancer_773495;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773510 = newJObject()
  var formData_773511 = newJObject()
  add(formData_773511, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_773510, "Action", newJString(Action))
  add(query_773510, "Version", newJString(Version))
  result = call_773509.call(nil, query_773510, nil, formData_773511, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_773495(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_773496, base: "/",
    url: url_PostDeleteLoadBalancer_773497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_773479 = ref object of OpenApiRestCall_772597
proc url_GetDeleteLoadBalancer_773481(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteLoadBalancer_773480(path: JsonNode; query: JsonNode;
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
  var valid_773482 = query.getOrDefault("Action")
  valid_773482 = validateParameter(valid_773482, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_773482 != nil:
    section.add "Action", valid_773482
  var valid_773483 = query.getOrDefault("LoadBalancerArn")
  valid_773483 = validateParameter(valid_773483, JString, required = true,
                                 default = nil)
  if valid_773483 != nil:
    section.add "LoadBalancerArn", valid_773483
  var valid_773484 = query.getOrDefault("Version")
  valid_773484 = validateParameter(valid_773484, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773484 != nil:
    section.add "Version", valid_773484
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
  var valid_773485 = header.getOrDefault("X-Amz-Date")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Date", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Security-Token")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Security-Token", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Content-Sha256", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-Algorithm")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-Algorithm", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-Signature")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Signature", valid_773489
  var valid_773490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-SignedHeaders", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Credential")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Credential", valid_773491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773492: Call_GetDeleteLoadBalancer_773479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_773492.validator(path, query, header, formData, body)
  let scheme = call_773492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773492.url(scheme.get, call_773492.host, call_773492.base,
                         call_773492.route, valid.getOrDefault("path"))
  result = hook(call_773492, url, valid)

proc call*(call_773493: Call_GetDeleteLoadBalancer_773479; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_773494 = newJObject()
  add(query_773494, "Action", newJString(Action))
  add(query_773494, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_773494, "Version", newJString(Version))
  result = call_773493.call(nil, query_773494, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_773479(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_773480, base: "/",
    url: url_GetDeleteLoadBalancer_773481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_773528 = ref object of OpenApiRestCall_772597
proc url_PostDeleteRule_773530(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteRule_773529(path: JsonNode; query: JsonNode;
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
  var valid_773531 = query.getOrDefault("Action")
  valid_773531 = validateParameter(valid_773531, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_773531 != nil:
    section.add "Action", valid_773531
  var valid_773532 = query.getOrDefault("Version")
  valid_773532 = validateParameter(valid_773532, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773532 != nil:
    section.add "Version", valid_773532
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
  var valid_773533 = header.getOrDefault("X-Amz-Date")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Date", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-Security-Token")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Security-Token", valid_773534
  var valid_773535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Content-Sha256", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Algorithm")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Algorithm", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Signature")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Signature", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-SignedHeaders", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Credential")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Credential", valid_773539
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_773540 = formData.getOrDefault("RuleArn")
  valid_773540 = validateParameter(valid_773540, JString, required = true,
                                 default = nil)
  if valid_773540 != nil:
    section.add "RuleArn", valid_773540
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773541: Call_PostDeleteRule_773528; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_773541.validator(path, query, header, formData, body)
  let scheme = call_773541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773541.url(scheme.get, call_773541.host, call_773541.base,
                         call_773541.route, valid.getOrDefault("path"))
  result = hook(call_773541, url, valid)

proc call*(call_773542: Call_PostDeleteRule_773528; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773543 = newJObject()
  var formData_773544 = newJObject()
  add(formData_773544, "RuleArn", newJString(RuleArn))
  add(query_773543, "Action", newJString(Action))
  add(query_773543, "Version", newJString(Version))
  result = call_773542.call(nil, query_773543, nil, formData_773544, nil)

var postDeleteRule* = Call_PostDeleteRule_773528(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_773529,
    base: "/", url: url_PostDeleteRule_773530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_773512 = ref object of OpenApiRestCall_772597
proc url_GetDeleteRule_773514(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteRule_773513(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773515 = query.getOrDefault("Action")
  valid_773515 = validateParameter(valid_773515, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_773515 != nil:
    section.add "Action", valid_773515
  var valid_773516 = query.getOrDefault("RuleArn")
  valid_773516 = validateParameter(valid_773516, JString, required = true,
                                 default = nil)
  if valid_773516 != nil:
    section.add "RuleArn", valid_773516
  var valid_773517 = query.getOrDefault("Version")
  valid_773517 = validateParameter(valid_773517, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773517 != nil:
    section.add "Version", valid_773517
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
  var valid_773518 = header.getOrDefault("X-Amz-Date")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Date", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Security-Token")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Security-Token", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Content-Sha256", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Algorithm")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Algorithm", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Signature")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Signature", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-SignedHeaders", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Credential")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Credential", valid_773524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773525: Call_GetDeleteRule_773512; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_773525.validator(path, query, header, formData, body)
  let scheme = call_773525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773525.url(scheme.get, call_773525.host, call_773525.base,
                         call_773525.route, valid.getOrDefault("path"))
  result = hook(call_773525, url, valid)

proc call*(call_773526: Call_GetDeleteRule_773512; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   Action: string (required)
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Version: string (required)
  var query_773527 = newJObject()
  add(query_773527, "Action", newJString(Action))
  add(query_773527, "RuleArn", newJString(RuleArn))
  add(query_773527, "Version", newJString(Version))
  result = call_773526.call(nil, query_773527, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_773512(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_773513,
    base: "/", url: url_GetDeleteRule_773514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_773561 = ref object of OpenApiRestCall_772597
proc url_PostDeleteTargetGroup_773563(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteTargetGroup_773562(path: JsonNode; query: JsonNode;
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
  var valid_773564 = query.getOrDefault("Action")
  valid_773564 = validateParameter(valid_773564, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_773564 != nil:
    section.add "Action", valid_773564
  var valid_773565 = query.getOrDefault("Version")
  valid_773565 = validateParameter(valid_773565, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773565 != nil:
    section.add "Version", valid_773565
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
  var valid_773566 = header.getOrDefault("X-Amz-Date")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Date", valid_773566
  var valid_773567 = header.getOrDefault("X-Amz-Security-Token")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-Security-Token", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-Content-Sha256", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-Algorithm")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Algorithm", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Signature")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Signature", valid_773570
  var valid_773571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-SignedHeaders", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Credential")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Credential", valid_773572
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_773573 = formData.getOrDefault("TargetGroupArn")
  valid_773573 = validateParameter(valid_773573, JString, required = true,
                                 default = nil)
  if valid_773573 != nil:
    section.add "TargetGroupArn", valid_773573
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773574: Call_PostDeleteTargetGroup_773561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_773574.validator(path, query, header, formData, body)
  let scheme = call_773574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773574.url(scheme.get, call_773574.host, call_773574.base,
                         call_773574.route, valid.getOrDefault("path"))
  result = hook(call_773574, url, valid)

proc call*(call_773575: Call_PostDeleteTargetGroup_773561; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_773576 = newJObject()
  var formData_773577 = newJObject()
  add(query_773576, "Action", newJString(Action))
  add(formData_773577, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_773576, "Version", newJString(Version))
  result = call_773575.call(nil, query_773576, nil, formData_773577, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_773561(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_773562, base: "/",
    url: url_PostDeleteTargetGroup_773563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_773545 = ref object of OpenApiRestCall_772597
proc url_GetDeleteTargetGroup_773547(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteTargetGroup_773546(path: JsonNode; query: JsonNode;
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
  var valid_773548 = query.getOrDefault("TargetGroupArn")
  valid_773548 = validateParameter(valid_773548, JString, required = true,
                                 default = nil)
  if valid_773548 != nil:
    section.add "TargetGroupArn", valid_773548
  var valid_773549 = query.getOrDefault("Action")
  valid_773549 = validateParameter(valid_773549, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_773549 != nil:
    section.add "Action", valid_773549
  var valid_773550 = query.getOrDefault("Version")
  valid_773550 = validateParameter(valid_773550, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773550 != nil:
    section.add "Version", valid_773550
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
  var valid_773551 = header.getOrDefault("X-Amz-Date")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Date", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-Security-Token")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Security-Token", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Content-Sha256", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Algorithm")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Algorithm", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Signature")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Signature", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-SignedHeaders", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-Credential")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Credential", valid_773557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773558: Call_GetDeleteTargetGroup_773545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_773558.validator(path, query, header, formData, body)
  let scheme = call_773558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773558.url(scheme.get, call_773558.host, call_773558.base,
                         call_773558.route, valid.getOrDefault("path"))
  result = hook(call_773558, url, valid)

proc call*(call_773559: Call_GetDeleteTargetGroup_773545; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773560 = newJObject()
  add(query_773560, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_773560, "Action", newJString(Action))
  add(query_773560, "Version", newJString(Version))
  result = call_773559.call(nil, query_773560, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_773545(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_773546,
    base: "/", url: url_GetDeleteTargetGroup_773547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_773595 = ref object of OpenApiRestCall_772597
proc url_PostDeregisterTargets_773597(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeregisterTargets_773596(path: JsonNode; query: JsonNode;
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
  var valid_773598 = query.getOrDefault("Action")
  valid_773598 = validateParameter(valid_773598, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_773598 != nil:
    section.add "Action", valid_773598
  var valid_773599 = query.getOrDefault("Version")
  valid_773599 = validateParameter(valid_773599, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773599 != nil:
    section.add "Version", valid_773599
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
  var valid_773600 = header.getOrDefault("X-Amz-Date")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Date", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-Security-Token")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-Security-Token", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Content-Sha256", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Algorithm")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Algorithm", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-Signature")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-Signature", valid_773604
  var valid_773605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-SignedHeaders", valid_773605
  var valid_773606 = header.getOrDefault("X-Amz-Credential")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-Credential", valid_773606
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_773607 = formData.getOrDefault("Targets")
  valid_773607 = validateParameter(valid_773607, JArray, required = true, default = nil)
  if valid_773607 != nil:
    section.add "Targets", valid_773607
  var valid_773608 = formData.getOrDefault("TargetGroupArn")
  valid_773608 = validateParameter(valid_773608, JString, required = true,
                                 default = nil)
  if valid_773608 != nil:
    section.add "TargetGroupArn", valid_773608
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773609: Call_PostDeregisterTargets_773595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_773609.validator(path, query, header, formData, body)
  let scheme = call_773609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773609.url(scheme.get, call_773609.host, call_773609.base,
                         call_773609.route, valid.getOrDefault("path"))
  result = hook(call_773609, url, valid)

proc call*(call_773610: Call_PostDeregisterTargets_773595; Targets: JsonNode;
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
  var query_773611 = newJObject()
  var formData_773612 = newJObject()
  if Targets != nil:
    formData_773612.add "Targets", Targets
  add(query_773611, "Action", newJString(Action))
  add(formData_773612, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_773611, "Version", newJString(Version))
  result = call_773610.call(nil, query_773611, nil, formData_773612, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_773595(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_773596, base: "/",
    url: url_PostDeregisterTargets_773597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_773578 = ref object of OpenApiRestCall_772597
proc url_GetDeregisterTargets_773580(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeregisterTargets_773579(path: JsonNode; query: JsonNode;
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
  var valid_773581 = query.getOrDefault("Targets")
  valid_773581 = validateParameter(valid_773581, JArray, required = true, default = nil)
  if valid_773581 != nil:
    section.add "Targets", valid_773581
  var valid_773582 = query.getOrDefault("TargetGroupArn")
  valid_773582 = validateParameter(valid_773582, JString, required = true,
                                 default = nil)
  if valid_773582 != nil:
    section.add "TargetGroupArn", valid_773582
  var valid_773583 = query.getOrDefault("Action")
  valid_773583 = validateParameter(valid_773583, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_773583 != nil:
    section.add "Action", valid_773583
  var valid_773584 = query.getOrDefault("Version")
  valid_773584 = validateParameter(valid_773584, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773584 != nil:
    section.add "Version", valid_773584
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
  var valid_773585 = header.getOrDefault("X-Amz-Date")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Date", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-Security-Token")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Security-Token", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Content-Sha256", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Algorithm")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Algorithm", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-Signature")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-Signature", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-SignedHeaders", valid_773590
  var valid_773591 = header.getOrDefault("X-Amz-Credential")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-Credential", valid_773591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773592: Call_GetDeregisterTargets_773578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_773592.validator(path, query, header, formData, body)
  let scheme = call_773592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773592.url(scheme.get, call_773592.host, call_773592.base,
                         call_773592.route, valid.getOrDefault("path"))
  result = hook(call_773592, url, valid)

proc call*(call_773593: Call_GetDeregisterTargets_773578; Targets: JsonNode;
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
  var query_773594 = newJObject()
  if Targets != nil:
    query_773594.add "Targets", Targets
  add(query_773594, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_773594, "Action", newJString(Action))
  add(query_773594, "Version", newJString(Version))
  result = call_773593.call(nil, query_773594, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_773578(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_773579,
    base: "/", url: url_GetDeregisterTargets_773580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_773630 = ref object of OpenApiRestCall_772597
proc url_PostDescribeAccountLimits_773632(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAccountLimits_773631(path: JsonNode; query: JsonNode;
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
  var valid_773633 = query.getOrDefault("Action")
  valid_773633 = validateParameter(valid_773633, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_773633 != nil:
    section.add "Action", valid_773633
  var valid_773634 = query.getOrDefault("Version")
  valid_773634 = validateParameter(valid_773634, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773634 != nil:
    section.add "Version", valid_773634
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
  var valid_773635 = header.getOrDefault("X-Amz-Date")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = nil)
  if valid_773635 != nil:
    section.add "X-Amz-Date", valid_773635
  var valid_773636 = header.getOrDefault("X-Amz-Security-Token")
  valid_773636 = validateParameter(valid_773636, JString, required = false,
                                 default = nil)
  if valid_773636 != nil:
    section.add "X-Amz-Security-Token", valid_773636
  var valid_773637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773637 = validateParameter(valid_773637, JString, required = false,
                                 default = nil)
  if valid_773637 != nil:
    section.add "X-Amz-Content-Sha256", valid_773637
  var valid_773638 = header.getOrDefault("X-Amz-Algorithm")
  valid_773638 = validateParameter(valid_773638, JString, required = false,
                                 default = nil)
  if valid_773638 != nil:
    section.add "X-Amz-Algorithm", valid_773638
  var valid_773639 = header.getOrDefault("X-Amz-Signature")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "X-Amz-Signature", valid_773639
  var valid_773640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-SignedHeaders", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Credential")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Credential", valid_773641
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_773642 = formData.getOrDefault("Marker")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "Marker", valid_773642
  var valid_773643 = formData.getOrDefault("PageSize")
  valid_773643 = validateParameter(valid_773643, JInt, required = false, default = nil)
  if valid_773643 != nil:
    section.add "PageSize", valid_773643
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773644: Call_PostDescribeAccountLimits_773630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773644.validator(path, query, header, formData, body)
  let scheme = call_773644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773644.url(scheme.get, call_773644.host, call_773644.base,
                         call_773644.route, valid.getOrDefault("path"))
  result = hook(call_773644, url, valid)

proc call*(call_773645: Call_PostDescribeAccountLimits_773630; Marker: string = "";
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
  var query_773646 = newJObject()
  var formData_773647 = newJObject()
  add(formData_773647, "Marker", newJString(Marker))
  add(query_773646, "Action", newJString(Action))
  add(formData_773647, "PageSize", newJInt(PageSize))
  add(query_773646, "Version", newJString(Version))
  result = call_773645.call(nil, query_773646, nil, formData_773647, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_773630(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_773631, base: "/",
    url: url_PostDescribeAccountLimits_773632,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_773613 = ref object of OpenApiRestCall_772597
proc url_GetDescribeAccountLimits_773615(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAccountLimits_773614(path: JsonNode; query: JsonNode;
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
  var valid_773616 = query.getOrDefault("PageSize")
  valid_773616 = validateParameter(valid_773616, JInt, required = false, default = nil)
  if valid_773616 != nil:
    section.add "PageSize", valid_773616
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773617 = query.getOrDefault("Action")
  valid_773617 = validateParameter(valid_773617, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_773617 != nil:
    section.add "Action", valid_773617
  var valid_773618 = query.getOrDefault("Marker")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "Marker", valid_773618
  var valid_773619 = query.getOrDefault("Version")
  valid_773619 = validateParameter(valid_773619, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773619 != nil:
    section.add "Version", valid_773619
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
  var valid_773620 = header.getOrDefault("X-Amz-Date")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-Date", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-Security-Token")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-Security-Token", valid_773621
  var valid_773622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Content-Sha256", valid_773622
  var valid_773623 = header.getOrDefault("X-Amz-Algorithm")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-Algorithm", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-Signature")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Signature", valid_773624
  var valid_773625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-SignedHeaders", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Credential")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Credential", valid_773626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773627: Call_GetDescribeAccountLimits_773613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773627.validator(path, query, header, formData, body)
  let scheme = call_773627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773627.url(scheme.get, call_773627.host, call_773627.base,
                         call_773627.route, valid.getOrDefault("path"))
  result = hook(call_773627, url, valid)

proc call*(call_773628: Call_GetDescribeAccountLimits_773613; PageSize: int = 0;
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
  var query_773629 = newJObject()
  add(query_773629, "PageSize", newJInt(PageSize))
  add(query_773629, "Action", newJString(Action))
  add(query_773629, "Marker", newJString(Marker))
  add(query_773629, "Version", newJString(Version))
  result = call_773628.call(nil, query_773629, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_773613(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_773614, base: "/",
    url: url_GetDescribeAccountLimits_773615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_773666 = ref object of OpenApiRestCall_772597
proc url_PostDescribeListenerCertificates_773668(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeListenerCertificates_773667(path: JsonNode;
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
  var valid_773669 = query.getOrDefault("Action")
  valid_773669 = validateParameter(valid_773669, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_773669 != nil:
    section.add "Action", valid_773669
  var valid_773670 = query.getOrDefault("Version")
  valid_773670 = validateParameter(valid_773670, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773670 != nil:
    section.add "Version", valid_773670
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
  var valid_773671 = header.getOrDefault("X-Amz-Date")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-Date", valid_773671
  var valid_773672 = header.getOrDefault("X-Amz-Security-Token")
  valid_773672 = validateParameter(valid_773672, JString, required = false,
                                 default = nil)
  if valid_773672 != nil:
    section.add "X-Amz-Security-Token", valid_773672
  var valid_773673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773673 = validateParameter(valid_773673, JString, required = false,
                                 default = nil)
  if valid_773673 != nil:
    section.add "X-Amz-Content-Sha256", valid_773673
  var valid_773674 = header.getOrDefault("X-Amz-Algorithm")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Algorithm", valid_773674
  var valid_773675 = header.getOrDefault("X-Amz-Signature")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-Signature", valid_773675
  var valid_773676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-SignedHeaders", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Credential")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Credential", valid_773677
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
  var valid_773678 = formData.getOrDefault("ListenerArn")
  valid_773678 = validateParameter(valid_773678, JString, required = true,
                                 default = nil)
  if valid_773678 != nil:
    section.add "ListenerArn", valid_773678
  var valid_773679 = formData.getOrDefault("Marker")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "Marker", valid_773679
  var valid_773680 = formData.getOrDefault("PageSize")
  valid_773680 = validateParameter(valid_773680, JInt, required = false, default = nil)
  if valid_773680 != nil:
    section.add "PageSize", valid_773680
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773681: Call_PostDescribeListenerCertificates_773666;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773681.validator(path, query, header, formData, body)
  let scheme = call_773681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773681.url(scheme.get, call_773681.host, call_773681.base,
                         call_773681.route, valid.getOrDefault("path"))
  result = hook(call_773681, url, valid)

proc call*(call_773682: Call_PostDescribeListenerCertificates_773666;
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
  var query_773683 = newJObject()
  var formData_773684 = newJObject()
  add(formData_773684, "ListenerArn", newJString(ListenerArn))
  add(formData_773684, "Marker", newJString(Marker))
  add(query_773683, "Action", newJString(Action))
  add(formData_773684, "PageSize", newJInt(PageSize))
  add(query_773683, "Version", newJString(Version))
  result = call_773682.call(nil, query_773683, nil, formData_773684, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_773666(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_773667, base: "/",
    url: url_PostDescribeListenerCertificates_773668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_773648 = ref object of OpenApiRestCall_772597
proc url_GetDescribeListenerCertificates_773650(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeListenerCertificates_773649(path: JsonNode;
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
  var valid_773651 = query.getOrDefault("PageSize")
  valid_773651 = validateParameter(valid_773651, JInt, required = false, default = nil)
  if valid_773651 != nil:
    section.add "PageSize", valid_773651
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773652 = query.getOrDefault("Action")
  valid_773652 = validateParameter(valid_773652, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_773652 != nil:
    section.add "Action", valid_773652
  var valid_773653 = query.getOrDefault("Marker")
  valid_773653 = validateParameter(valid_773653, JString, required = false,
                                 default = nil)
  if valid_773653 != nil:
    section.add "Marker", valid_773653
  var valid_773654 = query.getOrDefault("ListenerArn")
  valid_773654 = validateParameter(valid_773654, JString, required = true,
                                 default = nil)
  if valid_773654 != nil:
    section.add "ListenerArn", valid_773654
  var valid_773655 = query.getOrDefault("Version")
  valid_773655 = validateParameter(valid_773655, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773655 != nil:
    section.add "Version", valid_773655
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
  var valid_773656 = header.getOrDefault("X-Amz-Date")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Date", valid_773656
  var valid_773657 = header.getOrDefault("X-Amz-Security-Token")
  valid_773657 = validateParameter(valid_773657, JString, required = false,
                                 default = nil)
  if valid_773657 != nil:
    section.add "X-Amz-Security-Token", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Content-Sha256", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-Algorithm")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Algorithm", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Signature")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Signature", valid_773660
  var valid_773661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-SignedHeaders", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Credential")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Credential", valid_773662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773663: Call_GetDescribeListenerCertificates_773648;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773663.validator(path, query, header, formData, body)
  let scheme = call_773663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773663.url(scheme.get, call_773663.host, call_773663.base,
                         call_773663.route, valid.getOrDefault("path"))
  result = hook(call_773663, url, valid)

proc call*(call_773664: Call_GetDescribeListenerCertificates_773648;
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
  var query_773665 = newJObject()
  add(query_773665, "PageSize", newJInt(PageSize))
  add(query_773665, "Action", newJString(Action))
  add(query_773665, "Marker", newJString(Marker))
  add(query_773665, "ListenerArn", newJString(ListenerArn))
  add(query_773665, "Version", newJString(Version))
  result = call_773664.call(nil, query_773665, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_773648(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_773649, base: "/",
    url: url_GetDescribeListenerCertificates_773650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_773704 = ref object of OpenApiRestCall_772597
proc url_PostDescribeListeners_773706(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeListeners_773705(path: JsonNode; query: JsonNode;
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
  var valid_773707 = query.getOrDefault("Action")
  valid_773707 = validateParameter(valid_773707, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_773707 != nil:
    section.add "Action", valid_773707
  var valid_773708 = query.getOrDefault("Version")
  valid_773708 = validateParameter(valid_773708, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773708 != nil:
    section.add "Version", valid_773708
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
  var valid_773709 = header.getOrDefault("X-Amz-Date")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-Date", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Security-Token")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Security-Token", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-Content-Sha256", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-Algorithm")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-Algorithm", valid_773712
  var valid_773713 = header.getOrDefault("X-Amz-Signature")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-Signature", valid_773713
  var valid_773714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773714 = validateParameter(valid_773714, JString, required = false,
                                 default = nil)
  if valid_773714 != nil:
    section.add "X-Amz-SignedHeaders", valid_773714
  var valid_773715 = header.getOrDefault("X-Amz-Credential")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Credential", valid_773715
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
  var valid_773716 = formData.getOrDefault("LoadBalancerArn")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "LoadBalancerArn", valid_773716
  var valid_773717 = formData.getOrDefault("Marker")
  valid_773717 = validateParameter(valid_773717, JString, required = false,
                                 default = nil)
  if valid_773717 != nil:
    section.add "Marker", valid_773717
  var valid_773718 = formData.getOrDefault("PageSize")
  valid_773718 = validateParameter(valid_773718, JInt, required = false, default = nil)
  if valid_773718 != nil:
    section.add "PageSize", valid_773718
  var valid_773719 = formData.getOrDefault("ListenerArns")
  valid_773719 = validateParameter(valid_773719, JArray, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "ListenerArns", valid_773719
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773720: Call_PostDescribeListeners_773704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_773720.validator(path, query, header, formData, body)
  let scheme = call_773720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773720.url(scheme.get, call_773720.host, call_773720.base,
                         call_773720.route, valid.getOrDefault("path"))
  result = hook(call_773720, url, valid)

proc call*(call_773721: Call_PostDescribeListeners_773704;
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
  var query_773722 = newJObject()
  var formData_773723 = newJObject()
  add(formData_773723, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_773723, "Marker", newJString(Marker))
  add(query_773722, "Action", newJString(Action))
  add(formData_773723, "PageSize", newJInt(PageSize))
  if ListenerArns != nil:
    formData_773723.add "ListenerArns", ListenerArns
  add(query_773722, "Version", newJString(Version))
  result = call_773721.call(nil, query_773722, nil, formData_773723, nil)

var postDescribeListeners* = Call_PostDescribeListeners_773704(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_773705, base: "/",
    url: url_PostDescribeListeners_773706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_773685 = ref object of OpenApiRestCall_772597
proc url_GetDescribeListeners_773687(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeListeners_773686(path: JsonNode; query: JsonNode;
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
  var valid_773688 = query.getOrDefault("ListenerArns")
  valid_773688 = validateParameter(valid_773688, JArray, required = false,
                                 default = nil)
  if valid_773688 != nil:
    section.add "ListenerArns", valid_773688
  var valid_773689 = query.getOrDefault("PageSize")
  valid_773689 = validateParameter(valid_773689, JInt, required = false, default = nil)
  if valid_773689 != nil:
    section.add "PageSize", valid_773689
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773690 = query.getOrDefault("Action")
  valid_773690 = validateParameter(valid_773690, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_773690 != nil:
    section.add "Action", valid_773690
  var valid_773691 = query.getOrDefault("Marker")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "Marker", valid_773691
  var valid_773692 = query.getOrDefault("LoadBalancerArn")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "LoadBalancerArn", valid_773692
  var valid_773693 = query.getOrDefault("Version")
  valid_773693 = validateParameter(valid_773693, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773693 != nil:
    section.add "Version", valid_773693
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
  var valid_773694 = header.getOrDefault("X-Amz-Date")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Date", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Security-Token")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Security-Token", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Content-Sha256", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-Algorithm")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-Algorithm", valid_773697
  var valid_773698 = header.getOrDefault("X-Amz-Signature")
  valid_773698 = validateParameter(valid_773698, JString, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "X-Amz-Signature", valid_773698
  var valid_773699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773699 = validateParameter(valid_773699, JString, required = false,
                                 default = nil)
  if valid_773699 != nil:
    section.add "X-Amz-SignedHeaders", valid_773699
  var valid_773700 = header.getOrDefault("X-Amz-Credential")
  valid_773700 = validateParameter(valid_773700, JString, required = false,
                                 default = nil)
  if valid_773700 != nil:
    section.add "X-Amz-Credential", valid_773700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773701: Call_GetDescribeListeners_773685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_773701.validator(path, query, header, formData, body)
  let scheme = call_773701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773701.url(scheme.get, call_773701.host, call_773701.base,
                         call_773701.route, valid.getOrDefault("path"))
  result = hook(call_773701, url, valid)

proc call*(call_773702: Call_GetDescribeListeners_773685;
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
  var query_773703 = newJObject()
  if ListenerArns != nil:
    query_773703.add "ListenerArns", ListenerArns
  add(query_773703, "PageSize", newJInt(PageSize))
  add(query_773703, "Action", newJString(Action))
  add(query_773703, "Marker", newJString(Marker))
  add(query_773703, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_773703, "Version", newJString(Version))
  result = call_773702.call(nil, query_773703, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_773685(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_773686,
    base: "/", url: url_GetDescribeListeners_773687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_773740 = ref object of OpenApiRestCall_772597
proc url_PostDescribeLoadBalancerAttributes_773742(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancerAttributes_773741(path: JsonNode;
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
  var valid_773743 = query.getOrDefault("Action")
  valid_773743 = validateParameter(valid_773743, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_773743 != nil:
    section.add "Action", valid_773743
  var valid_773744 = query.getOrDefault("Version")
  valid_773744 = validateParameter(valid_773744, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773744 != nil:
    section.add "Version", valid_773744
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
  var valid_773745 = header.getOrDefault("X-Amz-Date")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "X-Amz-Date", valid_773745
  var valid_773746 = header.getOrDefault("X-Amz-Security-Token")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-Security-Token", valid_773746
  var valid_773747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Content-Sha256", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-Algorithm")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-Algorithm", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Signature")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Signature", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-SignedHeaders", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-Credential")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Credential", valid_773751
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_773752 = formData.getOrDefault("LoadBalancerArn")
  valid_773752 = validateParameter(valid_773752, JString, required = true,
                                 default = nil)
  if valid_773752 != nil:
    section.add "LoadBalancerArn", valid_773752
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773753: Call_PostDescribeLoadBalancerAttributes_773740;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773753.validator(path, query, header, formData, body)
  let scheme = call_773753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773753.url(scheme.get, call_773753.host, call_773753.base,
                         call_773753.route, valid.getOrDefault("path"))
  result = hook(call_773753, url, valid)

proc call*(call_773754: Call_PostDescribeLoadBalancerAttributes_773740;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773755 = newJObject()
  var formData_773756 = newJObject()
  add(formData_773756, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_773755, "Action", newJString(Action))
  add(query_773755, "Version", newJString(Version))
  result = call_773754.call(nil, query_773755, nil, formData_773756, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_773740(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_773741, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_773742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_773724 = ref object of OpenApiRestCall_772597
proc url_GetDescribeLoadBalancerAttributes_773726(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancerAttributes_773725(path: JsonNode;
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
  var valid_773727 = query.getOrDefault("Action")
  valid_773727 = validateParameter(valid_773727, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_773727 != nil:
    section.add "Action", valid_773727
  var valid_773728 = query.getOrDefault("LoadBalancerArn")
  valid_773728 = validateParameter(valid_773728, JString, required = true,
                                 default = nil)
  if valid_773728 != nil:
    section.add "LoadBalancerArn", valid_773728
  var valid_773729 = query.getOrDefault("Version")
  valid_773729 = validateParameter(valid_773729, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773729 != nil:
    section.add "Version", valid_773729
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
  var valid_773730 = header.getOrDefault("X-Amz-Date")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Date", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-Security-Token")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Security-Token", valid_773731
  var valid_773732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "X-Amz-Content-Sha256", valid_773732
  var valid_773733 = header.getOrDefault("X-Amz-Algorithm")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-Algorithm", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-Signature")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-Signature", valid_773734
  var valid_773735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "X-Amz-SignedHeaders", valid_773735
  var valid_773736 = header.getOrDefault("X-Amz-Credential")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-Credential", valid_773736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773737: Call_GetDescribeLoadBalancerAttributes_773724;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773737.validator(path, query, header, formData, body)
  let scheme = call_773737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773737.url(scheme.get, call_773737.host, call_773737.base,
                         call_773737.route, valid.getOrDefault("path"))
  result = hook(call_773737, url, valid)

proc call*(call_773738: Call_GetDescribeLoadBalancerAttributes_773724;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_773739 = newJObject()
  add(query_773739, "Action", newJString(Action))
  add(query_773739, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_773739, "Version", newJString(Version))
  result = call_773738.call(nil, query_773739, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_773724(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_773725, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_773726,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_773776 = ref object of OpenApiRestCall_772597
proc url_PostDescribeLoadBalancers_773778(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancers_773777(path: JsonNode; query: JsonNode;
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
  var valid_773779 = query.getOrDefault("Action")
  valid_773779 = validateParameter(valid_773779, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_773779 != nil:
    section.add "Action", valid_773779
  var valid_773780 = query.getOrDefault("Version")
  valid_773780 = validateParameter(valid_773780, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773780 != nil:
    section.add "Version", valid_773780
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
  var valid_773781 = header.getOrDefault("X-Amz-Date")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "X-Amz-Date", valid_773781
  var valid_773782 = header.getOrDefault("X-Amz-Security-Token")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Security-Token", valid_773782
  var valid_773783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-Content-Sha256", valid_773783
  var valid_773784 = header.getOrDefault("X-Amz-Algorithm")
  valid_773784 = validateParameter(valid_773784, JString, required = false,
                                 default = nil)
  if valid_773784 != nil:
    section.add "X-Amz-Algorithm", valid_773784
  var valid_773785 = header.getOrDefault("X-Amz-Signature")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "X-Amz-Signature", valid_773785
  var valid_773786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-SignedHeaders", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-Credential")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Credential", valid_773787
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
  var valid_773788 = formData.getOrDefault("Names")
  valid_773788 = validateParameter(valid_773788, JArray, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "Names", valid_773788
  var valid_773789 = formData.getOrDefault("Marker")
  valid_773789 = validateParameter(valid_773789, JString, required = false,
                                 default = nil)
  if valid_773789 != nil:
    section.add "Marker", valid_773789
  var valid_773790 = formData.getOrDefault("LoadBalancerArns")
  valid_773790 = validateParameter(valid_773790, JArray, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "LoadBalancerArns", valid_773790
  var valid_773791 = formData.getOrDefault("PageSize")
  valid_773791 = validateParameter(valid_773791, JInt, required = false, default = nil)
  if valid_773791 != nil:
    section.add "PageSize", valid_773791
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773792: Call_PostDescribeLoadBalancers_773776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_773792.validator(path, query, header, formData, body)
  let scheme = call_773792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773792.url(scheme.get, call_773792.host, call_773792.base,
                         call_773792.route, valid.getOrDefault("path"))
  result = hook(call_773792, url, valid)

proc call*(call_773793: Call_PostDescribeLoadBalancers_773776;
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
  var query_773794 = newJObject()
  var formData_773795 = newJObject()
  if Names != nil:
    formData_773795.add "Names", Names
  add(formData_773795, "Marker", newJString(Marker))
  add(query_773794, "Action", newJString(Action))
  if LoadBalancerArns != nil:
    formData_773795.add "LoadBalancerArns", LoadBalancerArns
  add(formData_773795, "PageSize", newJInt(PageSize))
  add(query_773794, "Version", newJString(Version))
  result = call_773793.call(nil, query_773794, nil, formData_773795, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_773776(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_773777, base: "/",
    url: url_PostDescribeLoadBalancers_773778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_773757 = ref object of OpenApiRestCall_772597
proc url_GetDescribeLoadBalancers_773759(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancers_773758(path: JsonNode; query: JsonNode;
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
  var valid_773760 = query.getOrDefault("Names")
  valid_773760 = validateParameter(valid_773760, JArray, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "Names", valid_773760
  var valid_773761 = query.getOrDefault("PageSize")
  valid_773761 = validateParameter(valid_773761, JInt, required = false, default = nil)
  if valid_773761 != nil:
    section.add "PageSize", valid_773761
  var valid_773762 = query.getOrDefault("LoadBalancerArns")
  valid_773762 = validateParameter(valid_773762, JArray, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "LoadBalancerArns", valid_773762
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773763 = query.getOrDefault("Action")
  valid_773763 = validateParameter(valid_773763, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_773763 != nil:
    section.add "Action", valid_773763
  var valid_773764 = query.getOrDefault("Marker")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "Marker", valid_773764
  var valid_773765 = query.getOrDefault("Version")
  valid_773765 = validateParameter(valid_773765, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773765 != nil:
    section.add "Version", valid_773765
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
  var valid_773766 = header.getOrDefault("X-Amz-Date")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-Date", valid_773766
  var valid_773767 = header.getOrDefault("X-Amz-Security-Token")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-Security-Token", valid_773767
  var valid_773768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Content-Sha256", valid_773768
  var valid_773769 = header.getOrDefault("X-Amz-Algorithm")
  valid_773769 = validateParameter(valid_773769, JString, required = false,
                                 default = nil)
  if valid_773769 != nil:
    section.add "X-Amz-Algorithm", valid_773769
  var valid_773770 = header.getOrDefault("X-Amz-Signature")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Signature", valid_773770
  var valid_773771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "X-Amz-SignedHeaders", valid_773771
  var valid_773772 = header.getOrDefault("X-Amz-Credential")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Credential", valid_773772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773773: Call_GetDescribeLoadBalancers_773757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_773773.validator(path, query, header, formData, body)
  let scheme = call_773773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773773.url(scheme.get, call_773773.host, call_773773.base,
                         call_773773.route, valid.getOrDefault("path"))
  result = hook(call_773773, url, valid)

proc call*(call_773774: Call_GetDescribeLoadBalancers_773757;
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
  var query_773775 = newJObject()
  if Names != nil:
    query_773775.add "Names", Names
  add(query_773775, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_773775.add "LoadBalancerArns", LoadBalancerArns
  add(query_773775, "Action", newJString(Action))
  add(query_773775, "Marker", newJString(Marker))
  add(query_773775, "Version", newJString(Version))
  result = call_773774.call(nil, query_773775, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_773757(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_773758, base: "/",
    url: url_GetDescribeLoadBalancers_773759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_773815 = ref object of OpenApiRestCall_772597
proc url_PostDescribeRules_773817(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeRules_773816(path: JsonNode; query: JsonNode;
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
  var valid_773818 = query.getOrDefault("Action")
  valid_773818 = validateParameter(valid_773818, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_773818 != nil:
    section.add "Action", valid_773818
  var valid_773819 = query.getOrDefault("Version")
  valid_773819 = validateParameter(valid_773819, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773819 != nil:
    section.add "Version", valid_773819
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
  var valid_773820 = header.getOrDefault("X-Amz-Date")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Date", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-Security-Token")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Security-Token", valid_773821
  var valid_773822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773822 = validateParameter(valid_773822, JString, required = false,
                                 default = nil)
  if valid_773822 != nil:
    section.add "X-Amz-Content-Sha256", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-Algorithm")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-Algorithm", valid_773823
  var valid_773824 = header.getOrDefault("X-Amz-Signature")
  valid_773824 = validateParameter(valid_773824, JString, required = false,
                                 default = nil)
  if valid_773824 != nil:
    section.add "X-Amz-Signature", valid_773824
  var valid_773825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773825 = validateParameter(valid_773825, JString, required = false,
                                 default = nil)
  if valid_773825 != nil:
    section.add "X-Amz-SignedHeaders", valid_773825
  var valid_773826 = header.getOrDefault("X-Amz-Credential")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "X-Amz-Credential", valid_773826
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
  var valid_773827 = formData.getOrDefault("ListenerArn")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "ListenerArn", valid_773827
  var valid_773828 = formData.getOrDefault("RuleArns")
  valid_773828 = validateParameter(valid_773828, JArray, required = false,
                                 default = nil)
  if valid_773828 != nil:
    section.add "RuleArns", valid_773828
  var valid_773829 = formData.getOrDefault("Marker")
  valid_773829 = validateParameter(valid_773829, JString, required = false,
                                 default = nil)
  if valid_773829 != nil:
    section.add "Marker", valid_773829
  var valid_773830 = formData.getOrDefault("PageSize")
  valid_773830 = validateParameter(valid_773830, JInt, required = false, default = nil)
  if valid_773830 != nil:
    section.add "PageSize", valid_773830
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773831: Call_PostDescribeRules_773815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_773831.validator(path, query, header, formData, body)
  let scheme = call_773831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773831.url(scheme.get, call_773831.host, call_773831.base,
                         call_773831.route, valid.getOrDefault("path"))
  result = hook(call_773831, url, valid)

proc call*(call_773832: Call_PostDescribeRules_773815; ListenerArn: string = "";
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
  var query_773833 = newJObject()
  var formData_773834 = newJObject()
  add(formData_773834, "ListenerArn", newJString(ListenerArn))
  if RuleArns != nil:
    formData_773834.add "RuleArns", RuleArns
  add(formData_773834, "Marker", newJString(Marker))
  add(query_773833, "Action", newJString(Action))
  add(formData_773834, "PageSize", newJInt(PageSize))
  add(query_773833, "Version", newJString(Version))
  result = call_773832.call(nil, query_773833, nil, formData_773834, nil)

var postDescribeRules* = Call_PostDescribeRules_773815(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_773816,
    base: "/", url: url_PostDescribeRules_773817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_773796 = ref object of OpenApiRestCall_772597
proc url_GetDescribeRules_773798(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeRules_773797(path: JsonNode; query: JsonNode;
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
  var valid_773799 = query.getOrDefault("PageSize")
  valid_773799 = validateParameter(valid_773799, JInt, required = false, default = nil)
  if valid_773799 != nil:
    section.add "PageSize", valid_773799
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773800 = query.getOrDefault("Action")
  valid_773800 = validateParameter(valid_773800, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_773800 != nil:
    section.add "Action", valid_773800
  var valid_773801 = query.getOrDefault("Marker")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "Marker", valid_773801
  var valid_773802 = query.getOrDefault("ListenerArn")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "ListenerArn", valid_773802
  var valid_773803 = query.getOrDefault("Version")
  valid_773803 = validateParameter(valid_773803, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773803 != nil:
    section.add "Version", valid_773803
  var valid_773804 = query.getOrDefault("RuleArns")
  valid_773804 = validateParameter(valid_773804, JArray, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "RuleArns", valid_773804
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
  var valid_773805 = header.getOrDefault("X-Amz-Date")
  valid_773805 = validateParameter(valid_773805, JString, required = false,
                                 default = nil)
  if valid_773805 != nil:
    section.add "X-Amz-Date", valid_773805
  var valid_773806 = header.getOrDefault("X-Amz-Security-Token")
  valid_773806 = validateParameter(valid_773806, JString, required = false,
                                 default = nil)
  if valid_773806 != nil:
    section.add "X-Amz-Security-Token", valid_773806
  var valid_773807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773807 = validateParameter(valid_773807, JString, required = false,
                                 default = nil)
  if valid_773807 != nil:
    section.add "X-Amz-Content-Sha256", valid_773807
  var valid_773808 = header.getOrDefault("X-Amz-Algorithm")
  valid_773808 = validateParameter(valid_773808, JString, required = false,
                                 default = nil)
  if valid_773808 != nil:
    section.add "X-Amz-Algorithm", valid_773808
  var valid_773809 = header.getOrDefault("X-Amz-Signature")
  valid_773809 = validateParameter(valid_773809, JString, required = false,
                                 default = nil)
  if valid_773809 != nil:
    section.add "X-Amz-Signature", valid_773809
  var valid_773810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773810 = validateParameter(valid_773810, JString, required = false,
                                 default = nil)
  if valid_773810 != nil:
    section.add "X-Amz-SignedHeaders", valid_773810
  var valid_773811 = header.getOrDefault("X-Amz-Credential")
  valid_773811 = validateParameter(valid_773811, JString, required = false,
                                 default = nil)
  if valid_773811 != nil:
    section.add "X-Amz-Credential", valid_773811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773812: Call_GetDescribeRules_773796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_773812.validator(path, query, header, formData, body)
  let scheme = call_773812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773812.url(scheme.get, call_773812.host, call_773812.base,
                         call_773812.route, valid.getOrDefault("path"))
  result = hook(call_773812, url, valid)

proc call*(call_773813: Call_GetDescribeRules_773796; PageSize: int = 0;
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
  var query_773814 = newJObject()
  add(query_773814, "PageSize", newJInt(PageSize))
  add(query_773814, "Action", newJString(Action))
  add(query_773814, "Marker", newJString(Marker))
  add(query_773814, "ListenerArn", newJString(ListenerArn))
  add(query_773814, "Version", newJString(Version))
  if RuleArns != nil:
    query_773814.add "RuleArns", RuleArns
  result = call_773813.call(nil, query_773814, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_773796(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_773797,
    base: "/", url: url_GetDescribeRules_773798,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_773853 = ref object of OpenApiRestCall_772597
proc url_PostDescribeSSLPolicies_773855(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeSSLPolicies_773854(path: JsonNode; query: JsonNode;
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
  var valid_773856 = query.getOrDefault("Action")
  valid_773856 = validateParameter(valid_773856, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_773856 != nil:
    section.add "Action", valid_773856
  var valid_773857 = query.getOrDefault("Version")
  valid_773857 = validateParameter(valid_773857, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773857 != nil:
    section.add "Version", valid_773857
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
  var valid_773858 = header.getOrDefault("X-Amz-Date")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Date", valid_773858
  var valid_773859 = header.getOrDefault("X-Amz-Security-Token")
  valid_773859 = validateParameter(valid_773859, JString, required = false,
                                 default = nil)
  if valid_773859 != nil:
    section.add "X-Amz-Security-Token", valid_773859
  var valid_773860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773860 = validateParameter(valid_773860, JString, required = false,
                                 default = nil)
  if valid_773860 != nil:
    section.add "X-Amz-Content-Sha256", valid_773860
  var valid_773861 = header.getOrDefault("X-Amz-Algorithm")
  valid_773861 = validateParameter(valid_773861, JString, required = false,
                                 default = nil)
  if valid_773861 != nil:
    section.add "X-Amz-Algorithm", valid_773861
  var valid_773862 = header.getOrDefault("X-Amz-Signature")
  valid_773862 = validateParameter(valid_773862, JString, required = false,
                                 default = nil)
  if valid_773862 != nil:
    section.add "X-Amz-Signature", valid_773862
  var valid_773863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773863 = validateParameter(valid_773863, JString, required = false,
                                 default = nil)
  if valid_773863 != nil:
    section.add "X-Amz-SignedHeaders", valid_773863
  var valid_773864 = header.getOrDefault("X-Amz-Credential")
  valid_773864 = validateParameter(valid_773864, JString, required = false,
                                 default = nil)
  if valid_773864 != nil:
    section.add "X-Amz-Credential", valid_773864
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_773865 = formData.getOrDefault("Names")
  valid_773865 = validateParameter(valid_773865, JArray, required = false,
                                 default = nil)
  if valid_773865 != nil:
    section.add "Names", valid_773865
  var valid_773866 = formData.getOrDefault("Marker")
  valid_773866 = validateParameter(valid_773866, JString, required = false,
                                 default = nil)
  if valid_773866 != nil:
    section.add "Marker", valid_773866
  var valid_773867 = formData.getOrDefault("PageSize")
  valid_773867 = validateParameter(valid_773867, JInt, required = false, default = nil)
  if valid_773867 != nil:
    section.add "PageSize", valid_773867
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773868: Call_PostDescribeSSLPolicies_773853; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773868.validator(path, query, header, formData, body)
  let scheme = call_773868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773868.url(scheme.get, call_773868.host, call_773868.base,
                         call_773868.route, valid.getOrDefault("path"))
  result = hook(call_773868, url, valid)

proc call*(call_773869: Call_PostDescribeSSLPolicies_773853; Names: JsonNode = nil;
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
  var query_773870 = newJObject()
  var formData_773871 = newJObject()
  if Names != nil:
    formData_773871.add "Names", Names
  add(formData_773871, "Marker", newJString(Marker))
  add(query_773870, "Action", newJString(Action))
  add(formData_773871, "PageSize", newJInt(PageSize))
  add(query_773870, "Version", newJString(Version))
  result = call_773869.call(nil, query_773870, nil, formData_773871, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_773853(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_773854, base: "/",
    url: url_PostDescribeSSLPolicies_773855, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_773835 = ref object of OpenApiRestCall_772597
proc url_GetDescribeSSLPolicies_773837(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeSSLPolicies_773836(path: JsonNode; query: JsonNode;
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
  var valid_773838 = query.getOrDefault("Names")
  valid_773838 = validateParameter(valid_773838, JArray, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "Names", valid_773838
  var valid_773839 = query.getOrDefault("PageSize")
  valid_773839 = validateParameter(valid_773839, JInt, required = false, default = nil)
  if valid_773839 != nil:
    section.add "PageSize", valid_773839
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773840 = query.getOrDefault("Action")
  valid_773840 = validateParameter(valid_773840, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_773840 != nil:
    section.add "Action", valid_773840
  var valid_773841 = query.getOrDefault("Marker")
  valid_773841 = validateParameter(valid_773841, JString, required = false,
                                 default = nil)
  if valid_773841 != nil:
    section.add "Marker", valid_773841
  var valid_773842 = query.getOrDefault("Version")
  valid_773842 = validateParameter(valid_773842, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773842 != nil:
    section.add "Version", valid_773842
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
  var valid_773843 = header.getOrDefault("X-Amz-Date")
  valid_773843 = validateParameter(valid_773843, JString, required = false,
                                 default = nil)
  if valid_773843 != nil:
    section.add "X-Amz-Date", valid_773843
  var valid_773844 = header.getOrDefault("X-Amz-Security-Token")
  valid_773844 = validateParameter(valid_773844, JString, required = false,
                                 default = nil)
  if valid_773844 != nil:
    section.add "X-Amz-Security-Token", valid_773844
  var valid_773845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773845 = validateParameter(valid_773845, JString, required = false,
                                 default = nil)
  if valid_773845 != nil:
    section.add "X-Amz-Content-Sha256", valid_773845
  var valid_773846 = header.getOrDefault("X-Amz-Algorithm")
  valid_773846 = validateParameter(valid_773846, JString, required = false,
                                 default = nil)
  if valid_773846 != nil:
    section.add "X-Amz-Algorithm", valid_773846
  var valid_773847 = header.getOrDefault("X-Amz-Signature")
  valid_773847 = validateParameter(valid_773847, JString, required = false,
                                 default = nil)
  if valid_773847 != nil:
    section.add "X-Amz-Signature", valid_773847
  var valid_773848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773848 = validateParameter(valid_773848, JString, required = false,
                                 default = nil)
  if valid_773848 != nil:
    section.add "X-Amz-SignedHeaders", valid_773848
  var valid_773849 = header.getOrDefault("X-Amz-Credential")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "X-Amz-Credential", valid_773849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773850: Call_GetDescribeSSLPolicies_773835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773850.validator(path, query, header, formData, body)
  let scheme = call_773850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773850.url(scheme.get, call_773850.host, call_773850.base,
                         call_773850.route, valid.getOrDefault("path"))
  result = hook(call_773850, url, valid)

proc call*(call_773851: Call_GetDescribeSSLPolicies_773835; Names: JsonNode = nil;
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
  var query_773852 = newJObject()
  if Names != nil:
    query_773852.add "Names", Names
  add(query_773852, "PageSize", newJInt(PageSize))
  add(query_773852, "Action", newJString(Action))
  add(query_773852, "Marker", newJString(Marker))
  add(query_773852, "Version", newJString(Version))
  result = call_773851.call(nil, query_773852, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_773835(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_773836, base: "/",
    url: url_GetDescribeSSLPolicies_773837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_773888 = ref object of OpenApiRestCall_772597
proc url_PostDescribeTags_773890(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTags_773889(path: JsonNode; query: JsonNode;
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
  var valid_773891 = query.getOrDefault("Action")
  valid_773891 = validateParameter(valid_773891, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_773891 != nil:
    section.add "Action", valid_773891
  var valid_773892 = query.getOrDefault("Version")
  valid_773892 = validateParameter(valid_773892, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773892 != nil:
    section.add "Version", valid_773892
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
  var valid_773893 = header.getOrDefault("X-Amz-Date")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-Date", valid_773893
  var valid_773894 = header.getOrDefault("X-Amz-Security-Token")
  valid_773894 = validateParameter(valid_773894, JString, required = false,
                                 default = nil)
  if valid_773894 != nil:
    section.add "X-Amz-Security-Token", valid_773894
  var valid_773895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773895 = validateParameter(valid_773895, JString, required = false,
                                 default = nil)
  if valid_773895 != nil:
    section.add "X-Amz-Content-Sha256", valid_773895
  var valid_773896 = header.getOrDefault("X-Amz-Algorithm")
  valid_773896 = validateParameter(valid_773896, JString, required = false,
                                 default = nil)
  if valid_773896 != nil:
    section.add "X-Amz-Algorithm", valid_773896
  var valid_773897 = header.getOrDefault("X-Amz-Signature")
  valid_773897 = validateParameter(valid_773897, JString, required = false,
                                 default = nil)
  if valid_773897 != nil:
    section.add "X-Amz-Signature", valid_773897
  var valid_773898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773898 = validateParameter(valid_773898, JString, required = false,
                                 default = nil)
  if valid_773898 != nil:
    section.add "X-Amz-SignedHeaders", valid_773898
  var valid_773899 = header.getOrDefault("X-Amz-Credential")
  valid_773899 = validateParameter(valid_773899, JString, required = false,
                                 default = nil)
  if valid_773899 != nil:
    section.add "X-Amz-Credential", valid_773899
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_773900 = formData.getOrDefault("ResourceArns")
  valid_773900 = validateParameter(valid_773900, JArray, required = true, default = nil)
  if valid_773900 != nil:
    section.add "ResourceArns", valid_773900
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773901: Call_PostDescribeTags_773888; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_773901.validator(path, query, header, formData, body)
  let scheme = call_773901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773901.url(scheme.get, call_773901.host, call_773901.base,
                         call_773901.route, valid.getOrDefault("path"))
  result = hook(call_773901, url, valid)

proc call*(call_773902: Call_PostDescribeTags_773888; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773903 = newJObject()
  var formData_773904 = newJObject()
  if ResourceArns != nil:
    formData_773904.add "ResourceArns", ResourceArns
  add(query_773903, "Action", newJString(Action))
  add(query_773903, "Version", newJString(Version))
  result = call_773902.call(nil, query_773903, nil, formData_773904, nil)

var postDescribeTags* = Call_PostDescribeTags_773888(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_773889,
    base: "/", url: url_PostDescribeTags_773890,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_773872 = ref object of OpenApiRestCall_772597
proc url_GetDescribeTags_773874(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTags_773873(path: JsonNode; query: JsonNode;
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
  var valid_773875 = query.getOrDefault("Action")
  valid_773875 = validateParameter(valid_773875, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_773875 != nil:
    section.add "Action", valid_773875
  var valid_773876 = query.getOrDefault("ResourceArns")
  valid_773876 = validateParameter(valid_773876, JArray, required = true, default = nil)
  if valid_773876 != nil:
    section.add "ResourceArns", valid_773876
  var valid_773877 = query.getOrDefault("Version")
  valid_773877 = validateParameter(valid_773877, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773877 != nil:
    section.add "Version", valid_773877
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
  var valid_773878 = header.getOrDefault("X-Amz-Date")
  valid_773878 = validateParameter(valid_773878, JString, required = false,
                                 default = nil)
  if valid_773878 != nil:
    section.add "X-Amz-Date", valid_773878
  var valid_773879 = header.getOrDefault("X-Amz-Security-Token")
  valid_773879 = validateParameter(valid_773879, JString, required = false,
                                 default = nil)
  if valid_773879 != nil:
    section.add "X-Amz-Security-Token", valid_773879
  var valid_773880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773880 = validateParameter(valid_773880, JString, required = false,
                                 default = nil)
  if valid_773880 != nil:
    section.add "X-Amz-Content-Sha256", valid_773880
  var valid_773881 = header.getOrDefault("X-Amz-Algorithm")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "X-Amz-Algorithm", valid_773881
  var valid_773882 = header.getOrDefault("X-Amz-Signature")
  valid_773882 = validateParameter(valid_773882, JString, required = false,
                                 default = nil)
  if valid_773882 != nil:
    section.add "X-Amz-Signature", valid_773882
  var valid_773883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773883 = validateParameter(valid_773883, JString, required = false,
                                 default = nil)
  if valid_773883 != nil:
    section.add "X-Amz-SignedHeaders", valid_773883
  var valid_773884 = header.getOrDefault("X-Amz-Credential")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "X-Amz-Credential", valid_773884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773885: Call_GetDescribeTags_773872; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_773885.validator(path, query, header, formData, body)
  let scheme = call_773885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773885.url(scheme.get, call_773885.host, call_773885.base,
                         call_773885.route, valid.getOrDefault("path"))
  result = hook(call_773885, url, valid)

proc call*(call_773886: Call_GetDescribeTags_773872; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   Action: string (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Version: string (required)
  var query_773887 = newJObject()
  add(query_773887, "Action", newJString(Action))
  if ResourceArns != nil:
    query_773887.add "ResourceArns", ResourceArns
  add(query_773887, "Version", newJString(Version))
  result = call_773886.call(nil, query_773887, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_773872(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_773873,
    base: "/", url: url_GetDescribeTags_773874, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_773921 = ref object of OpenApiRestCall_772597
proc url_PostDescribeTargetGroupAttributes_773923(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTargetGroupAttributes_773922(path: JsonNode;
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
  var valid_773924 = query.getOrDefault("Action")
  valid_773924 = validateParameter(valid_773924, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_773924 != nil:
    section.add "Action", valid_773924
  var valid_773925 = query.getOrDefault("Version")
  valid_773925 = validateParameter(valid_773925, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773925 != nil:
    section.add "Version", valid_773925
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
  var valid_773926 = header.getOrDefault("X-Amz-Date")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-Date", valid_773926
  var valid_773927 = header.getOrDefault("X-Amz-Security-Token")
  valid_773927 = validateParameter(valid_773927, JString, required = false,
                                 default = nil)
  if valid_773927 != nil:
    section.add "X-Amz-Security-Token", valid_773927
  var valid_773928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773928 = validateParameter(valid_773928, JString, required = false,
                                 default = nil)
  if valid_773928 != nil:
    section.add "X-Amz-Content-Sha256", valid_773928
  var valid_773929 = header.getOrDefault("X-Amz-Algorithm")
  valid_773929 = validateParameter(valid_773929, JString, required = false,
                                 default = nil)
  if valid_773929 != nil:
    section.add "X-Amz-Algorithm", valid_773929
  var valid_773930 = header.getOrDefault("X-Amz-Signature")
  valid_773930 = validateParameter(valid_773930, JString, required = false,
                                 default = nil)
  if valid_773930 != nil:
    section.add "X-Amz-Signature", valid_773930
  var valid_773931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773931 = validateParameter(valid_773931, JString, required = false,
                                 default = nil)
  if valid_773931 != nil:
    section.add "X-Amz-SignedHeaders", valid_773931
  var valid_773932 = header.getOrDefault("X-Amz-Credential")
  valid_773932 = validateParameter(valid_773932, JString, required = false,
                                 default = nil)
  if valid_773932 != nil:
    section.add "X-Amz-Credential", valid_773932
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_773933 = formData.getOrDefault("TargetGroupArn")
  valid_773933 = validateParameter(valid_773933, JString, required = true,
                                 default = nil)
  if valid_773933 != nil:
    section.add "TargetGroupArn", valid_773933
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773934: Call_PostDescribeTargetGroupAttributes_773921;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773934.validator(path, query, header, formData, body)
  let scheme = call_773934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773934.url(scheme.get, call_773934.host, call_773934.base,
                         call_773934.route, valid.getOrDefault("path"))
  result = hook(call_773934, url, valid)

proc call*(call_773935: Call_PostDescribeTargetGroupAttributes_773921;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_773936 = newJObject()
  var formData_773937 = newJObject()
  add(query_773936, "Action", newJString(Action))
  add(formData_773937, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_773936, "Version", newJString(Version))
  result = call_773935.call(nil, query_773936, nil, formData_773937, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_773921(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_773922, base: "/",
    url: url_PostDescribeTargetGroupAttributes_773923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_773905 = ref object of OpenApiRestCall_772597
proc url_GetDescribeTargetGroupAttributes_773907(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTargetGroupAttributes_773906(path: JsonNode;
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
  var valid_773908 = query.getOrDefault("TargetGroupArn")
  valid_773908 = validateParameter(valid_773908, JString, required = true,
                                 default = nil)
  if valid_773908 != nil:
    section.add "TargetGroupArn", valid_773908
  var valid_773909 = query.getOrDefault("Action")
  valid_773909 = validateParameter(valid_773909, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_773909 != nil:
    section.add "Action", valid_773909
  var valid_773910 = query.getOrDefault("Version")
  valid_773910 = validateParameter(valid_773910, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773910 != nil:
    section.add "Version", valid_773910
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
  var valid_773911 = header.getOrDefault("X-Amz-Date")
  valid_773911 = validateParameter(valid_773911, JString, required = false,
                                 default = nil)
  if valid_773911 != nil:
    section.add "X-Amz-Date", valid_773911
  var valid_773912 = header.getOrDefault("X-Amz-Security-Token")
  valid_773912 = validateParameter(valid_773912, JString, required = false,
                                 default = nil)
  if valid_773912 != nil:
    section.add "X-Amz-Security-Token", valid_773912
  var valid_773913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773913 = validateParameter(valid_773913, JString, required = false,
                                 default = nil)
  if valid_773913 != nil:
    section.add "X-Amz-Content-Sha256", valid_773913
  var valid_773914 = header.getOrDefault("X-Amz-Algorithm")
  valid_773914 = validateParameter(valid_773914, JString, required = false,
                                 default = nil)
  if valid_773914 != nil:
    section.add "X-Amz-Algorithm", valid_773914
  var valid_773915 = header.getOrDefault("X-Amz-Signature")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "X-Amz-Signature", valid_773915
  var valid_773916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773916 = validateParameter(valid_773916, JString, required = false,
                                 default = nil)
  if valid_773916 != nil:
    section.add "X-Amz-SignedHeaders", valid_773916
  var valid_773917 = header.getOrDefault("X-Amz-Credential")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "X-Amz-Credential", valid_773917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773918: Call_GetDescribeTargetGroupAttributes_773905;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773918.validator(path, query, header, formData, body)
  let scheme = call_773918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773918.url(scheme.get, call_773918.host, call_773918.base,
                         call_773918.route, valid.getOrDefault("path"))
  result = hook(call_773918, url, valid)

proc call*(call_773919: Call_GetDescribeTargetGroupAttributes_773905;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773920 = newJObject()
  add(query_773920, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_773920, "Action", newJString(Action))
  add(query_773920, "Version", newJString(Version))
  result = call_773919.call(nil, query_773920, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_773905(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_773906, base: "/",
    url: url_GetDescribeTargetGroupAttributes_773907,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_773958 = ref object of OpenApiRestCall_772597
proc url_PostDescribeTargetGroups_773960(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTargetGroups_773959(path: JsonNode; query: JsonNode;
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
  var valid_773961 = query.getOrDefault("Action")
  valid_773961 = validateParameter(valid_773961, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_773961 != nil:
    section.add "Action", valid_773961
  var valid_773962 = query.getOrDefault("Version")
  valid_773962 = validateParameter(valid_773962, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773962 != nil:
    section.add "Version", valid_773962
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
  var valid_773963 = header.getOrDefault("X-Amz-Date")
  valid_773963 = validateParameter(valid_773963, JString, required = false,
                                 default = nil)
  if valid_773963 != nil:
    section.add "X-Amz-Date", valid_773963
  var valid_773964 = header.getOrDefault("X-Amz-Security-Token")
  valid_773964 = validateParameter(valid_773964, JString, required = false,
                                 default = nil)
  if valid_773964 != nil:
    section.add "X-Amz-Security-Token", valid_773964
  var valid_773965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "X-Amz-Content-Sha256", valid_773965
  var valid_773966 = header.getOrDefault("X-Amz-Algorithm")
  valid_773966 = validateParameter(valid_773966, JString, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "X-Amz-Algorithm", valid_773966
  var valid_773967 = header.getOrDefault("X-Amz-Signature")
  valid_773967 = validateParameter(valid_773967, JString, required = false,
                                 default = nil)
  if valid_773967 != nil:
    section.add "X-Amz-Signature", valid_773967
  var valid_773968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-SignedHeaders", valid_773968
  var valid_773969 = header.getOrDefault("X-Amz-Credential")
  valid_773969 = validateParameter(valid_773969, JString, required = false,
                                 default = nil)
  if valid_773969 != nil:
    section.add "X-Amz-Credential", valid_773969
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
  var valid_773970 = formData.getOrDefault("LoadBalancerArn")
  valid_773970 = validateParameter(valid_773970, JString, required = false,
                                 default = nil)
  if valid_773970 != nil:
    section.add "LoadBalancerArn", valid_773970
  var valid_773971 = formData.getOrDefault("TargetGroupArns")
  valid_773971 = validateParameter(valid_773971, JArray, required = false,
                                 default = nil)
  if valid_773971 != nil:
    section.add "TargetGroupArns", valid_773971
  var valid_773972 = formData.getOrDefault("Names")
  valid_773972 = validateParameter(valid_773972, JArray, required = false,
                                 default = nil)
  if valid_773972 != nil:
    section.add "Names", valid_773972
  var valid_773973 = formData.getOrDefault("Marker")
  valid_773973 = validateParameter(valid_773973, JString, required = false,
                                 default = nil)
  if valid_773973 != nil:
    section.add "Marker", valid_773973
  var valid_773974 = formData.getOrDefault("PageSize")
  valid_773974 = validateParameter(valid_773974, JInt, required = false, default = nil)
  if valid_773974 != nil:
    section.add "PageSize", valid_773974
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773975: Call_PostDescribeTargetGroups_773958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_773975.validator(path, query, header, formData, body)
  let scheme = call_773975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773975.url(scheme.get, call_773975.host, call_773975.base,
                         call_773975.route, valid.getOrDefault("path"))
  result = hook(call_773975, url, valid)

proc call*(call_773976: Call_PostDescribeTargetGroups_773958;
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
  var query_773977 = newJObject()
  var formData_773978 = newJObject()
  add(formData_773978, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    formData_773978.add "TargetGroupArns", TargetGroupArns
  if Names != nil:
    formData_773978.add "Names", Names
  add(formData_773978, "Marker", newJString(Marker))
  add(query_773977, "Action", newJString(Action))
  add(formData_773978, "PageSize", newJInt(PageSize))
  add(query_773977, "Version", newJString(Version))
  result = call_773976.call(nil, query_773977, nil, formData_773978, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_773958(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_773959, base: "/",
    url: url_PostDescribeTargetGroups_773960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_773938 = ref object of OpenApiRestCall_772597
proc url_GetDescribeTargetGroups_773940(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTargetGroups_773939(path: JsonNode; query: JsonNode;
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
  var valid_773941 = query.getOrDefault("Names")
  valid_773941 = validateParameter(valid_773941, JArray, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "Names", valid_773941
  var valid_773942 = query.getOrDefault("PageSize")
  valid_773942 = validateParameter(valid_773942, JInt, required = false, default = nil)
  if valid_773942 != nil:
    section.add "PageSize", valid_773942
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773943 = query.getOrDefault("Action")
  valid_773943 = validateParameter(valid_773943, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_773943 != nil:
    section.add "Action", valid_773943
  var valid_773944 = query.getOrDefault("Marker")
  valid_773944 = validateParameter(valid_773944, JString, required = false,
                                 default = nil)
  if valid_773944 != nil:
    section.add "Marker", valid_773944
  var valid_773945 = query.getOrDefault("LoadBalancerArn")
  valid_773945 = validateParameter(valid_773945, JString, required = false,
                                 default = nil)
  if valid_773945 != nil:
    section.add "LoadBalancerArn", valid_773945
  var valid_773946 = query.getOrDefault("TargetGroupArns")
  valid_773946 = validateParameter(valid_773946, JArray, required = false,
                                 default = nil)
  if valid_773946 != nil:
    section.add "TargetGroupArns", valid_773946
  var valid_773947 = query.getOrDefault("Version")
  valid_773947 = validateParameter(valid_773947, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773947 != nil:
    section.add "Version", valid_773947
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
  var valid_773948 = header.getOrDefault("X-Amz-Date")
  valid_773948 = validateParameter(valid_773948, JString, required = false,
                                 default = nil)
  if valid_773948 != nil:
    section.add "X-Amz-Date", valid_773948
  var valid_773949 = header.getOrDefault("X-Amz-Security-Token")
  valid_773949 = validateParameter(valid_773949, JString, required = false,
                                 default = nil)
  if valid_773949 != nil:
    section.add "X-Amz-Security-Token", valid_773949
  var valid_773950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773950 = validateParameter(valid_773950, JString, required = false,
                                 default = nil)
  if valid_773950 != nil:
    section.add "X-Amz-Content-Sha256", valid_773950
  var valid_773951 = header.getOrDefault("X-Amz-Algorithm")
  valid_773951 = validateParameter(valid_773951, JString, required = false,
                                 default = nil)
  if valid_773951 != nil:
    section.add "X-Amz-Algorithm", valid_773951
  var valid_773952 = header.getOrDefault("X-Amz-Signature")
  valid_773952 = validateParameter(valid_773952, JString, required = false,
                                 default = nil)
  if valid_773952 != nil:
    section.add "X-Amz-Signature", valid_773952
  var valid_773953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773953 = validateParameter(valid_773953, JString, required = false,
                                 default = nil)
  if valid_773953 != nil:
    section.add "X-Amz-SignedHeaders", valid_773953
  var valid_773954 = header.getOrDefault("X-Amz-Credential")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "X-Amz-Credential", valid_773954
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773955: Call_GetDescribeTargetGroups_773938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_773955.validator(path, query, header, formData, body)
  let scheme = call_773955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773955.url(scheme.get, call_773955.host, call_773955.base,
                         call_773955.route, valid.getOrDefault("path"))
  result = hook(call_773955, url, valid)

proc call*(call_773956: Call_GetDescribeTargetGroups_773938; Names: JsonNode = nil;
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
  var query_773957 = newJObject()
  if Names != nil:
    query_773957.add "Names", Names
  add(query_773957, "PageSize", newJInt(PageSize))
  add(query_773957, "Action", newJString(Action))
  add(query_773957, "Marker", newJString(Marker))
  add(query_773957, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    query_773957.add "TargetGroupArns", TargetGroupArns
  add(query_773957, "Version", newJString(Version))
  result = call_773956.call(nil, query_773957, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_773938(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_773939, base: "/",
    url: url_GetDescribeTargetGroups_773940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_773996 = ref object of OpenApiRestCall_772597
proc url_PostDescribeTargetHealth_773998(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTargetHealth_773997(path: JsonNode; query: JsonNode;
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
  var valid_773999 = query.getOrDefault("Action")
  valid_773999 = validateParameter(valid_773999, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_773999 != nil:
    section.add "Action", valid_773999
  var valid_774000 = query.getOrDefault("Version")
  valid_774000 = validateParameter(valid_774000, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774000 != nil:
    section.add "Version", valid_774000
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
  var valid_774001 = header.getOrDefault("X-Amz-Date")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-Date", valid_774001
  var valid_774002 = header.getOrDefault("X-Amz-Security-Token")
  valid_774002 = validateParameter(valid_774002, JString, required = false,
                                 default = nil)
  if valid_774002 != nil:
    section.add "X-Amz-Security-Token", valid_774002
  var valid_774003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774003 = validateParameter(valid_774003, JString, required = false,
                                 default = nil)
  if valid_774003 != nil:
    section.add "X-Amz-Content-Sha256", valid_774003
  var valid_774004 = header.getOrDefault("X-Amz-Algorithm")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Algorithm", valid_774004
  var valid_774005 = header.getOrDefault("X-Amz-Signature")
  valid_774005 = validateParameter(valid_774005, JString, required = false,
                                 default = nil)
  if valid_774005 != nil:
    section.add "X-Amz-Signature", valid_774005
  var valid_774006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "X-Amz-SignedHeaders", valid_774006
  var valid_774007 = header.getOrDefault("X-Amz-Credential")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "X-Amz-Credential", valid_774007
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_774008 = formData.getOrDefault("Targets")
  valid_774008 = validateParameter(valid_774008, JArray, required = false,
                                 default = nil)
  if valid_774008 != nil:
    section.add "Targets", valid_774008
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_774009 = formData.getOrDefault("TargetGroupArn")
  valid_774009 = validateParameter(valid_774009, JString, required = true,
                                 default = nil)
  if valid_774009 != nil:
    section.add "TargetGroupArn", valid_774009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774010: Call_PostDescribeTargetHealth_773996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_774010.validator(path, query, header, formData, body)
  let scheme = call_774010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774010.url(scheme.get, call_774010.host, call_774010.base,
                         call_774010.route, valid.getOrDefault("path"))
  result = hook(call_774010, url, valid)

proc call*(call_774011: Call_PostDescribeTargetHealth_773996;
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
  var query_774012 = newJObject()
  var formData_774013 = newJObject()
  if Targets != nil:
    formData_774013.add "Targets", Targets
  add(query_774012, "Action", newJString(Action))
  add(formData_774013, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_774012, "Version", newJString(Version))
  result = call_774011.call(nil, query_774012, nil, formData_774013, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_773996(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_773997, base: "/",
    url: url_PostDescribeTargetHealth_773998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_773979 = ref object of OpenApiRestCall_772597
proc url_GetDescribeTargetHealth_773981(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTargetHealth_773980(path: JsonNode; query: JsonNode;
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
  var valid_773982 = query.getOrDefault("Targets")
  valid_773982 = validateParameter(valid_773982, JArray, required = false,
                                 default = nil)
  if valid_773982 != nil:
    section.add "Targets", valid_773982
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_773983 = query.getOrDefault("TargetGroupArn")
  valid_773983 = validateParameter(valid_773983, JString, required = true,
                                 default = nil)
  if valid_773983 != nil:
    section.add "TargetGroupArn", valid_773983
  var valid_773984 = query.getOrDefault("Action")
  valid_773984 = validateParameter(valid_773984, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_773984 != nil:
    section.add "Action", valid_773984
  var valid_773985 = query.getOrDefault("Version")
  valid_773985 = validateParameter(valid_773985, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_773985 != nil:
    section.add "Version", valid_773985
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
  var valid_773986 = header.getOrDefault("X-Amz-Date")
  valid_773986 = validateParameter(valid_773986, JString, required = false,
                                 default = nil)
  if valid_773986 != nil:
    section.add "X-Amz-Date", valid_773986
  var valid_773987 = header.getOrDefault("X-Amz-Security-Token")
  valid_773987 = validateParameter(valid_773987, JString, required = false,
                                 default = nil)
  if valid_773987 != nil:
    section.add "X-Amz-Security-Token", valid_773987
  var valid_773988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773988 = validateParameter(valid_773988, JString, required = false,
                                 default = nil)
  if valid_773988 != nil:
    section.add "X-Amz-Content-Sha256", valid_773988
  var valid_773989 = header.getOrDefault("X-Amz-Algorithm")
  valid_773989 = validateParameter(valid_773989, JString, required = false,
                                 default = nil)
  if valid_773989 != nil:
    section.add "X-Amz-Algorithm", valid_773989
  var valid_773990 = header.getOrDefault("X-Amz-Signature")
  valid_773990 = validateParameter(valid_773990, JString, required = false,
                                 default = nil)
  if valid_773990 != nil:
    section.add "X-Amz-Signature", valid_773990
  var valid_773991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "X-Amz-SignedHeaders", valid_773991
  var valid_773992 = header.getOrDefault("X-Amz-Credential")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-Credential", valid_773992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773993: Call_GetDescribeTargetHealth_773979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_773993.validator(path, query, header, formData, body)
  let scheme = call_773993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773993.url(scheme.get, call_773993.host, call_773993.base,
                         call_773993.route, valid.getOrDefault("path"))
  result = hook(call_773993, url, valid)

proc call*(call_773994: Call_GetDescribeTargetHealth_773979;
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
  var query_773995 = newJObject()
  if Targets != nil:
    query_773995.add "Targets", Targets
  add(query_773995, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_773995, "Action", newJString(Action))
  add(query_773995, "Version", newJString(Version))
  result = call_773994.call(nil, query_773995, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_773979(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_773980, base: "/",
    url: url_GetDescribeTargetHealth_773981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_774035 = ref object of OpenApiRestCall_772597
proc url_PostModifyListener_774037(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyListener_774036(path: JsonNode; query: JsonNode;
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
  var valid_774038 = query.getOrDefault("Action")
  valid_774038 = validateParameter(valid_774038, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_774038 != nil:
    section.add "Action", valid_774038
  var valid_774039 = query.getOrDefault("Version")
  valid_774039 = validateParameter(valid_774039, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774039 != nil:
    section.add "Version", valid_774039
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
  var valid_774040 = header.getOrDefault("X-Amz-Date")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Date", valid_774040
  var valid_774041 = header.getOrDefault("X-Amz-Security-Token")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Security-Token", valid_774041
  var valid_774042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774042 = validateParameter(valid_774042, JString, required = false,
                                 default = nil)
  if valid_774042 != nil:
    section.add "X-Amz-Content-Sha256", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-Algorithm")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-Algorithm", valid_774043
  var valid_774044 = header.getOrDefault("X-Amz-Signature")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "X-Amz-Signature", valid_774044
  var valid_774045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "X-Amz-SignedHeaders", valid_774045
  var valid_774046 = header.getOrDefault("X-Amz-Credential")
  valid_774046 = validateParameter(valid_774046, JString, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "X-Amz-Credential", valid_774046
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
  var valid_774047 = formData.getOrDefault("Certificates")
  valid_774047 = validateParameter(valid_774047, JArray, required = false,
                                 default = nil)
  if valid_774047 != nil:
    section.add "Certificates", valid_774047
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_774048 = formData.getOrDefault("ListenerArn")
  valid_774048 = validateParameter(valid_774048, JString, required = true,
                                 default = nil)
  if valid_774048 != nil:
    section.add "ListenerArn", valid_774048
  var valid_774049 = formData.getOrDefault("Port")
  valid_774049 = validateParameter(valid_774049, JInt, required = false, default = nil)
  if valid_774049 != nil:
    section.add "Port", valid_774049
  var valid_774050 = formData.getOrDefault("Protocol")
  valid_774050 = validateParameter(valid_774050, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_774050 != nil:
    section.add "Protocol", valid_774050
  var valid_774051 = formData.getOrDefault("SslPolicy")
  valid_774051 = validateParameter(valid_774051, JString, required = false,
                                 default = nil)
  if valid_774051 != nil:
    section.add "SslPolicy", valid_774051
  var valid_774052 = formData.getOrDefault("DefaultActions")
  valid_774052 = validateParameter(valid_774052, JArray, required = false,
                                 default = nil)
  if valid_774052 != nil:
    section.add "DefaultActions", valid_774052
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774053: Call_PostModifyListener_774035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_774053.validator(path, query, header, formData, body)
  let scheme = call_774053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774053.url(scheme.get, call_774053.host, call_774053.base,
                         call_774053.route, valid.getOrDefault("path"))
  result = hook(call_774053, url, valid)

proc call*(call_774054: Call_PostModifyListener_774035; ListenerArn: string;
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
  var query_774055 = newJObject()
  var formData_774056 = newJObject()
  if Certificates != nil:
    formData_774056.add "Certificates", Certificates
  add(formData_774056, "ListenerArn", newJString(ListenerArn))
  add(formData_774056, "Port", newJInt(Port))
  add(formData_774056, "Protocol", newJString(Protocol))
  add(query_774055, "Action", newJString(Action))
  add(formData_774056, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_774056.add "DefaultActions", DefaultActions
  add(query_774055, "Version", newJString(Version))
  result = call_774054.call(nil, query_774055, nil, formData_774056, nil)

var postModifyListener* = Call_PostModifyListener_774035(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_774036, base: "/",
    url: url_PostModifyListener_774037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_774014 = ref object of OpenApiRestCall_772597
proc url_GetModifyListener_774016(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyListener_774015(path: JsonNode; query: JsonNode;
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
  var valid_774017 = query.getOrDefault("DefaultActions")
  valid_774017 = validateParameter(valid_774017, JArray, required = false,
                                 default = nil)
  if valid_774017 != nil:
    section.add "DefaultActions", valid_774017
  var valid_774018 = query.getOrDefault("SslPolicy")
  valid_774018 = validateParameter(valid_774018, JString, required = false,
                                 default = nil)
  if valid_774018 != nil:
    section.add "SslPolicy", valid_774018
  var valid_774019 = query.getOrDefault("Protocol")
  valid_774019 = validateParameter(valid_774019, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_774019 != nil:
    section.add "Protocol", valid_774019
  var valid_774020 = query.getOrDefault("Certificates")
  valid_774020 = validateParameter(valid_774020, JArray, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "Certificates", valid_774020
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774021 = query.getOrDefault("Action")
  valid_774021 = validateParameter(valid_774021, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_774021 != nil:
    section.add "Action", valid_774021
  var valid_774022 = query.getOrDefault("ListenerArn")
  valid_774022 = validateParameter(valid_774022, JString, required = true,
                                 default = nil)
  if valid_774022 != nil:
    section.add "ListenerArn", valid_774022
  var valid_774023 = query.getOrDefault("Port")
  valid_774023 = validateParameter(valid_774023, JInt, required = false, default = nil)
  if valid_774023 != nil:
    section.add "Port", valid_774023
  var valid_774024 = query.getOrDefault("Version")
  valid_774024 = validateParameter(valid_774024, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774024 != nil:
    section.add "Version", valid_774024
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
  var valid_774025 = header.getOrDefault("X-Amz-Date")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "X-Amz-Date", valid_774025
  var valid_774026 = header.getOrDefault("X-Amz-Security-Token")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Security-Token", valid_774026
  var valid_774027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-Content-Sha256", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-Algorithm")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-Algorithm", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-Signature")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-Signature", valid_774029
  var valid_774030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774030 = validateParameter(valid_774030, JString, required = false,
                                 default = nil)
  if valid_774030 != nil:
    section.add "X-Amz-SignedHeaders", valid_774030
  var valid_774031 = header.getOrDefault("X-Amz-Credential")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "X-Amz-Credential", valid_774031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774032: Call_GetModifyListener_774014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_774032.validator(path, query, header, formData, body)
  let scheme = call_774032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774032.url(scheme.get, call_774032.host, call_774032.base,
                         call_774032.route, valid.getOrDefault("path"))
  result = hook(call_774032, url, valid)

proc call*(call_774033: Call_GetModifyListener_774014; ListenerArn: string;
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
  var query_774034 = newJObject()
  if DefaultActions != nil:
    query_774034.add "DefaultActions", DefaultActions
  add(query_774034, "SslPolicy", newJString(SslPolicy))
  add(query_774034, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_774034.add "Certificates", Certificates
  add(query_774034, "Action", newJString(Action))
  add(query_774034, "ListenerArn", newJString(ListenerArn))
  add(query_774034, "Port", newJInt(Port))
  add(query_774034, "Version", newJString(Version))
  result = call_774033.call(nil, query_774034, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_774014(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_774015,
    base: "/", url: url_GetModifyListener_774016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_774074 = ref object of OpenApiRestCall_772597
proc url_PostModifyLoadBalancerAttributes_774076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyLoadBalancerAttributes_774075(path: JsonNode;
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
  var valid_774077 = query.getOrDefault("Action")
  valid_774077 = validateParameter(valid_774077, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_774077 != nil:
    section.add "Action", valid_774077
  var valid_774078 = query.getOrDefault("Version")
  valid_774078 = validateParameter(valid_774078, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774078 != nil:
    section.add "Version", valid_774078
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
  var valid_774079 = header.getOrDefault("X-Amz-Date")
  valid_774079 = validateParameter(valid_774079, JString, required = false,
                                 default = nil)
  if valid_774079 != nil:
    section.add "X-Amz-Date", valid_774079
  var valid_774080 = header.getOrDefault("X-Amz-Security-Token")
  valid_774080 = validateParameter(valid_774080, JString, required = false,
                                 default = nil)
  if valid_774080 != nil:
    section.add "X-Amz-Security-Token", valid_774080
  var valid_774081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774081 = validateParameter(valid_774081, JString, required = false,
                                 default = nil)
  if valid_774081 != nil:
    section.add "X-Amz-Content-Sha256", valid_774081
  var valid_774082 = header.getOrDefault("X-Amz-Algorithm")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "X-Amz-Algorithm", valid_774082
  var valid_774083 = header.getOrDefault("X-Amz-Signature")
  valid_774083 = validateParameter(valid_774083, JString, required = false,
                                 default = nil)
  if valid_774083 != nil:
    section.add "X-Amz-Signature", valid_774083
  var valid_774084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774084 = validateParameter(valid_774084, JString, required = false,
                                 default = nil)
  if valid_774084 != nil:
    section.add "X-Amz-SignedHeaders", valid_774084
  var valid_774085 = header.getOrDefault("X-Amz-Credential")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = nil)
  if valid_774085 != nil:
    section.add "X-Amz-Credential", valid_774085
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_774086 = formData.getOrDefault("LoadBalancerArn")
  valid_774086 = validateParameter(valid_774086, JString, required = true,
                                 default = nil)
  if valid_774086 != nil:
    section.add "LoadBalancerArn", valid_774086
  var valid_774087 = formData.getOrDefault("Attributes")
  valid_774087 = validateParameter(valid_774087, JArray, required = true, default = nil)
  if valid_774087 != nil:
    section.add "Attributes", valid_774087
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774088: Call_PostModifyLoadBalancerAttributes_774074;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_774088.validator(path, query, header, formData, body)
  let scheme = call_774088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774088.url(scheme.get, call_774088.host, call_774088.base,
                         call_774088.route, valid.getOrDefault("path"))
  result = hook(call_774088, url, valid)

proc call*(call_774089: Call_PostModifyLoadBalancerAttributes_774074;
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
  var query_774090 = newJObject()
  var formData_774091 = newJObject()
  add(formData_774091, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    formData_774091.add "Attributes", Attributes
  add(query_774090, "Action", newJString(Action))
  add(query_774090, "Version", newJString(Version))
  result = call_774089.call(nil, query_774090, nil, formData_774091, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_774074(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_774075, base: "/",
    url: url_PostModifyLoadBalancerAttributes_774076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_774057 = ref object of OpenApiRestCall_772597
proc url_GetModifyLoadBalancerAttributes_774059(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyLoadBalancerAttributes_774058(path: JsonNode;
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
  var valid_774060 = query.getOrDefault("Attributes")
  valid_774060 = validateParameter(valid_774060, JArray, required = true, default = nil)
  if valid_774060 != nil:
    section.add "Attributes", valid_774060
  var valid_774061 = query.getOrDefault("Action")
  valid_774061 = validateParameter(valid_774061, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_774061 != nil:
    section.add "Action", valid_774061
  var valid_774062 = query.getOrDefault("LoadBalancerArn")
  valid_774062 = validateParameter(valid_774062, JString, required = true,
                                 default = nil)
  if valid_774062 != nil:
    section.add "LoadBalancerArn", valid_774062
  var valid_774063 = query.getOrDefault("Version")
  valid_774063 = validateParameter(valid_774063, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774063 != nil:
    section.add "Version", valid_774063
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
  var valid_774064 = header.getOrDefault("X-Amz-Date")
  valid_774064 = validateParameter(valid_774064, JString, required = false,
                                 default = nil)
  if valid_774064 != nil:
    section.add "X-Amz-Date", valid_774064
  var valid_774065 = header.getOrDefault("X-Amz-Security-Token")
  valid_774065 = validateParameter(valid_774065, JString, required = false,
                                 default = nil)
  if valid_774065 != nil:
    section.add "X-Amz-Security-Token", valid_774065
  var valid_774066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774066 = validateParameter(valid_774066, JString, required = false,
                                 default = nil)
  if valid_774066 != nil:
    section.add "X-Amz-Content-Sha256", valid_774066
  var valid_774067 = header.getOrDefault("X-Amz-Algorithm")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "X-Amz-Algorithm", valid_774067
  var valid_774068 = header.getOrDefault("X-Amz-Signature")
  valid_774068 = validateParameter(valid_774068, JString, required = false,
                                 default = nil)
  if valid_774068 != nil:
    section.add "X-Amz-Signature", valid_774068
  var valid_774069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774069 = validateParameter(valid_774069, JString, required = false,
                                 default = nil)
  if valid_774069 != nil:
    section.add "X-Amz-SignedHeaders", valid_774069
  var valid_774070 = header.getOrDefault("X-Amz-Credential")
  valid_774070 = validateParameter(valid_774070, JString, required = false,
                                 default = nil)
  if valid_774070 != nil:
    section.add "X-Amz-Credential", valid_774070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774071: Call_GetModifyLoadBalancerAttributes_774057;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_774071.validator(path, query, header, formData, body)
  let scheme = call_774071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774071.url(scheme.get, call_774071.host, call_774071.base,
                         call_774071.route, valid.getOrDefault("path"))
  result = hook(call_774071, url, valid)

proc call*(call_774072: Call_GetModifyLoadBalancerAttributes_774057;
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
  var query_774073 = newJObject()
  if Attributes != nil:
    query_774073.add "Attributes", Attributes
  add(query_774073, "Action", newJString(Action))
  add(query_774073, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_774073, "Version", newJString(Version))
  result = call_774072.call(nil, query_774073, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_774057(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_774058, base: "/",
    url: url_GetModifyLoadBalancerAttributes_774059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_774110 = ref object of OpenApiRestCall_772597
proc url_PostModifyRule_774112(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyRule_774111(path: JsonNode; query: JsonNode;
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
  var valid_774113 = query.getOrDefault("Action")
  valid_774113 = validateParameter(valid_774113, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_774113 != nil:
    section.add "Action", valid_774113
  var valid_774114 = query.getOrDefault("Version")
  valid_774114 = validateParameter(valid_774114, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774114 != nil:
    section.add "Version", valid_774114
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
  var valid_774115 = header.getOrDefault("X-Amz-Date")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Date", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Security-Token")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Security-Token", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-Content-Sha256", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-Algorithm")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-Algorithm", valid_774118
  var valid_774119 = header.getOrDefault("X-Amz-Signature")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Signature", valid_774119
  var valid_774120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774120 = validateParameter(valid_774120, JString, required = false,
                                 default = nil)
  if valid_774120 != nil:
    section.add "X-Amz-SignedHeaders", valid_774120
  var valid_774121 = header.getOrDefault("X-Amz-Credential")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "X-Amz-Credential", valid_774121
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
  var valid_774122 = formData.getOrDefault("RuleArn")
  valid_774122 = validateParameter(valid_774122, JString, required = true,
                                 default = nil)
  if valid_774122 != nil:
    section.add "RuleArn", valid_774122
  var valid_774123 = formData.getOrDefault("Actions")
  valid_774123 = validateParameter(valid_774123, JArray, required = false,
                                 default = nil)
  if valid_774123 != nil:
    section.add "Actions", valid_774123
  var valid_774124 = formData.getOrDefault("Conditions")
  valid_774124 = validateParameter(valid_774124, JArray, required = false,
                                 default = nil)
  if valid_774124 != nil:
    section.add "Conditions", valid_774124
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774125: Call_PostModifyRule_774110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_774125.validator(path, query, header, formData, body)
  let scheme = call_774125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774125.url(scheme.get, call_774125.host, call_774125.base,
                         call_774125.route, valid.getOrDefault("path"))
  result = hook(call_774125, url, valid)

proc call*(call_774126: Call_PostModifyRule_774110; RuleArn: string;
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
  var query_774127 = newJObject()
  var formData_774128 = newJObject()
  add(formData_774128, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    formData_774128.add "Actions", Actions
  if Conditions != nil:
    formData_774128.add "Conditions", Conditions
  add(query_774127, "Action", newJString(Action))
  add(query_774127, "Version", newJString(Version))
  result = call_774126.call(nil, query_774127, nil, formData_774128, nil)

var postModifyRule* = Call_PostModifyRule_774110(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_774111,
    base: "/", url: url_PostModifyRule_774112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_774092 = ref object of OpenApiRestCall_772597
proc url_GetModifyRule_774094(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyRule_774093(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774095 = query.getOrDefault("Conditions")
  valid_774095 = validateParameter(valid_774095, JArray, required = false,
                                 default = nil)
  if valid_774095 != nil:
    section.add "Conditions", valid_774095
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774096 = query.getOrDefault("Action")
  valid_774096 = validateParameter(valid_774096, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_774096 != nil:
    section.add "Action", valid_774096
  var valid_774097 = query.getOrDefault("RuleArn")
  valid_774097 = validateParameter(valid_774097, JString, required = true,
                                 default = nil)
  if valid_774097 != nil:
    section.add "RuleArn", valid_774097
  var valid_774098 = query.getOrDefault("Actions")
  valid_774098 = validateParameter(valid_774098, JArray, required = false,
                                 default = nil)
  if valid_774098 != nil:
    section.add "Actions", valid_774098
  var valid_774099 = query.getOrDefault("Version")
  valid_774099 = validateParameter(valid_774099, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774099 != nil:
    section.add "Version", valid_774099
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
  var valid_774100 = header.getOrDefault("X-Amz-Date")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-Date", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Security-Token")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Security-Token", valid_774101
  var valid_774102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774102 = validateParameter(valid_774102, JString, required = false,
                                 default = nil)
  if valid_774102 != nil:
    section.add "X-Amz-Content-Sha256", valid_774102
  var valid_774103 = header.getOrDefault("X-Amz-Algorithm")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "X-Amz-Algorithm", valid_774103
  var valid_774104 = header.getOrDefault("X-Amz-Signature")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "X-Amz-Signature", valid_774104
  var valid_774105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774105 = validateParameter(valid_774105, JString, required = false,
                                 default = nil)
  if valid_774105 != nil:
    section.add "X-Amz-SignedHeaders", valid_774105
  var valid_774106 = header.getOrDefault("X-Amz-Credential")
  valid_774106 = validateParameter(valid_774106, JString, required = false,
                                 default = nil)
  if valid_774106 != nil:
    section.add "X-Amz-Credential", valid_774106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774107: Call_GetModifyRule_774092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_774107.validator(path, query, header, formData, body)
  let scheme = call_774107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774107.url(scheme.get, call_774107.host, call_774107.base,
                         call_774107.route, valid.getOrDefault("path"))
  result = hook(call_774107, url, valid)

proc call*(call_774108: Call_GetModifyRule_774092; RuleArn: string;
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
  var query_774109 = newJObject()
  if Conditions != nil:
    query_774109.add "Conditions", Conditions
  add(query_774109, "Action", newJString(Action))
  add(query_774109, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_774109.add "Actions", Actions
  add(query_774109, "Version", newJString(Version))
  result = call_774108.call(nil, query_774109, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_774092(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_774093,
    base: "/", url: url_GetModifyRule_774094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_774154 = ref object of OpenApiRestCall_772597
proc url_PostModifyTargetGroup_774156(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyTargetGroup_774155(path: JsonNode; query: JsonNode;
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
  var valid_774157 = query.getOrDefault("Action")
  valid_774157 = validateParameter(valid_774157, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_774157 != nil:
    section.add "Action", valid_774157
  var valid_774158 = query.getOrDefault("Version")
  valid_774158 = validateParameter(valid_774158, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774158 != nil:
    section.add "Version", valid_774158
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
  var valid_774159 = header.getOrDefault("X-Amz-Date")
  valid_774159 = validateParameter(valid_774159, JString, required = false,
                                 default = nil)
  if valid_774159 != nil:
    section.add "X-Amz-Date", valid_774159
  var valid_774160 = header.getOrDefault("X-Amz-Security-Token")
  valid_774160 = validateParameter(valid_774160, JString, required = false,
                                 default = nil)
  if valid_774160 != nil:
    section.add "X-Amz-Security-Token", valid_774160
  var valid_774161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774161 = validateParameter(valid_774161, JString, required = false,
                                 default = nil)
  if valid_774161 != nil:
    section.add "X-Amz-Content-Sha256", valid_774161
  var valid_774162 = header.getOrDefault("X-Amz-Algorithm")
  valid_774162 = validateParameter(valid_774162, JString, required = false,
                                 default = nil)
  if valid_774162 != nil:
    section.add "X-Amz-Algorithm", valid_774162
  var valid_774163 = header.getOrDefault("X-Amz-Signature")
  valid_774163 = validateParameter(valid_774163, JString, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "X-Amz-Signature", valid_774163
  var valid_774164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "X-Amz-SignedHeaders", valid_774164
  var valid_774165 = header.getOrDefault("X-Amz-Credential")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = nil)
  if valid_774165 != nil:
    section.add "X-Amz-Credential", valid_774165
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
  var valid_774166 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_774166 = validateParameter(valid_774166, JInt, required = false, default = nil)
  if valid_774166 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_774166
  var valid_774167 = formData.getOrDefault("HealthCheckPort")
  valid_774167 = validateParameter(valid_774167, JString, required = false,
                                 default = nil)
  if valid_774167 != nil:
    section.add "HealthCheckPort", valid_774167
  var valid_774168 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_774168 = validateParameter(valid_774168, JInt, required = false, default = nil)
  if valid_774168 != nil:
    section.add "UnhealthyThresholdCount", valid_774168
  var valid_774169 = formData.getOrDefault("HealthCheckPath")
  valid_774169 = validateParameter(valid_774169, JString, required = false,
                                 default = nil)
  if valid_774169 != nil:
    section.add "HealthCheckPath", valid_774169
  var valid_774170 = formData.getOrDefault("HealthCheckEnabled")
  valid_774170 = validateParameter(valid_774170, JBool, required = false, default = nil)
  if valid_774170 != nil:
    section.add "HealthCheckEnabled", valid_774170
  var valid_774171 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_774171 = validateParameter(valid_774171, JInt, required = false, default = nil)
  if valid_774171 != nil:
    section.add "HealthCheckIntervalSeconds", valid_774171
  var valid_774172 = formData.getOrDefault("HealthyThresholdCount")
  valid_774172 = validateParameter(valid_774172, JInt, required = false, default = nil)
  if valid_774172 != nil:
    section.add "HealthyThresholdCount", valid_774172
  var valid_774173 = formData.getOrDefault("HealthCheckProtocol")
  valid_774173 = validateParameter(valid_774173, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_774173 != nil:
    section.add "HealthCheckProtocol", valid_774173
  var valid_774174 = formData.getOrDefault("Matcher.HttpCode")
  valid_774174 = validateParameter(valid_774174, JString, required = false,
                                 default = nil)
  if valid_774174 != nil:
    section.add "Matcher.HttpCode", valid_774174
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_774175 = formData.getOrDefault("TargetGroupArn")
  valid_774175 = validateParameter(valid_774175, JString, required = true,
                                 default = nil)
  if valid_774175 != nil:
    section.add "TargetGroupArn", valid_774175
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774176: Call_PostModifyTargetGroup_774154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_774176.validator(path, query, header, formData, body)
  let scheme = call_774176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774176.url(scheme.get, call_774176.host, call_774176.base,
                         call_774176.route, valid.getOrDefault("path"))
  result = hook(call_774176, url, valid)

proc call*(call_774177: Call_PostModifyTargetGroup_774154; TargetGroupArn: string;
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
  var query_774178 = newJObject()
  var formData_774179 = newJObject()
  add(formData_774179, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_774179, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_774179, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_774179, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_774179, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_774178, "Action", newJString(Action))
  add(formData_774179, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_774179, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_774179, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_774179, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(formData_774179, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_774178, "Version", newJString(Version))
  result = call_774177.call(nil, query_774178, nil, formData_774179, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_774154(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_774155, base: "/",
    url: url_PostModifyTargetGroup_774156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_774129 = ref object of OpenApiRestCall_772597
proc url_GetModifyTargetGroup_774131(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyTargetGroup_774130(path: JsonNode; query: JsonNode;
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
  var valid_774132 = query.getOrDefault("HealthCheckEnabled")
  valid_774132 = validateParameter(valid_774132, JBool, required = false, default = nil)
  if valid_774132 != nil:
    section.add "HealthCheckEnabled", valid_774132
  var valid_774133 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_774133 = validateParameter(valid_774133, JInt, required = false, default = nil)
  if valid_774133 != nil:
    section.add "HealthCheckIntervalSeconds", valid_774133
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_774134 = query.getOrDefault("TargetGroupArn")
  valid_774134 = validateParameter(valid_774134, JString, required = true,
                                 default = nil)
  if valid_774134 != nil:
    section.add "TargetGroupArn", valid_774134
  var valid_774135 = query.getOrDefault("HealthCheckPort")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "HealthCheckPort", valid_774135
  var valid_774136 = query.getOrDefault("Action")
  valid_774136 = validateParameter(valid_774136, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_774136 != nil:
    section.add "Action", valid_774136
  var valid_774137 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_774137 = validateParameter(valid_774137, JInt, required = false, default = nil)
  if valid_774137 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_774137
  var valid_774138 = query.getOrDefault("Matcher.HttpCode")
  valid_774138 = validateParameter(valid_774138, JString, required = false,
                                 default = nil)
  if valid_774138 != nil:
    section.add "Matcher.HttpCode", valid_774138
  var valid_774139 = query.getOrDefault("UnhealthyThresholdCount")
  valid_774139 = validateParameter(valid_774139, JInt, required = false, default = nil)
  if valid_774139 != nil:
    section.add "UnhealthyThresholdCount", valid_774139
  var valid_774140 = query.getOrDefault("HealthCheckProtocol")
  valid_774140 = validateParameter(valid_774140, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_774140 != nil:
    section.add "HealthCheckProtocol", valid_774140
  var valid_774141 = query.getOrDefault("HealthyThresholdCount")
  valid_774141 = validateParameter(valid_774141, JInt, required = false, default = nil)
  if valid_774141 != nil:
    section.add "HealthyThresholdCount", valid_774141
  var valid_774142 = query.getOrDefault("Version")
  valid_774142 = validateParameter(valid_774142, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774142 != nil:
    section.add "Version", valid_774142
  var valid_774143 = query.getOrDefault("HealthCheckPath")
  valid_774143 = validateParameter(valid_774143, JString, required = false,
                                 default = nil)
  if valid_774143 != nil:
    section.add "HealthCheckPath", valid_774143
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
  var valid_774144 = header.getOrDefault("X-Amz-Date")
  valid_774144 = validateParameter(valid_774144, JString, required = false,
                                 default = nil)
  if valid_774144 != nil:
    section.add "X-Amz-Date", valid_774144
  var valid_774145 = header.getOrDefault("X-Amz-Security-Token")
  valid_774145 = validateParameter(valid_774145, JString, required = false,
                                 default = nil)
  if valid_774145 != nil:
    section.add "X-Amz-Security-Token", valid_774145
  var valid_774146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774146 = validateParameter(valid_774146, JString, required = false,
                                 default = nil)
  if valid_774146 != nil:
    section.add "X-Amz-Content-Sha256", valid_774146
  var valid_774147 = header.getOrDefault("X-Amz-Algorithm")
  valid_774147 = validateParameter(valid_774147, JString, required = false,
                                 default = nil)
  if valid_774147 != nil:
    section.add "X-Amz-Algorithm", valid_774147
  var valid_774148 = header.getOrDefault("X-Amz-Signature")
  valid_774148 = validateParameter(valid_774148, JString, required = false,
                                 default = nil)
  if valid_774148 != nil:
    section.add "X-Amz-Signature", valid_774148
  var valid_774149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "X-Amz-SignedHeaders", valid_774149
  var valid_774150 = header.getOrDefault("X-Amz-Credential")
  valid_774150 = validateParameter(valid_774150, JString, required = false,
                                 default = nil)
  if valid_774150 != nil:
    section.add "X-Amz-Credential", valid_774150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774151: Call_GetModifyTargetGroup_774129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_774151.validator(path, query, header, formData, body)
  let scheme = call_774151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774151.url(scheme.get, call_774151.host, call_774151.base,
                         call_774151.route, valid.getOrDefault("path"))
  result = hook(call_774151, url, valid)

proc call*(call_774152: Call_GetModifyTargetGroup_774129; TargetGroupArn: string;
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
  var query_774153 = newJObject()
  add(query_774153, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_774153, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_774153, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_774153, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_774153, "Action", newJString(Action))
  add(query_774153, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_774153, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_774153, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_774153, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_774153, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_774153, "Version", newJString(Version))
  add(query_774153, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_774152.call(nil, query_774153, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_774129(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_774130,
    base: "/", url: url_GetModifyTargetGroup_774131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_774197 = ref object of OpenApiRestCall_772597
proc url_PostModifyTargetGroupAttributes_774199(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyTargetGroupAttributes_774198(path: JsonNode;
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
  var valid_774200 = query.getOrDefault("Action")
  valid_774200 = validateParameter(valid_774200, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_774200 != nil:
    section.add "Action", valid_774200
  var valid_774201 = query.getOrDefault("Version")
  valid_774201 = validateParameter(valid_774201, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774201 != nil:
    section.add "Version", valid_774201
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
  var valid_774202 = header.getOrDefault("X-Amz-Date")
  valid_774202 = validateParameter(valid_774202, JString, required = false,
                                 default = nil)
  if valid_774202 != nil:
    section.add "X-Amz-Date", valid_774202
  var valid_774203 = header.getOrDefault("X-Amz-Security-Token")
  valid_774203 = validateParameter(valid_774203, JString, required = false,
                                 default = nil)
  if valid_774203 != nil:
    section.add "X-Amz-Security-Token", valid_774203
  var valid_774204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774204 = validateParameter(valid_774204, JString, required = false,
                                 default = nil)
  if valid_774204 != nil:
    section.add "X-Amz-Content-Sha256", valid_774204
  var valid_774205 = header.getOrDefault("X-Amz-Algorithm")
  valid_774205 = validateParameter(valid_774205, JString, required = false,
                                 default = nil)
  if valid_774205 != nil:
    section.add "X-Amz-Algorithm", valid_774205
  var valid_774206 = header.getOrDefault("X-Amz-Signature")
  valid_774206 = validateParameter(valid_774206, JString, required = false,
                                 default = nil)
  if valid_774206 != nil:
    section.add "X-Amz-Signature", valid_774206
  var valid_774207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774207 = validateParameter(valid_774207, JString, required = false,
                                 default = nil)
  if valid_774207 != nil:
    section.add "X-Amz-SignedHeaders", valid_774207
  var valid_774208 = header.getOrDefault("X-Amz-Credential")
  valid_774208 = validateParameter(valid_774208, JString, required = false,
                                 default = nil)
  if valid_774208 != nil:
    section.add "X-Amz-Credential", valid_774208
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_774209 = formData.getOrDefault("Attributes")
  valid_774209 = validateParameter(valid_774209, JArray, required = true, default = nil)
  if valid_774209 != nil:
    section.add "Attributes", valid_774209
  var valid_774210 = formData.getOrDefault("TargetGroupArn")
  valid_774210 = validateParameter(valid_774210, JString, required = true,
                                 default = nil)
  if valid_774210 != nil:
    section.add "TargetGroupArn", valid_774210
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774211: Call_PostModifyTargetGroupAttributes_774197;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_774211.validator(path, query, header, formData, body)
  let scheme = call_774211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774211.url(scheme.get, call_774211.host, call_774211.base,
                         call_774211.route, valid.getOrDefault("path"))
  result = hook(call_774211, url, valid)

proc call*(call_774212: Call_PostModifyTargetGroupAttributes_774197;
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
  var query_774213 = newJObject()
  var formData_774214 = newJObject()
  if Attributes != nil:
    formData_774214.add "Attributes", Attributes
  add(query_774213, "Action", newJString(Action))
  add(formData_774214, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_774213, "Version", newJString(Version))
  result = call_774212.call(nil, query_774213, nil, formData_774214, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_774197(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_774198, base: "/",
    url: url_PostModifyTargetGroupAttributes_774199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_774180 = ref object of OpenApiRestCall_772597
proc url_GetModifyTargetGroupAttributes_774182(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyTargetGroupAttributes_774181(path: JsonNode;
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
  var valid_774183 = query.getOrDefault("TargetGroupArn")
  valid_774183 = validateParameter(valid_774183, JString, required = true,
                                 default = nil)
  if valid_774183 != nil:
    section.add "TargetGroupArn", valid_774183
  var valid_774184 = query.getOrDefault("Attributes")
  valid_774184 = validateParameter(valid_774184, JArray, required = true, default = nil)
  if valid_774184 != nil:
    section.add "Attributes", valid_774184
  var valid_774185 = query.getOrDefault("Action")
  valid_774185 = validateParameter(valid_774185, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_774185 != nil:
    section.add "Action", valid_774185
  var valid_774186 = query.getOrDefault("Version")
  valid_774186 = validateParameter(valid_774186, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774186 != nil:
    section.add "Version", valid_774186
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
  var valid_774187 = header.getOrDefault("X-Amz-Date")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "X-Amz-Date", valid_774187
  var valid_774188 = header.getOrDefault("X-Amz-Security-Token")
  valid_774188 = validateParameter(valid_774188, JString, required = false,
                                 default = nil)
  if valid_774188 != nil:
    section.add "X-Amz-Security-Token", valid_774188
  var valid_774189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774189 = validateParameter(valid_774189, JString, required = false,
                                 default = nil)
  if valid_774189 != nil:
    section.add "X-Amz-Content-Sha256", valid_774189
  var valid_774190 = header.getOrDefault("X-Amz-Algorithm")
  valid_774190 = validateParameter(valid_774190, JString, required = false,
                                 default = nil)
  if valid_774190 != nil:
    section.add "X-Amz-Algorithm", valid_774190
  var valid_774191 = header.getOrDefault("X-Amz-Signature")
  valid_774191 = validateParameter(valid_774191, JString, required = false,
                                 default = nil)
  if valid_774191 != nil:
    section.add "X-Amz-Signature", valid_774191
  var valid_774192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774192 = validateParameter(valid_774192, JString, required = false,
                                 default = nil)
  if valid_774192 != nil:
    section.add "X-Amz-SignedHeaders", valid_774192
  var valid_774193 = header.getOrDefault("X-Amz-Credential")
  valid_774193 = validateParameter(valid_774193, JString, required = false,
                                 default = nil)
  if valid_774193 != nil:
    section.add "X-Amz-Credential", valid_774193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774194: Call_GetModifyTargetGroupAttributes_774180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_774194.validator(path, query, header, formData, body)
  let scheme = call_774194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774194.url(scheme.get, call_774194.host, call_774194.base,
                         call_774194.route, valid.getOrDefault("path"))
  result = hook(call_774194, url, valid)

proc call*(call_774195: Call_GetModifyTargetGroupAttributes_774180;
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
  var query_774196 = newJObject()
  add(query_774196, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_774196.add "Attributes", Attributes
  add(query_774196, "Action", newJString(Action))
  add(query_774196, "Version", newJString(Version))
  result = call_774195.call(nil, query_774196, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_774180(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_774181, base: "/",
    url: url_GetModifyTargetGroupAttributes_774182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_774232 = ref object of OpenApiRestCall_772597
proc url_PostRegisterTargets_774234(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRegisterTargets_774233(path: JsonNode; query: JsonNode;
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
  var valid_774235 = query.getOrDefault("Action")
  valid_774235 = validateParameter(valid_774235, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_774235 != nil:
    section.add "Action", valid_774235
  var valid_774236 = query.getOrDefault("Version")
  valid_774236 = validateParameter(valid_774236, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774236 != nil:
    section.add "Version", valid_774236
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
  var valid_774237 = header.getOrDefault("X-Amz-Date")
  valid_774237 = validateParameter(valid_774237, JString, required = false,
                                 default = nil)
  if valid_774237 != nil:
    section.add "X-Amz-Date", valid_774237
  var valid_774238 = header.getOrDefault("X-Amz-Security-Token")
  valid_774238 = validateParameter(valid_774238, JString, required = false,
                                 default = nil)
  if valid_774238 != nil:
    section.add "X-Amz-Security-Token", valid_774238
  var valid_774239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774239 = validateParameter(valid_774239, JString, required = false,
                                 default = nil)
  if valid_774239 != nil:
    section.add "X-Amz-Content-Sha256", valid_774239
  var valid_774240 = header.getOrDefault("X-Amz-Algorithm")
  valid_774240 = validateParameter(valid_774240, JString, required = false,
                                 default = nil)
  if valid_774240 != nil:
    section.add "X-Amz-Algorithm", valid_774240
  var valid_774241 = header.getOrDefault("X-Amz-Signature")
  valid_774241 = validateParameter(valid_774241, JString, required = false,
                                 default = nil)
  if valid_774241 != nil:
    section.add "X-Amz-Signature", valid_774241
  var valid_774242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774242 = validateParameter(valid_774242, JString, required = false,
                                 default = nil)
  if valid_774242 != nil:
    section.add "X-Amz-SignedHeaders", valid_774242
  var valid_774243 = header.getOrDefault("X-Amz-Credential")
  valid_774243 = validateParameter(valid_774243, JString, required = false,
                                 default = nil)
  if valid_774243 != nil:
    section.add "X-Amz-Credential", valid_774243
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_774244 = formData.getOrDefault("Targets")
  valid_774244 = validateParameter(valid_774244, JArray, required = true, default = nil)
  if valid_774244 != nil:
    section.add "Targets", valid_774244
  var valid_774245 = formData.getOrDefault("TargetGroupArn")
  valid_774245 = validateParameter(valid_774245, JString, required = true,
                                 default = nil)
  if valid_774245 != nil:
    section.add "TargetGroupArn", valid_774245
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774246: Call_PostRegisterTargets_774232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_774246.validator(path, query, header, formData, body)
  let scheme = call_774246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774246.url(scheme.get, call_774246.host, call_774246.base,
                         call_774246.route, valid.getOrDefault("path"))
  result = hook(call_774246, url, valid)

proc call*(call_774247: Call_PostRegisterTargets_774232; Targets: JsonNode;
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
  var query_774248 = newJObject()
  var formData_774249 = newJObject()
  if Targets != nil:
    formData_774249.add "Targets", Targets
  add(query_774248, "Action", newJString(Action))
  add(formData_774249, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_774248, "Version", newJString(Version))
  result = call_774247.call(nil, query_774248, nil, formData_774249, nil)

var postRegisterTargets* = Call_PostRegisterTargets_774232(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_774233, base: "/",
    url: url_PostRegisterTargets_774234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_774215 = ref object of OpenApiRestCall_772597
proc url_GetRegisterTargets_774217(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRegisterTargets_774216(path: JsonNode; query: JsonNode;
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
  var valid_774218 = query.getOrDefault("Targets")
  valid_774218 = validateParameter(valid_774218, JArray, required = true, default = nil)
  if valid_774218 != nil:
    section.add "Targets", valid_774218
  var valid_774219 = query.getOrDefault("TargetGroupArn")
  valid_774219 = validateParameter(valid_774219, JString, required = true,
                                 default = nil)
  if valid_774219 != nil:
    section.add "TargetGroupArn", valid_774219
  var valid_774220 = query.getOrDefault("Action")
  valid_774220 = validateParameter(valid_774220, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_774220 != nil:
    section.add "Action", valid_774220
  var valid_774221 = query.getOrDefault("Version")
  valid_774221 = validateParameter(valid_774221, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774221 != nil:
    section.add "Version", valid_774221
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
  var valid_774222 = header.getOrDefault("X-Amz-Date")
  valid_774222 = validateParameter(valid_774222, JString, required = false,
                                 default = nil)
  if valid_774222 != nil:
    section.add "X-Amz-Date", valid_774222
  var valid_774223 = header.getOrDefault("X-Amz-Security-Token")
  valid_774223 = validateParameter(valid_774223, JString, required = false,
                                 default = nil)
  if valid_774223 != nil:
    section.add "X-Amz-Security-Token", valid_774223
  var valid_774224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774224 = validateParameter(valid_774224, JString, required = false,
                                 default = nil)
  if valid_774224 != nil:
    section.add "X-Amz-Content-Sha256", valid_774224
  var valid_774225 = header.getOrDefault("X-Amz-Algorithm")
  valid_774225 = validateParameter(valid_774225, JString, required = false,
                                 default = nil)
  if valid_774225 != nil:
    section.add "X-Amz-Algorithm", valid_774225
  var valid_774226 = header.getOrDefault("X-Amz-Signature")
  valid_774226 = validateParameter(valid_774226, JString, required = false,
                                 default = nil)
  if valid_774226 != nil:
    section.add "X-Amz-Signature", valid_774226
  var valid_774227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774227 = validateParameter(valid_774227, JString, required = false,
                                 default = nil)
  if valid_774227 != nil:
    section.add "X-Amz-SignedHeaders", valid_774227
  var valid_774228 = header.getOrDefault("X-Amz-Credential")
  valid_774228 = validateParameter(valid_774228, JString, required = false,
                                 default = nil)
  if valid_774228 != nil:
    section.add "X-Amz-Credential", valid_774228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774229: Call_GetRegisterTargets_774215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_774229.validator(path, query, header, formData, body)
  let scheme = call_774229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774229.url(scheme.get, call_774229.host, call_774229.base,
                         call_774229.route, valid.getOrDefault("path"))
  result = hook(call_774229, url, valid)

proc call*(call_774230: Call_GetRegisterTargets_774215; Targets: JsonNode;
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
  var query_774231 = newJObject()
  if Targets != nil:
    query_774231.add "Targets", Targets
  add(query_774231, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_774231, "Action", newJString(Action))
  add(query_774231, "Version", newJString(Version))
  result = call_774230.call(nil, query_774231, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_774215(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_774216, base: "/",
    url: url_GetRegisterTargets_774217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_774267 = ref object of OpenApiRestCall_772597
proc url_PostRemoveListenerCertificates_774269(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveListenerCertificates_774268(path: JsonNode;
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
  var valid_774270 = query.getOrDefault("Action")
  valid_774270 = validateParameter(valid_774270, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_774270 != nil:
    section.add "Action", valid_774270
  var valid_774271 = query.getOrDefault("Version")
  valid_774271 = validateParameter(valid_774271, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774271 != nil:
    section.add "Version", valid_774271
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
  var valid_774272 = header.getOrDefault("X-Amz-Date")
  valid_774272 = validateParameter(valid_774272, JString, required = false,
                                 default = nil)
  if valid_774272 != nil:
    section.add "X-Amz-Date", valid_774272
  var valid_774273 = header.getOrDefault("X-Amz-Security-Token")
  valid_774273 = validateParameter(valid_774273, JString, required = false,
                                 default = nil)
  if valid_774273 != nil:
    section.add "X-Amz-Security-Token", valid_774273
  var valid_774274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774274 = validateParameter(valid_774274, JString, required = false,
                                 default = nil)
  if valid_774274 != nil:
    section.add "X-Amz-Content-Sha256", valid_774274
  var valid_774275 = header.getOrDefault("X-Amz-Algorithm")
  valid_774275 = validateParameter(valid_774275, JString, required = false,
                                 default = nil)
  if valid_774275 != nil:
    section.add "X-Amz-Algorithm", valid_774275
  var valid_774276 = header.getOrDefault("X-Amz-Signature")
  valid_774276 = validateParameter(valid_774276, JString, required = false,
                                 default = nil)
  if valid_774276 != nil:
    section.add "X-Amz-Signature", valid_774276
  var valid_774277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774277 = validateParameter(valid_774277, JString, required = false,
                                 default = nil)
  if valid_774277 != nil:
    section.add "X-Amz-SignedHeaders", valid_774277
  var valid_774278 = header.getOrDefault("X-Amz-Credential")
  valid_774278 = validateParameter(valid_774278, JString, required = false,
                                 default = nil)
  if valid_774278 != nil:
    section.add "X-Amz-Credential", valid_774278
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_774279 = formData.getOrDefault("Certificates")
  valid_774279 = validateParameter(valid_774279, JArray, required = true, default = nil)
  if valid_774279 != nil:
    section.add "Certificates", valid_774279
  var valid_774280 = formData.getOrDefault("ListenerArn")
  valid_774280 = validateParameter(valid_774280, JString, required = true,
                                 default = nil)
  if valid_774280 != nil:
    section.add "ListenerArn", valid_774280
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774281: Call_PostRemoveListenerCertificates_774267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_774281.validator(path, query, header, formData, body)
  let scheme = call_774281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774281.url(scheme.get, call_774281.host, call_774281.base,
                         call_774281.route, valid.getOrDefault("path"))
  result = hook(call_774281, url, valid)

proc call*(call_774282: Call_PostRemoveListenerCertificates_774267;
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
  var query_774283 = newJObject()
  var formData_774284 = newJObject()
  if Certificates != nil:
    formData_774284.add "Certificates", Certificates
  add(formData_774284, "ListenerArn", newJString(ListenerArn))
  add(query_774283, "Action", newJString(Action))
  add(query_774283, "Version", newJString(Version))
  result = call_774282.call(nil, query_774283, nil, formData_774284, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_774267(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_774268, base: "/",
    url: url_PostRemoveListenerCertificates_774269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_774250 = ref object of OpenApiRestCall_772597
proc url_GetRemoveListenerCertificates_774252(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveListenerCertificates_774251(path: JsonNode; query: JsonNode;
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
  var valid_774253 = query.getOrDefault("Certificates")
  valid_774253 = validateParameter(valid_774253, JArray, required = true, default = nil)
  if valid_774253 != nil:
    section.add "Certificates", valid_774253
  var valid_774254 = query.getOrDefault("Action")
  valid_774254 = validateParameter(valid_774254, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_774254 != nil:
    section.add "Action", valid_774254
  var valid_774255 = query.getOrDefault("ListenerArn")
  valid_774255 = validateParameter(valid_774255, JString, required = true,
                                 default = nil)
  if valid_774255 != nil:
    section.add "ListenerArn", valid_774255
  var valid_774256 = query.getOrDefault("Version")
  valid_774256 = validateParameter(valid_774256, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774256 != nil:
    section.add "Version", valid_774256
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
  var valid_774257 = header.getOrDefault("X-Amz-Date")
  valid_774257 = validateParameter(valid_774257, JString, required = false,
                                 default = nil)
  if valid_774257 != nil:
    section.add "X-Amz-Date", valid_774257
  var valid_774258 = header.getOrDefault("X-Amz-Security-Token")
  valid_774258 = validateParameter(valid_774258, JString, required = false,
                                 default = nil)
  if valid_774258 != nil:
    section.add "X-Amz-Security-Token", valid_774258
  var valid_774259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774259 = validateParameter(valid_774259, JString, required = false,
                                 default = nil)
  if valid_774259 != nil:
    section.add "X-Amz-Content-Sha256", valid_774259
  var valid_774260 = header.getOrDefault("X-Amz-Algorithm")
  valid_774260 = validateParameter(valid_774260, JString, required = false,
                                 default = nil)
  if valid_774260 != nil:
    section.add "X-Amz-Algorithm", valid_774260
  var valid_774261 = header.getOrDefault("X-Amz-Signature")
  valid_774261 = validateParameter(valid_774261, JString, required = false,
                                 default = nil)
  if valid_774261 != nil:
    section.add "X-Amz-Signature", valid_774261
  var valid_774262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774262 = validateParameter(valid_774262, JString, required = false,
                                 default = nil)
  if valid_774262 != nil:
    section.add "X-Amz-SignedHeaders", valid_774262
  var valid_774263 = header.getOrDefault("X-Amz-Credential")
  valid_774263 = validateParameter(valid_774263, JString, required = false,
                                 default = nil)
  if valid_774263 != nil:
    section.add "X-Amz-Credential", valid_774263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774264: Call_GetRemoveListenerCertificates_774250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_774264.validator(path, query, header, formData, body)
  let scheme = call_774264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774264.url(scheme.get, call_774264.host, call_774264.base,
                         call_774264.route, valid.getOrDefault("path"))
  result = hook(call_774264, url, valid)

proc call*(call_774265: Call_GetRemoveListenerCertificates_774250;
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
  var query_774266 = newJObject()
  if Certificates != nil:
    query_774266.add "Certificates", Certificates
  add(query_774266, "Action", newJString(Action))
  add(query_774266, "ListenerArn", newJString(ListenerArn))
  add(query_774266, "Version", newJString(Version))
  result = call_774265.call(nil, query_774266, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_774250(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_774251, base: "/",
    url: url_GetRemoveListenerCertificates_774252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_774302 = ref object of OpenApiRestCall_772597
proc url_PostRemoveTags_774304(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTags_774303(path: JsonNode; query: JsonNode;
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
  var valid_774305 = query.getOrDefault("Action")
  valid_774305 = validateParameter(valid_774305, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_774305 != nil:
    section.add "Action", valid_774305
  var valid_774306 = query.getOrDefault("Version")
  valid_774306 = validateParameter(valid_774306, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774306 != nil:
    section.add "Version", valid_774306
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
  var valid_774307 = header.getOrDefault("X-Amz-Date")
  valid_774307 = validateParameter(valid_774307, JString, required = false,
                                 default = nil)
  if valid_774307 != nil:
    section.add "X-Amz-Date", valid_774307
  var valid_774308 = header.getOrDefault("X-Amz-Security-Token")
  valid_774308 = validateParameter(valid_774308, JString, required = false,
                                 default = nil)
  if valid_774308 != nil:
    section.add "X-Amz-Security-Token", valid_774308
  var valid_774309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774309 = validateParameter(valid_774309, JString, required = false,
                                 default = nil)
  if valid_774309 != nil:
    section.add "X-Amz-Content-Sha256", valid_774309
  var valid_774310 = header.getOrDefault("X-Amz-Algorithm")
  valid_774310 = validateParameter(valid_774310, JString, required = false,
                                 default = nil)
  if valid_774310 != nil:
    section.add "X-Amz-Algorithm", valid_774310
  var valid_774311 = header.getOrDefault("X-Amz-Signature")
  valid_774311 = validateParameter(valid_774311, JString, required = false,
                                 default = nil)
  if valid_774311 != nil:
    section.add "X-Amz-Signature", valid_774311
  var valid_774312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774312 = validateParameter(valid_774312, JString, required = false,
                                 default = nil)
  if valid_774312 != nil:
    section.add "X-Amz-SignedHeaders", valid_774312
  var valid_774313 = header.getOrDefault("X-Amz-Credential")
  valid_774313 = validateParameter(valid_774313, JString, required = false,
                                 default = nil)
  if valid_774313 != nil:
    section.add "X-Amz-Credential", valid_774313
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_774314 = formData.getOrDefault("ResourceArns")
  valid_774314 = validateParameter(valid_774314, JArray, required = true, default = nil)
  if valid_774314 != nil:
    section.add "ResourceArns", valid_774314
  var valid_774315 = formData.getOrDefault("TagKeys")
  valid_774315 = validateParameter(valid_774315, JArray, required = true, default = nil)
  if valid_774315 != nil:
    section.add "TagKeys", valid_774315
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774316: Call_PostRemoveTags_774302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_774316.validator(path, query, header, formData, body)
  let scheme = call_774316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774316.url(scheme.get, call_774316.host, call_774316.base,
                         call_774316.route, valid.getOrDefault("path"))
  result = hook(call_774316, url, valid)

proc call*(call_774317: Call_PostRemoveTags_774302; ResourceArns: JsonNode;
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
  var query_774318 = newJObject()
  var formData_774319 = newJObject()
  if ResourceArns != nil:
    formData_774319.add "ResourceArns", ResourceArns
  add(query_774318, "Action", newJString(Action))
  if TagKeys != nil:
    formData_774319.add "TagKeys", TagKeys
  add(query_774318, "Version", newJString(Version))
  result = call_774317.call(nil, query_774318, nil, formData_774319, nil)

var postRemoveTags* = Call_PostRemoveTags_774302(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_774303,
    base: "/", url: url_PostRemoveTags_774304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_774285 = ref object of OpenApiRestCall_772597
proc url_GetRemoveTags_774287(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTags_774286(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774288 = query.getOrDefault("Action")
  valid_774288 = validateParameter(valid_774288, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_774288 != nil:
    section.add "Action", valid_774288
  var valid_774289 = query.getOrDefault("ResourceArns")
  valid_774289 = validateParameter(valid_774289, JArray, required = true, default = nil)
  if valid_774289 != nil:
    section.add "ResourceArns", valid_774289
  var valid_774290 = query.getOrDefault("TagKeys")
  valid_774290 = validateParameter(valid_774290, JArray, required = true, default = nil)
  if valid_774290 != nil:
    section.add "TagKeys", valid_774290
  var valid_774291 = query.getOrDefault("Version")
  valid_774291 = validateParameter(valid_774291, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774291 != nil:
    section.add "Version", valid_774291
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
  var valid_774292 = header.getOrDefault("X-Amz-Date")
  valid_774292 = validateParameter(valid_774292, JString, required = false,
                                 default = nil)
  if valid_774292 != nil:
    section.add "X-Amz-Date", valid_774292
  var valid_774293 = header.getOrDefault("X-Amz-Security-Token")
  valid_774293 = validateParameter(valid_774293, JString, required = false,
                                 default = nil)
  if valid_774293 != nil:
    section.add "X-Amz-Security-Token", valid_774293
  var valid_774294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774294 = validateParameter(valid_774294, JString, required = false,
                                 default = nil)
  if valid_774294 != nil:
    section.add "X-Amz-Content-Sha256", valid_774294
  var valid_774295 = header.getOrDefault("X-Amz-Algorithm")
  valid_774295 = validateParameter(valid_774295, JString, required = false,
                                 default = nil)
  if valid_774295 != nil:
    section.add "X-Amz-Algorithm", valid_774295
  var valid_774296 = header.getOrDefault("X-Amz-Signature")
  valid_774296 = validateParameter(valid_774296, JString, required = false,
                                 default = nil)
  if valid_774296 != nil:
    section.add "X-Amz-Signature", valid_774296
  var valid_774297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774297 = validateParameter(valid_774297, JString, required = false,
                                 default = nil)
  if valid_774297 != nil:
    section.add "X-Amz-SignedHeaders", valid_774297
  var valid_774298 = header.getOrDefault("X-Amz-Credential")
  valid_774298 = validateParameter(valid_774298, JString, required = false,
                                 default = nil)
  if valid_774298 != nil:
    section.add "X-Amz-Credential", valid_774298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774299: Call_GetRemoveTags_774285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_774299.validator(path, query, header, formData, body)
  let scheme = call_774299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774299.url(scheme.get, call_774299.host, call_774299.base,
                         call_774299.route, valid.getOrDefault("path"))
  result = hook(call_774299, url, valid)

proc call*(call_774300: Call_GetRemoveTags_774285; ResourceArns: JsonNode;
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
  var query_774301 = newJObject()
  add(query_774301, "Action", newJString(Action))
  if ResourceArns != nil:
    query_774301.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_774301.add "TagKeys", TagKeys
  add(query_774301, "Version", newJString(Version))
  result = call_774300.call(nil, query_774301, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_774285(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_774286,
    base: "/", url: url_GetRemoveTags_774287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_774337 = ref object of OpenApiRestCall_772597
proc url_PostSetIpAddressType_774339(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetIpAddressType_774338(path: JsonNode; query: JsonNode;
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
  var valid_774340 = query.getOrDefault("Action")
  valid_774340 = validateParameter(valid_774340, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_774340 != nil:
    section.add "Action", valid_774340
  var valid_774341 = query.getOrDefault("Version")
  valid_774341 = validateParameter(valid_774341, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774341 != nil:
    section.add "Version", valid_774341
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
  var valid_774342 = header.getOrDefault("X-Amz-Date")
  valid_774342 = validateParameter(valid_774342, JString, required = false,
                                 default = nil)
  if valid_774342 != nil:
    section.add "X-Amz-Date", valid_774342
  var valid_774343 = header.getOrDefault("X-Amz-Security-Token")
  valid_774343 = validateParameter(valid_774343, JString, required = false,
                                 default = nil)
  if valid_774343 != nil:
    section.add "X-Amz-Security-Token", valid_774343
  var valid_774344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774344 = validateParameter(valid_774344, JString, required = false,
                                 default = nil)
  if valid_774344 != nil:
    section.add "X-Amz-Content-Sha256", valid_774344
  var valid_774345 = header.getOrDefault("X-Amz-Algorithm")
  valid_774345 = validateParameter(valid_774345, JString, required = false,
                                 default = nil)
  if valid_774345 != nil:
    section.add "X-Amz-Algorithm", valid_774345
  var valid_774346 = header.getOrDefault("X-Amz-Signature")
  valid_774346 = validateParameter(valid_774346, JString, required = false,
                                 default = nil)
  if valid_774346 != nil:
    section.add "X-Amz-Signature", valid_774346
  var valid_774347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774347 = validateParameter(valid_774347, JString, required = false,
                                 default = nil)
  if valid_774347 != nil:
    section.add "X-Amz-SignedHeaders", valid_774347
  var valid_774348 = header.getOrDefault("X-Amz-Credential")
  valid_774348 = validateParameter(valid_774348, JString, required = false,
                                 default = nil)
  if valid_774348 != nil:
    section.add "X-Amz-Credential", valid_774348
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_774349 = formData.getOrDefault("LoadBalancerArn")
  valid_774349 = validateParameter(valid_774349, JString, required = true,
                                 default = nil)
  if valid_774349 != nil:
    section.add "LoadBalancerArn", valid_774349
  var valid_774350 = formData.getOrDefault("IpAddressType")
  valid_774350 = validateParameter(valid_774350, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_774350 != nil:
    section.add "IpAddressType", valid_774350
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774351: Call_PostSetIpAddressType_774337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_774351.validator(path, query, header, formData, body)
  let scheme = call_774351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774351.url(scheme.get, call_774351.host, call_774351.base,
                         call_774351.route, valid.getOrDefault("path"))
  result = hook(call_774351, url, valid)

proc call*(call_774352: Call_PostSetIpAddressType_774337; LoadBalancerArn: string;
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
  var query_774353 = newJObject()
  var formData_774354 = newJObject()
  add(formData_774354, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_774354, "IpAddressType", newJString(IpAddressType))
  add(query_774353, "Action", newJString(Action))
  add(query_774353, "Version", newJString(Version))
  result = call_774352.call(nil, query_774353, nil, formData_774354, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_774337(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_774338,
    base: "/", url: url_PostSetIpAddressType_774339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_774320 = ref object of OpenApiRestCall_772597
proc url_GetSetIpAddressType_774322(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetIpAddressType_774321(path: JsonNode; query: JsonNode;
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
  var valid_774323 = query.getOrDefault("IpAddressType")
  valid_774323 = validateParameter(valid_774323, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_774323 != nil:
    section.add "IpAddressType", valid_774323
  var valid_774324 = query.getOrDefault("Action")
  valid_774324 = validateParameter(valid_774324, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_774324 != nil:
    section.add "Action", valid_774324
  var valid_774325 = query.getOrDefault("LoadBalancerArn")
  valid_774325 = validateParameter(valid_774325, JString, required = true,
                                 default = nil)
  if valid_774325 != nil:
    section.add "LoadBalancerArn", valid_774325
  var valid_774326 = query.getOrDefault("Version")
  valid_774326 = validateParameter(valid_774326, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774326 != nil:
    section.add "Version", valid_774326
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
  var valid_774327 = header.getOrDefault("X-Amz-Date")
  valid_774327 = validateParameter(valid_774327, JString, required = false,
                                 default = nil)
  if valid_774327 != nil:
    section.add "X-Amz-Date", valid_774327
  var valid_774328 = header.getOrDefault("X-Amz-Security-Token")
  valid_774328 = validateParameter(valid_774328, JString, required = false,
                                 default = nil)
  if valid_774328 != nil:
    section.add "X-Amz-Security-Token", valid_774328
  var valid_774329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774329 = validateParameter(valid_774329, JString, required = false,
                                 default = nil)
  if valid_774329 != nil:
    section.add "X-Amz-Content-Sha256", valid_774329
  var valid_774330 = header.getOrDefault("X-Amz-Algorithm")
  valid_774330 = validateParameter(valid_774330, JString, required = false,
                                 default = nil)
  if valid_774330 != nil:
    section.add "X-Amz-Algorithm", valid_774330
  var valid_774331 = header.getOrDefault("X-Amz-Signature")
  valid_774331 = validateParameter(valid_774331, JString, required = false,
                                 default = nil)
  if valid_774331 != nil:
    section.add "X-Amz-Signature", valid_774331
  var valid_774332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774332 = validateParameter(valid_774332, JString, required = false,
                                 default = nil)
  if valid_774332 != nil:
    section.add "X-Amz-SignedHeaders", valid_774332
  var valid_774333 = header.getOrDefault("X-Amz-Credential")
  valid_774333 = validateParameter(valid_774333, JString, required = false,
                                 default = nil)
  if valid_774333 != nil:
    section.add "X-Amz-Credential", valid_774333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774334: Call_GetSetIpAddressType_774320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_774334.validator(path, query, header, formData, body)
  let scheme = call_774334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774334.url(scheme.get, call_774334.host, call_774334.base,
                         call_774334.route, valid.getOrDefault("path"))
  result = hook(call_774334, url, valid)

proc call*(call_774335: Call_GetSetIpAddressType_774320; LoadBalancerArn: string;
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
  var query_774336 = newJObject()
  add(query_774336, "IpAddressType", newJString(IpAddressType))
  add(query_774336, "Action", newJString(Action))
  add(query_774336, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_774336, "Version", newJString(Version))
  result = call_774335.call(nil, query_774336, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_774320(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_774321,
    base: "/", url: url_GetSetIpAddressType_774322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_774371 = ref object of OpenApiRestCall_772597
proc url_PostSetRulePriorities_774373(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetRulePriorities_774372(path: JsonNode; query: JsonNode;
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
  var valid_774374 = query.getOrDefault("Action")
  valid_774374 = validateParameter(valid_774374, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_774374 != nil:
    section.add "Action", valid_774374
  var valid_774375 = query.getOrDefault("Version")
  valid_774375 = validateParameter(valid_774375, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774375 != nil:
    section.add "Version", valid_774375
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
  var valid_774376 = header.getOrDefault("X-Amz-Date")
  valid_774376 = validateParameter(valid_774376, JString, required = false,
                                 default = nil)
  if valid_774376 != nil:
    section.add "X-Amz-Date", valid_774376
  var valid_774377 = header.getOrDefault("X-Amz-Security-Token")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "X-Amz-Security-Token", valid_774377
  var valid_774378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774378 = validateParameter(valid_774378, JString, required = false,
                                 default = nil)
  if valid_774378 != nil:
    section.add "X-Amz-Content-Sha256", valid_774378
  var valid_774379 = header.getOrDefault("X-Amz-Algorithm")
  valid_774379 = validateParameter(valid_774379, JString, required = false,
                                 default = nil)
  if valid_774379 != nil:
    section.add "X-Amz-Algorithm", valid_774379
  var valid_774380 = header.getOrDefault("X-Amz-Signature")
  valid_774380 = validateParameter(valid_774380, JString, required = false,
                                 default = nil)
  if valid_774380 != nil:
    section.add "X-Amz-Signature", valid_774380
  var valid_774381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774381 = validateParameter(valid_774381, JString, required = false,
                                 default = nil)
  if valid_774381 != nil:
    section.add "X-Amz-SignedHeaders", valid_774381
  var valid_774382 = header.getOrDefault("X-Amz-Credential")
  valid_774382 = validateParameter(valid_774382, JString, required = false,
                                 default = nil)
  if valid_774382 != nil:
    section.add "X-Amz-Credential", valid_774382
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_774383 = formData.getOrDefault("RulePriorities")
  valid_774383 = validateParameter(valid_774383, JArray, required = true, default = nil)
  if valid_774383 != nil:
    section.add "RulePriorities", valid_774383
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774384: Call_PostSetRulePriorities_774371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_774384.validator(path, query, header, formData, body)
  let scheme = call_774384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774384.url(scheme.get, call_774384.host, call_774384.base,
                         call_774384.route, valid.getOrDefault("path"))
  result = hook(call_774384, url, valid)

proc call*(call_774385: Call_PostSetRulePriorities_774371;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774386 = newJObject()
  var formData_774387 = newJObject()
  if RulePriorities != nil:
    formData_774387.add "RulePriorities", RulePriorities
  add(query_774386, "Action", newJString(Action))
  add(query_774386, "Version", newJString(Version))
  result = call_774385.call(nil, query_774386, nil, formData_774387, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_774371(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_774372, base: "/",
    url: url_PostSetRulePriorities_774373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_774355 = ref object of OpenApiRestCall_772597
proc url_GetSetRulePriorities_774357(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetRulePriorities_774356(path: JsonNode; query: JsonNode;
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
  var valid_774358 = query.getOrDefault("RulePriorities")
  valid_774358 = validateParameter(valid_774358, JArray, required = true, default = nil)
  if valid_774358 != nil:
    section.add "RulePriorities", valid_774358
  var valid_774359 = query.getOrDefault("Action")
  valid_774359 = validateParameter(valid_774359, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_774359 != nil:
    section.add "Action", valid_774359
  var valid_774360 = query.getOrDefault("Version")
  valid_774360 = validateParameter(valid_774360, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774360 != nil:
    section.add "Version", valid_774360
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
  var valid_774361 = header.getOrDefault("X-Amz-Date")
  valid_774361 = validateParameter(valid_774361, JString, required = false,
                                 default = nil)
  if valid_774361 != nil:
    section.add "X-Amz-Date", valid_774361
  var valid_774362 = header.getOrDefault("X-Amz-Security-Token")
  valid_774362 = validateParameter(valid_774362, JString, required = false,
                                 default = nil)
  if valid_774362 != nil:
    section.add "X-Amz-Security-Token", valid_774362
  var valid_774363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774363 = validateParameter(valid_774363, JString, required = false,
                                 default = nil)
  if valid_774363 != nil:
    section.add "X-Amz-Content-Sha256", valid_774363
  var valid_774364 = header.getOrDefault("X-Amz-Algorithm")
  valid_774364 = validateParameter(valid_774364, JString, required = false,
                                 default = nil)
  if valid_774364 != nil:
    section.add "X-Amz-Algorithm", valid_774364
  var valid_774365 = header.getOrDefault("X-Amz-Signature")
  valid_774365 = validateParameter(valid_774365, JString, required = false,
                                 default = nil)
  if valid_774365 != nil:
    section.add "X-Amz-Signature", valid_774365
  var valid_774366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774366 = validateParameter(valid_774366, JString, required = false,
                                 default = nil)
  if valid_774366 != nil:
    section.add "X-Amz-SignedHeaders", valid_774366
  var valid_774367 = header.getOrDefault("X-Amz-Credential")
  valid_774367 = validateParameter(valid_774367, JString, required = false,
                                 default = nil)
  if valid_774367 != nil:
    section.add "X-Amz-Credential", valid_774367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774368: Call_GetSetRulePriorities_774355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_774368.validator(path, query, header, formData, body)
  let scheme = call_774368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774368.url(scheme.get, call_774368.host, call_774368.base,
                         call_774368.route, valid.getOrDefault("path"))
  result = hook(call_774368, url, valid)

proc call*(call_774369: Call_GetSetRulePriorities_774355; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774370 = newJObject()
  if RulePriorities != nil:
    query_774370.add "RulePriorities", RulePriorities
  add(query_774370, "Action", newJString(Action))
  add(query_774370, "Version", newJString(Version))
  result = call_774369.call(nil, query_774370, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_774355(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_774356,
    base: "/", url: url_GetSetRulePriorities_774357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_774405 = ref object of OpenApiRestCall_772597
proc url_PostSetSecurityGroups_774407(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSecurityGroups_774406(path: JsonNode; query: JsonNode;
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
  var valid_774408 = query.getOrDefault("Action")
  valid_774408 = validateParameter(valid_774408, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_774408 != nil:
    section.add "Action", valid_774408
  var valid_774409 = query.getOrDefault("Version")
  valid_774409 = validateParameter(valid_774409, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774409 != nil:
    section.add "Version", valid_774409
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
  var valid_774410 = header.getOrDefault("X-Amz-Date")
  valid_774410 = validateParameter(valid_774410, JString, required = false,
                                 default = nil)
  if valid_774410 != nil:
    section.add "X-Amz-Date", valid_774410
  var valid_774411 = header.getOrDefault("X-Amz-Security-Token")
  valid_774411 = validateParameter(valid_774411, JString, required = false,
                                 default = nil)
  if valid_774411 != nil:
    section.add "X-Amz-Security-Token", valid_774411
  var valid_774412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774412 = validateParameter(valid_774412, JString, required = false,
                                 default = nil)
  if valid_774412 != nil:
    section.add "X-Amz-Content-Sha256", valid_774412
  var valid_774413 = header.getOrDefault("X-Amz-Algorithm")
  valid_774413 = validateParameter(valid_774413, JString, required = false,
                                 default = nil)
  if valid_774413 != nil:
    section.add "X-Amz-Algorithm", valid_774413
  var valid_774414 = header.getOrDefault("X-Amz-Signature")
  valid_774414 = validateParameter(valid_774414, JString, required = false,
                                 default = nil)
  if valid_774414 != nil:
    section.add "X-Amz-Signature", valid_774414
  var valid_774415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774415 = validateParameter(valid_774415, JString, required = false,
                                 default = nil)
  if valid_774415 != nil:
    section.add "X-Amz-SignedHeaders", valid_774415
  var valid_774416 = header.getOrDefault("X-Amz-Credential")
  valid_774416 = validateParameter(valid_774416, JString, required = false,
                                 default = nil)
  if valid_774416 != nil:
    section.add "X-Amz-Credential", valid_774416
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_774417 = formData.getOrDefault("LoadBalancerArn")
  valid_774417 = validateParameter(valid_774417, JString, required = true,
                                 default = nil)
  if valid_774417 != nil:
    section.add "LoadBalancerArn", valid_774417
  var valid_774418 = formData.getOrDefault("SecurityGroups")
  valid_774418 = validateParameter(valid_774418, JArray, required = true, default = nil)
  if valid_774418 != nil:
    section.add "SecurityGroups", valid_774418
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774419: Call_PostSetSecurityGroups_774405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_774419.validator(path, query, header, formData, body)
  let scheme = call_774419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774419.url(scheme.get, call_774419.host, call_774419.base,
                         call_774419.route, valid.getOrDefault("path"))
  result = hook(call_774419, url, valid)

proc call*(call_774420: Call_PostSetSecurityGroups_774405; LoadBalancerArn: string;
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
  var query_774421 = newJObject()
  var formData_774422 = newJObject()
  add(formData_774422, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_774421, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_774422.add "SecurityGroups", SecurityGroups
  add(query_774421, "Version", newJString(Version))
  result = call_774420.call(nil, query_774421, nil, formData_774422, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_774405(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_774406, base: "/",
    url: url_PostSetSecurityGroups_774407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_774388 = ref object of OpenApiRestCall_772597
proc url_GetSetSecurityGroups_774390(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSecurityGroups_774389(path: JsonNode; query: JsonNode;
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
  var valid_774391 = query.getOrDefault("Action")
  valid_774391 = validateParameter(valid_774391, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_774391 != nil:
    section.add "Action", valid_774391
  var valid_774392 = query.getOrDefault("LoadBalancerArn")
  valid_774392 = validateParameter(valid_774392, JString, required = true,
                                 default = nil)
  if valid_774392 != nil:
    section.add "LoadBalancerArn", valid_774392
  var valid_774393 = query.getOrDefault("Version")
  valid_774393 = validateParameter(valid_774393, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774393 != nil:
    section.add "Version", valid_774393
  var valid_774394 = query.getOrDefault("SecurityGroups")
  valid_774394 = validateParameter(valid_774394, JArray, required = true, default = nil)
  if valid_774394 != nil:
    section.add "SecurityGroups", valid_774394
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
  var valid_774395 = header.getOrDefault("X-Amz-Date")
  valid_774395 = validateParameter(valid_774395, JString, required = false,
                                 default = nil)
  if valid_774395 != nil:
    section.add "X-Amz-Date", valid_774395
  var valid_774396 = header.getOrDefault("X-Amz-Security-Token")
  valid_774396 = validateParameter(valid_774396, JString, required = false,
                                 default = nil)
  if valid_774396 != nil:
    section.add "X-Amz-Security-Token", valid_774396
  var valid_774397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774397 = validateParameter(valid_774397, JString, required = false,
                                 default = nil)
  if valid_774397 != nil:
    section.add "X-Amz-Content-Sha256", valid_774397
  var valid_774398 = header.getOrDefault("X-Amz-Algorithm")
  valid_774398 = validateParameter(valid_774398, JString, required = false,
                                 default = nil)
  if valid_774398 != nil:
    section.add "X-Amz-Algorithm", valid_774398
  var valid_774399 = header.getOrDefault("X-Amz-Signature")
  valid_774399 = validateParameter(valid_774399, JString, required = false,
                                 default = nil)
  if valid_774399 != nil:
    section.add "X-Amz-Signature", valid_774399
  var valid_774400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774400 = validateParameter(valid_774400, JString, required = false,
                                 default = nil)
  if valid_774400 != nil:
    section.add "X-Amz-SignedHeaders", valid_774400
  var valid_774401 = header.getOrDefault("X-Amz-Credential")
  valid_774401 = validateParameter(valid_774401, JString, required = false,
                                 default = nil)
  if valid_774401 != nil:
    section.add "X-Amz-Credential", valid_774401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774402: Call_GetSetSecurityGroups_774388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_774402.validator(path, query, header, formData, body)
  let scheme = call_774402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774402.url(scheme.get, call_774402.host, call_774402.base,
                         call_774402.route, valid.getOrDefault("path"))
  result = hook(call_774402, url, valid)

proc call*(call_774403: Call_GetSetSecurityGroups_774388; LoadBalancerArn: string;
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
  var query_774404 = newJObject()
  add(query_774404, "Action", newJString(Action))
  add(query_774404, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_774404, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_774404.add "SecurityGroups", SecurityGroups
  result = call_774403.call(nil, query_774404, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_774388(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_774389,
    base: "/", url: url_GetSetSecurityGroups_774390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_774441 = ref object of OpenApiRestCall_772597
proc url_PostSetSubnets_774443(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSubnets_774442(path: JsonNode; query: JsonNode;
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
  var valid_774444 = query.getOrDefault("Action")
  valid_774444 = validateParameter(valid_774444, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_774444 != nil:
    section.add "Action", valid_774444
  var valid_774445 = query.getOrDefault("Version")
  valid_774445 = validateParameter(valid_774445, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774445 != nil:
    section.add "Version", valid_774445
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
  var valid_774446 = header.getOrDefault("X-Amz-Date")
  valid_774446 = validateParameter(valid_774446, JString, required = false,
                                 default = nil)
  if valid_774446 != nil:
    section.add "X-Amz-Date", valid_774446
  var valid_774447 = header.getOrDefault("X-Amz-Security-Token")
  valid_774447 = validateParameter(valid_774447, JString, required = false,
                                 default = nil)
  if valid_774447 != nil:
    section.add "X-Amz-Security-Token", valid_774447
  var valid_774448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774448 = validateParameter(valid_774448, JString, required = false,
                                 default = nil)
  if valid_774448 != nil:
    section.add "X-Amz-Content-Sha256", valid_774448
  var valid_774449 = header.getOrDefault("X-Amz-Algorithm")
  valid_774449 = validateParameter(valid_774449, JString, required = false,
                                 default = nil)
  if valid_774449 != nil:
    section.add "X-Amz-Algorithm", valid_774449
  var valid_774450 = header.getOrDefault("X-Amz-Signature")
  valid_774450 = validateParameter(valid_774450, JString, required = false,
                                 default = nil)
  if valid_774450 != nil:
    section.add "X-Amz-Signature", valid_774450
  var valid_774451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774451 = validateParameter(valid_774451, JString, required = false,
                                 default = nil)
  if valid_774451 != nil:
    section.add "X-Amz-SignedHeaders", valid_774451
  var valid_774452 = header.getOrDefault("X-Amz-Credential")
  valid_774452 = validateParameter(valid_774452, JString, required = false,
                                 default = nil)
  if valid_774452 != nil:
    section.add "X-Amz-Credential", valid_774452
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
  var valid_774453 = formData.getOrDefault("LoadBalancerArn")
  valid_774453 = validateParameter(valid_774453, JString, required = true,
                                 default = nil)
  if valid_774453 != nil:
    section.add "LoadBalancerArn", valid_774453
  var valid_774454 = formData.getOrDefault("Subnets")
  valid_774454 = validateParameter(valid_774454, JArray, required = false,
                                 default = nil)
  if valid_774454 != nil:
    section.add "Subnets", valid_774454
  var valid_774455 = formData.getOrDefault("SubnetMappings")
  valid_774455 = validateParameter(valid_774455, JArray, required = false,
                                 default = nil)
  if valid_774455 != nil:
    section.add "SubnetMappings", valid_774455
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774456: Call_PostSetSubnets_774441; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_774456.validator(path, query, header, formData, body)
  let scheme = call_774456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774456.url(scheme.get, call_774456.host, call_774456.base,
                         call_774456.route, valid.getOrDefault("path"))
  result = hook(call_774456, url, valid)

proc call*(call_774457: Call_PostSetSubnets_774441; LoadBalancerArn: string;
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
  var query_774458 = newJObject()
  var formData_774459 = newJObject()
  add(formData_774459, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_774458, "Action", newJString(Action))
  if Subnets != nil:
    formData_774459.add "Subnets", Subnets
  if SubnetMappings != nil:
    formData_774459.add "SubnetMappings", SubnetMappings
  add(query_774458, "Version", newJString(Version))
  result = call_774457.call(nil, query_774458, nil, formData_774459, nil)

var postSetSubnets* = Call_PostSetSubnets_774441(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_774442,
    base: "/", url: url_PostSetSubnets_774443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_774423 = ref object of OpenApiRestCall_772597
proc url_GetSetSubnets_774425(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSubnets_774424(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774426 = query.getOrDefault("SubnetMappings")
  valid_774426 = validateParameter(valid_774426, JArray, required = false,
                                 default = nil)
  if valid_774426 != nil:
    section.add "SubnetMappings", valid_774426
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774427 = query.getOrDefault("Action")
  valid_774427 = validateParameter(valid_774427, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_774427 != nil:
    section.add "Action", valid_774427
  var valid_774428 = query.getOrDefault("LoadBalancerArn")
  valid_774428 = validateParameter(valid_774428, JString, required = true,
                                 default = nil)
  if valid_774428 != nil:
    section.add "LoadBalancerArn", valid_774428
  var valid_774429 = query.getOrDefault("Subnets")
  valid_774429 = validateParameter(valid_774429, JArray, required = false,
                                 default = nil)
  if valid_774429 != nil:
    section.add "Subnets", valid_774429
  var valid_774430 = query.getOrDefault("Version")
  valid_774430 = validateParameter(valid_774430, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_774430 != nil:
    section.add "Version", valid_774430
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
  var valid_774431 = header.getOrDefault("X-Amz-Date")
  valid_774431 = validateParameter(valid_774431, JString, required = false,
                                 default = nil)
  if valid_774431 != nil:
    section.add "X-Amz-Date", valid_774431
  var valid_774432 = header.getOrDefault("X-Amz-Security-Token")
  valid_774432 = validateParameter(valid_774432, JString, required = false,
                                 default = nil)
  if valid_774432 != nil:
    section.add "X-Amz-Security-Token", valid_774432
  var valid_774433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774433 = validateParameter(valid_774433, JString, required = false,
                                 default = nil)
  if valid_774433 != nil:
    section.add "X-Amz-Content-Sha256", valid_774433
  var valid_774434 = header.getOrDefault("X-Amz-Algorithm")
  valid_774434 = validateParameter(valid_774434, JString, required = false,
                                 default = nil)
  if valid_774434 != nil:
    section.add "X-Amz-Algorithm", valid_774434
  var valid_774435 = header.getOrDefault("X-Amz-Signature")
  valid_774435 = validateParameter(valid_774435, JString, required = false,
                                 default = nil)
  if valid_774435 != nil:
    section.add "X-Amz-Signature", valid_774435
  var valid_774436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774436 = validateParameter(valid_774436, JString, required = false,
                                 default = nil)
  if valid_774436 != nil:
    section.add "X-Amz-SignedHeaders", valid_774436
  var valid_774437 = header.getOrDefault("X-Amz-Credential")
  valid_774437 = validateParameter(valid_774437, JString, required = false,
                                 default = nil)
  if valid_774437 != nil:
    section.add "X-Amz-Credential", valid_774437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774438: Call_GetSetSubnets_774423; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_774438.validator(path, query, header, formData, body)
  let scheme = call_774438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774438.url(scheme.get, call_774438.host, call_774438.base,
                         call_774438.route, valid.getOrDefault("path"))
  result = hook(call_774438, url, valid)

proc call*(call_774439: Call_GetSetSubnets_774423; LoadBalancerArn: string;
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
  var query_774440 = newJObject()
  if SubnetMappings != nil:
    query_774440.add "SubnetMappings", SubnetMappings
  add(query_774440, "Action", newJString(Action))
  add(query_774440, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Subnets != nil:
    query_774440.add "Subnets", Subnets
  add(query_774440, "Version", newJString(Version))
  result = call_774439.call(nil, query_774440, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_774423(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_774424,
    base: "/", url: url_GetSetSubnets_774425, schemes: {Scheme.Https, Scheme.Http})
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
