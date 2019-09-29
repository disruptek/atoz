
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  Call_PostAddListenerCertificates_594046 = ref object of OpenApiRestCall_593437
proc url_PostAddListenerCertificates_594048(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddListenerCertificates_594047(path: JsonNode; query: JsonNode;
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
  var valid_594049 = query.getOrDefault("Action")
  valid_594049 = validateParameter(valid_594049, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_594049 != nil:
    section.add "Action", valid_594049
  var valid_594050 = query.getOrDefault("Version")
  valid_594050 = validateParameter(valid_594050, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594050 != nil:
    section.add "Version", valid_594050
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
  var valid_594051 = header.getOrDefault("X-Amz-Date")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Date", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Security-Token")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Security-Token", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Content-Sha256", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Algorithm")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Algorithm", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Signature")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Signature", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-SignedHeaders", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Credential")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Credential", valid_594057
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_594058 = formData.getOrDefault("Certificates")
  valid_594058 = validateParameter(valid_594058, JArray, required = true, default = nil)
  if valid_594058 != nil:
    section.add "Certificates", valid_594058
  var valid_594059 = formData.getOrDefault("ListenerArn")
  valid_594059 = validateParameter(valid_594059, JString, required = true,
                                 default = nil)
  if valid_594059 != nil:
    section.add "ListenerArn", valid_594059
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594060: Call_PostAddListenerCertificates_594046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594060.validator(path, query, header, formData, body)
  let scheme = call_594060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594060.url(scheme.get, call_594060.host, call_594060.base,
                         call_594060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594060, url, valid)

proc call*(call_594061: Call_PostAddListenerCertificates_594046;
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
  var query_594062 = newJObject()
  var formData_594063 = newJObject()
  if Certificates != nil:
    formData_594063.add "Certificates", Certificates
  add(formData_594063, "ListenerArn", newJString(ListenerArn))
  add(query_594062, "Action", newJString(Action))
  add(query_594062, "Version", newJString(Version))
  result = call_594061.call(nil, query_594062, nil, formData_594063, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_594046(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_594047, base: "/",
    url: url_PostAddListenerCertificates_594048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_593774 = ref object of OpenApiRestCall_593437
proc url_GetAddListenerCertificates_593776(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddListenerCertificates_593775(path: JsonNode; query: JsonNode;
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
  var valid_593888 = query.getOrDefault("Certificates")
  valid_593888 = validateParameter(valid_593888, JArray, required = true, default = nil)
  if valid_593888 != nil:
    section.add "Certificates", valid_593888
  var valid_593902 = query.getOrDefault("Action")
  valid_593902 = validateParameter(valid_593902, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_593902 != nil:
    section.add "Action", valid_593902
  var valid_593903 = query.getOrDefault("ListenerArn")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = nil)
  if valid_593903 != nil:
    section.add "ListenerArn", valid_593903
  var valid_593904 = query.getOrDefault("Version")
  valid_593904 = validateParameter(valid_593904, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_593904 != nil:
    section.add "Version", valid_593904
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
  var valid_593905 = header.getOrDefault("X-Amz-Date")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Date", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Security-Token")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Security-Token", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Content-Sha256", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Algorithm")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Algorithm", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Signature")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Signature", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-SignedHeaders", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-Credential")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-Credential", valid_593911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593934: Call_GetAddListenerCertificates_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593934.validator(path, query, header, formData, body)
  let scheme = call_593934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593934.url(scheme.get, call_593934.host, call_593934.base,
                         call_593934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593934, url, valid)

proc call*(call_594005: Call_GetAddListenerCertificates_593774;
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
  var query_594006 = newJObject()
  if Certificates != nil:
    query_594006.add "Certificates", Certificates
  add(query_594006, "Action", newJString(Action))
  add(query_594006, "ListenerArn", newJString(ListenerArn))
  add(query_594006, "Version", newJString(Version))
  result = call_594005.call(nil, query_594006, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_593774(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_593775, base: "/",
    url: url_GetAddListenerCertificates_593776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_594081 = ref object of OpenApiRestCall_593437
proc url_PostAddTags_594083(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTags_594082(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594084 = query.getOrDefault("Action")
  valid_594084 = validateParameter(valid_594084, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_594084 != nil:
    section.add "Action", valid_594084
  var valid_594085 = query.getOrDefault("Version")
  valid_594085 = validateParameter(valid_594085, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594085 != nil:
    section.add "Version", valid_594085
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
  var valid_594086 = header.getOrDefault("X-Amz-Date")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Date", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Security-Token")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Security-Token", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Content-Sha256", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Algorithm")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Algorithm", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Signature")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Signature", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-SignedHeaders", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Credential")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Credential", valid_594092
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_594093 = formData.getOrDefault("ResourceArns")
  valid_594093 = validateParameter(valid_594093, JArray, required = true, default = nil)
  if valid_594093 != nil:
    section.add "ResourceArns", valid_594093
  var valid_594094 = formData.getOrDefault("Tags")
  valid_594094 = validateParameter(valid_594094, JArray, required = true, default = nil)
  if valid_594094 != nil:
    section.add "Tags", valid_594094
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594095: Call_PostAddTags_594081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_594095.validator(path, query, header, formData, body)
  let scheme = call_594095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594095.url(scheme.get, call_594095.host, call_594095.base,
                         call_594095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594095, url, valid)

proc call*(call_594096: Call_PostAddTags_594081; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594097 = newJObject()
  var formData_594098 = newJObject()
  if ResourceArns != nil:
    formData_594098.add "ResourceArns", ResourceArns
  if Tags != nil:
    formData_594098.add "Tags", Tags
  add(query_594097, "Action", newJString(Action))
  add(query_594097, "Version", newJString(Version))
  result = call_594096.call(nil, query_594097, nil, formData_594098, nil)

var postAddTags* = Call_PostAddTags_594081(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_594082,
                                        base: "/", url: url_PostAddTags_594083,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_594064 = ref object of OpenApiRestCall_593437
proc url_GetAddTags_594066(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTags_594065(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594067 = query.getOrDefault("Tags")
  valid_594067 = validateParameter(valid_594067, JArray, required = true, default = nil)
  if valid_594067 != nil:
    section.add "Tags", valid_594067
  var valid_594068 = query.getOrDefault("Action")
  valid_594068 = validateParameter(valid_594068, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_594068 != nil:
    section.add "Action", valid_594068
  var valid_594069 = query.getOrDefault("ResourceArns")
  valid_594069 = validateParameter(valid_594069, JArray, required = true, default = nil)
  if valid_594069 != nil:
    section.add "ResourceArns", valid_594069
  var valid_594070 = query.getOrDefault("Version")
  valid_594070 = validateParameter(valid_594070, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594070 != nil:
    section.add "Version", valid_594070
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
  var valid_594071 = header.getOrDefault("X-Amz-Date")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Date", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Security-Token")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Security-Token", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Content-Sha256", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Algorithm")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Algorithm", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Signature")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Signature", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-SignedHeaders", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Credential")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Credential", valid_594077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594078: Call_GetAddTags_594064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_594078.validator(path, query, header, formData, body)
  let scheme = call_594078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594078.url(scheme.get, call_594078.host, call_594078.base,
                         call_594078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594078, url, valid)

proc call*(call_594079: Call_GetAddTags_594064; Tags: JsonNode;
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
  var query_594080 = newJObject()
  if Tags != nil:
    query_594080.add "Tags", Tags
  add(query_594080, "Action", newJString(Action))
  if ResourceArns != nil:
    query_594080.add "ResourceArns", ResourceArns
  add(query_594080, "Version", newJString(Version))
  result = call_594079.call(nil, query_594080, nil, nil, nil)

var getAddTags* = Call_GetAddTags_594064(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_594065,
                                      base: "/", url: url_GetAddTags_594066,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_594120 = ref object of OpenApiRestCall_593437
proc url_PostCreateListener_594122(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateListener_594121(path: JsonNode; query: JsonNode;
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
  var valid_594123 = query.getOrDefault("Action")
  valid_594123 = validateParameter(valid_594123, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_594123 != nil:
    section.add "Action", valid_594123
  var valid_594124 = query.getOrDefault("Version")
  valid_594124 = validateParameter(valid_594124, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594124 != nil:
    section.add "Version", valid_594124
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
  var valid_594125 = header.getOrDefault("X-Amz-Date")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Date", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Security-Token")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Security-Token", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Content-Sha256", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Algorithm")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Algorithm", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Signature")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Signature", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-SignedHeaders", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Credential")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Credential", valid_594131
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
  var valid_594132 = formData.getOrDefault("Certificates")
  valid_594132 = validateParameter(valid_594132, JArray, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "Certificates", valid_594132
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_594133 = formData.getOrDefault("LoadBalancerArn")
  valid_594133 = validateParameter(valid_594133, JString, required = true,
                                 default = nil)
  if valid_594133 != nil:
    section.add "LoadBalancerArn", valid_594133
  var valid_594134 = formData.getOrDefault("Port")
  valid_594134 = validateParameter(valid_594134, JInt, required = true, default = nil)
  if valid_594134 != nil:
    section.add "Port", valid_594134
  var valid_594135 = formData.getOrDefault("Protocol")
  valid_594135 = validateParameter(valid_594135, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_594135 != nil:
    section.add "Protocol", valid_594135
  var valid_594136 = formData.getOrDefault("SslPolicy")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "SslPolicy", valid_594136
  var valid_594137 = formData.getOrDefault("DefaultActions")
  valid_594137 = validateParameter(valid_594137, JArray, required = true, default = nil)
  if valid_594137 != nil:
    section.add "DefaultActions", valid_594137
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594138: Call_PostCreateListener_594120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594138.validator(path, query, header, formData, body)
  let scheme = call_594138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594138.url(scheme.get, call_594138.host, call_594138.base,
                         call_594138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594138, url, valid)

proc call*(call_594139: Call_PostCreateListener_594120; LoadBalancerArn: string;
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
  var query_594140 = newJObject()
  var formData_594141 = newJObject()
  if Certificates != nil:
    formData_594141.add "Certificates", Certificates
  add(formData_594141, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_594141, "Port", newJInt(Port))
  add(formData_594141, "Protocol", newJString(Protocol))
  add(query_594140, "Action", newJString(Action))
  add(formData_594141, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_594141.add "DefaultActions", DefaultActions
  add(query_594140, "Version", newJString(Version))
  result = call_594139.call(nil, query_594140, nil, formData_594141, nil)

var postCreateListener* = Call_PostCreateListener_594120(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_594121, base: "/",
    url: url_PostCreateListener_594122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_594099 = ref object of OpenApiRestCall_593437
proc url_GetCreateListener_594101(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateListener_594100(path: JsonNode; query: JsonNode;
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
  var valid_594102 = query.getOrDefault("DefaultActions")
  valid_594102 = validateParameter(valid_594102, JArray, required = true, default = nil)
  if valid_594102 != nil:
    section.add "DefaultActions", valid_594102
  var valid_594103 = query.getOrDefault("SslPolicy")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "SslPolicy", valid_594103
  var valid_594104 = query.getOrDefault("Protocol")
  valid_594104 = validateParameter(valid_594104, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_594104 != nil:
    section.add "Protocol", valid_594104
  var valid_594105 = query.getOrDefault("Certificates")
  valid_594105 = validateParameter(valid_594105, JArray, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "Certificates", valid_594105
  var valid_594106 = query.getOrDefault("Action")
  valid_594106 = validateParameter(valid_594106, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_594106 != nil:
    section.add "Action", valid_594106
  var valid_594107 = query.getOrDefault("LoadBalancerArn")
  valid_594107 = validateParameter(valid_594107, JString, required = true,
                                 default = nil)
  if valid_594107 != nil:
    section.add "LoadBalancerArn", valid_594107
  var valid_594108 = query.getOrDefault("Port")
  valid_594108 = validateParameter(valid_594108, JInt, required = true, default = nil)
  if valid_594108 != nil:
    section.add "Port", valid_594108
  var valid_594109 = query.getOrDefault("Version")
  valid_594109 = validateParameter(valid_594109, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594109 != nil:
    section.add "Version", valid_594109
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
  var valid_594110 = header.getOrDefault("X-Amz-Date")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Date", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Security-Token")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Security-Token", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Content-Sha256", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Algorithm")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Algorithm", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Signature")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Signature", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-SignedHeaders", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Credential")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Credential", valid_594116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594117: Call_GetCreateListener_594099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594117.validator(path, query, header, formData, body)
  let scheme = call_594117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594117.url(scheme.get, call_594117.host, call_594117.base,
                         call_594117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594117, url, valid)

proc call*(call_594118: Call_GetCreateListener_594099; DefaultActions: JsonNode;
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
  var query_594119 = newJObject()
  if DefaultActions != nil:
    query_594119.add "DefaultActions", DefaultActions
  add(query_594119, "SslPolicy", newJString(SslPolicy))
  add(query_594119, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_594119.add "Certificates", Certificates
  add(query_594119, "Action", newJString(Action))
  add(query_594119, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594119, "Port", newJInt(Port))
  add(query_594119, "Version", newJString(Version))
  result = call_594118.call(nil, query_594119, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_594099(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_594100,
    base: "/", url: url_GetCreateListener_594101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_594165 = ref object of OpenApiRestCall_593437
proc url_PostCreateLoadBalancer_594167(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancer_594166(path: JsonNode; query: JsonNode;
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
  var valid_594168 = query.getOrDefault("Action")
  valid_594168 = validateParameter(valid_594168, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_594168 != nil:
    section.add "Action", valid_594168
  var valid_594169 = query.getOrDefault("Version")
  valid_594169 = validateParameter(valid_594169, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594169 != nil:
    section.add "Version", valid_594169
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
  var valid_594170 = header.getOrDefault("X-Amz-Date")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Date", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Security-Token")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Security-Token", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Content-Sha256", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Algorithm")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Algorithm", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Signature")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Signature", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-SignedHeaders", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-Credential")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Credential", valid_594176
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
  var valid_594177 = formData.getOrDefault("Name")
  valid_594177 = validateParameter(valid_594177, JString, required = true,
                                 default = nil)
  if valid_594177 != nil:
    section.add "Name", valid_594177
  var valid_594178 = formData.getOrDefault("IpAddressType")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_594178 != nil:
    section.add "IpAddressType", valid_594178
  var valid_594179 = formData.getOrDefault("Tags")
  valid_594179 = validateParameter(valid_594179, JArray, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "Tags", valid_594179
  var valid_594180 = formData.getOrDefault("Type")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = newJString("application"))
  if valid_594180 != nil:
    section.add "Type", valid_594180
  var valid_594181 = formData.getOrDefault("Subnets")
  valid_594181 = validateParameter(valid_594181, JArray, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "Subnets", valid_594181
  var valid_594182 = formData.getOrDefault("SecurityGroups")
  valid_594182 = validateParameter(valid_594182, JArray, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "SecurityGroups", valid_594182
  var valid_594183 = formData.getOrDefault("SubnetMappings")
  valid_594183 = validateParameter(valid_594183, JArray, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "SubnetMappings", valid_594183
  var valid_594184 = formData.getOrDefault("Scheme")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_594184 != nil:
    section.add "Scheme", valid_594184
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594185: Call_PostCreateLoadBalancer_594165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594185.validator(path, query, header, formData, body)
  let scheme = call_594185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594185.url(scheme.get, call_594185.host, call_594185.base,
                         call_594185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594185, url, valid)

proc call*(call_594186: Call_PostCreateLoadBalancer_594165; Name: string;
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
  var query_594187 = newJObject()
  var formData_594188 = newJObject()
  add(formData_594188, "Name", newJString(Name))
  add(formData_594188, "IpAddressType", newJString(IpAddressType))
  if Tags != nil:
    formData_594188.add "Tags", Tags
  add(formData_594188, "Type", newJString(Type))
  add(query_594187, "Action", newJString(Action))
  if Subnets != nil:
    formData_594188.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_594188.add "SecurityGroups", SecurityGroups
  if SubnetMappings != nil:
    formData_594188.add "SubnetMappings", SubnetMappings
  add(formData_594188, "Scheme", newJString(Scheme))
  add(query_594187, "Version", newJString(Version))
  result = call_594186.call(nil, query_594187, nil, formData_594188, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_594165(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_594166, base: "/",
    url: url_PostCreateLoadBalancer_594167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_594142 = ref object of OpenApiRestCall_593437
proc url_GetCreateLoadBalancer_594144(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancer_594143(path: JsonNode; query: JsonNode;
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
  var valid_594145 = query.getOrDefault("Name")
  valid_594145 = validateParameter(valid_594145, JString, required = true,
                                 default = nil)
  if valid_594145 != nil:
    section.add "Name", valid_594145
  var valid_594146 = query.getOrDefault("SubnetMappings")
  valid_594146 = validateParameter(valid_594146, JArray, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "SubnetMappings", valid_594146
  var valid_594147 = query.getOrDefault("IpAddressType")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_594147 != nil:
    section.add "IpAddressType", valid_594147
  var valid_594148 = query.getOrDefault("Scheme")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_594148 != nil:
    section.add "Scheme", valid_594148
  var valid_594149 = query.getOrDefault("Tags")
  valid_594149 = validateParameter(valid_594149, JArray, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "Tags", valid_594149
  var valid_594150 = query.getOrDefault("Type")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = newJString("application"))
  if valid_594150 != nil:
    section.add "Type", valid_594150
  var valid_594151 = query.getOrDefault("Action")
  valid_594151 = validateParameter(valid_594151, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_594151 != nil:
    section.add "Action", valid_594151
  var valid_594152 = query.getOrDefault("Subnets")
  valid_594152 = validateParameter(valid_594152, JArray, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "Subnets", valid_594152
  var valid_594153 = query.getOrDefault("Version")
  valid_594153 = validateParameter(valid_594153, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594153 != nil:
    section.add "Version", valid_594153
  var valid_594154 = query.getOrDefault("SecurityGroups")
  valid_594154 = validateParameter(valid_594154, JArray, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "SecurityGroups", valid_594154
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
  var valid_594155 = header.getOrDefault("X-Amz-Date")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Date", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Security-Token")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Security-Token", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Content-Sha256", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Algorithm")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Algorithm", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Signature")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Signature", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-SignedHeaders", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Credential")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Credential", valid_594161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594162: Call_GetCreateLoadBalancer_594142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594162.validator(path, query, header, formData, body)
  let scheme = call_594162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594162.url(scheme.get, call_594162.host, call_594162.base,
                         call_594162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594162, url, valid)

proc call*(call_594163: Call_GetCreateLoadBalancer_594142; Name: string;
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
  var query_594164 = newJObject()
  add(query_594164, "Name", newJString(Name))
  if SubnetMappings != nil:
    query_594164.add "SubnetMappings", SubnetMappings
  add(query_594164, "IpAddressType", newJString(IpAddressType))
  add(query_594164, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_594164.add "Tags", Tags
  add(query_594164, "Type", newJString(Type))
  add(query_594164, "Action", newJString(Action))
  if Subnets != nil:
    query_594164.add "Subnets", Subnets
  add(query_594164, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_594164.add "SecurityGroups", SecurityGroups
  result = call_594163.call(nil, query_594164, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_594142(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_594143, base: "/",
    url: url_GetCreateLoadBalancer_594144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_594208 = ref object of OpenApiRestCall_593437
proc url_PostCreateRule_594210(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateRule_594209(path: JsonNode; query: JsonNode;
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
  var valid_594211 = query.getOrDefault("Action")
  valid_594211 = validateParameter(valid_594211, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_594211 != nil:
    section.add "Action", valid_594211
  var valid_594212 = query.getOrDefault("Version")
  valid_594212 = validateParameter(valid_594212, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594212 != nil:
    section.add "Version", valid_594212
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
  var valid_594213 = header.getOrDefault("X-Amz-Date")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Date", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Security-Token")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Security-Token", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Content-Sha256", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Algorithm")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Algorithm", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Signature")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Signature", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-SignedHeaders", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-Credential")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-Credential", valid_594219
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
  var valid_594220 = formData.getOrDefault("ListenerArn")
  valid_594220 = validateParameter(valid_594220, JString, required = true,
                                 default = nil)
  if valid_594220 != nil:
    section.add "ListenerArn", valid_594220
  var valid_594221 = formData.getOrDefault("Actions")
  valid_594221 = validateParameter(valid_594221, JArray, required = true, default = nil)
  if valid_594221 != nil:
    section.add "Actions", valid_594221
  var valid_594222 = formData.getOrDefault("Conditions")
  valid_594222 = validateParameter(valid_594222, JArray, required = true, default = nil)
  if valid_594222 != nil:
    section.add "Conditions", valid_594222
  var valid_594223 = formData.getOrDefault("Priority")
  valid_594223 = validateParameter(valid_594223, JInt, required = true, default = nil)
  if valid_594223 != nil:
    section.add "Priority", valid_594223
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594224: Call_PostCreateRule_594208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_594224.validator(path, query, header, formData, body)
  let scheme = call_594224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594224.url(scheme.get, call_594224.host, call_594224.base,
                         call_594224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594224, url, valid)

proc call*(call_594225: Call_PostCreateRule_594208; ListenerArn: string;
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
  var query_594226 = newJObject()
  var formData_594227 = newJObject()
  add(formData_594227, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    formData_594227.add "Actions", Actions
  if Conditions != nil:
    formData_594227.add "Conditions", Conditions
  add(query_594226, "Action", newJString(Action))
  add(formData_594227, "Priority", newJInt(Priority))
  add(query_594226, "Version", newJString(Version))
  result = call_594225.call(nil, query_594226, nil, formData_594227, nil)

var postCreateRule* = Call_PostCreateRule_594208(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_594209,
    base: "/", url: url_PostCreateRule_594210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_594189 = ref object of OpenApiRestCall_593437
proc url_GetCreateRule_594191(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateRule_594190(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594192 = query.getOrDefault("Conditions")
  valid_594192 = validateParameter(valid_594192, JArray, required = true, default = nil)
  if valid_594192 != nil:
    section.add "Conditions", valid_594192
  var valid_594193 = query.getOrDefault("Action")
  valid_594193 = validateParameter(valid_594193, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_594193 != nil:
    section.add "Action", valid_594193
  var valid_594194 = query.getOrDefault("ListenerArn")
  valid_594194 = validateParameter(valid_594194, JString, required = true,
                                 default = nil)
  if valid_594194 != nil:
    section.add "ListenerArn", valid_594194
  var valid_594195 = query.getOrDefault("Actions")
  valid_594195 = validateParameter(valid_594195, JArray, required = true, default = nil)
  if valid_594195 != nil:
    section.add "Actions", valid_594195
  var valid_594196 = query.getOrDefault("Priority")
  valid_594196 = validateParameter(valid_594196, JInt, required = true, default = nil)
  if valid_594196 != nil:
    section.add "Priority", valid_594196
  var valid_594197 = query.getOrDefault("Version")
  valid_594197 = validateParameter(valid_594197, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594197 != nil:
    section.add "Version", valid_594197
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
  var valid_594198 = header.getOrDefault("X-Amz-Date")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Date", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Security-Token")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Security-Token", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Content-Sha256", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Algorithm")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Algorithm", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Signature")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Signature", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-SignedHeaders", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-Credential")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-Credential", valid_594204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_GetCreateRule_594189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_GetCreateRule_594189; Conditions: JsonNode;
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
  var query_594207 = newJObject()
  if Conditions != nil:
    query_594207.add "Conditions", Conditions
  add(query_594207, "Action", newJString(Action))
  add(query_594207, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    query_594207.add "Actions", Actions
  add(query_594207, "Priority", newJInt(Priority))
  add(query_594207, "Version", newJString(Version))
  result = call_594206.call(nil, query_594207, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_594189(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_594190,
    base: "/", url: url_GetCreateRule_594191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_594257 = ref object of OpenApiRestCall_593437
proc url_PostCreateTargetGroup_594259(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateTargetGroup_594258(path: JsonNode; query: JsonNode;
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
  var valid_594260 = query.getOrDefault("Action")
  valid_594260 = validateParameter(valid_594260, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_594260 != nil:
    section.add "Action", valid_594260
  var valid_594261 = query.getOrDefault("Version")
  valid_594261 = validateParameter(valid_594261, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594261 != nil:
    section.add "Version", valid_594261
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
  var valid_594262 = header.getOrDefault("X-Amz-Date")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Date", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Security-Token")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Security-Token", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Content-Sha256", valid_594264
  var valid_594265 = header.getOrDefault("X-Amz-Algorithm")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Algorithm", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Signature")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Signature", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-SignedHeaders", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Credential")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Credential", valid_594268
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
  var valid_594269 = formData.getOrDefault("Name")
  valid_594269 = validateParameter(valid_594269, JString, required = true,
                                 default = nil)
  if valid_594269 != nil:
    section.add "Name", valid_594269
  var valid_594270 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_594270 = validateParameter(valid_594270, JInt, required = false, default = nil)
  if valid_594270 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_594270
  var valid_594271 = formData.getOrDefault("Port")
  valid_594271 = validateParameter(valid_594271, JInt, required = false, default = nil)
  if valid_594271 != nil:
    section.add "Port", valid_594271
  var valid_594272 = formData.getOrDefault("Protocol")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594272 != nil:
    section.add "Protocol", valid_594272
  var valid_594273 = formData.getOrDefault("HealthCheckPort")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "HealthCheckPort", valid_594273
  var valid_594274 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_594274 = validateParameter(valid_594274, JInt, required = false, default = nil)
  if valid_594274 != nil:
    section.add "UnhealthyThresholdCount", valid_594274
  var valid_594275 = formData.getOrDefault("HealthCheckEnabled")
  valid_594275 = validateParameter(valid_594275, JBool, required = false, default = nil)
  if valid_594275 != nil:
    section.add "HealthCheckEnabled", valid_594275
  var valid_594276 = formData.getOrDefault("HealthCheckPath")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "HealthCheckPath", valid_594276
  var valid_594277 = formData.getOrDefault("TargetType")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = newJString("instance"))
  if valid_594277 != nil:
    section.add "TargetType", valid_594277
  var valid_594278 = formData.getOrDefault("VpcId")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "VpcId", valid_594278
  var valid_594279 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_594279 = validateParameter(valid_594279, JInt, required = false, default = nil)
  if valid_594279 != nil:
    section.add "HealthCheckIntervalSeconds", valid_594279
  var valid_594280 = formData.getOrDefault("HealthyThresholdCount")
  valid_594280 = validateParameter(valid_594280, JInt, required = false, default = nil)
  if valid_594280 != nil:
    section.add "HealthyThresholdCount", valid_594280
  var valid_594281 = formData.getOrDefault("HealthCheckProtocol")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594281 != nil:
    section.add "HealthCheckProtocol", valid_594281
  var valid_594282 = formData.getOrDefault("Matcher.HttpCode")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "Matcher.HttpCode", valid_594282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594283: Call_PostCreateTargetGroup_594257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594283.validator(path, query, header, formData, body)
  let scheme = call_594283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594283.url(scheme.get, call_594283.host, call_594283.base,
                         call_594283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594283, url, valid)

proc call*(call_594284: Call_PostCreateTargetGroup_594257; Name: string;
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
  var query_594285 = newJObject()
  var formData_594286 = newJObject()
  add(formData_594286, "Name", newJString(Name))
  add(formData_594286, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_594286, "Port", newJInt(Port))
  add(formData_594286, "Protocol", newJString(Protocol))
  add(formData_594286, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_594286, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_594286, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_594286, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_594286, "TargetType", newJString(TargetType))
  add(query_594285, "Action", newJString(Action))
  add(formData_594286, "VpcId", newJString(VpcId))
  add(formData_594286, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_594286, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_594286, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_594286, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_594285, "Version", newJString(Version))
  result = call_594284.call(nil, query_594285, nil, formData_594286, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_594257(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_594258, base: "/",
    url: url_PostCreateTargetGroup_594259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_594228 = ref object of OpenApiRestCall_593437
proc url_GetCreateTargetGroup_594230(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateTargetGroup_594229(path: JsonNode; query: JsonNode;
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
  var valid_594231 = query.getOrDefault("HealthCheckEnabled")
  valid_594231 = validateParameter(valid_594231, JBool, required = false, default = nil)
  if valid_594231 != nil:
    section.add "HealthCheckEnabled", valid_594231
  var valid_594232 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_594232 = validateParameter(valid_594232, JInt, required = false, default = nil)
  if valid_594232 != nil:
    section.add "HealthCheckIntervalSeconds", valid_594232
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_594233 = query.getOrDefault("Name")
  valid_594233 = validateParameter(valid_594233, JString, required = true,
                                 default = nil)
  if valid_594233 != nil:
    section.add "Name", valid_594233
  var valid_594234 = query.getOrDefault("HealthCheckPort")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "HealthCheckPort", valid_594234
  var valid_594235 = query.getOrDefault("Protocol")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594235 != nil:
    section.add "Protocol", valid_594235
  var valid_594236 = query.getOrDefault("VpcId")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "VpcId", valid_594236
  var valid_594237 = query.getOrDefault("Action")
  valid_594237 = validateParameter(valid_594237, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_594237 != nil:
    section.add "Action", valid_594237
  var valid_594238 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_594238 = validateParameter(valid_594238, JInt, required = false, default = nil)
  if valid_594238 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_594238
  var valid_594239 = query.getOrDefault("Matcher.HttpCode")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "Matcher.HttpCode", valid_594239
  var valid_594240 = query.getOrDefault("UnhealthyThresholdCount")
  valid_594240 = validateParameter(valid_594240, JInt, required = false, default = nil)
  if valid_594240 != nil:
    section.add "UnhealthyThresholdCount", valid_594240
  var valid_594241 = query.getOrDefault("TargetType")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = newJString("instance"))
  if valid_594241 != nil:
    section.add "TargetType", valid_594241
  var valid_594242 = query.getOrDefault("Port")
  valid_594242 = validateParameter(valid_594242, JInt, required = false, default = nil)
  if valid_594242 != nil:
    section.add "Port", valid_594242
  var valid_594243 = query.getOrDefault("HealthCheckProtocol")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594243 != nil:
    section.add "HealthCheckProtocol", valid_594243
  var valid_594244 = query.getOrDefault("HealthyThresholdCount")
  valid_594244 = validateParameter(valid_594244, JInt, required = false, default = nil)
  if valid_594244 != nil:
    section.add "HealthyThresholdCount", valid_594244
  var valid_594245 = query.getOrDefault("Version")
  valid_594245 = validateParameter(valid_594245, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594245 != nil:
    section.add "Version", valid_594245
  var valid_594246 = query.getOrDefault("HealthCheckPath")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "HealthCheckPath", valid_594246
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
  var valid_594247 = header.getOrDefault("X-Amz-Date")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Date", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Security-Token")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Security-Token", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Content-Sha256", valid_594249
  var valid_594250 = header.getOrDefault("X-Amz-Algorithm")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Algorithm", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Signature")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Signature", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-SignedHeaders", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Credential")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Credential", valid_594253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594254: Call_GetCreateTargetGroup_594228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594254.validator(path, query, header, formData, body)
  let scheme = call_594254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594254.url(scheme.get, call_594254.host, call_594254.base,
                         call_594254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594254, url, valid)

proc call*(call_594255: Call_GetCreateTargetGroup_594228; Name: string;
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
  var query_594256 = newJObject()
  add(query_594256, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_594256, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_594256, "Name", newJString(Name))
  add(query_594256, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_594256, "Protocol", newJString(Protocol))
  add(query_594256, "VpcId", newJString(VpcId))
  add(query_594256, "Action", newJString(Action))
  add(query_594256, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_594256, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_594256, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_594256, "TargetType", newJString(TargetType))
  add(query_594256, "Port", newJInt(Port))
  add(query_594256, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_594256, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_594256, "Version", newJString(Version))
  add(query_594256, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_594255.call(nil, query_594256, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_594228(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_594229,
    base: "/", url: url_GetCreateTargetGroup_594230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_594303 = ref object of OpenApiRestCall_593437
proc url_PostDeleteListener_594305(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteListener_594304(path: JsonNode; query: JsonNode;
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
  var valid_594306 = query.getOrDefault("Action")
  valid_594306 = validateParameter(valid_594306, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_594306 != nil:
    section.add "Action", valid_594306
  var valid_594307 = query.getOrDefault("Version")
  valid_594307 = validateParameter(valid_594307, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594307 != nil:
    section.add "Version", valid_594307
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
  var valid_594308 = header.getOrDefault("X-Amz-Date")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Date", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Security-Token")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Security-Token", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Content-Sha256", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Algorithm")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Algorithm", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-Signature")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Signature", valid_594312
  var valid_594313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-SignedHeaders", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-Credential")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Credential", valid_594314
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_594315 = formData.getOrDefault("ListenerArn")
  valid_594315 = validateParameter(valid_594315, JString, required = true,
                                 default = nil)
  if valid_594315 != nil:
    section.add "ListenerArn", valid_594315
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594316: Call_PostDeleteListener_594303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_594316.validator(path, query, header, formData, body)
  let scheme = call_594316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594316.url(scheme.get, call_594316.host, call_594316.base,
                         call_594316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594316, url, valid)

proc call*(call_594317: Call_PostDeleteListener_594303; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594318 = newJObject()
  var formData_594319 = newJObject()
  add(formData_594319, "ListenerArn", newJString(ListenerArn))
  add(query_594318, "Action", newJString(Action))
  add(query_594318, "Version", newJString(Version))
  result = call_594317.call(nil, query_594318, nil, formData_594319, nil)

var postDeleteListener* = Call_PostDeleteListener_594303(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_594304, base: "/",
    url: url_PostDeleteListener_594305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_594287 = ref object of OpenApiRestCall_593437
proc url_GetDeleteListener_594289(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteListener_594288(path: JsonNode; query: JsonNode;
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
  var valid_594290 = query.getOrDefault("Action")
  valid_594290 = validateParameter(valid_594290, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_594290 != nil:
    section.add "Action", valid_594290
  var valid_594291 = query.getOrDefault("ListenerArn")
  valid_594291 = validateParameter(valid_594291, JString, required = true,
                                 default = nil)
  if valid_594291 != nil:
    section.add "ListenerArn", valid_594291
  var valid_594292 = query.getOrDefault("Version")
  valid_594292 = validateParameter(valid_594292, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594292 != nil:
    section.add "Version", valid_594292
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
  var valid_594293 = header.getOrDefault("X-Amz-Date")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Date", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-Security-Token")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Security-Token", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Content-Sha256", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Algorithm")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Algorithm", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-Signature")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Signature", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-SignedHeaders", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-Credential")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Credential", valid_594299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594300: Call_GetDeleteListener_594287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_594300.validator(path, query, header, formData, body)
  let scheme = call_594300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594300.url(scheme.get, call_594300.host, call_594300.base,
                         call_594300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594300, url, valid)

proc call*(call_594301: Call_GetDeleteListener_594287; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  var query_594302 = newJObject()
  add(query_594302, "Action", newJString(Action))
  add(query_594302, "ListenerArn", newJString(ListenerArn))
  add(query_594302, "Version", newJString(Version))
  result = call_594301.call(nil, query_594302, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_594287(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_594288,
    base: "/", url: url_GetDeleteListener_594289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_594336 = ref object of OpenApiRestCall_593437
proc url_PostDeleteLoadBalancer_594338(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancer_594337(path: JsonNode; query: JsonNode;
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
  var valid_594339 = query.getOrDefault("Action")
  valid_594339 = validateParameter(valid_594339, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_594339 != nil:
    section.add "Action", valid_594339
  var valid_594340 = query.getOrDefault("Version")
  valid_594340 = validateParameter(valid_594340, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594340 != nil:
    section.add "Version", valid_594340
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
  var valid_594341 = header.getOrDefault("X-Amz-Date")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Date", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Security-Token")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Security-Token", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Content-Sha256", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Algorithm")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Algorithm", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Signature")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Signature", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-SignedHeaders", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Credential")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Credential", valid_594347
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_594348 = formData.getOrDefault("LoadBalancerArn")
  valid_594348 = validateParameter(valid_594348, JString, required = true,
                                 default = nil)
  if valid_594348 != nil:
    section.add "LoadBalancerArn", valid_594348
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594349: Call_PostDeleteLoadBalancer_594336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_594349.validator(path, query, header, formData, body)
  let scheme = call_594349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594349.url(scheme.get, call_594349.host, call_594349.base,
                         call_594349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594349, url, valid)

proc call*(call_594350: Call_PostDeleteLoadBalancer_594336;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594351 = newJObject()
  var formData_594352 = newJObject()
  add(formData_594352, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594351, "Action", newJString(Action))
  add(query_594351, "Version", newJString(Version))
  result = call_594350.call(nil, query_594351, nil, formData_594352, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_594336(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_594337, base: "/",
    url: url_PostDeleteLoadBalancer_594338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_594320 = ref object of OpenApiRestCall_593437
proc url_GetDeleteLoadBalancer_594322(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancer_594321(path: JsonNode; query: JsonNode;
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
  var valid_594323 = query.getOrDefault("Action")
  valid_594323 = validateParameter(valid_594323, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_594323 != nil:
    section.add "Action", valid_594323
  var valid_594324 = query.getOrDefault("LoadBalancerArn")
  valid_594324 = validateParameter(valid_594324, JString, required = true,
                                 default = nil)
  if valid_594324 != nil:
    section.add "LoadBalancerArn", valid_594324
  var valid_594325 = query.getOrDefault("Version")
  valid_594325 = validateParameter(valid_594325, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594325 != nil:
    section.add "Version", valid_594325
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
  var valid_594326 = header.getOrDefault("X-Amz-Date")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-Date", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Security-Token")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Security-Token", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Content-Sha256", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-Algorithm")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Algorithm", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Signature")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Signature", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-SignedHeaders", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Credential")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Credential", valid_594332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594333: Call_GetDeleteLoadBalancer_594320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_594333.validator(path, query, header, formData, body)
  let scheme = call_594333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594333.url(scheme.get, call_594333.host, call_594333.base,
                         call_594333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594333, url, valid)

proc call*(call_594334: Call_GetDeleteLoadBalancer_594320; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_594335 = newJObject()
  add(query_594335, "Action", newJString(Action))
  add(query_594335, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594335, "Version", newJString(Version))
  result = call_594334.call(nil, query_594335, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_594320(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_594321, base: "/",
    url: url_GetDeleteLoadBalancer_594322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_594369 = ref object of OpenApiRestCall_593437
proc url_PostDeleteRule_594371(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteRule_594370(path: JsonNode; query: JsonNode;
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
  var valid_594372 = query.getOrDefault("Action")
  valid_594372 = validateParameter(valid_594372, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_594372 != nil:
    section.add "Action", valid_594372
  var valid_594373 = query.getOrDefault("Version")
  valid_594373 = validateParameter(valid_594373, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594373 != nil:
    section.add "Version", valid_594373
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
  var valid_594374 = header.getOrDefault("X-Amz-Date")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "X-Amz-Date", valid_594374
  var valid_594375 = header.getOrDefault("X-Amz-Security-Token")
  valid_594375 = validateParameter(valid_594375, JString, required = false,
                                 default = nil)
  if valid_594375 != nil:
    section.add "X-Amz-Security-Token", valid_594375
  var valid_594376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Content-Sha256", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Algorithm")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Algorithm", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Signature")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Signature", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-SignedHeaders", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Credential")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Credential", valid_594380
  result.add "header", section
  ## parameters in `formData` object:
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_594381 = formData.getOrDefault("RuleArn")
  valid_594381 = validateParameter(valid_594381, JString, required = true,
                                 default = nil)
  if valid_594381 != nil:
    section.add "RuleArn", valid_594381
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594382: Call_PostDeleteRule_594369; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_594382.validator(path, query, header, formData, body)
  let scheme = call_594382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594382.url(scheme.get, call_594382.host, call_594382.base,
                         call_594382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594382, url, valid)

proc call*(call_594383: Call_PostDeleteRule_594369; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594384 = newJObject()
  var formData_594385 = newJObject()
  add(formData_594385, "RuleArn", newJString(RuleArn))
  add(query_594384, "Action", newJString(Action))
  add(query_594384, "Version", newJString(Version))
  result = call_594383.call(nil, query_594384, nil, formData_594385, nil)

var postDeleteRule* = Call_PostDeleteRule_594369(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_594370,
    base: "/", url: url_PostDeleteRule_594371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_594353 = ref object of OpenApiRestCall_593437
proc url_GetDeleteRule_594355(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteRule_594354(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594356 = query.getOrDefault("Action")
  valid_594356 = validateParameter(valid_594356, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_594356 != nil:
    section.add "Action", valid_594356
  var valid_594357 = query.getOrDefault("RuleArn")
  valid_594357 = validateParameter(valid_594357, JString, required = true,
                                 default = nil)
  if valid_594357 != nil:
    section.add "RuleArn", valid_594357
  var valid_594358 = query.getOrDefault("Version")
  valid_594358 = validateParameter(valid_594358, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594358 != nil:
    section.add "Version", valid_594358
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
  var valid_594359 = header.getOrDefault("X-Amz-Date")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Date", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-Security-Token")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-Security-Token", valid_594360
  var valid_594361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Content-Sha256", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Algorithm")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Algorithm", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-Signature")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Signature", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-SignedHeaders", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Credential")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Credential", valid_594365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594366: Call_GetDeleteRule_594353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_594366.validator(path, query, header, formData, body)
  let scheme = call_594366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594366.url(scheme.get, call_594366.host, call_594366.base,
                         call_594366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594366, url, valid)

proc call*(call_594367: Call_GetDeleteRule_594353; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   Action: string (required)
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Version: string (required)
  var query_594368 = newJObject()
  add(query_594368, "Action", newJString(Action))
  add(query_594368, "RuleArn", newJString(RuleArn))
  add(query_594368, "Version", newJString(Version))
  result = call_594367.call(nil, query_594368, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_594353(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_594354,
    base: "/", url: url_GetDeleteRule_594355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_594402 = ref object of OpenApiRestCall_593437
proc url_PostDeleteTargetGroup_594404(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteTargetGroup_594403(path: JsonNode; query: JsonNode;
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
  var valid_594405 = query.getOrDefault("Action")
  valid_594405 = validateParameter(valid_594405, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_594405 != nil:
    section.add "Action", valid_594405
  var valid_594406 = query.getOrDefault("Version")
  valid_594406 = validateParameter(valid_594406, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594406 != nil:
    section.add "Version", valid_594406
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
  var valid_594407 = header.getOrDefault("X-Amz-Date")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Date", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-Security-Token")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Security-Token", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Content-Sha256", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Algorithm")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Algorithm", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Signature")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Signature", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-SignedHeaders", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Credential")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Credential", valid_594413
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_594414 = formData.getOrDefault("TargetGroupArn")
  valid_594414 = validateParameter(valid_594414, JString, required = true,
                                 default = nil)
  if valid_594414 != nil:
    section.add "TargetGroupArn", valid_594414
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594415: Call_PostDeleteTargetGroup_594402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_594415.validator(path, query, header, formData, body)
  let scheme = call_594415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594415.url(scheme.get, call_594415.host, call_594415.base,
                         call_594415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594415, url, valid)

proc call*(call_594416: Call_PostDeleteTargetGroup_594402; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_594417 = newJObject()
  var formData_594418 = newJObject()
  add(query_594417, "Action", newJString(Action))
  add(formData_594418, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594417, "Version", newJString(Version))
  result = call_594416.call(nil, query_594417, nil, formData_594418, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_594402(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_594403, base: "/",
    url: url_PostDeleteTargetGroup_594404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_594386 = ref object of OpenApiRestCall_593437
proc url_GetDeleteTargetGroup_594388(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteTargetGroup_594387(path: JsonNode; query: JsonNode;
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
  var valid_594389 = query.getOrDefault("TargetGroupArn")
  valid_594389 = validateParameter(valid_594389, JString, required = true,
                                 default = nil)
  if valid_594389 != nil:
    section.add "TargetGroupArn", valid_594389
  var valid_594390 = query.getOrDefault("Action")
  valid_594390 = validateParameter(valid_594390, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_594390 != nil:
    section.add "Action", valid_594390
  var valid_594391 = query.getOrDefault("Version")
  valid_594391 = validateParameter(valid_594391, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594391 != nil:
    section.add "Version", valid_594391
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
  var valid_594392 = header.getOrDefault("X-Amz-Date")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Date", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Security-Token")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Security-Token", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Content-Sha256", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Algorithm")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Algorithm", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Signature")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Signature", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-SignedHeaders", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Credential")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Credential", valid_594398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594399: Call_GetDeleteTargetGroup_594386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_594399.validator(path, query, header, formData, body)
  let scheme = call_594399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594399.url(scheme.get, call_594399.host, call_594399.base,
                         call_594399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594399, url, valid)

proc call*(call_594400: Call_GetDeleteTargetGroup_594386; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594401 = newJObject()
  add(query_594401, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594401, "Action", newJString(Action))
  add(query_594401, "Version", newJString(Version))
  result = call_594400.call(nil, query_594401, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_594386(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_594387,
    base: "/", url: url_GetDeleteTargetGroup_594388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_594436 = ref object of OpenApiRestCall_593437
proc url_PostDeregisterTargets_594438(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeregisterTargets_594437(path: JsonNode; query: JsonNode;
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
  var valid_594439 = query.getOrDefault("Action")
  valid_594439 = validateParameter(valid_594439, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_594439 != nil:
    section.add "Action", valid_594439
  var valid_594440 = query.getOrDefault("Version")
  valid_594440 = validateParameter(valid_594440, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594440 != nil:
    section.add "Version", valid_594440
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
  var valid_594441 = header.getOrDefault("X-Amz-Date")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Date", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Security-Token")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Security-Token", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Content-Sha256", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Algorithm")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Algorithm", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Signature")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Signature", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-SignedHeaders", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-Credential")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Credential", valid_594447
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_594448 = formData.getOrDefault("Targets")
  valid_594448 = validateParameter(valid_594448, JArray, required = true, default = nil)
  if valid_594448 != nil:
    section.add "Targets", valid_594448
  var valid_594449 = formData.getOrDefault("TargetGroupArn")
  valid_594449 = validateParameter(valid_594449, JString, required = true,
                                 default = nil)
  if valid_594449 != nil:
    section.add "TargetGroupArn", valid_594449
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594450: Call_PostDeregisterTargets_594436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_594450.validator(path, query, header, formData, body)
  let scheme = call_594450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594450.url(scheme.get, call_594450.host, call_594450.base,
                         call_594450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594450, url, valid)

proc call*(call_594451: Call_PostDeregisterTargets_594436; Targets: JsonNode;
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
  var query_594452 = newJObject()
  var formData_594453 = newJObject()
  if Targets != nil:
    formData_594453.add "Targets", Targets
  add(query_594452, "Action", newJString(Action))
  add(formData_594453, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594452, "Version", newJString(Version))
  result = call_594451.call(nil, query_594452, nil, formData_594453, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_594436(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_594437, base: "/",
    url: url_PostDeregisterTargets_594438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_594419 = ref object of OpenApiRestCall_593437
proc url_GetDeregisterTargets_594421(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeregisterTargets_594420(path: JsonNode; query: JsonNode;
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
  var valid_594422 = query.getOrDefault("Targets")
  valid_594422 = validateParameter(valid_594422, JArray, required = true, default = nil)
  if valid_594422 != nil:
    section.add "Targets", valid_594422
  var valid_594423 = query.getOrDefault("TargetGroupArn")
  valid_594423 = validateParameter(valid_594423, JString, required = true,
                                 default = nil)
  if valid_594423 != nil:
    section.add "TargetGroupArn", valid_594423
  var valid_594424 = query.getOrDefault("Action")
  valid_594424 = validateParameter(valid_594424, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_594424 != nil:
    section.add "Action", valid_594424
  var valid_594425 = query.getOrDefault("Version")
  valid_594425 = validateParameter(valid_594425, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594425 != nil:
    section.add "Version", valid_594425
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
  var valid_594426 = header.getOrDefault("X-Amz-Date")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Date", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Security-Token")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Security-Token", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Content-Sha256", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Algorithm")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Algorithm", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Signature")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Signature", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-SignedHeaders", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-Credential")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Credential", valid_594432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594433: Call_GetDeregisterTargets_594419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_594433.validator(path, query, header, formData, body)
  let scheme = call_594433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594433.url(scheme.get, call_594433.host, call_594433.base,
                         call_594433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594433, url, valid)

proc call*(call_594434: Call_GetDeregisterTargets_594419; Targets: JsonNode;
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
  var query_594435 = newJObject()
  if Targets != nil:
    query_594435.add "Targets", Targets
  add(query_594435, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594435, "Action", newJString(Action))
  add(query_594435, "Version", newJString(Version))
  result = call_594434.call(nil, query_594435, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_594419(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_594420,
    base: "/", url: url_GetDeregisterTargets_594421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_594471 = ref object of OpenApiRestCall_593437
proc url_PostDescribeAccountLimits_594473(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAccountLimits_594472(path: JsonNode; query: JsonNode;
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
  var valid_594474 = query.getOrDefault("Action")
  valid_594474 = validateParameter(valid_594474, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_594474 != nil:
    section.add "Action", valid_594474
  var valid_594475 = query.getOrDefault("Version")
  valid_594475 = validateParameter(valid_594475, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594475 != nil:
    section.add "Version", valid_594475
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
  var valid_594476 = header.getOrDefault("X-Amz-Date")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Date", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Security-Token")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Security-Token", valid_594477
  var valid_594478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-Content-Sha256", valid_594478
  var valid_594479 = header.getOrDefault("X-Amz-Algorithm")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-Algorithm", valid_594479
  var valid_594480 = header.getOrDefault("X-Amz-Signature")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-Signature", valid_594480
  var valid_594481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-SignedHeaders", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Credential")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Credential", valid_594482
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_594483 = formData.getOrDefault("Marker")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "Marker", valid_594483
  var valid_594484 = formData.getOrDefault("PageSize")
  valid_594484 = validateParameter(valid_594484, JInt, required = false, default = nil)
  if valid_594484 != nil:
    section.add "PageSize", valid_594484
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594485: Call_PostDescribeAccountLimits_594471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594485.validator(path, query, header, formData, body)
  let scheme = call_594485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594485.url(scheme.get, call_594485.host, call_594485.base,
                         call_594485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594485, url, valid)

proc call*(call_594486: Call_PostDescribeAccountLimits_594471; Marker: string = "";
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
  var query_594487 = newJObject()
  var formData_594488 = newJObject()
  add(formData_594488, "Marker", newJString(Marker))
  add(query_594487, "Action", newJString(Action))
  add(formData_594488, "PageSize", newJInt(PageSize))
  add(query_594487, "Version", newJString(Version))
  result = call_594486.call(nil, query_594487, nil, formData_594488, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_594471(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_594472, base: "/",
    url: url_PostDescribeAccountLimits_594473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_594454 = ref object of OpenApiRestCall_593437
proc url_GetDescribeAccountLimits_594456(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAccountLimits_594455(path: JsonNode; query: JsonNode;
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
  var valid_594457 = query.getOrDefault("PageSize")
  valid_594457 = validateParameter(valid_594457, JInt, required = false, default = nil)
  if valid_594457 != nil:
    section.add "PageSize", valid_594457
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594458 = query.getOrDefault("Action")
  valid_594458 = validateParameter(valid_594458, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_594458 != nil:
    section.add "Action", valid_594458
  var valid_594459 = query.getOrDefault("Marker")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "Marker", valid_594459
  var valid_594460 = query.getOrDefault("Version")
  valid_594460 = validateParameter(valid_594460, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594460 != nil:
    section.add "Version", valid_594460
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
  var valid_594461 = header.getOrDefault("X-Amz-Date")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-Date", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Security-Token")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Security-Token", valid_594462
  var valid_594463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Content-Sha256", valid_594463
  var valid_594464 = header.getOrDefault("X-Amz-Algorithm")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "X-Amz-Algorithm", valid_594464
  var valid_594465 = header.getOrDefault("X-Amz-Signature")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-Signature", valid_594465
  var valid_594466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-SignedHeaders", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Credential")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Credential", valid_594467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594468: Call_GetDescribeAccountLimits_594454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594468.validator(path, query, header, formData, body)
  let scheme = call_594468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594468.url(scheme.get, call_594468.host, call_594468.base,
                         call_594468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594468, url, valid)

proc call*(call_594469: Call_GetDescribeAccountLimits_594454; PageSize: int = 0;
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
  var query_594470 = newJObject()
  add(query_594470, "PageSize", newJInt(PageSize))
  add(query_594470, "Action", newJString(Action))
  add(query_594470, "Marker", newJString(Marker))
  add(query_594470, "Version", newJString(Version))
  result = call_594469.call(nil, query_594470, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_594454(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_594455, base: "/",
    url: url_GetDescribeAccountLimits_594456, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_594507 = ref object of OpenApiRestCall_593437
proc url_PostDescribeListenerCertificates_594509(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeListenerCertificates_594508(path: JsonNode;
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
  var valid_594510 = query.getOrDefault("Action")
  valid_594510 = validateParameter(valid_594510, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_594510 != nil:
    section.add "Action", valid_594510
  var valid_594511 = query.getOrDefault("Version")
  valid_594511 = validateParameter(valid_594511, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594511 != nil:
    section.add "Version", valid_594511
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
  var valid_594512 = header.getOrDefault("X-Amz-Date")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Date", valid_594512
  var valid_594513 = header.getOrDefault("X-Amz-Security-Token")
  valid_594513 = validateParameter(valid_594513, JString, required = false,
                                 default = nil)
  if valid_594513 != nil:
    section.add "X-Amz-Security-Token", valid_594513
  var valid_594514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594514 = validateParameter(valid_594514, JString, required = false,
                                 default = nil)
  if valid_594514 != nil:
    section.add "X-Amz-Content-Sha256", valid_594514
  var valid_594515 = header.getOrDefault("X-Amz-Algorithm")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Algorithm", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Signature")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Signature", valid_594516
  var valid_594517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-SignedHeaders", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Credential")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Credential", valid_594518
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
  var valid_594519 = formData.getOrDefault("ListenerArn")
  valid_594519 = validateParameter(valid_594519, JString, required = true,
                                 default = nil)
  if valid_594519 != nil:
    section.add "ListenerArn", valid_594519
  var valid_594520 = formData.getOrDefault("Marker")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "Marker", valid_594520
  var valid_594521 = formData.getOrDefault("PageSize")
  valid_594521 = validateParameter(valid_594521, JInt, required = false, default = nil)
  if valid_594521 != nil:
    section.add "PageSize", valid_594521
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594522: Call_PostDescribeListenerCertificates_594507;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594522.validator(path, query, header, formData, body)
  let scheme = call_594522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594522.url(scheme.get, call_594522.host, call_594522.base,
                         call_594522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594522, url, valid)

proc call*(call_594523: Call_PostDescribeListenerCertificates_594507;
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
  var query_594524 = newJObject()
  var formData_594525 = newJObject()
  add(formData_594525, "ListenerArn", newJString(ListenerArn))
  add(formData_594525, "Marker", newJString(Marker))
  add(query_594524, "Action", newJString(Action))
  add(formData_594525, "PageSize", newJInt(PageSize))
  add(query_594524, "Version", newJString(Version))
  result = call_594523.call(nil, query_594524, nil, formData_594525, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_594507(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_594508, base: "/",
    url: url_PostDescribeListenerCertificates_594509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_594489 = ref object of OpenApiRestCall_593437
proc url_GetDescribeListenerCertificates_594491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeListenerCertificates_594490(path: JsonNode;
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
  var valid_594492 = query.getOrDefault("PageSize")
  valid_594492 = validateParameter(valid_594492, JInt, required = false, default = nil)
  if valid_594492 != nil:
    section.add "PageSize", valid_594492
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594493 = query.getOrDefault("Action")
  valid_594493 = validateParameter(valid_594493, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_594493 != nil:
    section.add "Action", valid_594493
  var valid_594494 = query.getOrDefault("Marker")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "Marker", valid_594494
  var valid_594495 = query.getOrDefault("ListenerArn")
  valid_594495 = validateParameter(valid_594495, JString, required = true,
                                 default = nil)
  if valid_594495 != nil:
    section.add "ListenerArn", valid_594495
  var valid_594496 = query.getOrDefault("Version")
  valid_594496 = validateParameter(valid_594496, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594496 != nil:
    section.add "Version", valid_594496
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
  var valid_594497 = header.getOrDefault("X-Amz-Date")
  valid_594497 = validateParameter(valid_594497, JString, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "X-Amz-Date", valid_594497
  var valid_594498 = header.getOrDefault("X-Amz-Security-Token")
  valid_594498 = validateParameter(valid_594498, JString, required = false,
                                 default = nil)
  if valid_594498 != nil:
    section.add "X-Amz-Security-Token", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Content-Sha256", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-Algorithm")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Algorithm", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Signature")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Signature", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-SignedHeaders", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Credential")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Credential", valid_594503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594504: Call_GetDescribeListenerCertificates_594489;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594504.validator(path, query, header, formData, body)
  let scheme = call_594504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594504.url(scheme.get, call_594504.host, call_594504.base,
                         call_594504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594504, url, valid)

proc call*(call_594505: Call_GetDescribeListenerCertificates_594489;
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
  var query_594506 = newJObject()
  add(query_594506, "PageSize", newJInt(PageSize))
  add(query_594506, "Action", newJString(Action))
  add(query_594506, "Marker", newJString(Marker))
  add(query_594506, "ListenerArn", newJString(ListenerArn))
  add(query_594506, "Version", newJString(Version))
  result = call_594505.call(nil, query_594506, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_594489(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_594490, base: "/",
    url: url_GetDescribeListenerCertificates_594491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_594545 = ref object of OpenApiRestCall_593437
proc url_PostDescribeListeners_594547(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeListeners_594546(path: JsonNode; query: JsonNode;
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
  var valid_594548 = query.getOrDefault("Action")
  valid_594548 = validateParameter(valid_594548, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_594548 != nil:
    section.add "Action", valid_594548
  var valid_594549 = query.getOrDefault("Version")
  valid_594549 = validateParameter(valid_594549, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594549 != nil:
    section.add "Version", valid_594549
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
  var valid_594550 = header.getOrDefault("X-Amz-Date")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Date", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Security-Token")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Security-Token", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Content-Sha256", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Algorithm")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Algorithm", valid_594553
  var valid_594554 = header.getOrDefault("X-Amz-Signature")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Signature", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-SignedHeaders", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Credential")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Credential", valid_594556
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
  var valid_594557 = formData.getOrDefault("LoadBalancerArn")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "LoadBalancerArn", valid_594557
  var valid_594558 = formData.getOrDefault("Marker")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "Marker", valid_594558
  var valid_594559 = formData.getOrDefault("PageSize")
  valid_594559 = validateParameter(valid_594559, JInt, required = false, default = nil)
  if valid_594559 != nil:
    section.add "PageSize", valid_594559
  var valid_594560 = formData.getOrDefault("ListenerArns")
  valid_594560 = validateParameter(valid_594560, JArray, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "ListenerArns", valid_594560
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594561: Call_PostDescribeListeners_594545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_594561.validator(path, query, header, formData, body)
  let scheme = call_594561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594561.url(scheme.get, call_594561.host, call_594561.base,
                         call_594561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594561, url, valid)

proc call*(call_594562: Call_PostDescribeListeners_594545;
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
  var query_594563 = newJObject()
  var formData_594564 = newJObject()
  add(formData_594564, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_594564, "Marker", newJString(Marker))
  add(query_594563, "Action", newJString(Action))
  add(formData_594564, "PageSize", newJInt(PageSize))
  if ListenerArns != nil:
    formData_594564.add "ListenerArns", ListenerArns
  add(query_594563, "Version", newJString(Version))
  result = call_594562.call(nil, query_594563, nil, formData_594564, nil)

var postDescribeListeners* = Call_PostDescribeListeners_594545(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_594546, base: "/",
    url: url_PostDescribeListeners_594547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_594526 = ref object of OpenApiRestCall_593437
proc url_GetDescribeListeners_594528(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeListeners_594527(path: JsonNode; query: JsonNode;
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
  var valid_594529 = query.getOrDefault("ListenerArns")
  valid_594529 = validateParameter(valid_594529, JArray, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "ListenerArns", valid_594529
  var valid_594530 = query.getOrDefault("PageSize")
  valid_594530 = validateParameter(valid_594530, JInt, required = false, default = nil)
  if valid_594530 != nil:
    section.add "PageSize", valid_594530
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594531 = query.getOrDefault("Action")
  valid_594531 = validateParameter(valid_594531, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_594531 != nil:
    section.add "Action", valid_594531
  var valid_594532 = query.getOrDefault("Marker")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "Marker", valid_594532
  var valid_594533 = query.getOrDefault("LoadBalancerArn")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "LoadBalancerArn", valid_594533
  var valid_594534 = query.getOrDefault("Version")
  valid_594534 = validateParameter(valid_594534, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594534 != nil:
    section.add "Version", valid_594534
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
  var valid_594535 = header.getOrDefault("X-Amz-Date")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Date", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Security-Token")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Security-Token", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Content-Sha256", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-Algorithm")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-Algorithm", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Signature")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Signature", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-SignedHeaders", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-Credential")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Credential", valid_594541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594542: Call_GetDescribeListeners_594526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_594542.validator(path, query, header, formData, body)
  let scheme = call_594542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594542.url(scheme.get, call_594542.host, call_594542.base,
                         call_594542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594542, url, valid)

proc call*(call_594543: Call_GetDescribeListeners_594526;
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
  var query_594544 = newJObject()
  if ListenerArns != nil:
    query_594544.add "ListenerArns", ListenerArns
  add(query_594544, "PageSize", newJInt(PageSize))
  add(query_594544, "Action", newJString(Action))
  add(query_594544, "Marker", newJString(Marker))
  add(query_594544, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594544, "Version", newJString(Version))
  result = call_594543.call(nil, query_594544, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_594526(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_594527,
    base: "/", url: url_GetDescribeListeners_594528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_594581 = ref object of OpenApiRestCall_593437
proc url_PostDescribeLoadBalancerAttributes_594583(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_594582(path: JsonNode;
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
  var valid_594584 = query.getOrDefault("Action")
  valid_594584 = validateParameter(valid_594584, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_594584 != nil:
    section.add "Action", valid_594584
  var valid_594585 = query.getOrDefault("Version")
  valid_594585 = validateParameter(valid_594585, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594585 != nil:
    section.add "Version", valid_594585
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
  var valid_594586 = header.getOrDefault("X-Amz-Date")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "X-Amz-Date", valid_594586
  var valid_594587 = header.getOrDefault("X-Amz-Security-Token")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "X-Amz-Security-Token", valid_594587
  var valid_594588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "X-Amz-Content-Sha256", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-Algorithm")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Algorithm", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Signature")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Signature", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-SignedHeaders", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Credential")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Credential", valid_594592
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_594593 = formData.getOrDefault("LoadBalancerArn")
  valid_594593 = validateParameter(valid_594593, JString, required = true,
                                 default = nil)
  if valid_594593 != nil:
    section.add "LoadBalancerArn", valid_594593
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594594: Call_PostDescribeLoadBalancerAttributes_594581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594594.validator(path, query, header, formData, body)
  let scheme = call_594594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594594.url(scheme.get, call_594594.host, call_594594.base,
                         call_594594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594594, url, valid)

proc call*(call_594595: Call_PostDescribeLoadBalancerAttributes_594581;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594596 = newJObject()
  var formData_594597 = newJObject()
  add(formData_594597, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594596, "Action", newJString(Action))
  add(query_594596, "Version", newJString(Version))
  result = call_594595.call(nil, query_594596, nil, formData_594597, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_594581(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_594582, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_594583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_594565 = ref object of OpenApiRestCall_593437
proc url_GetDescribeLoadBalancerAttributes_594567(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_594566(path: JsonNode;
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
  var valid_594568 = query.getOrDefault("Action")
  valid_594568 = validateParameter(valid_594568, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_594568 != nil:
    section.add "Action", valid_594568
  var valid_594569 = query.getOrDefault("LoadBalancerArn")
  valid_594569 = validateParameter(valid_594569, JString, required = true,
                                 default = nil)
  if valid_594569 != nil:
    section.add "LoadBalancerArn", valid_594569
  var valid_594570 = query.getOrDefault("Version")
  valid_594570 = validateParameter(valid_594570, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594570 != nil:
    section.add "Version", valid_594570
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
  var valid_594571 = header.getOrDefault("X-Amz-Date")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Date", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Security-Token")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Security-Token", valid_594572
  var valid_594573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "X-Amz-Content-Sha256", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Algorithm")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Algorithm", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-Signature")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Signature", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-SignedHeaders", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-Credential")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Credential", valid_594577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594578: Call_GetDescribeLoadBalancerAttributes_594565;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594578.validator(path, query, header, formData, body)
  let scheme = call_594578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594578.url(scheme.get, call_594578.host, call_594578.base,
                         call_594578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594578, url, valid)

proc call*(call_594579: Call_GetDescribeLoadBalancerAttributes_594565;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_594580 = newJObject()
  add(query_594580, "Action", newJString(Action))
  add(query_594580, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594580, "Version", newJString(Version))
  result = call_594579.call(nil, query_594580, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_594565(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_594566, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_594567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_594617 = ref object of OpenApiRestCall_593437
proc url_PostDescribeLoadBalancers_594619(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancers_594618(path: JsonNode; query: JsonNode;
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
  var valid_594620 = query.getOrDefault("Action")
  valid_594620 = validateParameter(valid_594620, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_594620 != nil:
    section.add "Action", valid_594620
  var valid_594621 = query.getOrDefault("Version")
  valid_594621 = validateParameter(valid_594621, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594621 != nil:
    section.add "Version", valid_594621
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
  var valid_594622 = header.getOrDefault("X-Amz-Date")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-Date", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Security-Token")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Security-Token", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Content-Sha256", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Algorithm")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Algorithm", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Signature")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Signature", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-SignedHeaders", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Credential")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Credential", valid_594628
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
  var valid_594629 = formData.getOrDefault("Names")
  valid_594629 = validateParameter(valid_594629, JArray, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "Names", valid_594629
  var valid_594630 = formData.getOrDefault("Marker")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "Marker", valid_594630
  var valid_594631 = formData.getOrDefault("LoadBalancerArns")
  valid_594631 = validateParameter(valid_594631, JArray, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "LoadBalancerArns", valid_594631
  var valid_594632 = formData.getOrDefault("PageSize")
  valid_594632 = validateParameter(valid_594632, JInt, required = false, default = nil)
  if valid_594632 != nil:
    section.add "PageSize", valid_594632
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594633: Call_PostDescribeLoadBalancers_594617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_594633.validator(path, query, header, formData, body)
  let scheme = call_594633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594633.url(scheme.get, call_594633.host, call_594633.base,
                         call_594633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594633, url, valid)

proc call*(call_594634: Call_PostDescribeLoadBalancers_594617;
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
  var query_594635 = newJObject()
  var formData_594636 = newJObject()
  if Names != nil:
    formData_594636.add "Names", Names
  add(formData_594636, "Marker", newJString(Marker))
  add(query_594635, "Action", newJString(Action))
  if LoadBalancerArns != nil:
    formData_594636.add "LoadBalancerArns", LoadBalancerArns
  add(formData_594636, "PageSize", newJInt(PageSize))
  add(query_594635, "Version", newJString(Version))
  result = call_594634.call(nil, query_594635, nil, formData_594636, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_594617(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_594618, base: "/",
    url: url_PostDescribeLoadBalancers_594619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_594598 = ref object of OpenApiRestCall_593437
proc url_GetDescribeLoadBalancers_594600(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancers_594599(path: JsonNode; query: JsonNode;
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
  var valid_594601 = query.getOrDefault("Names")
  valid_594601 = validateParameter(valid_594601, JArray, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "Names", valid_594601
  var valid_594602 = query.getOrDefault("PageSize")
  valid_594602 = validateParameter(valid_594602, JInt, required = false, default = nil)
  if valid_594602 != nil:
    section.add "PageSize", valid_594602
  var valid_594603 = query.getOrDefault("LoadBalancerArns")
  valid_594603 = validateParameter(valid_594603, JArray, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "LoadBalancerArns", valid_594603
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594604 = query.getOrDefault("Action")
  valid_594604 = validateParameter(valid_594604, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_594604 != nil:
    section.add "Action", valid_594604
  var valid_594605 = query.getOrDefault("Marker")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "Marker", valid_594605
  var valid_594606 = query.getOrDefault("Version")
  valid_594606 = validateParameter(valid_594606, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594606 != nil:
    section.add "Version", valid_594606
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
  var valid_594607 = header.getOrDefault("X-Amz-Date")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Date", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Security-Token")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Security-Token", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Content-Sha256", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Algorithm")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Algorithm", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Signature")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Signature", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-SignedHeaders", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Credential")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Credential", valid_594613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594614: Call_GetDescribeLoadBalancers_594598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_594614.validator(path, query, header, formData, body)
  let scheme = call_594614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594614.url(scheme.get, call_594614.host, call_594614.base,
                         call_594614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594614, url, valid)

proc call*(call_594615: Call_GetDescribeLoadBalancers_594598;
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
  var query_594616 = newJObject()
  if Names != nil:
    query_594616.add "Names", Names
  add(query_594616, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_594616.add "LoadBalancerArns", LoadBalancerArns
  add(query_594616, "Action", newJString(Action))
  add(query_594616, "Marker", newJString(Marker))
  add(query_594616, "Version", newJString(Version))
  result = call_594615.call(nil, query_594616, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_594598(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_594599, base: "/",
    url: url_GetDescribeLoadBalancers_594600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_594656 = ref object of OpenApiRestCall_593437
proc url_PostDescribeRules_594658(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeRules_594657(path: JsonNode; query: JsonNode;
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
  var valid_594659 = query.getOrDefault("Action")
  valid_594659 = validateParameter(valid_594659, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_594659 != nil:
    section.add "Action", valid_594659
  var valid_594660 = query.getOrDefault("Version")
  valid_594660 = validateParameter(valid_594660, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594660 != nil:
    section.add "Version", valid_594660
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
  var valid_594661 = header.getOrDefault("X-Amz-Date")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Date", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Security-Token")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Security-Token", valid_594662
  var valid_594663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-Content-Sha256", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Algorithm")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Algorithm", valid_594664
  var valid_594665 = header.getOrDefault("X-Amz-Signature")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Signature", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-SignedHeaders", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-Credential")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-Credential", valid_594667
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
  var valid_594668 = formData.getOrDefault("ListenerArn")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "ListenerArn", valid_594668
  var valid_594669 = formData.getOrDefault("RuleArns")
  valid_594669 = validateParameter(valid_594669, JArray, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "RuleArns", valid_594669
  var valid_594670 = formData.getOrDefault("Marker")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "Marker", valid_594670
  var valid_594671 = formData.getOrDefault("PageSize")
  valid_594671 = validateParameter(valid_594671, JInt, required = false, default = nil)
  if valid_594671 != nil:
    section.add "PageSize", valid_594671
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594672: Call_PostDescribeRules_594656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_594672.validator(path, query, header, formData, body)
  let scheme = call_594672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594672.url(scheme.get, call_594672.host, call_594672.base,
                         call_594672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594672, url, valid)

proc call*(call_594673: Call_PostDescribeRules_594656; ListenerArn: string = "";
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
  var query_594674 = newJObject()
  var formData_594675 = newJObject()
  add(formData_594675, "ListenerArn", newJString(ListenerArn))
  if RuleArns != nil:
    formData_594675.add "RuleArns", RuleArns
  add(formData_594675, "Marker", newJString(Marker))
  add(query_594674, "Action", newJString(Action))
  add(formData_594675, "PageSize", newJInt(PageSize))
  add(query_594674, "Version", newJString(Version))
  result = call_594673.call(nil, query_594674, nil, formData_594675, nil)

var postDescribeRules* = Call_PostDescribeRules_594656(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_594657,
    base: "/", url: url_PostDescribeRules_594658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_594637 = ref object of OpenApiRestCall_593437
proc url_GetDescribeRules_594639(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeRules_594638(path: JsonNode; query: JsonNode;
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
  var valid_594640 = query.getOrDefault("PageSize")
  valid_594640 = validateParameter(valid_594640, JInt, required = false, default = nil)
  if valid_594640 != nil:
    section.add "PageSize", valid_594640
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594641 = query.getOrDefault("Action")
  valid_594641 = validateParameter(valid_594641, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_594641 != nil:
    section.add "Action", valid_594641
  var valid_594642 = query.getOrDefault("Marker")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "Marker", valid_594642
  var valid_594643 = query.getOrDefault("ListenerArn")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "ListenerArn", valid_594643
  var valid_594644 = query.getOrDefault("Version")
  valid_594644 = validateParameter(valid_594644, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594644 != nil:
    section.add "Version", valid_594644
  var valid_594645 = query.getOrDefault("RuleArns")
  valid_594645 = validateParameter(valid_594645, JArray, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "RuleArns", valid_594645
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
  var valid_594646 = header.getOrDefault("X-Amz-Date")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Date", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-Security-Token")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Security-Token", valid_594647
  var valid_594648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594648 = validateParameter(valid_594648, JString, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "X-Amz-Content-Sha256", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Algorithm")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Algorithm", valid_594649
  var valid_594650 = header.getOrDefault("X-Amz-Signature")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "X-Amz-Signature", valid_594650
  var valid_594651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-SignedHeaders", valid_594651
  var valid_594652 = header.getOrDefault("X-Amz-Credential")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-Credential", valid_594652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594653: Call_GetDescribeRules_594637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_594653.validator(path, query, header, formData, body)
  let scheme = call_594653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594653.url(scheme.get, call_594653.host, call_594653.base,
                         call_594653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594653, url, valid)

proc call*(call_594654: Call_GetDescribeRules_594637; PageSize: int = 0;
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
  var query_594655 = newJObject()
  add(query_594655, "PageSize", newJInt(PageSize))
  add(query_594655, "Action", newJString(Action))
  add(query_594655, "Marker", newJString(Marker))
  add(query_594655, "ListenerArn", newJString(ListenerArn))
  add(query_594655, "Version", newJString(Version))
  if RuleArns != nil:
    query_594655.add "RuleArns", RuleArns
  result = call_594654.call(nil, query_594655, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_594637(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_594638,
    base: "/", url: url_GetDescribeRules_594639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_594694 = ref object of OpenApiRestCall_593437
proc url_PostDescribeSSLPolicies_594696(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeSSLPolicies_594695(path: JsonNode; query: JsonNode;
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
  var valid_594697 = query.getOrDefault("Action")
  valid_594697 = validateParameter(valid_594697, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_594697 != nil:
    section.add "Action", valid_594697
  var valid_594698 = query.getOrDefault("Version")
  valid_594698 = validateParameter(valid_594698, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594698 != nil:
    section.add "Version", valid_594698
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
  var valid_594699 = header.getOrDefault("X-Amz-Date")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-Date", valid_594699
  var valid_594700 = header.getOrDefault("X-Amz-Security-Token")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "X-Amz-Security-Token", valid_594700
  var valid_594701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-Content-Sha256", valid_594701
  var valid_594702 = header.getOrDefault("X-Amz-Algorithm")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Algorithm", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-Signature")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Signature", valid_594703
  var valid_594704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-SignedHeaders", valid_594704
  var valid_594705 = header.getOrDefault("X-Amz-Credential")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Credential", valid_594705
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_594706 = formData.getOrDefault("Names")
  valid_594706 = validateParameter(valid_594706, JArray, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "Names", valid_594706
  var valid_594707 = formData.getOrDefault("Marker")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "Marker", valid_594707
  var valid_594708 = formData.getOrDefault("PageSize")
  valid_594708 = validateParameter(valid_594708, JInt, required = false, default = nil)
  if valid_594708 != nil:
    section.add "PageSize", valid_594708
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594709: Call_PostDescribeSSLPolicies_594694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594709.validator(path, query, header, formData, body)
  let scheme = call_594709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594709.url(scheme.get, call_594709.host, call_594709.base,
                         call_594709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594709, url, valid)

proc call*(call_594710: Call_PostDescribeSSLPolicies_594694; Names: JsonNode = nil;
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
  var query_594711 = newJObject()
  var formData_594712 = newJObject()
  if Names != nil:
    formData_594712.add "Names", Names
  add(formData_594712, "Marker", newJString(Marker))
  add(query_594711, "Action", newJString(Action))
  add(formData_594712, "PageSize", newJInt(PageSize))
  add(query_594711, "Version", newJString(Version))
  result = call_594710.call(nil, query_594711, nil, formData_594712, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_594694(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_594695, base: "/",
    url: url_PostDescribeSSLPolicies_594696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_594676 = ref object of OpenApiRestCall_593437
proc url_GetDescribeSSLPolicies_594678(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeSSLPolicies_594677(path: JsonNode; query: JsonNode;
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
  var valid_594679 = query.getOrDefault("Names")
  valid_594679 = validateParameter(valid_594679, JArray, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "Names", valid_594679
  var valid_594680 = query.getOrDefault("PageSize")
  valid_594680 = validateParameter(valid_594680, JInt, required = false, default = nil)
  if valid_594680 != nil:
    section.add "PageSize", valid_594680
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594681 = query.getOrDefault("Action")
  valid_594681 = validateParameter(valid_594681, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_594681 != nil:
    section.add "Action", valid_594681
  var valid_594682 = query.getOrDefault("Marker")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "Marker", valid_594682
  var valid_594683 = query.getOrDefault("Version")
  valid_594683 = validateParameter(valid_594683, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594683 != nil:
    section.add "Version", valid_594683
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
  var valid_594684 = header.getOrDefault("X-Amz-Date")
  valid_594684 = validateParameter(valid_594684, JString, required = false,
                                 default = nil)
  if valid_594684 != nil:
    section.add "X-Amz-Date", valid_594684
  var valid_594685 = header.getOrDefault("X-Amz-Security-Token")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "X-Amz-Security-Token", valid_594685
  var valid_594686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "X-Amz-Content-Sha256", valid_594686
  var valid_594687 = header.getOrDefault("X-Amz-Algorithm")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Algorithm", valid_594687
  var valid_594688 = header.getOrDefault("X-Amz-Signature")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-Signature", valid_594688
  var valid_594689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594689 = validateParameter(valid_594689, JString, required = false,
                                 default = nil)
  if valid_594689 != nil:
    section.add "X-Amz-SignedHeaders", valid_594689
  var valid_594690 = header.getOrDefault("X-Amz-Credential")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-Credential", valid_594690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594691: Call_GetDescribeSSLPolicies_594676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594691.validator(path, query, header, formData, body)
  let scheme = call_594691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594691.url(scheme.get, call_594691.host, call_594691.base,
                         call_594691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594691, url, valid)

proc call*(call_594692: Call_GetDescribeSSLPolicies_594676; Names: JsonNode = nil;
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
  var query_594693 = newJObject()
  if Names != nil:
    query_594693.add "Names", Names
  add(query_594693, "PageSize", newJInt(PageSize))
  add(query_594693, "Action", newJString(Action))
  add(query_594693, "Marker", newJString(Marker))
  add(query_594693, "Version", newJString(Version))
  result = call_594692.call(nil, query_594693, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_594676(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_594677, base: "/",
    url: url_GetDescribeSSLPolicies_594678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_594729 = ref object of OpenApiRestCall_593437
proc url_PostDescribeTags_594731(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTags_594730(path: JsonNode; query: JsonNode;
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
  var valid_594732 = query.getOrDefault("Action")
  valid_594732 = validateParameter(valid_594732, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_594732 != nil:
    section.add "Action", valid_594732
  var valid_594733 = query.getOrDefault("Version")
  valid_594733 = validateParameter(valid_594733, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594733 != nil:
    section.add "Version", valid_594733
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
  var valid_594734 = header.getOrDefault("X-Amz-Date")
  valid_594734 = validateParameter(valid_594734, JString, required = false,
                                 default = nil)
  if valid_594734 != nil:
    section.add "X-Amz-Date", valid_594734
  var valid_594735 = header.getOrDefault("X-Amz-Security-Token")
  valid_594735 = validateParameter(valid_594735, JString, required = false,
                                 default = nil)
  if valid_594735 != nil:
    section.add "X-Amz-Security-Token", valid_594735
  var valid_594736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "X-Amz-Content-Sha256", valid_594736
  var valid_594737 = header.getOrDefault("X-Amz-Algorithm")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "X-Amz-Algorithm", valid_594737
  var valid_594738 = header.getOrDefault("X-Amz-Signature")
  valid_594738 = validateParameter(valid_594738, JString, required = false,
                                 default = nil)
  if valid_594738 != nil:
    section.add "X-Amz-Signature", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-SignedHeaders", valid_594739
  var valid_594740 = header.getOrDefault("X-Amz-Credential")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Credential", valid_594740
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_594741 = formData.getOrDefault("ResourceArns")
  valid_594741 = validateParameter(valid_594741, JArray, required = true, default = nil)
  if valid_594741 != nil:
    section.add "ResourceArns", valid_594741
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594742: Call_PostDescribeTags_594729; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_594742.validator(path, query, header, formData, body)
  let scheme = call_594742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594742.url(scheme.get, call_594742.host, call_594742.base,
                         call_594742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594742, url, valid)

proc call*(call_594743: Call_PostDescribeTags_594729; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594744 = newJObject()
  var formData_594745 = newJObject()
  if ResourceArns != nil:
    formData_594745.add "ResourceArns", ResourceArns
  add(query_594744, "Action", newJString(Action))
  add(query_594744, "Version", newJString(Version))
  result = call_594743.call(nil, query_594744, nil, formData_594745, nil)

var postDescribeTags* = Call_PostDescribeTags_594729(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_594730,
    base: "/", url: url_PostDescribeTags_594731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_594713 = ref object of OpenApiRestCall_593437
proc url_GetDescribeTags_594715(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTags_594714(path: JsonNode; query: JsonNode;
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
  var valid_594716 = query.getOrDefault("Action")
  valid_594716 = validateParameter(valid_594716, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_594716 != nil:
    section.add "Action", valid_594716
  var valid_594717 = query.getOrDefault("ResourceArns")
  valid_594717 = validateParameter(valid_594717, JArray, required = true, default = nil)
  if valid_594717 != nil:
    section.add "ResourceArns", valid_594717
  var valid_594718 = query.getOrDefault("Version")
  valid_594718 = validateParameter(valid_594718, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594718 != nil:
    section.add "Version", valid_594718
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
  var valid_594719 = header.getOrDefault("X-Amz-Date")
  valid_594719 = validateParameter(valid_594719, JString, required = false,
                                 default = nil)
  if valid_594719 != nil:
    section.add "X-Amz-Date", valid_594719
  var valid_594720 = header.getOrDefault("X-Amz-Security-Token")
  valid_594720 = validateParameter(valid_594720, JString, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "X-Amz-Security-Token", valid_594720
  var valid_594721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Content-Sha256", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Algorithm")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Algorithm", valid_594722
  var valid_594723 = header.getOrDefault("X-Amz-Signature")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-Signature", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-SignedHeaders", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-Credential")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-Credential", valid_594725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594726: Call_GetDescribeTags_594713; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_594726.validator(path, query, header, formData, body)
  let scheme = call_594726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594726.url(scheme.get, call_594726.host, call_594726.base,
                         call_594726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594726, url, valid)

proc call*(call_594727: Call_GetDescribeTags_594713; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   Action: string (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Version: string (required)
  var query_594728 = newJObject()
  add(query_594728, "Action", newJString(Action))
  if ResourceArns != nil:
    query_594728.add "ResourceArns", ResourceArns
  add(query_594728, "Version", newJString(Version))
  result = call_594727.call(nil, query_594728, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_594713(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_594714,
    base: "/", url: url_GetDescribeTags_594715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_594762 = ref object of OpenApiRestCall_593437
proc url_PostDescribeTargetGroupAttributes_594764(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTargetGroupAttributes_594763(path: JsonNode;
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
  var valid_594765 = query.getOrDefault("Action")
  valid_594765 = validateParameter(valid_594765, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_594765 != nil:
    section.add "Action", valid_594765
  var valid_594766 = query.getOrDefault("Version")
  valid_594766 = validateParameter(valid_594766, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594766 != nil:
    section.add "Version", valid_594766
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
  var valid_594767 = header.getOrDefault("X-Amz-Date")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-Date", valid_594767
  var valid_594768 = header.getOrDefault("X-Amz-Security-Token")
  valid_594768 = validateParameter(valid_594768, JString, required = false,
                                 default = nil)
  if valid_594768 != nil:
    section.add "X-Amz-Security-Token", valid_594768
  var valid_594769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "X-Amz-Content-Sha256", valid_594769
  var valid_594770 = header.getOrDefault("X-Amz-Algorithm")
  valid_594770 = validateParameter(valid_594770, JString, required = false,
                                 default = nil)
  if valid_594770 != nil:
    section.add "X-Amz-Algorithm", valid_594770
  var valid_594771 = header.getOrDefault("X-Amz-Signature")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "X-Amz-Signature", valid_594771
  var valid_594772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "X-Amz-SignedHeaders", valid_594772
  var valid_594773 = header.getOrDefault("X-Amz-Credential")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "X-Amz-Credential", valid_594773
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_594774 = formData.getOrDefault("TargetGroupArn")
  valid_594774 = validateParameter(valid_594774, JString, required = true,
                                 default = nil)
  if valid_594774 != nil:
    section.add "TargetGroupArn", valid_594774
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594775: Call_PostDescribeTargetGroupAttributes_594762;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594775.validator(path, query, header, formData, body)
  let scheme = call_594775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594775.url(scheme.get, call_594775.host, call_594775.base,
                         call_594775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594775, url, valid)

proc call*(call_594776: Call_PostDescribeTargetGroupAttributes_594762;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_594777 = newJObject()
  var formData_594778 = newJObject()
  add(query_594777, "Action", newJString(Action))
  add(formData_594778, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594777, "Version", newJString(Version))
  result = call_594776.call(nil, query_594777, nil, formData_594778, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_594762(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_594763, base: "/",
    url: url_PostDescribeTargetGroupAttributes_594764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_594746 = ref object of OpenApiRestCall_593437
proc url_GetDescribeTargetGroupAttributes_594748(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTargetGroupAttributes_594747(path: JsonNode;
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
  var valid_594749 = query.getOrDefault("TargetGroupArn")
  valid_594749 = validateParameter(valid_594749, JString, required = true,
                                 default = nil)
  if valid_594749 != nil:
    section.add "TargetGroupArn", valid_594749
  var valid_594750 = query.getOrDefault("Action")
  valid_594750 = validateParameter(valid_594750, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_594750 != nil:
    section.add "Action", valid_594750
  var valid_594751 = query.getOrDefault("Version")
  valid_594751 = validateParameter(valid_594751, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594751 != nil:
    section.add "Version", valid_594751
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
  var valid_594752 = header.getOrDefault("X-Amz-Date")
  valid_594752 = validateParameter(valid_594752, JString, required = false,
                                 default = nil)
  if valid_594752 != nil:
    section.add "X-Amz-Date", valid_594752
  var valid_594753 = header.getOrDefault("X-Amz-Security-Token")
  valid_594753 = validateParameter(valid_594753, JString, required = false,
                                 default = nil)
  if valid_594753 != nil:
    section.add "X-Amz-Security-Token", valid_594753
  var valid_594754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594754 = validateParameter(valid_594754, JString, required = false,
                                 default = nil)
  if valid_594754 != nil:
    section.add "X-Amz-Content-Sha256", valid_594754
  var valid_594755 = header.getOrDefault("X-Amz-Algorithm")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "X-Amz-Algorithm", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-Signature")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-Signature", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-SignedHeaders", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-Credential")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Credential", valid_594758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594759: Call_GetDescribeTargetGroupAttributes_594746;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594759.validator(path, query, header, formData, body)
  let scheme = call_594759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594759.url(scheme.get, call_594759.host, call_594759.base,
                         call_594759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594759, url, valid)

proc call*(call_594760: Call_GetDescribeTargetGroupAttributes_594746;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594761 = newJObject()
  add(query_594761, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594761, "Action", newJString(Action))
  add(query_594761, "Version", newJString(Version))
  result = call_594760.call(nil, query_594761, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_594746(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_594747, base: "/",
    url: url_GetDescribeTargetGroupAttributes_594748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_594799 = ref object of OpenApiRestCall_593437
proc url_PostDescribeTargetGroups_594801(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTargetGroups_594800(path: JsonNode; query: JsonNode;
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
  var valid_594802 = query.getOrDefault("Action")
  valid_594802 = validateParameter(valid_594802, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_594802 != nil:
    section.add "Action", valid_594802
  var valid_594803 = query.getOrDefault("Version")
  valid_594803 = validateParameter(valid_594803, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594803 != nil:
    section.add "Version", valid_594803
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
  var valid_594804 = header.getOrDefault("X-Amz-Date")
  valid_594804 = validateParameter(valid_594804, JString, required = false,
                                 default = nil)
  if valid_594804 != nil:
    section.add "X-Amz-Date", valid_594804
  var valid_594805 = header.getOrDefault("X-Amz-Security-Token")
  valid_594805 = validateParameter(valid_594805, JString, required = false,
                                 default = nil)
  if valid_594805 != nil:
    section.add "X-Amz-Security-Token", valid_594805
  var valid_594806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "X-Amz-Content-Sha256", valid_594806
  var valid_594807 = header.getOrDefault("X-Amz-Algorithm")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-Algorithm", valid_594807
  var valid_594808 = header.getOrDefault("X-Amz-Signature")
  valid_594808 = validateParameter(valid_594808, JString, required = false,
                                 default = nil)
  if valid_594808 != nil:
    section.add "X-Amz-Signature", valid_594808
  var valid_594809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "X-Amz-SignedHeaders", valid_594809
  var valid_594810 = header.getOrDefault("X-Amz-Credential")
  valid_594810 = validateParameter(valid_594810, JString, required = false,
                                 default = nil)
  if valid_594810 != nil:
    section.add "X-Amz-Credential", valid_594810
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
  var valid_594811 = formData.getOrDefault("LoadBalancerArn")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "LoadBalancerArn", valid_594811
  var valid_594812 = formData.getOrDefault("TargetGroupArns")
  valid_594812 = validateParameter(valid_594812, JArray, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "TargetGroupArns", valid_594812
  var valid_594813 = formData.getOrDefault("Names")
  valid_594813 = validateParameter(valid_594813, JArray, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "Names", valid_594813
  var valid_594814 = formData.getOrDefault("Marker")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "Marker", valid_594814
  var valid_594815 = formData.getOrDefault("PageSize")
  valid_594815 = validateParameter(valid_594815, JInt, required = false, default = nil)
  if valid_594815 != nil:
    section.add "PageSize", valid_594815
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594816: Call_PostDescribeTargetGroups_594799; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_594816.validator(path, query, header, formData, body)
  let scheme = call_594816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594816.url(scheme.get, call_594816.host, call_594816.base,
                         call_594816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594816, url, valid)

proc call*(call_594817: Call_PostDescribeTargetGroups_594799;
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
  var query_594818 = newJObject()
  var formData_594819 = newJObject()
  add(formData_594819, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    formData_594819.add "TargetGroupArns", TargetGroupArns
  if Names != nil:
    formData_594819.add "Names", Names
  add(formData_594819, "Marker", newJString(Marker))
  add(query_594818, "Action", newJString(Action))
  add(formData_594819, "PageSize", newJInt(PageSize))
  add(query_594818, "Version", newJString(Version))
  result = call_594817.call(nil, query_594818, nil, formData_594819, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_594799(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_594800, base: "/",
    url: url_PostDescribeTargetGroups_594801, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_594779 = ref object of OpenApiRestCall_593437
proc url_GetDescribeTargetGroups_594781(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTargetGroups_594780(path: JsonNode; query: JsonNode;
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
  var valid_594782 = query.getOrDefault("Names")
  valid_594782 = validateParameter(valid_594782, JArray, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "Names", valid_594782
  var valid_594783 = query.getOrDefault("PageSize")
  valid_594783 = validateParameter(valid_594783, JInt, required = false, default = nil)
  if valid_594783 != nil:
    section.add "PageSize", valid_594783
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594784 = query.getOrDefault("Action")
  valid_594784 = validateParameter(valid_594784, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_594784 != nil:
    section.add "Action", valid_594784
  var valid_594785 = query.getOrDefault("Marker")
  valid_594785 = validateParameter(valid_594785, JString, required = false,
                                 default = nil)
  if valid_594785 != nil:
    section.add "Marker", valid_594785
  var valid_594786 = query.getOrDefault("LoadBalancerArn")
  valid_594786 = validateParameter(valid_594786, JString, required = false,
                                 default = nil)
  if valid_594786 != nil:
    section.add "LoadBalancerArn", valid_594786
  var valid_594787 = query.getOrDefault("TargetGroupArns")
  valid_594787 = validateParameter(valid_594787, JArray, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "TargetGroupArns", valid_594787
  var valid_594788 = query.getOrDefault("Version")
  valid_594788 = validateParameter(valid_594788, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594788 != nil:
    section.add "Version", valid_594788
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
  var valid_594789 = header.getOrDefault("X-Amz-Date")
  valid_594789 = validateParameter(valid_594789, JString, required = false,
                                 default = nil)
  if valid_594789 != nil:
    section.add "X-Amz-Date", valid_594789
  var valid_594790 = header.getOrDefault("X-Amz-Security-Token")
  valid_594790 = validateParameter(valid_594790, JString, required = false,
                                 default = nil)
  if valid_594790 != nil:
    section.add "X-Amz-Security-Token", valid_594790
  var valid_594791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594791 = validateParameter(valid_594791, JString, required = false,
                                 default = nil)
  if valid_594791 != nil:
    section.add "X-Amz-Content-Sha256", valid_594791
  var valid_594792 = header.getOrDefault("X-Amz-Algorithm")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "X-Amz-Algorithm", valid_594792
  var valid_594793 = header.getOrDefault("X-Amz-Signature")
  valid_594793 = validateParameter(valid_594793, JString, required = false,
                                 default = nil)
  if valid_594793 != nil:
    section.add "X-Amz-Signature", valid_594793
  var valid_594794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-SignedHeaders", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Credential")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Credential", valid_594795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594796: Call_GetDescribeTargetGroups_594779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_594796.validator(path, query, header, formData, body)
  let scheme = call_594796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594796.url(scheme.get, call_594796.host, call_594796.base,
                         call_594796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594796, url, valid)

proc call*(call_594797: Call_GetDescribeTargetGroups_594779; Names: JsonNode = nil;
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
  var query_594798 = newJObject()
  if Names != nil:
    query_594798.add "Names", Names
  add(query_594798, "PageSize", newJInt(PageSize))
  add(query_594798, "Action", newJString(Action))
  add(query_594798, "Marker", newJString(Marker))
  add(query_594798, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    query_594798.add "TargetGroupArns", TargetGroupArns
  add(query_594798, "Version", newJString(Version))
  result = call_594797.call(nil, query_594798, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_594779(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_594780, base: "/",
    url: url_GetDescribeTargetGroups_594781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_594837 = ref object of OpenApiRestCall_593437
proc url_PostDescribeTargetHealth_594839(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTargetHealth_594838(path: JsonNode; query: JsonNode;
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
  var valid_594840 = query.getOrDefault("Action")
  valid_594840 = validateParameter(valid_594840, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_594840 != nil:
    section.add "Action", valid_594840
  var valid_594841 = query.getOrDefault("Version")
  valid_594841 = validateParameter(valid_594841, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594841 != nil:
    section.add "Version", valid_594841
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
  var valid_594842 = header.getOrDefault("X-Amz-Date")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Date", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-Security-Token")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-Security-Token", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-Content-Sha256", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Algorithm")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Algorithm", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-Signature")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Signature", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-SignedHeaders", valid_594847
  var valid_594848 = header.getOrDefault("X-Amz-Credential")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-Credential", valid_594848
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_594849 = formData.getOrDefault("Targets")
  valid_594849 = validateParameter(valid_594849, JArray, required = false,
                                 default = nil)
  if valid_594849 != nil:
    section.add "Targets", valid_594849
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_594850 = formData.getOrDefault("TargetGroupArn")
  valid_594850 = validateParameter(valid_594850, JString, required = true,
                                 default = nil)
  if valid_594850 != nil:
    section.add "TargetGroupArn", valid_594850
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594851: Call_PostDescribeTargetHealth_594837; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_594851.validator(path, query, header, formData, body)
  let scheme = call_594851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594851.url(scheme.get, call_594851.host, call_594851.base,
                         call_594851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594851, url, valid)

proc call*(call_594852: Call_PostDescribeTargetHealth_594837;
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
  var query_594853 = newJObject()
  var formData_594854 = newJObject()
  if Targets != nil:
    formData_594854.add "Targets", Targets
  add(query_594853, "Action", newJString(Action))
  add(formData_594854, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594853, "Version", newJString(Version))
  result = call_594852.call(nil, query_594853, nil, formData_594854, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_594837(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_594838, base: "/",
    url: url_PostDescribeTargetHealth_594839, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_594820 = ref object of OpenApiRestCall_593437
proc url_GetDescribeTargetHealth_594822(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTargetHealth_594821(path: JsonNode; query: JsonNode;
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
  var valid_594823 = query.getOrDefault("Targets")
  valid_594823 = validateParameter(valid_594823, JArray, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "Targets", valid_594823
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_594824 = query.getOrDefault("TargetGroupArn")
  valid_594824 = validateParameter(valid_594824, JString, required = true,
                                 default = nil)
  if valid_594824 != nil:
    section.add "TargetGroupArn", valid_594824
  var valid_594825 = query.getOrDefault("Action")
  valid_594825 = validateParameter(valid_594825, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_594825 != nil:
    section.add "Action", valid_594825
  var valid_594826 = query.getOrDefault("Version")
  valid_594826 = validateParameter(valid_594826, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594826 != nil:
    section.add "Version", valid_594826
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
  var valid_594827 = header.getOrDefault("X-Amz-Date")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Date", valid_594827
  var valid_594828 = header.getOrDefault("X-Amz-Security-Token")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "X-Amz-Security-Token", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-Content-Sha256", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-Algorithm")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Algorithm", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-Signature")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Signature", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-SignedHeaders", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-Credential")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Credential", valid_594833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594834: Call_GetDescribeTargetHealth_594820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_594834.validator(path, query, header, formData, body)
  let scheme = call_594834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594834.url(scheme.get, call_594834.host, call_594834.base,
                         call_594834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594834, url, valid)

proc call*(call_594835: Call_GetDescribeTargetHealth_594820;
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
  var query_594836 = newJObject()
  if Targets != nil:
    query_594836.add "Targets", Targets
  add(query_594836, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594836, "Action", newJString(Action))
  add(query_594836, "Version", newJString(Version))
  result = call_594835.call(nil, query_594836, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_594820(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_594821, base: "/",
    url: url_GetDescribeTargetHealth_594822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_594876 = ref object of OpenApiRestCall_593437
proc url_PostModifyListener_594878(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyListener_594877(path: JsonNode; query: JsonNode;
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
  var valid_594879 = query.getOrDefault("Action")
  valid_594879 = validateParameter(valid_594879, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_594879 != nil:
    section.add "Action", valid_594879
  var valid_594880 = query.getOrDefault("Version")
  valid_594880 = validateParameter(valid_594880, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594880 != nil:
    section.add "Version", valid_594880
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
  var valid_594881 = header.getOrDefault("X-Amz-Date")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Date", valid_594881
  var valid_594882 = header.getOrDefault("X-Amz-Security-Token")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Security-Token", valid_594882
  var valid_594883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-Content-Sha256", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Algorithm")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Algorithm", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-Signature")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-Signature", valid_594885
  var valid_594886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-SignedHeaders", valid_594886
  var valid_594887 = header.getOrDefault("X-Amz-Credential")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "X-Amz-Credential", valid_594887
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
  var valid_594888 = formData.getOrDefault("Certificates")
  valid_594888 = validateParameter(valid_594888, JArray, required = false,
                                 default = nil)
  if valid_594888 != nil:
    section.add "Certificates", valid_594888
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_594889 = formData.getOrDefault("ListenerArn")
  valid_594889 = validateParameter(valid_594889, JString, required = true,
                                 default = nil)
  if valid_594889 != nil:
    section.add "ListenerArn", valid_594889
  var valid_594890 = formData.getOrDefault("Port")
  valid_594890 = validateParameter(valid_594890, JInt, required = false, default = nil)
  if valid_594890 != nil:
    section.add "Port", valid_594890
  var valid_594891 = formData.getOrDefault("Protocol")
  valid_594891 = validateParameter(valid_594891, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594891 != nil:
    section.add "Protocol", valid_594891
  var valid_594892 = formData.getOrDefault("SslPolicy")
  valid_594892 = validateParameter(valid_594892, JString, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "SslPolicy", valid_594892
  var valid_594893 = formData.getOrDefault("DefaultActions")
  valid_594893 = validateParameter(valid_594893, JArray, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "DefaultActions", valid_594893
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594894: Call_PostModifyListener_594876; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_594894.validator(path, query, header, formData, body)
  let scheme = call_594894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594894.url(scheme.get, call_594894.host, call_594894.base,
                         call_594894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594894, url, valid)

proc call*(call_594895: Call_PostModifyListener_594876; ListenerArn: string;
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
  var query_594896 = newJObject()
  var formData_594897 = newJObject()
  if Certificates != nil:
    formData_594897.add "Certificates", Certificates
  add(formData_594897, "ListenerArn", newJString(ListenerArn))
  add(formData_594897, "Port", newJInt(Port))
  add(formData_594897, "Protocol", newJString(Protocol))
  add(query_594896, "Action", newJString(Action))
  add(formData_594897, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_594897.add "DefaultActions", DefaultActions
  add(query_594896, "Version", newJString(Version))
  result = call_594895.call(nil, query_594896, nil, formData_594897, nil)

var postModifyListener* = Call_PostModifyListener_594876(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_594877, base: "/",
    url: url_PostModifyListener_594878, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_594855 = ref object of OpenApiRestCall_593437
proc url_GetModifyListener_594857(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyListener_594856(path: JsonNode; query: JsonNode;
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
  var valid_594858 = query.getOrDefault("DefaultActions")
  valid_594858 = validateParameter(valid_594858, JArray, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "DefaultActions", valid_594858
  var valid_594859 = query.getOrDefault("SslPolicy")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "SslPolicy", valid_594859
  var valid_594860 = query.getOrDefault("Protocol")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594860 != nil:
    section.add "Protocol", valid_594860
  var valid_594861 = query.getOrDefault("Certificates")
  valid_594861 = validateParameter(valid_594861, JArray, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "Certificates", valid_594861
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594862 = query.getOrDefault("Action")
  valid_594862 = validateParameter(valid_594862, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_594862 != nil:
    section.add "Action", valid_594862
  var valid_594863 = query.getOrDefault("ListenerArn")
  valid_594863 = validateParameter(valid_594863, JString, required = true,
                                 default = nil)
  if valid_594863 != nil:
    section.add "ListenerArn", valid_594863
  var valid_594864 = query.getOrDefault("Port")
  valid_594864 = validateParameter(valid_594864, JInt, required = false, default = nil)
  if valid_594864 != nil:
    section.add "Port", valid_594864
  var valid_594865 = query.getOrDefault("Version")
  valid_594865 = validateParameter(valid_594865, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594865 != nil:
    section.add "Version", valid_594865
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
  var valid_594866 = header.getOrDefault("X-Amz-Date")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-Date", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-Security-Token")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-Security-Token", valid_594867
  var valid_594868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "X-Amz-Content-Sha256", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Algorithm")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Algorithm", valid_594869
  var valid_594870 = header.getOrDefault("X-Amz-Signature")
  valid_594870 = validateParameter(valid_594870, JString, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "X-Amz-Signature", valid_594870
  var valid_594871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594871 = validateParameter(valid_594871, JString, required = false,
                                 default = nil)
  if valid_594871 != nil:
    section.add "X-Amz-SignedHeaders", valid_594871
  var valid_594872 = header.getOrDefault("X-Amz-Credential")
  valid_594872 = validateParameter(valid_594872, JString, required = false,
                                 default = nil)
  if valid_594872 != nil:
    section.add "X-Amz-Credential", valid_594872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594873: Call_GetModifyListener_594855; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_594873.validator(path, query, header, formData, body)
  let scheme = call_594873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594873.url(scheme.get, call_594873.host, call_594873.base,
                         call_594873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594873, url, valid)

proc call*(call_594874: Call_GetModifyListener_594855; ListenerArn: string;
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
  var query_594875 = newJObject()
  if DefaultActions != nil:
    query_594875.add "DefaultActions", DefaultActions
  add(query_594875, "SslPolicy", newJString(SslPolicy))
  add(query_594875, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_594875.add "Certificates", Certificates
  add(query_594875, "Action", newJString(Action))
  add(query_594875, "ListenerArn", newJString(ListenerArn))
  add(query_594875, "Port", newJInt(Port))
  add(query_594875, "Version", newJString(Version))
  result = call_594874.call(nil, query_594875, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_594855(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_594856,
    base: "/", url: url_GetModifyListener_594857,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_594915 = ref object of OpenApiRestCall_593437
proc url_PostModifyLoadBalancerAttributes_594917(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_594916(path: JsonNode;
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
  var valid_594918 = query.getOrDefault("Action")
  valid_594918 = validateParameter(valid_594918, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_594918 != nil:
    section.add "Action", valid_594918
  var valid_594919 = query.getOrDefault("Version")
  valid_594919 = validateParameter(valid_594919, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594919 != nil:
    section.add "Version", valid_594919
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
  var valid_594920 = header.getOrDefault("X-Amz-Date")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "X-Amz-Date", valid_594920
  var valid_594921 = header.getOrDefault("X-Amz-Security-Token")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "X-Amz-Security-Token", valid_594921
  var valid_594922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594922 = validateParameter(valid_594922, JString, required = false,
                                 default = nil)
  if valid_594922 != nil:
    section.add "X-Amz-Content-Sha256", valid_594922
  var valid_594923 = header.getOrDefault("X-Amz-Algorithm")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "X-Amz-Algorithm", valid_594923
  var valid_594924 = header.getOrDefault("X-Amz-Signature")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "X-Amz-Signature", valid_594924
  var valid_594925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-SignedHeaders", valid_594925
  var valid_594926 = header.getOrDefault("X-Amz-Credential")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "X-Amz-Credential", valid_594926
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_594927 = formData.getOrDefault("LoadBalancerArn")
  valid_594927 = validateParameter(valid_594927, JString, required = true,
                                 default = nil)
  if valid_594927 != nil:
    section.add "LoadBalancerArn", valid_594927
  var valid_594928 = formData.getOrDefault("Attributes")
  valid_594928 = validateParameter(valid_594928, JArray, required = true, default = nil)
  if valid_594928 != nil:
    section.add "Attributes", valid_594928
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594929: Call_PostModifyLoadBalancerAttributes_594915;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_594929.validator(path, query, header, formData, body)
  let scheme = call_594929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594929.url(scheme.get, call_594929.host, call_594929.base,
                         call_594929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594929, url, valid)

proc call*(call_594930: Call_PostModifyLoadBalancerAttributes_594915;
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
  var query_594931 = newJObject()
  var formData_594932 = newJObject()
  add(formData_594932, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    formData_594932.add "Attributes", Attributes
  add(query_594931, "Action", newJString(Action))
  add(query_594931, "Version", newJString(Version))
  result = call_594930.call(nil, query_594931, nil, formData_594932, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_594915(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_594916, base: "/",
    url: url_PostModifyLoadBalancerAttributes_594917,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_594898 = ref object of OpenApiRestCall_593437
proc url_GetModifyLoadBalancerAttributes_594900(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_594899(path: JsonNode;
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
  var valid_594901 = query.getOrDefault("Attributes")
  valid_594901 = validateParameter(valid_594901, JArray, required = true, default = nil)
  if valid_594901 != nil:
    section.add "Attributes", valid_594901
  var valid_594902 = query.getOrDefault("Action")
  valid_594902 = validateParameter(valid_594902, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_594902 != nil:
    section.add "Action", valid_594902
  var valid_594903 = query.getOrDefault("LoadBalancerArn")
  valid_594903 = validateParameter(valid_594903, JString, required = true,
                                 default = nil)
  if valid_594903 != nil:
    section.add "LoadBalancerArn", valid_594903
  var valid_594904 = query.getOrDefault("Version")
  valid_594904 = validateParameter(valid_594904, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594904 != nil:
    section.add "Version", valid_594904
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
  var valid_594905 = header.getOrDefault("X-Amz-Date")
  valid_594905 = validateParameter(valid_594905, JString, required = false,
                                 default = nil)
  if valid_594905 != nil:
    section.add "X-Amz-Date", valid_594905
  var valid_594906 = header.getOrDefault("X-Amz-Security-Token")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "X-Amz-Security-Token", valid_594906
  var valid_594907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "X-Amz-Content-Sha256", valid_594907
  var valid_594908 = header.getOrDefault("X-Amz-Algorithm")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Algorithm", valid_594908
  var valid_594909 = header.getOrDefault("X-Amz-Signature")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "X-Amz-Signature", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-SignedHeaders", valid_594910
  var valid_594911 = header.getOrDefault("X-Amz-Credential")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-Credential", valid_594911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594912: Call_GetModifyLoadBalancerAttributes_594898;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_594912.validator(path, query, header, formData, body)
  let scheme = call_594912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594912.url(scheme.get, call_594912.host, call_594912.base,
                         call_594912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594912, url, valid)

proc call*(call_594913: Call_GetModifyLoadBalancerAttributes_594898;
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
  var query_594914 = newJObject()
  if Attributes != nil:
    query_594914.add "Attributes", Attributes
  add(query_594914, "Action", newJString(Action))
  add(query_594914, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_594914, "Version", newJString(Version))
  result = call_594913.call(nil, query_594914, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_594898(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_594899, base: "/",
    url: url_GetModifyLoadBalancerAttributes_594900,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_594951 = ref object of OpenApiRestCall_593437
proc url_PostModifyRule_594953(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyRule_594952(path: JsonNode; query: JsonNode;
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
  var valid_594954 = query.getOrDefault("Action")
  valid_594954 = validateParameter(valid_594954, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_594954 != nil:
    section.add "Action", valid_594954
  var valid_594955 = query.getOrDefault("Version")
  valid_594955 = validateParameter(valid_594955, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594955 != nil:
    section.add "Version", valid_594955
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
  var valid_594956 = header.getOrDefault("X-Amz-Date")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Date", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Security-Token")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Security-Token", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Content-Sha256", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-Algorithm")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-Algorithm", valid_594959
  var valid_594960 = header.getOrDefault("X-Amz-Signature")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Signature", valid_594960
  var valid_594961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-SignedHeaders", valid_594961
  var valid_594962 = header.getOrDefault("X-Amz-Credential")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "X-Amz-Credential", valid_594962
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
  var valid_594963 = formData.getOrDefault("RuleArn")
  valid_594963 = validateParameter(valid_594963, JString, required = true,
                                 default = nil)
  if valid_594963 != nil:
    section.add "RuleArn", valid_594963
  var valid_594964 = formData.getOrDefault("Actions")
  valid_594964 = validateParameter(valid_594964, JArray, required = false,
                                 default = nil)
  if valid_594964 != nil:
    section.add "Actions", valid_594964
  var valid_594965 = formData.getOrDefault("Conditions")
  valid_594965 = validateParameter(valid_594965, JArray, required = false,
                                 default = nil)
  if valid_594965 != nil:
    section.add "Conditions", valid_594965
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594966: Call_PostModifyRule_594951; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_594966.validator(path, query, header, formData, body)
  let scheme = call_594966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594966.url(scheme.get, call_594966.host, call_594966.base,
                         call_594966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594966, url, valid)

proc call*(call_594967: Call_PostModifyRule_594951; RuleArn: string;
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
  var query_594968 = newJObject()
  var formData_594969 = newJObject()
  add(formData_594969, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    formData_594969.add "Actions", Actions
  if Conditions != nil:
    formData_594969.add "Conditions", Conditions
  add(query_594968, "Action", newJString(Action))
  add(query_594968, "Version", newJString(Version))
  result = call_594967.call(nil, query_594968, nil, formData_594969, nil)

var postModifyRule* = Call_PostModifyRule_594951(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_594952,
    base: "/", url: url_PostModifyRule_594953, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_594933 = ref object of OpenApiRestCall_593437
proc url_GetModifyRule_594935(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyRule_594934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594936 = query.getOrDefault("Conditions")
  valid_594936 = validateParameter(valid_594936, JArray, required = false,
                                 default = nil)
  if valid_594936 != nil:
    section.add "Conditions", valid_594936
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594937 = query.getOrDefault("Action")
  valid_594937 = validateParameter(valid_594937, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_594937 != nil:
    section.add "Action", valid_594937
  var valid_594938 = query.getOrDefault("RuleArn")
  valid_594938 = validateParameter(valid_594938, JString, required = true,
                                 default = nil)
  if valid_594938 != nil:
    section.add "RuleArn", valid_594938
  var valid_594939 = query.getOrDefault("Actions")
  valid_594939 = validateParameter(valid_594939, JArray, required = false,
                                 default = nil)
  if valid_594939 != nil:
    section.add "Actions", valid_594939
  var valid_594940 = query.getOrDefault("Version")
  valid_594940 = validateParameter(valid_594940, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594940 != nil:
    section.add "Version", valid_594940
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
  var valid_594941 = header.getOrDefault("X-Amz-Date")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "X-Amz-Date", valid_594941
  var valid_594942 = header.getOrDefault("X-Amz-Security-Token")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "X-Amz-Security-Token", valid_594942
  var valid_594943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594943 = validateParameter(valid_594943, JString, required = false,
                                 default = nil)
  if valid_594943 != nil:
    section.add "X-Amz-Content-Sha256", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-Algorithm")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-Algorithm", valid_594944
  var valid_594945 = header.getOrDefault("X-Amz-Signature")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "X-Amz-Signature", valid_594945
  var valid_594946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "X-Amz-SignedHeaders", valid_594946
  var valid_594947 = header.getOrDefault("X-Amz-Credential")
  valid_594947 = validateParameter(valid_594947, JString, required = false,
                                 default = nil)
  if valid_594947 != nil:
    section.add "X-Amz-Credential", valid_594947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594948: Call_GetModifyRule_594933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_594948.validator(path, query, header, formData, body)
  let scheme = call_594948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594948.url(scheme.get, call_594948.host, call_594948.base,
                         call_594948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594948, url, valid)

proc call*(call_594949: Call_GetModifyRule_594933; RuleArn: string;
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
  var query_594950 = newJObject()
  if Conditions != nil:
    query_594950.add "Conditions", Conditions
  add(query_594950, "Action", newJString(Action))
  add(query_594950, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_594950.add "Actions", Actions
  add(query_594950, "Version", newJString(Version))
  result = call_594949.call(nil, query_594950, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_594933(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_594934,
    base: "/", url: url_GetModifyRule_594935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_594995 = ref object of OpenApiRestCall_593437
proc url_PostModifyTargetGroup_594997(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyTargetGroup_594996(path: JsonNode; query: JsonNode;
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
  var valid_594998 = query.getOrDefault("Action")
  valid_594998 = validateParameter(valid_594998, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_594998 != nil:
    section.add "Action", valid_594998
  var valid_594999 = query.getOrDefault("Version")
  valid_594999 = validateParameter(valid_594999, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594999 != nil:
    section.add "Version", valid_594999
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
  var valid_595000 = header.getOrDefault("X-Amz-Date")
  valid_595000 = validateParameter(valid_595000, JString, required = false,
                                 default = nil)
  if valid_595000 != nil:
    section.add "X-Amz-Date", valid_595000
  var valid_595001 = header.getOrDefault("X-Amz-Security-Token")
  valid_595001 = validateParameter(valid_595001, JString, required = false,
                                 default = nil)
  if valid_595001 != nil:
    section.add "X-Amz-Security-Token", valid_595001
  var valid_595002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "X-Amz-Content-Sha256", valid_595002
  var valid_595003 = header.getOrDefault("X-Amz-Algorithm")
  valid_595003 = validateParameter(valid_595003, JString, required = false,
                                 default = nil)
  if valid_595003 != nil:
    section.add "X-Amz-Algorithm", valid_595003
  var valid_595004 = header.getOrDefault("X-Amz-Signature")
  valid_595004 = validateParameter(valid_595004, JString, required = false,
                                 default = nil)
  if valid_595004 != nil:
    section.add "X-Amz-Signature", valid_595004
  var valid_595005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595005 = validateParameter(valid_595005, JString, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "X-Amz-SignedHeaders", valid_595005
  var valid_595006 = header.getOrDefault("X-Amz-Credential")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "X-Amz-Credential", valid_595006
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
  var valid_595007 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_595007 = validateParameter(valid_595007, JInt, required = false, default = nil)
  if valid_595007 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_595007
  var valid_595008 = formData.getOrDefault("HealthCheckPort")
  valid_595008 = validateParameter(valid_595008, JString, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "HealthCheckPort", valid_595008
  var valid_595009 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_595009 = validateParameter(valid_595009, JInt, required = false, default = nil)
  if valid_595009 != nil:
    section.add "UnhealthyThresholdCount", valid_595009
  var valid_595010 = formData.getOrDefault("HealthCheckPath")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "HealthCheckPath", valid_595010
  var valid_595011 = formData.getOrDefault("HealthCheckEnabled")
  valid_595011 = validateParameter(valid_595011, JBool, required = false, default = nil)
  if valid_595011 != nil:
    section.add "HealthCheckEnabled", valid_595011
  var valid_595012 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_595012 = validateParameter(valid_595012, JInt, required = false, default = nil)
  if valid_595012 != nil:
    section.add "HealthCheckIntervalSeconds", valid_595012
  var valid_595013 = formData.getOrDefault("HealthyThresholdCount")
  valid_595013 = validateParameter(valid_595013, JInt, required = false, default = nil)
  if valid_595013 != nil:
    section.add "HealthyThresholdCount", valid_595013
  var valid_595014 = formData.getOrDefault("HealthCheckProtocol")
  valid_595014 = validateParameter(valid_595014, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_595014 != nil:
    section.add "HealthCheckProtocol", valid_595014
  var valid_595015 = formData.getOrDefault("Matcher.HttpCode")
  valid_595015 = validateParameter(valid_595015, JString, required = false,
                                 default = nil)
  if valid_595015 != nil:
    section.add "Matcher.HttpCode", valid_595015
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_595016 = formData.getOrDefault("TargetGroupArn")
  valid_595016 = validateParameter(valid_595016, JString, required = true,
                                 default = nil)
  if valid_595016 != nil:
    section.add "TargetGroupArn", valid_595016
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595017: Call_PostModifyTargetGroup_594995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_595017.validator(path, query, header, formData, body)
  let scheme = call_595017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595017.url(scheme.get, call_595017.host, call_595017.base,
                         call_595017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595017, url, valid)

proc call*(call_595018: Call_PostModifyTargetGroup_594995; TargetGroupArn: string;
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
  var query_595019 = newJObject()
  var formData_595020 = newJObject()
  add(formData_595020, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_595020, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_595020, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_595020, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_595020, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_595019, "Action", newJString(Action))
  add(formData_595020, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_595020, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_595020, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_595020, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(formData_595020, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_595019, "Version", newJString(Version))
  result = call_595018.call(nil, query_595019, nil, formData_595020, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_594995(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_594996, base: "/",
    url: url_PostModifyTargetGroup_594997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_594970 = ref object of OpenApiRestCall_593437
proc url_GetModifyTargetGroup_594972(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyTargetGroup_594971(path: JsonNode; query: JsonNode;
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
  var valid_594973 = query.getOrDefault("HealthCheckEnabled")
  valid_594973 = validateParameter(valid_594973, JBool, required = false, default = nil)
  if valid_594973 != nil:
    section.add "HealthCheckEnabled", valid_594973
  var valid_594974 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_594974 = validateParameter(valid_594974, JInt, required = false, default = nil)
  if valid_594974 != nil:
    section.add "HealthCheckIntervalSeconds", valid_594974
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_594975 = query.getOrDefault("TargetGroupArn")
  valid_594975 = validateParameter(valid_594975, JString, required = true,
                                 default = nil)
  if valid_594975 != nil:
    section.add "TargetGroupArn", valid_594975
  var valid_594976 = query.getOrDefault("HealthCheckPort")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "HealthCheckPort", valid_594976
  var valid_594977 = query.getOrDefault("Action")
  valid_594977 = validateParameter(valid_594977, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_594977 != nil:
    section.add "Action", valid_594977
  var valid_594978 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_594978 = validateParameter(valid_594978, JInt, required = false, default = nil)
  if valid_594978 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_594978
  var valid_594979 = query.getOrDefault("Matcher.HttpCode")
  valid_594979 = validateParameter(valid_594979, JString, required = false,
                                 default = nil)
  if valid_594979 != nil:
    section.add "Matcher.HttpCode", valid_594979
  var valid_594980 = query.getOrDefault("UnhealthyThresholdCount")
  valid_594980 = validateParameter(valid_594980, JInt, required = false, default = nil)
  if valid_594980 != nil:
    section.add "UnhealthyThresholdCount", valid_594980
  var valid_594981 = query.getOrDefault("HealthCheckProtocol")
  valid_594981 = validateParameter(valid_594981, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_594981 != nil:
    section.add "HealthCheckProtocol", valid_594981
  var valid_594982 = query.getOrDefault("HealthyThresholdCount")
  valid_594982 = validateParameter(valid_594982, JInt, required = false, default = nil)
  if valid_594982 != nil:
    section.add "HealthyThresholdCount", valid_594982
  var valid_594983 = query.getOrDefault("Version")
  valid_594983 = validateParameter(valid_594983, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_594983 != nil:
    section.add "Version", valid_594983
  var valid_594984 = query.getOrDefault("HealthCheckPath")
  valid_594984 = validateParameter(valid_594984, JString, required = false,
                                 default = nil)
  if valid_594984 != nil:
    section.add "HealthCheckPath", valid_594984
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
  var valid_594985 = header.getOrDefault("X-Amz-Date")
  valid_594985 = validateParameter(valid_594985, JString, required = false,
                                 default = nil)
  if valid_594985 != nil:
    section.add "X-Amz-Date", valid_594985
  var valid_594986 = header.getOrDefault("X-Amz-Security-Token")
  valid_594986 = validateParameter(valid_594986, JString, required = false,
                                 default = nil)
  if valid_594986 != nil:
    section.add "X-Amz-Security-Token", valid_594986
  var valid_594987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594987 = validateParameter(valid_594987, JString, required = false,
                                 default = nil)
  if valid_594987 != nil:
    section.add "X-Amz-Content-Sha256", valid_594987
  var valid_594988 = header.getOrDefault("X-Amz-Algorithm")
  valid_594988 = validateParameter(valid_594988, JString, required = false,
                                 default = nil)
  if valid_594988 != nil:
    section.add "X-Amz-Algorithm", valid_594988
  var valid_594989 = header.getOrDefault("X-Amz-Signature")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "X-Amz-Signature", valid_594989
  var valid_594990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594990 = validateParameter(valid_594990, JString, required = false,
                                 default = nil)
  if valid_594990 != nil:
    section.add "X-Amz-SignedHeaders", valid_594990
  var valid_594991 = header.getOrDefault("X-Amz-Credential")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "X-Amz-Credential", valid_594991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594992: Call_GetModifyTargetGroup_594970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_594992.validator(path, query, header, formData, body)
  let scheme = call_594992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594992.url(scheme.get, call_594992.host, call_594992.base,
                         call_594992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594992, url, valid)

proc call*(call_594993: Call_GetModifyTargetGroup_594970; TargetGroupArn: string;
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
  var query_594994 = newJObject()
  add(query_594994, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_594994, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_594994, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_594994, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_594994, "Action", newJString(Action))
  add(query_594994, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_594994, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_594994, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_594994, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_594994, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_594994, "Version", newJString(Version))
  add(query_594994, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_594993.call(nil, query_594994, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_594970(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_594971,
    base: "/", url: url_GetModifyTargetGroup_594972,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_595038 = ref object of OpenApiRestCall_593437
proc url_PostModifyTargetGroupAttributes_595040(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyTargetGroupAttributes_595039(path: JsonNode;
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
  var valid_595041 = query.getOrDefault("Action")
  valid_595041 = validateParameter(valid_595041, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_595041 != nil:
    section.add "Action", valid_595041
  var valid_595042 = query.getOrDefault("Version")
  valid_595042 = validateParameter(valid_595042, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595042 != nil:
    section.add "Version", valid_595042
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
  var valid_595043 = header.getOrDefault("X-Amz-Date")
  valid_595043 = validateParameter(valid_595043, JString, required = false,
                                 default = nil)
  if valid_595043 != nil:
    section.add "X-Amz-Date", valid_595043
  var valid_595044 = header.getOrDefault("X-Amz-Security-Token")
  valid_595044 = validateParameter(valid_595044, JString, required = false,
                                 default = nil)
  if valid_595044 != nil:
    section.add "X-Amz-Security-Token", valid_595044
  var valid_595045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595045 = validateParameter(valid_595045, JString, required = false,
                                 default = nil)
  if valid_595045 != nil:
    section.add "X-Amz-Content-Sha256", valid_595045
  var valid_595046 = header.getOrDefault("X-Amz-Algorithm")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = nil)
  if valid_595046 != nil:
    section.add "X-Amz-Algorithm", valid_595046
  var valid_595047 = header.getOrDefault("X-Amz-Signature")
  valid_595047 = validateParameter(valid_595047, JString, required = false,
                                 default = nil)
  if valid_595047 != nil:
    section.add "X-Amz-Signature", valid_595047
  var valid_595048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595048 = validateParameter(valid_595048, JString, required = false,
                                 default = nil)
  if valid_595048 != nil:
    section.add "X-Amz-SignedHeaders", valid_595048
  var valid_595049 = header.getOrDefault("X-Amz-Credential")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-Credential", valid_595049
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_595050 = formData.getOrDefault("Attributes")
  valid_595050 = validateParameter(valid_595050, JArray, required = true, default = nil)
  if valid_595050 != nil:
    section.add "Attributes", valid_595050
  var valid_595051 = formData.getOrDefault("TargetGroupArn")
  valid_595051 = validateParameter(valid_595051, JString, required = true,
                                 default = nil)
  if valid_595051 != nil:
    section.add "TargetGroupArn", valid_595051
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595052: Call_PostModifyTargetGroupAttributes_595038;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_595052.validator(path, query, header, formData, body)
  let scheme = call_595052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595052.url(scheme.get, call_595052.host, call_595052.base,
                         call_595052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595052, url, valid)

proc call*(call_595053: Call_PostModifyTargetGroupAttributes_595038;
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
  var query_595054 = newJObject()
  var formData_595055 = newJObject()
  if Attributes != nil:
    formData_595055.add "Attributes", Attributes
  add(query_595054, "Action", newJString(Action))
  add(formData_595055, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_595054, "Version", newJString(Version))
  result = call_595053.call(nil, query_595054, nil, formData_595055, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_595038(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_595039, base: "/",
    url: url_PostModifyTargetGroupAttributes_595040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_595021 = ref object of OpenApiRestCall_593437
proc url_GetModifyTargetGroupAttributes_595023(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyTargetGroupAttributes_595022(path: JsonNode;
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
  var valid_595024 = query.getOrDefault("TargetGroupArn")
  valid_595024 = validateParameter(valid_595024, JString, required = true,
                                 default = nil)
  if valid_595024 != nil:
    section.add "TargetGroupArn", valid_595024
  var valid_595025 = query.getOrDefault("Attributes")
  valid_595025 = validateParameter(valid_595025, JArray, required = true, default = nil)
  if valid_595025 != nil:
    section.add "Attributes", valid_595025
  var valid_595026 = query.getOrDefault("Action")
  valid_595026 = validateParameter(valid_595026, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_595026 != nil:
    section.add "Action", valid_595026
  var valid_595027 = query.getOrDefault("Version")
  valid_595027 = validateParameter(valid_595027, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595027 != nil:
    section.add "Version", valid_595027
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
  var valid_595028 = header.getOrDefault("X-Amz-Date")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "X-Amz-Date", valid_595028
  var valid_595029 = header.getOrDefault("X-Amz-Security-Token")
  valid_595029 = validateParameter(valid_595029, JString, required = false,
                                 default = nil)
  if valid_595029 != nil:
    section.add "X-Amz-Security-Token", valid_595029
  var valid_595030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "X-Amz-Content-Sha256", valid_595030
  var valid_595031 = header.getOrDefault("X-Amz-Algorithm")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "X-Amz-Algorithm", valid_595031
  var valid_595032 = header.getOrDefault("X-Amz-Signature")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "X-Amz-Signature", valid_595032
  var valid_595033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "X-Amz-SignedHeaders", valid_595033
  var valid_595034 = header.getOrDefault("X-Amz-Credential")
  valid_595034 = validateParameter(valid_595034, JString, required = false,
                                 default = nil)
  if valid_595034 != nil:
    section.add "X-Amz-Credential", valid_595034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595035: Call_GetModifyTargetGroupAttributes_595021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_595035.validator(path, query, header, formData, body)
  let scheme = call_595035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595035.url(scheme.get, call_595035.host, call_595035.base,
                         call_595035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595035, url, valid)

proc call*(call_595036: Call_GetModifyTargetGroupAttributes_595021;
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
  var query_595037 = newJObject()
  add(query_595037, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_595037.add "Attributes", Attributes
  add(query_595037, "Action", newJString(Action))
  add(query_595037, "Version", newJString(Version))
  result = call_595036.call(nil, query_595037, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_595021(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_595022, base: "/",
    url: url_GetModifyTargetGroupAttributes_595023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_595073 = ref object of OpenApiRestCall_593437
proc url_PostRegisterTargets_595075(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRegisterTargets_595074(path: JsonNode; query: JsonNode;
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
  var valid_595076 = query.getOrDefault("Action")
  valid_595076 = validateParameter(valid_595076, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_595076 != nil:
    section.add "Action", valid_595076
  var valid_595077 = query.getOrDefault("Version")
  valid_595077 = validateParameter(valid_595077, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595077 != nil:
    section.add "Version", valid_595077
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
  var valid_595078 = header.getOrDefault("X-Amz-Date")
  valid_595078 = validateParameter(valid_595078, JString, required = false,
                                 default = nil)
  if valid_595078 != nil:
    section.add "X-Amz-Date", valid_595078
  var valid_595079 = header.getOrDefault("X-Amz-Security-Token")
  valid_595079 = validateParameter(valid_595079, JString, required = false,
                                 default = nil)
  if valid_595079 != nil:
    section.add "X-Amz-Security-Token", valid_595079
  var valid_595080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595080 = validateParameter(valid_595080, JString, required = false,
                                 default = nil)
  if valid_595080 != nil:
    section.add "X-Amz-Content-Sha256", valid_595080
  var valid_595081 = header.getOrDefault("X-Amz-Algorithm")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "X-Amz-Algorithm", valid_595081
  var valid_595082 = header.getOrDefault("X-Amz-Signature")
  valid_595082 = validateParameter(valid_595082, JString, required = false,
                                 default = nil)
  if valid_595082 != nil:
    section.add "X-Amz-Signature", valid_595082
  var valid_595083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595083 = validateParameter(valid_595083, JString, required = false,
                                 default = nil)
  if valid_595083 != nil:
    section.add "X-Amz-SignedHeaders", valid_595083
  var valid_595084 = header.getOrDefault("X-Amz-Credential")
  valid_595084 = validateParameter(valid_595084, JString, required = false,
                                 default = nil)
  if valid_595084 != nil:
    section.add "X-Amz-Credential", valid_595084
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_595085 = formData.getOrDefault("Targets")
  valid_595085 = validateParameter(valid_595085, JArray, required = true, default = nil)
  if valid_595085 != nil:
    section.add "Targets", valid_595085
  var valid_595086 = formData.getOrDefault("TargetGroupArn")
  valid_595086 = validateParameter(valid_595086, JString, required = true,
                                 default = nil)
  if valid_595086 != nil:
    section.add "TargetGroupArn", valid_595086
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595087: Call_PostRegisterTargets_595073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_595087.validator(path, query, header, formData, body)
  let scheme = call_595087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595087.url(scheme.get, call_595087.host, call_595087.base,
                         call_595087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595087, url, valid)

proc call*(call_595088: Call_PostRegisterTargets_595073; Targets: JsonNode;
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
  var query_595089 = newJObject()
  var formData_595090 = newJObject()
  if Targets != nil:
    formData_595090.add "Targets", Targets
  add(query_595089, "Action", newJString(Action))
  add(formData_595090, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_595089, "Version", newJString(Version))
  result = call_595088.call(nil, query_595089, nil, formData_595090, nil)

var postRegisterTargets* = Call_PostRegisterTargets_595073(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_595074, base: "/",
    url: url_PostRegisterTargets_595075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_595056 = ref object of OpenApiRestCall_593437
proc url_GetRegisterTargets_595058(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRegisterTargets_595057(path: JsonNode; query: JsonNode;
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
  var valid_595059 = query.getOrDefault("Targets")
  valid_595059 = validateParameter(valid_595059, JArray, required = true, default = nil)
  if valid_595059 != nil:
    section.add "Targets", valid_595059
  var valid_595060 = query.getOrDefault("TargetGroupArn")
  valid_595060 = validateParameter(valid_595060, JString, required = true,
                                 default = nil)
  if valid_595060 != nil:
    section.add "TargetGroupArn", valid_595060
  var valid_595061 = query.getOrDefault("Action")
  valid_595061 = validateParameter(valid_595061, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_595061 != nil:
    section.add "Action", valid_595061
  var valid_595062 = query.getOrDefault("Version")
  valid_595062 = validateParameter(valid_595062, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595062 != nil:
    section.add "Version", valid_595062
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
  var valid_595063 = header.getOrDefault("X-Amz-Date")
  valid_595063 = validateParameter(valid_595063, JString, required = false,
                                 default = nil)
  if valid_595063 != nil:
    section.add "X-Amz-Date", valid_595063
  var valid_595064 = header.getOrDefault("X-Amz-Security-Token")
  valid_595064 = validateParameter(valid_595064, JString, required = false,
                                 default = nil)
  if valid_595064 != nil:
    section.add "X-Amz-Security-Token", valid_595064
  var valid_595065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595065 = validateParameter(valid_595065, JString, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "X-Amz-Content-Sha256", valid_595065
  var valid_595066 = header.getOrDefault("X-Amz-Algorithm")
  valid_595066 = validateParameter(valid_595066, JString, required = false,
                                 default = nil)
  if valid_595066 != nil:
    section.add "X-Amz-Algorithm", valid_595066
  var valid_595067 = header.getOrDefault("X-Amz-Signature")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "X-Amz-Signature", valid_595067
  var valid_595068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595068 = validateParameter(valid_595068, JString, required = false,
                                 default = nil)
  if valid_595068 != nil:
    section.add "X-Amz-SignedHeaders", valid_595068
  var valid_595069 = header.getOrDefault("X-Amz-Credential")
  valid_595069 = validateParameter(valid_595069, JString, required = false,
                                 default = nil)
  if valid_595069 != nil:
    section.add "X-Amz-Credential", valid_595069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595070: Call_GetRegisterTargets_595056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_595070.validator(path, query, header, formData, body)
  let scheme = call_595070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595070.url(scheme.get, call_595070.host, call_595070.base,
                         call_595070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595070, url, valid)

proc call*(call_595071: Call_GetRegisterTargets_595056; Targets: JsonNode;
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
  var query_595072 = newJObject()
  if Targets != nil:
    query_595072.add "Targets", Targets
  add(query_595072, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_595072, "Action", newJString(Action))
  add(query_595072, "Version", newJString(Version))
  result = call_595071.call(nil, query_595072, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_595056(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_595057, base: "/",
    url: url_GetRegisterTargets_595058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_595108 = ref object of OpenApiRestCall_593437
proc url_PostRemoveListenerCertificates_595110(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveListenerCertificates_595109(path: JsonNode;
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
  var valid_595111 = query.getOrDefault("Action")
  valid_595111 = validateParameter(valid_595111, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_595111 != nil:
    section.add "Action", valid_595111
  var valid_595112 = query.getOrDefault("Version")
  valid_595112 = validateParameter(valid_595112, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595112 != nil:
    section.add "Version", valid_595112
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
  var valid_595113 = header.getOrDefault("X-Amz-Date")
  valid_595113 = validateParameter(valid_595113, JString, required = false,
                                 default = nil)
  if valid_595113 != nil:
    section.add "X-Amz-Date", valid_595113
  var valid_595114 = header.getOrDefault("X-Amz-Security-Token")
  valid_595114 = validateParameter(valid_595114, JString, required = false,
                                 default = nil)
  if valid_595114 != nil:
    section.add "X-Amz-Security-Token", valid_595114
  var valid_595115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-Content-Sha256", valid_595115
  var valid_595116 = header.getOrDefault("X-Amz-Algorithm")
  valid_595116 = validateParameter(valid_595116, JString, required = false,
                                 default = nil)
  if valid_595116 != nil:
    section.add "X-Amz-Algorithm", valid_595116
  var valid_595117 = header.getOrDefault("X-Amz-Signature")
  valid_595117 = validateParameter(valid_595117, JString, required = false,
                                 default = nil)
  if valid_595117 != nil:
    section.add "X-Amz-Signature", valid_595117
  var valid_595118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595118 = validateParameter(valid_595118, JString, required = false,
                                 default = nil)
  if valid_595118 != nil:
    section.add "X-Amz-SignedHeaders", valid_595118
  var valid_595119 = header.getOrDefault("X-Amz-Credential")
  valid_595119 = validateParameter(valid_595119, JString, required = false,
                                 default = nil)
  if valid_595119 != nil:
    section.add "X-Amz-Credential", valid_595119
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_595120 = formData.getOrDefault("Certificates")
  valid_595120 = validateParameter(valid_595120, JArray, required = true, default = nil)
  if valid_595120 != nil:
    section.add "Certificates", valid_595120
  var valid_595121 = formData.getOrDefault("ListenerArn")
  valid_595121 = validateParameter(valid_595121, JString, required = true,
                                 default = nil)
  if valid_595121 != nil:
    section.add "ListenerArn", valid_595121
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595122: Call_PostRemoveListenerCertificates_595108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_595122.validator(path, query, header, formData, body)
  let scheme = call_595122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595122.url(scheme.get, call_595122.host, call_595122.base,
                         call_595122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595122, url, valid)

proc call*(call_595123: Call_PostRemoveListenerCertificates_595108;
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
  var query_595124 = newJObject()
  var formData_595125 = newJObject()
  if Certificates != nil:
    formData_595125.add "Certificates", Certificates
  add(formData_595125, "ListenerArn", newJString(ListenerArn))
  add(query_595124, "Action", newJString(Action))
  add(query_595124, "Version", newJString(Version))
  result = call_595123.call(nil, query_595124, nil, formData_595125, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_595108(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_595109, base: "/",
    url: url_PostRemoveListenerCertificates_595110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_595091 = ref object of OpenApiRestCall_593437
proc url_GetRemoveListenerCertificates_595093(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveListenerCertificates_595092(path: JsonNode; query: JsonNode;
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
  var valid_595094 = query.getOrDefault("Certificates")
  valid_595094 = validateParameter(valid_595094, JArray, required = true, default = nil)
  if valid_595094 != nil:
    section.add "Certificates", valid_595094
  var valid_595095 = query.getOrDefault("Action")
  valid_595095 = validateParameter(valid_595095, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_595095 != nil:
    section.add "Action", valid_595095
  var valid_595096 = query.getOrDefault("ListenerArn")
  valid_595096 = validateParameter(valid_595096, JString, required = true,
                                 default = nil)
  if valid_595096 != nil:
    section.add "ListenerArn", valid_595096
  var valid_595097 = query.getOrDefault("Version")
  valid_595097 = validateParameter(valid_595097, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595097 != nil:
    section.add "Version", valid_595097
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
  var valid_595098 = header.getOrDefault("X-Amz-Date")
  valid_595098 = validateParameter(valid_595098, JString, required = false,
                                 default = nil)
  if valid_595098 != nil:
    section.add "X-Amz-Date", valid_595098
  var valid_595099 = header.getOrDefault("X-Amz-Security-Token")
  valid_595099 = validateParameter(valid_595099, JString, required = false,
                                 default = nil)
  if valid_595099 != nil:
    section.add "X-Amz-Security-Token", valid_595099
  var valid_595100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595100 = validateParameter(valid_595100, JString, required = false,
                                 default = nil)
  if valid_595100 != nil:
    section.add "X-Amz-Content-Sha256", valid_595100
  var valid_595101 = header.getOrDefault("X-Amz-Algorithm")
  valid_595101 = validateParameter(valid_595101, JString, required = false,
                                 default = nil)
  if valid_595101 != nil:
    section.add "X-Amz-Algorithm", valid_595101
  var valid_595102 = header.getOrDefault("X-Amz-Signature")
  valid_595102 = validateParameter(valid_595102, JString, required = false,
                                 default = nil)
  if valid_595102 != nil:
    section.add "X-Amz-Signature", valid_595102
  var valid_595103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595103 = validateParameter(valid_595103, JString, required = false,
                                 default = nil)
  if valid_595103 != nil:
    section.add "X-Amz-SignedHeaders", valid_595103
  var valid_595104 = header.getOrDefault("X-Amz-Credential")
  valid_595104 = validateParameter(valid_595104, JString, required = false,
                                 default = nil)
  if valid_595104 != nil:
    section.add "X-Amz-Credential", valid_595104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595105: Call_GetRemoveListenerCertificates_595091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_595105.validator(path, query, header, formData, body)
  let scheme = call_595105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595105.url(scheme.get, call_595105.host, call_595105.base,
                         call_595105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595105, url, valid)

proc call*(call_595106: Call_GetRemoveListenerCertificates_595091;
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
  var query_595107 = newJObject()
  if Certificates != nil:
    query_595107.add "Certificates", Certificates
  add(query_595107, "Action", newJString(Action))
  add(query_595107, "ListenerArn", newJString(ListenerArn))
  add(query_595107, "Version", newJString(Version))
  result = call_595106.call(nil, query_595107, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_595091(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_595092, base: "/",
    url: url_GetRemoveListenerCertificates_595093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_595143 = ref object of OpenApiRestCall_593437
proc url_PostRemoveTags_595145(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTags_595144(path: JsonNode; query: JsonNode;
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
  var valid_595146 = query.getOrDefault("Action")
  valid_595146 = validateParameter(valid_595146, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_595146 != nil:
    section.add "Action", valid_595146
  var valid_595147 = query.getOrDefault("Version")
  valid_595147 = validateParameter(valid_595147, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595147 != nil:
    section.add "Version", valid_595147
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
  var valid_595148 = header.getOrDefault("X-Amz-Date")
  valid_595148 = validateParameter(valid_595148, JString, required = false,
                                 default = nil)
  if valid_595148 != nil:
    section.add "X-Amz-Date", valid_595148
  var valid_595149 = header.getOrDefault("X-Amz-Security-Token")
  valid_595149 = validateParameter(valid_595149, JString, required = false,
                                 default = nil)
  if valid_595149 != nil:
    section.add "X-Amz-Security-Token", valid_595149
  var valid_595150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595150 = validateParameter(valid_595150, JString, required = false,
                                 default = nil)
  if valid_595150 != nil:
    section.add "X-Amz-Content-Sha256", valid_595150
  var valid_595151 = header.getOrDefault("X-Amz-Algorithm")
  valid_595151 = validateParameter(valid_595151, JString, required = false,
                                 default = nil)
  if valid_595151 != nil:
    section.add "X-Amz-Algorithm", valid_595151
  var valid_595152 = header.getOrDefault("X-Amz-Signature")
  valid_595152 = validateParameter(valid_595152, JString, required = false,
                                 default = nil)
  if valid_595152 != nil:
    section.add "X-Amz-Signature", valid_595152
  var valid_595153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595153 = validateParameter(valid_595153, JString, required = false,
                                 default = nil)
  if valid_595153 != nil:
    section.add "X-Amz-SignedHeaders", valid_595153
  var valid_595154 = header.getOrDefault("X-Amz-Credential")
  valid_595154 = validateParameter(valid_595154, JString, required = false,
                                 default = nil)
  if valid_595154 != nil:
    section.add "X-Amz-Credential", valid_595154
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_595155 = formData.getOrDefault("ResourceArns")
  valid_595155 = validateParameter(valid_595155, JArray, required = true, default = nil)
  if valid_595155 != nil:
    section.add "ResourceArns", valid_595155
  var valid_595156 = formData.getOrDefault("TagKeys")
  valid_595156 = validateParameter(valid_595156, JArray, required = true, default = nil)
  if valid_595156 != nil:
    section.add "TagKeys", valid_595156
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595157: Call_PostRemoveTags_595143; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_595157.validator(path, query, header, formData, body)
  let scheme = call_595157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595157.url(scheme.get, call_595157.host, call_595157.base,
                         call_595157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595157, url, valid)

proc call*(call_595158: Call_PostRemoveTags_595143; ResourceArns: JsonNode;
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
  var query_595159 = newJObject()
  var formData_595160 = newJObject()
  if ResourceArns != nil:
    formData_595160.add "ResourceArns", ResourceArns
  add(query_595159, "Action", newJString(Action))
  if TagKeys != nil:
    formData_595160.add "TagKeys", TagKeys
  add(query_595159, "Version", newJString(Version))
  result = call_595158.call(nil, query_595159, nil, formData_595160, nil)

var postRemoveTags* = Call_PostRemoveTags_595143(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_595144,
    base: "/", url: url_PostRemoveTags_595145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_595126 = ref object of OpenApiRestCall_593437
proc url_GetRemoveTags_595128(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTags_595127(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595129 = query.getOrDefault("Action")
  valid_595129 = validateParameter(valid_595129, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_595129 != nil:
    section.add "Action", valid_595129
  var valid_595130 = query.getOrDefault("ResourceArns")
  valid_595130 = validateParameter(valid_595130, JArray, required = true, default = nil)
  if valid_595130 != nil:
    section.add "ResourceArns", valid_595130
  var valid_595131 = query.getOrDefault("TagKeys")
  valid_595131 = validateParameter(valid_595131, JArray, required = true, default = nil)
  if valid_595131 != nil:
    section.add "TagKeys", valid_595131
  var valid_595132 = query.getOrDefault("Version")
  valid_595132 = validateParameter(valid_595132, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595132 != nil:
    section.add "Version", valid_595132
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
  var valid_595133 = header.getOrDefault("X-Amz-Date")
  valid_595133 = validateParameter(valid_595133, JString, required = false,
                                 default = nil)
  if valid_595133 != nil:
    section.add "X-Amz-Date", valid_595133
  var valid_595134 = header.getOrDefault("X-Amz-Security-Token")
  valid_595134 = validateParameter(valid_595134, JString, required = false,
                                 default = nil)
  if valid_595134 != nil:
    section.add "X-Amz-Security-Token", valid_595134
  var valid_595135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595135 = validateParameter(valid_595135, JString, required = false,
                                 default = nil)
  if valid_595135 != nil:
    section.add "X-Amz-Content-Sha256", valid_595135
  var valid_595136 = header.getOrDefault("X-Amz-Algorithm")
  valid_595136 = validateParameter(valid_595136, JString, required = false,
                                 default = nil)
  if valid_595136 != nil:
    section.add "X-Amz-Algorithm", valid_595136
  var valid_595137 = header.getOrDefault("X-Amz-Signature")
  valid_595137 = validateParameter(valid_595137, JString, required = false,
                                 default = nil)
  if valid_595137 != nil:
    section.add "X-Amz-Signature", valid_595137
  var valid_595138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595138 = validateParameter(valid_595138, JString, required = false,
                                 default = nil)
  if valid_595138 != nil:
    section.add "X-Amz-SignedHeaders", valid_595138
  var valid_595139 = header.getOrDefault("X-Amz-Credential")
  valid_595139 = validateParameter(valid_595139, JString, required = false,
                                 default = nil)
  if valid_595139 != nil:
    section.add "X-Amz-Credential", valid_595139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595140: Call_GetRemoveTags_595126; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_595140.validator(path, query, header, formData, body)
  let scheme = call_595140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595140.url(scheme.get, call_595140.host, call_595140.base,
                         call_595140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595140, url, valid)

proc call*(call_595141: Call_GetRemoveTags_595126; ResourceArns: JsonNode;
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
  var query_595142 = newJObject()
  add(query_595142, "Action", newJString(Action))
  if ResourceArns != nil:
    query_595142.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_595142.add "TagKeys", TagKeys
  add(query_595142, "Version", newJString(Version))
  result = call_595141.call(nil, query_595142, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_595126(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_595127,
    base: "/", url: url_GetRemoveTags_595128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_595178 = ref object of OpenApiRestCall_593437
proc url_PostSetIpAddressType_595180(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetIpAddressType_595179(path: JsonNode; query: JsonNode;
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
  var valid_595181 = query.getOrDefault("Action")
  valid_595181 = validateParameter(valid_595181, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_595181 != nil:
    section.add "Action", valid_595181
  var valid_595182 = query.getOrDefault("Version")
  valid_595182 = validateParameter(valid_595182, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595182 != nil:
    section.add "Version", valid_595182
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
  var valid_595183 = header.getOrDefault("X-Amz-Date")
  valid_595183 = validateParameter(valid_595183, JString, required = false,
                                 default = nil)
  if valid_595183 != nil:
    section.add "X-Amz-Date", valid_595183
  var valid_595184 = header.getOrDefault("X-Amz-Security-Token")
  valid_595184 = validateParameter(valid_595184, JString, required = false,
                                 default = nil)
  if valid_595184 != nil:
    section.add "X-Amz-Security-Token", valid_595184
  var valid_595185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595185 = validateParameter(valid_595185, JString, required = false,
                                 default = nil)
  if valid_595185 != nil:
    section.add "X-Amz-Content-Sha256", valid_595185
  var valid_595186 = header.getOrDefault("X-Amz-Algorithm")
  valid_595186 = validateParameter(valid_595186, JString, required = false,
                                 default = nil)
  if valid_595186 != nil:
    section.add "X-Amz-Algorithm", valid_595186
  var valid_595187 = header.getOrDefault("X-Amz-Signature")
  valid_595187 = validateParameter(valid_595187, JString, required = false,
                                 default = nil)
  if valid_595187 != nil:
    section.add "X-Amz-Signature", valid_595187
  var valid_595188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595188 = validateParameter(valid_595188, JString, required = false,
                                 default = nil)
  if valid_595188 != nil:
    section.add "X-Amz-SignedHeaders", valid_595188
  var valid_595189 = header.getOrDefault("X-Amz-Credential")
  valid_595189 = validateParameter(valid_595189, JString, required = false,
                                 default = nil)
  if valid_595189 != nil:
    section.add "X-Amz-Credential", valid_595189
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_595190 = formData.getOrDefault("LoadBalancerArn")
  valid_595190 = validateParameter(valid_595190, JString, required = true,
                                 default = nil)
  if valid_595190 != nil:
    section.add "LoadBalancerArn", valid_595190
  var valid_595191 = formData.getOrDefault("IpAddressType")
  valid_595191 = validateParameter(valid_595191, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_595191 != nil:
    section.add "IpAddressType", valid_595191
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595192: Call_PostSetIpAddressType_595178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_595192.validator(path, query, header, formData, body)
  let scheme = call_595192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595192.url(scheme.get, call_595192.host, call_595192.base,
                         call_595192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595192, url, valid)

proc call*(call_595193: Call_PostSetIpAddressType_595178; LoadBalancerArn: string;
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
  var query_595194 = newJObject()
  var formData_595195 = newJObject()
  add(formData_595195, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_595195, "IpAddressType", newJString(IpAddressType))
  add(query_595194, "Action", newJString(Action))
  add(query_595194, "Version", newJString(Version))
  result = call_595193.call(nil, query_595194, nil, formData_595195, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_595178(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_595179,
    base: "/", url: url_PostSetIpAddressType_595180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_595161 = ref object of OpenApiRestCall_593437
proc url_GetSetIpAddressType_595163(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetIpAddressType_595162(path: JsonNode; query: JsonNode;
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
  var valid_595164 = query.getOrDefault("IpAddressType")
  valid_595164 = validateParameter(valid_595164, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_595164 != nil:
    section.add "IpAddressType", valid_595164
  var valid_595165 = query.getOrDefault("Action")
  valid_595165 = validateParameter(valid_595165, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_595165 != nil:
    section.add "Action", valid_595165
  var valid_595166 = query.getOrDefault("LoadBalancerArn")
  valid_595166 = validateParameter(valid_595166, JString, required = true,
                                 default = nil)
  if valid_595166 != nil:
    section.add "LoadBalancerArn", valid_595166
  var valid_595167 = query.getOrDefault("Version")
  valid_595167 = validateParameter(valid_595167, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595167 != nil:
    section.add "Version", valid_595167
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
  var valid_595168 = header.getOrDefault("X-Amz-Date")
  valid_595168 = validateParameter(valid_595168, JString, required = false,
                                 default = nil)
  if valid_595168 != nil:
    section.add "X-Amz-Date", valid_595168
  var valid_595169 = header.getOrDefault("X-Amz-Security-Token")
  valid_595169 = validateParameter(valid_595169, JString, required = false,
                                 default = nil)
  if valid_595169 != nil:
    section.add "X-Amz-Security-Token", valid_595169
  var valid_595170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595170 = validateParameter(valid_595170, JString, required = false,
                                 default = nil)
  if valid_595170 != nil:
    section.add "X-Amz-Content-Sha256", valid_595170
  var valid_595171 = header.getOrDefault("X-Amz-Algorithm")
  valid_595171 = validateParameter(valid_595171, JString, required = false,
                                 default = nil)
  if valid_595171 != nil:
    section.add "X-Amz-Algorithm", valid_595171
  var valid_595172 = header.getOrDefault("X-Amz-Signature")
  valid_595172 = validateParameter(valid_595172, JString, required = false,
                                 default = nil)
  if valid_595172 != nil:
    section.add "X-Amz-Signature", valid_595172
  var valid_595173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595173 = validateParameter(valid_595173, JString, required = false,
                                 default = nil)
  if valid_595173 != nil:
    section.add "X-Amz-SignedHeaders", valid_595173
  var valid_595174 = header.getOrDefault("X-Amz-Credential")
  valid_595174 = validateParameter(valid_595174, JString, required = false,
                                 default = nil)
  if valid_595174 != nil:
    section.add "X-Amz-Credential", valid_595174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595175: Call_GetSetIpAddressType_595161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_595175.validator(path, query, header, formData, body)
  let scheme = call_595175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595175.url(scheme.get, call_595175.host, call_595175.base,
                         call_595175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595175, url, valid)

proc call*(call_595176: Call_GetSetIpAddressType_595161; LoadBalancerArn: string;
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
  var query_595177 = newJObject()
  add(query_595177, "IpAddressType", newJString(IpAddressType))
  add(query_595177, "Action", newJString(Action))
  add(query_595177, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_595177, "Version", newJString(Version))
  result = call_595176.call(nil, query_595177, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_595161(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_595162,
    base: "/", url: url_GetSetIpAddressType_595163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_595212 = ref object of OpenApiRestCall_593437
proc url_PostSetRulePriorities_595214(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetRulePriorities_595213(path: JsonNode; query: JsonNode;
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
  var valid_595215 = query.getOrDefault("Action")
  valid_595215 = validateParameter(valid_595215, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_595215 != nil:
    section.add "Action", valid_595215
  var valid_595216 = query.getOrDefault("Version")
  valid_595216 = validateParameter(valid_595216, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595216 != nil:
    section.add "Version", valid_595216
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
  var valid_595217 = header.getOrDefault("X-Amz-Date")
  valid_595217 = validateParameter(valid_595217, JString, required = false,
                                 default = nil)
  if valid_595217 != nil:
    section.add "X-Amz-Date", valid_595217
  var valid_595218 = header.getOrDefault("X-Amz-Security-Token")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "X-Amz-Security-Token", valid_595218
  var valid_595219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595219 = validateParameter(valid_595219, JString, required = false,
                                 default = nil)
  if valid_595219 != nil:
    section.add "X-Amz-Content-Sha256", valid_595219
  var valid_595220 = header.getOrDefault("X-Amz-Algorithm")
  valid_595220 = validateParameter(valid_595220, JString, required = false,
                                 default = nil)
  if valid_595220 != nil:
    section.add "X-Amz-Algorithm", valid_595220
  var valid_595221 = header.getOrDefault("X-Amz-Signature")
  valid_595221 = validateParameter(valid_595221, JString, required = false,
                                 default = nil)
  if valid_595221 != nil:
    section.add "X-Amz-Signature", valid_595221
  var valid_595222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595222 = validateParameter(valid_595222, JString, required = false,
                                 default = nil)
  if valid_595222 != nil:
    section.add "X-Amz-SignedHeaders", valid_595222
  var valid_595223 = header.getOrDefault("X-Amz-Credential")
  valid_595223 = validateParameter(valid_595223, JString, required = false,
                                 default = nil)
  if valid_595223 != nil:
    section.add "X-Amz-Credential", valid_595223
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_595224 = formData.getOrDefault("RulePriorities")
  valid_595224 = validateParameter(valid_595224, JArray, required = true, default = nil)
  if valid_595224 != nil:
    section.add "RulePriorities", valid_595224
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595225: Call_PostSetRulePriorities_595212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_595225.validator(path, query, header, formData, body)
  let scheme = call_595225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595225.url(scheme.get, call_595225.host, call_595225.base,
                         call_595225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595225, url, valid)

proc call*(call_595226: Call_PostSetRulePriorities_595212;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595227 = newJObject()
  var formData_595228 = newJObject()
  if RulePriorities != nil:
    formData_595228.add "RulePriorities", RulePriorities
  add(query_595227, "Action", newJString(Action))
  add(query_595227, "Version", newJString(Version))
  result = call_595226.call(nil, query_595227, nil, formData_595228, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_595212(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_595213, base: "/",
    url: url_PostSetRulePriorities_595214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_595196 = ref object of OpenApiRestCall_593437
proc url_GetSetRulePriorities_595198(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetRulePriorities_595197(path: JsonNode; query: JsonNode;
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
  var valid_595199 = query.getOrDefault("RulePriorities")
  valid_595199 = validateParameter(valid_595199, JArray, required = true, default = nil)
  if valid_595199 != nil:
    section.add "RulePriorities", valid_595199
  var valid_595200 = query.getOrDefault("Action")
  valid_595200 = validateParameter(valid_595200, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_595200 != nil:
    section.add "Action", valid_595200
  var valid_595201 = query.getOrDefault("Version")
  valid_595201 = validateParameter(valid_595201, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595201 != nil:
    section.add "Version", valid_595201
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
  var valid_595202 = header.getOrDefault("X-Amz-Date")
  valid_595202 = validateParameter(valid_595202, JString, required = false,
                                 default = nil)
  if valid_595202 != nil:
    section.add "X-Amz-Date", valid_595202
  var valid_595203 = header.getOrDefault("X-Amz-Security-Token")
  valid_595203 = validateParameter(valid_595203, JString, required = false,
                                 default = nil)
  if valid_595203 != nil:
    section.add "X-Amz-Security-Token", valid_595203
  var valid_595204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595204 = validateParameter(valid_595204, JString, required = false,
                                 default = nil)
  if valid_595204 != nil:
    section.add "X-Amz-Content-Sha256", valid_595204
  var valid_595205 = header.getOrDefault("X-Amz-Algorithm")
  valid_595205 = validateParameter(valid_595205, JString, required = false,
                                 default = nil)
  if valid_595205 != nil:
    section.add "X-Amz-Algorithm", valid_595205
  var valid_595206 = header.getOrDefault("X-Amz-Signature")
  valid_595206 = validateParameter(valid_595206, JString, required = false,
                                 default = nil)
  if valid_595206 != nil:
    section.add "X-Amz-Signature", valid_595206
  var valid_595207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595207 = validateParameter(valid_595207, JString, required = false,
                                 default = nil)
  if valid_595207 != nil:
    section.add "X-Amz-SignedHeaders", valid_595207
  var valid_595208 = header.getOrDefault("X-Amz-Credential")
  valid_595208 = validateParameter(valid_595208, JString, required = false,
                                 default = nil)
  if valid_595208 != nil:
    section.add "X-Amz-Credential", valid_595208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595209: Call_GetSetRulePriorities_595196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_595209.validator(path, query, header, formData, body)
  let scheme = call_595209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595209.url(scheme.get, call_595209.host, call_595209.base,
                         call_595209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595209, url, valid)

proc call*(call_595210: Call_GetSetRulePriorities_595196; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595211 = newJObject()
  if RulePriorities != nil:
    query_595211.add "RulePriorities", RulePriorities
  add(query_595211, "Action", newJString(Action))
  add(query_595211, "Version", newJString(Version))
  result = call_595210.call(nil, query_595211, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_595196(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_595197,
    base: "/", url: url_GetSetRulePriorities_595198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_595246 = ref object of OpenApiRestCall_593437
proc url_PostSetSecurityGroups_595248(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSecurityGroups_595247(path: JsonNode; query: JsonNode;
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
  var valid_595249 = query.getOrDefault("Action")
  valid_595249 = validateParameter(valid_595249, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_595249 != nil:
    section.add "Action", valid_595249
  var valid_595250 = query.getOrDefault("Version")
  valid_595250 = validateParameter(valid_595250, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595250 != nil:
    section.add "Version", valid_595250
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
  var valid_595251 = header.getOrDefault("X-Amz-Date")
  valid_595251 = validateParameter(valid_595251, JString, required = false,
                                 default = nil)
  if valid_595251 != nil:
    section.add "X-Amz-Date", valid_595251
  var valid_595252 = header.getOrDefault("X-Amz-Security-Token")
  valid_595252 = validateParameter(valid_595252, JString, required = false,
                                 default = nil)
  if valid_595252 != nil:
    section.add "X-Amz-Security-Token", valid_595252
  var valid_595253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595253 = validateParameter(valid_595253, JString, required = false,
                                 default = nil)
  if valid_595253 != nil:
    section.add "X-Amz-Content-Sha256", valid_595253
  var valid_595254 = header.getOrDefault("X-Amz-Algorithm")
  valid_595254 = validateParameter(valid_595254, JString, required = false,
                                 default = nil)
  if valid_595254 != nil:
    section.add "X-Amz-Algorithm", valid_595254
  var valid_595255 = header.getOrDefault("X-Amz-Signature")
  valid_595255 = validateParameter(valid_595255, JString, required = false,
                                 default = nil)
  if valid_595255 != nil:
    section.add "X-Amz-Signature", valid_595255
  var valid_595256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595256 = validateParameter(valid_595256, JString, required = false,
                                 default = nil)
  if valid_595256 != nil:
    section.add "X-Amz-SignedHeaders", valid_595256
  var valid_595257 = header.getOrDefault("X-Amz-Credential")
  valid_595257 = validateParameter(valid_595257, JString, required = false,
                                 default = nil)
  if valid_595257 != nil:
    section.add "X-Amz-Credential", valid_595257
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_595258 = formData.getOrDefault("LoadBalancerArn")
  valid_595258 = validateParameter(valid_595258, JString, required = true,
                                 default = nil)
  if valid_595258 != nil:
    section.add "LoadBalancerArn", valid_595258
  var valid_595259 = formData.getOrDefault("SecurityGroups")
  valid_595259 = validateParameter(valid_595259, JArray, required = true, default = nil)
  if valid_595259 != nil:
    section.add "SecurityGroups", valid_595259
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595260: Call_PostSetSecurityGroups_595246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_595260.validator(path, query, header, formData, body)
  let scheme = call_595260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595260.url(scheme.get, call_595260.host, call_595260.base,
                         call_595260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595260, url, valid)

proc call*(call_595261: Call_PostSetSecurityGroups_595246; LoadBalancerArn: string;
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
  var query_595262 = newJObject()
  var formData_595263 = newJObject()
  add(formData_595263, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_595262, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_595263.add "SecurityGroups", SecurityGroups
  add(query_595262, "Version", newJString(Version))
  result = call_595261.call(nil, query_595262, nil, formData_595263, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_595246(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_595247, base: "/",
    url: url_PostSetSecurityGroups_595248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_595229 = ref object of OpenApiRestCall_593437
proc url_GetSetSecurityGroups_595231(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSecurityGroups_595230(path: JsonNode; query: JsonNode;
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
  var valid_595232 = query.getOrDefault("Action")
  valid_595232 = validateParameter(valid_595232, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_595232 != nil:
    section.add "Action", valid_595232
  var valid_595233 = query.getOrDefault("LoadBalancerArn")
  valid_595233 = validateParameter(valid_595233, JString, required = true,
                                 default = nil)
  if valid_595233 != nil:
    section.add "LoadBalancerArn", valid_595233
  var valid_595234 = query.getOrDefault("Version")
  valid_595234 = validateParameter(valid_595234, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595234 != nil:
    section.add "Version", valid_595234
  var valid_595235 = query.getOrDefault("SecurityGroups")
  valid_595235 = validateParameter(valid_595235, JArray, required = true, default = nil)
  if valid_595235 != nil:
    section.add "SecurityGroups", valid_595235
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
  var valid_595236 = header.getOrDefault("X-Amz-Date")
  valid_595236 = validateParameter(valid_595236, JString, required = false,
                                 default = nil)
  if valid_595236 != nil:
    section.add "X-Amz-Date", valid_595236
  var valid_595237 = header.getOrDefault("X-Amz-Security-Token")
  valid_595237 = validateParameter(valid_595237, JString, required = false,
                                 default = nil)
  if valid_595237 != nil:
    section.add "X-Amz-Security-Token", valid_595237
  var valid_595238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595238 = validateParameter(valid_595238, JString, required = false,
                                 default = nil)
  if valid_595238 != nil:
    section.add "X-Amz-Content-Sha256", valid_595238
  var valid_595239 = header.getOrDefault("X-Amz-Algorithm")
  valid_595239 = validateParameter(valid_595239, JString, required = false,
                                 default = nil)
  if valid_595239 != nil:
    section.add "X-Amz-Algorithm", valid_595239
  var valid_595240 = header.getOrDefault("X-Amz-Signature")
  valid_595240 = validateParameter(valid_595240, JString, required = false,
                                 default = nil)
  if valid_595240 != nil:
    section.add "X-Amz-Signature", valid_595240
  var valid_595241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595241 = validateParameter(valid_595241, JString, required = false,
                                 default = nil)
  if valid_595241 != nil:
    section.add "X-Amz-SignedHeaders", valid_595241
  var valid_595242 = header.getOrDefault("X-Amz-Credential")
  valid_595242 = validateParameter(valid_595242, JString, required = false,
                                 default = nil)
  if valid_595242 != nil:
    section.add "X-Amz-Credential", valid_595242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595243: Call_GetSetSecurityGroups_595229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_595243.validator(path, query, header, formData, body)
  let scheme = call_595243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595243.url(scheme.get, call_595243.host, call_595243.base,
                         call_595243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595243, url, valid)

proc call*(call_595244: Call_GetSetSecurityGroups_595229; LoadBalancerArn: string;
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
  var query_595245 = newJObject()
  add(query_595245, "Action", newJString(Action))
  add(query_595245, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_595245, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_595245.add "SecurityGroups", SecurityGroups
  result = call_595244.call(nil, query_595245, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_595229(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_595230,
    base: "/", url: url_GetSetSecurityGroups_595231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_595282 = ref object of OpenApiRestCall_593437
proc url_PostSetSubnets_595284(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSubnets_595283(path: JsonNode; query: JsonNode;
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
  var valid_595285 = query.getOrDefault("Action")
  valid_595285 = validateParameter(valid_595285, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_595285 != nil:
    section.add "Action", valid_595285
  var valid_595286 = query.getOrDefault("Version")
  valid_595286 = validateParameter(valid_595286, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595286 != nil:
    section.add "Version", valid_595286
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
  var valid_595287 = header.getOrDefault("X-Amz-Date")
  valid_595287 = validateParameter(valid_595287, JString, required = false,
                                 default = nil)
  if valid_595287 != nil:
    section.add "X-Amz-Date", valid_595287
  var valid_595288 = header.getOrDefault("X-Amz-Security-Token")
  valid_595288 = validateParameter(valid_595288, JString, required = false,
                                 default = nil)
  if valid_595288 != nil:
    section.add "X-Amz-Security-Token", valid_595288
  var valid_595289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595289 = validateParameter(valid_595289, JString, required = false,
                                 default = nil)
  if valid_595289 != nil:
    section.add "X-Amz-Content-Sha256", valid_595289
  var valid_595290 = header.getOrDefault("X-Amz-Algorithm")
  valid_595290 = validateParameter(valid_595290, JString, required = false,
                                 default = nil)
  if valid_595290 != nil:
    section.add "X-Amz-Algorithm", valid_595290
  var valid_595291 = header.getOrDefault("X-Amz-Signature")
  valid_595291 = validateParameter(valid_595291, JString, required = false,
                                 default = nil)
  if valid_595291 != nil:
    section.add "X-Amz-Signature", valid_595291
  var valid_595292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595292 = validateParameter(valid_595292, JString, required = false,
                                 default = nil)
  if valid_595292 != nil:
    section.add "X-Amz-SignedHeaders", valid_595292
  var valid_595293 = header.getOrDefault("X-Amz-Credential")
  valid_595293 = validateParameter(valid_595293, JString, required = false,
                                 default = nil)
  if valid_595293 != nil:
    section.add "X-Amz-Credential", valid_595293
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
  var valid_595294 = formData.getOrDefault("LoadBalancerArn")
  valid_595294 = validateParameter(valid_595294, JString, required = true,
                                 default = nil)
  if valid_595294 != nil:
    section.add "LoadBalancerArn", valid_595294
  var valid_595295 = formData.getOrDefault("Subnets")
  valid_595295 = validateParameter(valid_595295, JArray, required = false,
                                 default = nil)
  if valid_595295 != nil:
    section.add "Subnets", valid_595295
  var valid_595296 = formData.getOrDefault("SubnetMappings")
  valid_595296 = validateParameter(valid_595296, JArray, required = false,
                                 default = nil)
  if valid_595296 != nil:
    section.add "SubnetMappings", valid_595296
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595297: Call_PostSetSubnets_595282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_595297.validator(path, query, header, formData, body)
  let scheme = call_595297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595297.url(scheme.get, call_595297.host, call_595297.base,
                         call_595297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595297, url, valid)

proc call*(call_595298: Call_PostSetSubnets_595282; LoadBalancerArn: string;
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
  var query_595299 = newJObject()
  var formData_595300 = newJObject()
  add(formData_595300, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_595299, "Action", newJString(Action))
  if Subnets != nil:
    formData_595300.add "Subnets", Subnets
  if SubnetMappings != nil:
    formData_595300.add "SubnetMappings", SubnetMappings
  add(query_595299, "Version", newJString(Version))
  result = call_595298.call(nil, query_595299, nil, formData_595300, nil)

var postSetSubnets* = Call_PostSetSubnets_595282(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_595283,
    base: "/", url: url_PostSetSubnets_595284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_595264 = ref object of OpenApiRestCall_593437
proc url_GetSetSubnets_595266(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSubnets_595265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595267 = query.getOrDefault("SubnetMappings")
  valid_595267 = validateParameter(valid_595267, JArray, required = false,
                                 default = nil)
  if valid_595267 != nil:
    section.add "SubnetMappings", valid_595267
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595268 = query.getOrDefault("Action")
  valid_595268 = validateParameter(valid_595268, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_595268 != nil:
    section.add "Action", valid_595268
  var valid_595269 = query.getOrDefault("LoadBalancerArn")
  valid_595269 = validateParameter(valid_595269, JString, required = true,
                                 default = nil)
  if valid_595269 != nil:
    section.add "LoadBalancerArn", valid_595269
  var valid_595270 = query.getOrDefault("Subnets")
  valid_595270 = validateParameter(valid_595270, JArray, required = false,
                                 default = nil)
  if valid_595270 != nil:
    section.add "Subnets", valid_595270
  var valid_595271 = query.getOrDefault("Version")
  valid_595271 = validateParameter(valid_595271, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_595271 != nil:
    section.add "Version", valid_595271
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
  var valid_595272 = header.getOrDefault("X-Amz-Date")
  valid_595272 = validateParameter(valid_595272, JString, required = false,
                                 default = nil)
  if valid_595272 != nil:
    section.add "X-Amz-Date", valid_595272
  var valid_595273 = header.getOrDefault("X-Amz-Security-Token")
  valid_595273 = validateParameter(valid_595273, JString, required = false,
                                 default = nil)
  if valid_595273 != nil:
    section.add "X-Amz-Security-Token", valid_595273
  var valid_595274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595274 = validateParameter(valid_595274, JString, required = false,
                                 default = nil)
  if valid_595274 != nil:
    section.add "X-Amz-Content-Sha256", valid_595274
  var valid_595275 = header.getOrDefault("X-Amz-Algorithm")
  valid_595275 = validateParameter(valid_595275, JString, required = false,
                                 default = nil)
  if valid_595275 != nil:
    section.add "X-Amz-Algorithm", valid_595275
  var valid_595276 = header.getOrDefault("X-Amz-Signature")
  valid_595276 = validateParameter(valid_595276, JString, required = false,
                                 default = nil)
  if valid_595276 != nil:
    section.add "X-Amz-Signature", valid_595276
  var valid_595277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595277 = validateParameter(valid_595277, JString, required = false,
                                 default = nil)
  if valid_595277 != nil:
    section.add "X-Amz-SignedHeaders", valid_595277
  var valid_595278 = header.getOrDefault("X-Amz-Credential")
  valid_595278 = validateParameter(valid_595278, JString, required = false,
                                 default = nil)
  if valid_595278 != nil:
    section.add "X-Amz-Credential", valid_595278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595279: Call_GetSetSubnets_595264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_595279.validator(path, query, header, formData, body)
  let scheme = call_595279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595279.url(scheme.get, call_595279.host, call_595279.base,
                         call_595279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595279, url, valid)

proc call*(call_595280: Call_GetSetSubnets_595264; LoadBalancerArn: string;
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
  var query_595281 = newJObject()
  if SubnetMappings != nil:
    query_595281.add "SubnetMappings", SubnetMappings
  add(query_595281, "Action", newJString(Action))
  add(query_595281, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Subnets != nil:
    query_595281.add "Subnets", Subnets
  add(query_595281, "Version", newJString(Version))
  result = call_595280.call(nil, query_595281, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_595264(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_595265,
    base: "/", url: url_GetSetSubnets_595266, schemes: {Scheme.Https, Scheme.Http})
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
