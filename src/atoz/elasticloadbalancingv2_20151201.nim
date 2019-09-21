
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAddListenerCertificates_603042 = ref object of OpenApiRestCall_602433
proc url_PostAddListenerCertificates_603044(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddListenerCertificates_603043(path: JsonNode; query: JsonNode;
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
  var valid_603045 = query.getOrDefault("Action")
  valid_603045 = validateParameter(valid_603045, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_603045 != nil:
    section.add "Action", valid_603045
  var valid_603046 = query.getOrDefault("Version")
  valid_603046 = validateParameter(valid_603046, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603046 != nil:
    section.add "Version", valid_603046
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603047 = header.getOrDefault("X-Amz-Date")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Date", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Security-Token")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Security-Token", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Content-Sha256", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Algorithm")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Algorithm", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Signature")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Signature", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-SignedHeaders", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Credential")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Credential", valid_603053
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to add. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_603054 = formData.getOrDefault("Certificates")
  valid_603054 = validateParameter(valid_603054, JArray, required = true, default = nil)
  if valid_603054 != nil:
    section.add "Certificates", valid_603054
  var valid_603055 = formData.getOrDefault("ListenerArn")
  valid_603055 = validateParameter(valid_603055, JString, required = true,
                                 default = nil)
  if valid_603055 != nil:
    section.add "ListenerArn", valid_603055
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603056: Call_PostAddListenerCertificates_603042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603056.validator(path, query, header, formData, body)
  let scheme = call_603056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603056.url(scheme.get, call_603056.host, call_603056.base,
                         call_603056.route, valid.getOrDefault("path"))
  result = hook(call_603056, url, valid)

proc call*(call_603057: Call_PostAddListenerCertificates_603042;
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
  var query_603058 = newJObject()
  var formData_603059 = newJObject()
  if Certificates != nil:
    formData_603059.add "Certificates", Certificates
  add(formData_603059, "ListenerArn", newJString(ListenerArn))
  add(query_603058, "Action", newJString(Action))
  add(query_603058, "Version", newJString(Version))
  result = call_603057.call(nil, query_603058, nil, formData_603059, nil)

var postAddListenerCertificates* = Call_PostAddListenerCertificates_603042(
    name: "postAddListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_PostAddListenerCertificates_603043, base: "/",
    url: url_PostAddListenerCertificates_603044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddListenerCertificates_602770 = ref object of OpenApiRestCall_602433
proc url_GetAddListenerCertificates_602772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddListenerCertificates_602771(path: JsonNode; query: JsonNode;
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
  var valid_602884 = query.getOrDefault("Certificates")
  valid_602884 = validateParameter(valid_602884, JArray, required = true, default = nil)
  if valid_602884 != nil:
    section.add "Certificates", valid_602884
  var valid_602898 = query.getOrDefault("Action")
  valid_602898 = validateParameter(valid_602898, JString, required = true, default = newJString(
      "AddListenerCertificates"))
  if valid_602898 != nil:
    section.add "Action", valid_602898
  var valid_602899 = query.getOrDefault("ListenerArn")
  valid_602899 = validateParameter(valid_602899, JString, required = true,
                                 default = nil)
  if valid_602899 != nil:
    section.add "ListenerArn", valid_602899
  var valid_602900 = query.getOrDefault("Version")
  valid_602900 = validateParameter(valid_602900, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_602900 != nil:
    section.add "Version", valid_602900
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602901 = header.getOrDefault("X-Amz-Date")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Date", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Security-Token")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Security-Token", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Content-Sha256", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Algorithm")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Algorithm", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Signature")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Signature", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-SignedHeaders", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Credential")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Credential", valid_602907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602930: Call_GetAddListenerCertificates_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified SSL server certificate to the certificate list for the specified HTTPS or TLS listener.</p> <p>If the certificate in already in the certificate list, the call is successful but the certificate is not added again.</p> <p>To get the certificate list for a listener, use <a>DescribeListenerCertificates</a>. To remove certificates from the certificate list for a listener, use <a>RemoveListenerCertificates</a>. To replace the default certificate for a listener, use <a>ModifyListener</a>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602930.validator(path, query, header, formData, body)
  let scheme = call_602930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602930.url(scheme.get, call_602930.host, call_602930.base,
                         call_602930.route, valid.getOrDefault("path"))
  result = hook(call_602930, url, valid)

proc call*(call_603001: Call_GetAddListenerCertificates_602770;
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
  var query_603002 = newJObject()
  if Certificates != nil:
    query_603002.add "Certificates", Certificates
  add(query_603002, "Action", newJString(Action))
  add(query_603002, "ListenerArn", newJString(ListenerArn))
  add(query_603002, "Version", newJString(Version))
  result = call_603001.call(nil, query_603002, nil, nil, nil)

var getAddListenerCertificates* = Call_GetAddListenerCertificates_602770(
    name: "getAddListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddListenerCertificates",
    validator: validate_GetAddListenerCertificates_602771, base: "/",
    url: url_GetAddListenerCertificates_602772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTags_603077 = ref object of OpenApiRestCall_602433
proc url_PostAddTags_603079(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddTags_603078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603080 = query.getOrDefault("Action")
  valid_603080 = validateParameter(valid_603080, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_603080 != nil:
    section.add "Action", valid_603080
  var valid_603081 = query.getOrDefault("Version")
  valid_603081 = validateParameter(valid_603081, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603081 != nil:
    section.add "Version", valid_603081
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603082 = header.getOrDefault("X-Amz-Date")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Date", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Security-Token")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Security-Token", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Content-Sha256", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Algorithm")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Algorithm", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Signature")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Signature", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-SignedHeaders", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Credential")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Credential", valid_603088
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_603089 = formData.getOrDefault("ResourceArns")
  valid_603089 = validateParameter(valid_603089, JArray, required = true, default = nil)
  if valid_603089 != nil:
    section.add "ResourceArns", valid_603089
  var valid_603090 = formData.getOrDefault("Tags")
  valid_603090 = validateParameter(valid_603090, JArray, required = true, default = nil)
  if valid_603090 != nil:
    section.add "Tags", valid_603090
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603091: Call_PostAddTags_603077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_603091.validator(path, query, header, formData, body)
  let scheme = call_603091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603091.url(scheme.get, call_603091.host, call_603091.base,
                         call_603091.route, valid.getOrDefault("path"))
  result = hook(call_603091, url, valid)

proc call*(call_603092: Call_PostAddTags_603077; ResourceArns: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2015-12-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   Tags: JArray (required)
  ##       : The tags. Each resource can have a maximum of 10 tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603093 = newJObject()
  var formData_603094 = newJObject()
  if ResourceArns != nil:
    formData_603094.add "ResourceArns", ResourceArns
  if Tags != nil:
    formData_603094.add "Tags", Tags
  add(query_603093, "Action", newJString(Action))
  add(query_603093, "Version", newJString(Version))
  result = call_603092.call(nil, query_603093, nil, formData_603094, nil)

var postAddTags* = Call_PostAddTags_603077(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_603078,
                                        base: "/", url: url_PostAddTags_603079,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_603060 = ref object of OpenApiRestCall_602433
proc url_GetAddTags_603062(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddTags_603061(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603063 = query.getOrDefault("Tags")
  valid_603063 = validateParameter(valid_603063, JArray, required = true, default = nil)
  if valid_603063 != nil:
    section.add "Tags", valid_603063
  var valid_603064 = query.getOrDefault("Action")
  valid_603064 = validateParameter(valid_603064, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_603064 != nil:
    section.add "Action", valid_603064
  var valid_603065 = query.getOrDefault("ResourceArns")
  valid_603065 = validateParameter(valid_603065, JArray, required = true, default = nil)
  if valid_603065 != nil:
    section.add "ResourceArns", valid_603065
  var valid_603066 = query.getOrDefault("Version")
  valid_603066 = validateParameter(valid_603066, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603066 != nil:
    section.add "Version", valid_603066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603067 = header.getOrDefault("X-Amz-Date")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Date", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Security-Token")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Security-Token", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Content-Sha256", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Algorithm")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Algorithm", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Signature")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Signature", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-SignedHeaders", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Credential")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Credential", valid_603073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603074: Call_GetAddTags_603060; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified Elastic Load Balancing resource. You can tag your Application Load Balancers, Network Load Balancers, and your target groups.</p> <p>Each tag consists of a key and an optional value. If a resource already has a tag with the same key, <code>AddTags</code> updates its value.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>. To remove tags from your resources, use <a>RemoveTags</a>.</p>
  ## 
  let valid = call_603074.validator(path, query, header, formData, body)
  let scheme = call_603074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603074.url(scheme.get, call_603074.host, call_603074.base,
                         call_603074.route, valid.getOrDefault("path"))
  result = hook(call_603074, url, valid)

proc call*(call_603075: Call_GetAddTags_603060; Tags: JsonNode;
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
  var query_603076 = newJObject()
  if Tags != nil:
    query_603076.add "Tags", Tags
  add(query_603076, "Action", newJString(Action))
  if ResourceArns != nil:
    query_603076.add "ResourceArns", ResourceArns
  add(query_603076, "Version", newJString(Version))
  result = call_603075.call(nil, query_603076, nil, nil, nil)

var getAddTags* = Call_GetAddTags_603060(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_603061,
                                      base: "/", url: url_GetAddTags_603062,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateListener_603116 = ref object of OpenApiRestCall_602433
proc url_PostCreateListener_603118(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateListener_603117(path: JsonNode; query: JsonNode;
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
  var valid_603119 = query.getOrDefault("Action")
  valid_603119 = validateParameter(valid_603119, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_603119 != nil:
    section.add "Action", valid_603119
  var valid_603120 = query.getOrDefault("Version")
  valid_603120 = validateParameter(valid_603120, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603120 != nil:
    section.add "Version", valid_603120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603121 = header.getOrDefault("X-Amz-Date")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Date", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Security-Token")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Security-Token", valid_603122
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
  var valid_603128 = formData.getOrDefault("Certificates")
  valid_603128 = validateParameter(valid_603128, JArray, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "Certificates", valid_603128
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_603129 = formData.getOrDefault("LoadBalancerArn")
  valid_603129 = validateParameter(valid_603129, JString, required = true,
                                 default = nil)
  if valid_603129 != nil:
    section.add "LoadBalancerArn", valid_603129
  var valid_603130 = formData.getOrDefault("Port")
  valid_603130 = validateParameter(valid_603130, JInt, required = true, default = nil)
  if valid_603130 != nil:
    section.add "Port", valid_603130
  var valid_603131 = formData.getOrDefault("Protocol")
  valid_603131 = validateParameter(valid_603131, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_603131 != nil:
    section.add "Protocol", valid_603131
  var valid_603132 = formData.getOrDefault("SslPolicy")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "SslPolicy", valid_603132
  var valid_603133 = formData.getOrDefault("DefaultActions")
  valid_603133 = validateParameter(valid_603133, JArray, required = true, default = nil)
  if valid_603133 != nil:
    section.add "DefaultActions", valid_603133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603134: Call_PostCreateListener_603116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603134.validator(path, query, header, formData, body)
  let scheme = call_603134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603134.url(scheme.get, call_603134.host, call_603134.base,
                         call_603134.route, valid.getOrDefault("path"))
  result = hook(call_603134, url, valid)

proc call*(call_603135: Call_PostCreateListener_603116; LoadBalancerArn: string;
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
  var query_603136 = newJObject()
  var formData_603137 = newJObject()
  if Certificates != nil:
    formData_603137.add "Certificates", Certificates
  add(formData_603137, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_603137, "Port", newJInt(Port))
  add(formData_603137, "Protocol", newJString(Protocol))
  add(query_603136, "Action", newJString(Action))
  add(formData_603137, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_603137.add "DefaultActions", DefaultActions
  add(query_603136, "Version", newJString(Version))
  result = call_603135.call(nil, query_603136, nil, formData_603137, nil)

var postCreateListener* = Call_PostCreateListener_603116(
    name: "postCreateListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=CreateListener",
    validator: validate_PostCreateListener_603117, base: "/",
    url: url_PostCreateListener_603118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateListener_603095 = ref object of OpenApiRestCall_602433
proc url_GetCreateListener_603097(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateListener_603096(path: JsonNode; query: JsonNode;
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
  var valid_603098 = query.getOrDefault("DefaultActions")
  valid_603098 = validateParameter(valid_603098, JArray, required = true, default = nil)
  if valid_603098 != nil:
    section.add "DefaultActions", valid_603098
  var valid_603099 = query.getOrDefault("SslPolicy")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "SslPolicy", valid_603099
  var valid_603100 = query.getOrDefault("Protocol")
  valid_603100 = validateParameter(valid_603100, JString, required = true,
                                 default = newJString("HTTP"))
  if valid_603100 != nil:
    section.add "Protocol", valid_603100
  var valid_603101 = query.getOrDefault("Certificates")
  valid_603101 = validateParameter(valid_603101, JArray, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "Certificates", valid_603101
  var valid_603102 = query.getOrDefault("Action")
  valid_603102 = validateParameter(valid_603102, JString, required = true,
                                 default = newJString("CreateListener"))
  if valid_603102 != nil:
    section.add "Action", valid_603102
  var valid_603103 = query.getOrDefault("LoadBalancerArn")
  valid_603103 = validateParameter(valid_603103, JString, required = true,
                                 default = nil)
  if valid_603103 != nil:
    section.add "LoadBalancerArn", valid_603103
  var valid_603104 = query.getOrDefault("Port")
  valid_603104 = validateParameter(valid_603104, JInt, required = true, default = nil)
  if valid_603104 != nil:
    section.add "Port", valid_603104
  var valid_603105 = query.getOrDefault("Version")
  valid_603105 = validateParameter(valid_603105, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603105 != nil:
    section.add "Version", valid_603105
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603106 = header.getOrDefault("X-Amz-Date")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Date", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Security-Token")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Security-Token", valid_603107
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
  if body != nil:
    result.add "body", body

proc call*(call_603113: Call_GetCreateListener_603095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a listener for the specified Application Load Balancer or Network Load Balancer.</p> <p>To update a listener, use <a>ModifyListener</a>. When you are finished with a listener, you can delete it using <a>DeleteListener</a>. If you are finished with both the listener and the load balancer, you can delete them both using <a>DeleteLoadBalancer</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple listeners with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html">Listeners for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-listeners.html">Listeners for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603113.validator(path, query, header, formData, body)
  let scheme = call_603113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603113.url(scheme.get, call_603113.host, call_603113.base,
                         call_603113.route, valid.getOrDefault("path"))
  result = hook(call_603113, url, valid)

proc call*(call_603114: Call_GetCreateListener_603095; DefaultActions: JsonNode;
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
  var query_603115 = newJObject()
  if DefaultActions != nil:
    query_603115.add "DefaultActions", DefaultActions
  add(query_603115, "SslPolicy", newJString(SslPolicy))
  add(query_603115, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_603115.add "Certificates", Certificates
  add(query_603115, "Action", newJString(Action))
  add(query_603115, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603115, "Port", newJInt(Port))
  add(query_603115, "Version", newJString(Version))
  result = call_603114.call(nil, query_603115, nil, nil, nil)

var getCreateListener* = Call_GetCreateListener_603095(name: "getCreateListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateListener", validator: validate_GetCreateListener_603096,
    base: "/", url: url_GetCreateListener_603097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_603161 = ref object of OpenApiRestCall_602433
proc url_PostCreateLoadBalancer_603163(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateLoadBalancer_603162(path: JsonNode; query: JsonNode;
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
  var valid_603164 = query.getOrDefault("Action")
  valid_603164 = validateParameter(valid_603164, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_603164 != nil:
    section.add "Action", valid_603164
  var valid_603165 = query.getOrDefault("Version")
  valid_603165 = validateParameter(valid_603165, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603165 != nil:
    section.add "Version", valid_603165
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603166 = header.getOrDefault("X-Amz-Date")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Date", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Security-Token")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Security-Token", valid_603167
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
  var valid_603173 = formData.getOrDefault("Name")
  valid_603173 = validateParameter(valid_603173, JString, required = true,
                                 default = nil)
  if valid_603173 != nil:
    section.add "Name", valid_603173
  var valid_603174 = formData.getOrDefault("IpAddressType")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_603174 != nil:
    section.add "IpAddressType", valid_603174
  var valid_603175 = formData.getOrDefault("Tags")
  valid_603175 = validateParameter(valid_603175, JArray, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "Tags", valid_603175
  var valid_603176 = formData.getOrDefault("Type")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = newJString("application"))
  if valid_603176 != nil:
    section.add "Type", valid_603176
  var valid_603177 = formData.getOrDefault("Subnets")
  valid_603177 = validateParameter(valid_603177, JArray, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "Subnets", valid_603177
  var valid_603178 = formData.getOrDefault("SecurityGroups")
  valid_603178 = validateParameter(valid_603178, JArray, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "SecurityGroups", valid_603178
  var valid_603179 = formData.getOrDefault("SubnetMappings")
  valid_603179 = validateParameter(valid_603179, JArray, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "SubnetMappings", valid_603179
  var valid_603180 = formData.getOrDefault("Scheme")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_603180 != nil:
    section.add "Scheme", valid_603180
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603181: Call_PostCreateLoadBalancer_603161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603181.validator(path, query, header, formData, body)
  let scheme = call_603181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603181.url(scheme.get, call_603181.host, call_603181.base,
                         call_603181.route, valid.getOrDefault("path"))
  result = hook(call_603181, url, valid)

proc call*(call_603182: Call_PostCreateLoadBalancer_603161; Name: string;
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
  var query_603183 = newJObject()
  var formData_603184 = newJObject()
  add(formData_603184, "Name", newJString(Name))
  add(formData_603184, "IpAddressType", newJString(IpAddressType))
  if Tags != nil:
    formData_603184.add "Tags", Tags
  add(formData_603184, "Type", newJString(Type))
  add(query_603183, "Action", newJString(Action))
  if Subnets != nil:
    formData_603184.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_603184.add "SecurityGroups", SecurityGroups
  if SubnetMappings != nil:
    formData_603184.add "SubnetMappings", SubnetMappings
  add(formData_603184, "Scheme", newJString(Scheme))
  add(query_603183, "Version", newJString(Version))
  result = call_603182.call(nil, query_603183, nil, formData_603184, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_603161(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_603162, base: "/",
    url: url_PostCreateLoadBalancer_603163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_603138 = ref object of OpenApiRestCall_602433
proc url_GetCreateLoadBalancer_603140(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateLoadBalancer_603139(path: JsonNode; query: JsonNode;
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
  var valid_603141 = query.getOrDefault("Name")
  valid_603141 = validateParameter(valid_603141, JString, required = true,
                                 default = nil)
  if valid_603141 != nil:
    section.add "Name", valid_603141
  var valid_603142 = query.getOrDefault("SubnetMappings")
  valid_603142 = validateParameter(valid_603142, JArray, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "SubnetMappings", valid_603142
  var valid_603143 = query.getOrDefault("IpAddressType")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = newJString("ipv4"))
  if valid_603143 != nil:
    section.add "IpAddressType", valid_603143
  var valid_603144 = query.getOrDefault("Scheme")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = newJString("internet-facing"))
  if valid_603144 != nil:
    section.add "Scheme", valid_603144
  var valid_603145 = query.getOrDefault("Tags")
  valid_603145 = validateParameter(valid_603145, JArray, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "Tags", valid_603145
  var valid_603146 = query.getOrDefault("Type")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = newJString("application"))
  if valid_603146 != nil:
    section.add "Type", valid_603146
  var valid_603147 = query.getOrDefault("Action")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_603147 != nil:
    section.add "Action", valid_603147
  var valid_603148 = query.getOrDefault("Subnets")
  valid_603148 = validateParameter(valid_603148, JArray, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "Subnets", valid_603148
  var valid_603149 = query.getOrDefault("Version")
  valid_603149 = validateParameter(valid_603149, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603149 != nil:
    section.add "Version", valid_603149
  var valid_603150 = query.getOrDefault("SecurityGroups")
  valid_603150 = validateParameter(valid_603150, JArray, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "SecurityGroups", valid_603150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603151 = header.getOrDefault("X-Amz-Date")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Date", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Security-Token")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Security-Token", valid_603152
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
  if body != nil:
    result.add "body", body

proc call*(call_603158: Call_GetCreateLoadBalancer_603138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Application Load Balancer or a Network Load Balancer.</p> <p>When you create a load balancer, you can specify security groups, public subnets, IP address type, and tags. Otherwise, you could do so later using <a>SetSecurityGroups</a>, <a>SetSubnets</a>, <a>SetIpAddressType</a>, and <a>AddTags</a>.</p> <p>To create listeners for your load balancer, use <a>CreateListener</a>. To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>For limit information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancer</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancer</a> in the <i>Network Load Balancers Guide</i>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html">Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> and <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html">Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603158.validator(path, query, header, formData, body)
  let scheme = call_603158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603158.url(scheme.get, call_603158.host, call_603158.base,
                         call_603158.route, valid.getOrDefault("path"))
  result = hook(call_603158, url, valid)

proc call*(call_603159: Call_GetCreateLoadBalancer_603138; Name: string;
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
  var query_603160 = newJObject()
  add(query_603160, "Name", newJString(Name))
  if SubnetMappings != nil:
    query_603160.add "SubnetMappings", SubnetMappings
  add(query_603160, "IpAddressType", newJString(IpAddressType))
  add(query_603160, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_603160.add "Tags", Tags
  add(query_603160, "Type", newJString(Type))
  add(query_603160, "Action", newJString(Action))
  if Subnets != nil:
    query_603160.add "Subnets", Subnets
  add(query_603160, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_603160.add "SecurityGroups", SecurityGroups
  result = call_603159.call(nil, query_603160, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_603138(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_603139, base: "/",
    url: url_GetCreateLoadBalancer_603140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateRule_603204 = ref object of OpenApiRestCall_602433
proc url_PostCreateRule_603206(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateRule_603205(path: JsonNode; query: JsonNode;
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
  var valid_603207 = query.getOrDefault("Action")
  valid_603207 = validateParameter(valid_603207, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_603207 != nil:
    section.add "Action", valid_603207
  var valid_603208 = query.getOrDefault("Version")
  valid_603208 = validateParameter(valid_603208, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603208 != nil:
    section.add "Version", valid_603208
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603209 = header.getOrDefault("X-Amz-Date")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Date", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Security-Token")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Security-Token", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Content-Sha256", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Algorithm")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Algorithm", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Signature")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Signature", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-SignedHeaders", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Credential")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Credential", valid_603215
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
  var valid_603216 = formData.getOrDefault("ListenerArn")
  valid_603216 = validateParameter(valid_603216, JString, required = true,
                                 default = nil)
  if valid_603216 != nil:
    section.add "ListenerArn", valid_603216
  var valid_603217 = formData.getOrDefault("Actions")
  valid_603217 = validateParameter(valid_603217, JArray, required = true, default = nil)
  if valid_603217 != nil:
    section.add "Actions", valid_603217
  var valid_603218 = formData.getOrDefault("Conditions")
  valid_603218 = validateParameter(valid_603218, JArray, required = true, default = nil)
  if valid_603218 != nil:
    section.add "Conditions", valid_603218
  var valid_603219 = formData.getOrDefault("Priority")
  valid_603219 = validateParameter(valid_603219, JInt, required = true, default = nil)
  if valid_603219 != nil:
    section.add "Priority", valid_603219
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603220: Call_PostCreateRule_603204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_603220.validator(path, query, header, formData, body)
  let scheme = call_603220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603220.url(scheme.get, call_603220.host, call_603220.base,
                         call_603220.route, valid.getOrDefault("path"))
  result = hook(call_603220, url, valid)

proc call*(call_603221: Call_PostCreateRule_603204; ListenerArn: string;
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
  var query_603222 = newJObject()
  var formData_603223 = newJObject()
  add(formData_603223, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    formData_603223.add "Actions", Actions
  if Conditions != nil:
    formData_603223.add "Conditions", Conditions
  add(query_603222, "Action", newJString(Action))
  add(formData_603223, "Priority", newJInt(Priority))
  add(query_603222, "Version", newJString(Version))
  result = call_603221.call(nil, query_603222, nil, formData_603223, nil)

var postCreateRule* = Call_PostCreateRule_603204(name: "postCreateRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_PostCreateRule_603205,
    base: "/", url: url_PostCreateRule_603206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateRule_603185 = ref object of OpenApiRestCall_602433
proc url_GetCreateRule_603187(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateRule_603186(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603188 = query.getOrDefault("Conditions")
  valid_603188 = validateParameter(valid_603188, JArray, required = true, default = nil)
  if valid_603188 != nil:
    section.add "Conditions", valid_603188
  var valid_603189 = query.getOrDefault("Action")
  valid_603189 = validateParameter(valid_603189, JString, required = true,
                                 default = newJString("CreateRule"))
  if valid_603189 != nil:
    section.add "Action", valid_603189
  var valid_603190 = query.getOrDefault("ListenerArn")
  valid_603190 = validateParameter(valid_603190, JString, required = true,
                                 default = nil)
  if valid_603190 != nil:
    section.add "ListenerArn", valid_603190
  var valid_603191 = query.getOrDefault("Actions")
  valid_603191 = validateParameter(valid_603191, JArray, required = true, default = nil)
  if valid_603191 != nil:
    section.add "Actions", valid_603191
  var valid_603192 = query.getOrDefault("Priority")
  valid_603192 = validateParameter(valid_603192, JInt, required = true, default = nil)
  if valid_603192 != nil:
    section.add "Priority", valid_603192
  var valid_603193 = query.getOrDefault("Version")
  valid_603193 = validateParameter(valid_603193, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603193 != nil:
    section.add "Version", valid_603193
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603194 = header.getOrDefault("X-Amz-Date")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Date", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Security-Token")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Security-Token", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Content-Sha256", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Algorithm")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Algorithm", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Signature")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Signature", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-SignedHeaders", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Credential")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Credential", valid_603200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603201: Call_GetCreateRule_603185; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a rule for the specified listener. The listener must be associated with an Application Load Balancer.</p> <p>Rules are evaluated in priority order, from the lowest value to the highest value. When the conditions for a rule are met, its actions are performed. If the conditions for no rules are met, the actions for the default rule are performed. For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#listener-rules">Listener Rules</a> in the <i>Application Load Balancers Guide</i>.</p> <p>To view your current rules, use <a>DescribeRules</a>. To update a rule, use <a>ModifyRule</a>. To set the priorities of your rules, use <a>SetRulePriorities</a>. To delete a rule, use <a>DeleteRule</a>.</p>
  ## 
  let valid = call_603201.validator(path, query, header, formData, body)
  let scheme = call_603201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603201.url(scheme.get, call_603201.host, call_603201.base,
                         call_603201.route, valid.getOrDefault("path"))
  result = hook(call_603201, url, valid)

proc call*(call_603202: Call_GetCreateRule_603185; Conditions: JsonNode;
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
  var query_603203 = newJObject()
  if Conditions != nil:
    query_603203.add "Conditions", Conditions
  add(query_603203, "Action", newJString(Action))
  add(query_603203, "ListenerArn", newJString(ListenerArn))
  if Actions != nil:
    query_603203.add "Actions", Actions
  add(query_603203, "Priority", newJInt(Priority))
  add(query_603203, "Version", newJString(Version))
  result = call_603202.call(nil, query_603203, nil, nil, nil)

var getCreateRule* = Call_GetCreateRule_603185(name: "getCreateRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateRule", validator: validate_GetCreateRule_603186,
    base: "/", url: url_GetCreateRule_603187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTargetGroup_603253 = ref object of OpenApiRestCall_602433
proc url_PostCreateTargetGroup_603255(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateTargetGroup_603254(path: JsonNode; query: JsonNode;
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
  var valid_603256 = query.getOrDefault("Action")
  valid_603256 = validateParameter(valid_603256, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_603256 != nil:
    section.add "Action", valid_603256
  var valid_603257 = query.getOrDefault("Version")
  valid_603257 = validateParameter(valid_603257, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603257 != nil:
    section.add "Version", valid_603257
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603258 = header.getOrDefault("X-Amz-Date")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Date", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Security-Token")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Security-Token", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Content-Sha256", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Algorithm")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Algorithm", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Signature")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Signature", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-SignedHeaders", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Credential")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Credential", valid_603264
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
  var valid_603265 = formData.getOrDefault("Name")
  valid_603265 = validateParameter(valid_603265, JString, required = true,
                                 default = nil)
  if valid_603265 != nil:
    section.add "Name", valid_603265
  var valid_603266 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_603266 = validateParameter(valid_603266, JInt, required = false, default = nil)
  if valid_603266 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_603266
  var valid_603267 = formData.getOrDefault("Port")
  valid_603267 = validateParameter(valid_603267, JInt, required = false, default = nil)
  if valid_603267 != nil:
    section.add "Port", valid_603267
  var valid_603268 = formData.getOrDefault("Protocol")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603268 != nil:
    section.add "Protocol", valid_603268
  var valid_603269 = formData.getOrDefault("HealthCheckPort")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "HealthCheckPort", valid_603269
  var valid_603270 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_603270 = validateParameter(valid_603270, JInt, required = false, default = nil)
  if valid_603270 != nil:
    section.add "UnhealthyThresholdCount", valid_603270
  var valid_603271 = formData.getOrDefault("HealthCheckEnabled")
  valid_603271 = validateParameter(valid_603271, JBool, required = false, default = nil)
  if valid_603271 != nil:
    section.add "HealthCheckEnabled", valid_603271
  var valid_603272 = formData.getOrDefault("HealthCheckPath")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "HealthCheckPath", valid_603272
  var valid_603273 = formData.getOrDefault("TargetType")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = newJString("instance"))
  if valid_603273 != nil:
    section.add "TargetType", valid_603273
  var valid_603274 = formData.getOrDefault("VpcId")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "VpcId", valid_603274
  var valid_603275 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_603275 = validateParameter(valid_603275, JInt, required = false, default = nil)
  if valid_603275 != nil:
    section.add "HealthCheckIntervalSeconds", valid_603275
  var valid_603276 = formData.getOrDefault("HealthyThresholdCount")
  valid_603276 = validateParameter(valid_603276, JInt, required = false, default = nil)
  if valid_603276 != nil:
    section.add "HealthyThresholdCount", valid_603276
  var valid_603277 = formData.getOrDefault("HealthCheckProtocol")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603277 != nil:
    section.add "HealthCheckProtocol", valid_603277
  var valid_603278 = formData.getOrDefault("Matcher.HttpCode")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "Matcher.HttpCode", valid_603278
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_PostCreateTargetGroup_603253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_PostCreateTargetGroup_603253; Name: string;
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
  var query_603281 = newJObject()
  var formData_603282 = newJObject()
  add(formData_603282, "Name", newJString(Name))
  add(formData_603282, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_603282, "Port", newJInt(Port))
  add(formData_603282, "Protocol", newJString(Protocol))
  add(formData_603282, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_603282, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_603282, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(formData_603282, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_603282, "TargetType", newJString(TargetType))
  add(query_603281, "Action", newJString(Action))
  add(formData_603282, "VpcId", newJString(VpcId))
  add(formData_603282, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_603282, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_603282, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_603282, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_603281, "Version", newJString(Version))
  result = call_603280.call(nil, query_603281, nil, formData_603282, nil)

var postCreateTargetGroup* = Call_PostCreateTargetGroup_603253(
    name: "postCreateTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup",
    validator: validate_PostCreateTargetGroup_603254, base: "/",
    url: url_PostCreateTargetGroup_603255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTargetGroup_603224 = ref object of OpenApiRestCall_602433
proc url_GetCreateTargetGroup_603226(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateTargetGroup_603225(path: JsonNode; query: JsonNode;
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
  var valid_603227 = query.getOrDefault("HealthCheckEnabled")
  valid_603227 = validateParameter(valid_603227, JBool, required = false, default = nil)
  if valid_603227 != nil:
    section.add "HealthCheckEnabled", valid_603227
  var valid_603228 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_603228 = validateParameter(valid_603228, JInt, required = false, default = nil)
  if valid_603228 != nil:
    section.add "HealthCheckIntervalSeconds", valid_603228
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_603229 = query.getOrDefault("Name")
  valid_603229 = validateParameter(valid_603229, JString, required = true,
                                 default = nil)
  if valid_603229 != nil:
    section.add "Name", valid_603229
  var valid_603230 = query.getOrDefault("HealthCheckPort")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "HealthCheckPort", valid_603230
  var valid_603231 = query.getOrDefault("Protocol")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603231 != nil:
    section.add "Protocol", valid_603231
  var valid_603232 = query.getOrDefault("VpcId")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "VpcId", valid_603232
  var valid_603233 = query.getOrDefault("Action")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = newJString("CreateTargetGroup"))
  if valid_603233 != nil:
    section.add "Action", valid_603233
  var valid_603234 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_603234 = validateParameter(valid_603234, JInt, required = false, default = nil)
  if valid_603234 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_603234
  var valid_603235 = query.getOrDefault("Matcher.HttpCode")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "Matcher.HttpCode", valid_603235
  var valid_603236 = query.getOrDefault("UnhealthyThresholdCount")
  valid_603236 = validateParameter(valid_603236, JInt, required = false, default = nil)
  if valid_603236 != nil:
    section.add "UnhealthyThresholdCount", valid_603236
  var valid_603237 = query.getOrDefault("TargetType")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = newJString("instance"))
  if valid_603237 != nil:
    section.add "TargetType", valid_603237
  var valid_603238 = query.getOrDefault("Port")
  valid_603238 = validateParameter(valid_603238, JInt, required = false, default = nil)
  if valid_603238 != nil:
    section.add "Port", valid_603238
  var valid_603239 = query.getOrDefault("HealthCheckProtocol")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603239 != nil:
    section.add "HealthCheckProtocol", valid_603239
  var valid_603240 = query.getOrDefault("HealthyThresholdCount")
  valid_603240 = validateParameter(valid_603240, JInt, required = false, default = nil)
  if valid_603240 != nil:
    section.add "HealthyThresholdCount", valid_603240
  var valid_603241 = query.getOrDefault("Version")
  valid_603241 = validateParameter(valid_603241, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603241 != nil:
    section.add "Version", valid_603241
  var valid_603242 = query.getOrDefault("HealthCheckPath")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "HealthCheckPath", valid_603242
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603243 = header.getOrDefault("X-Amz-Date")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Date", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Security-Token")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Security-Token", valid_603244
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
  if body != nil:
    result.add "body", body

proc call*(call_603250: Call_GetCreateTargetGroup_603224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a target group.</p> <p>To register targets with the target group, use <a>RegisterTargets</a>. To update the health check settings for the target group, use <a>ModifyTargetGroup</a>. To monitor the health of targets in the target group, use <a>DescribeTargetHealth</a>.</p> <p>To route traffic to the targets in a target group, specify the target group in an action using <a>CreateListener</a> or <a>CreateRule</a>.</p> <p>To delete a target group, use <a>DeleteTargetGroup</a>.</p> <p>This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple target groups with the same settings, each call succeeds.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html">Target Groups for Your Application Load Balancers</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html">Target Groups for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603250.validator(path, query, header, formData, body)
  let scheme = call_603250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603250.url(scheme.get, call_603250.host, call_603250.base,
                         call_603250.route, valid.getOrDefault("path"))
  result = hook(call_603250, url, valid)

proc call*(call_603251: Call_GetCreateTargetGroup_603224; Name: string;
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
  var query_603252 = newJObject()
  add(query_603252, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_603252, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_603252, "Name", newJString(Name))
  add(query_603252, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_603252, "Protocol", newJString(Protocol))
  add(query_603252, "VpcId", newJString(VpcId))
  add(query_603252, "Action", newJString(Action))
  add(query_603252, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_603252, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_603252, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_603252, "TargetType", newJString(TargetType))
  add(query_603252, "Port", newJInt(Port))
  add(query_603252, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_603252, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_603252, "Version", newJString(Version))
  add(query_603252, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_603251.call(nil, query_603252, nil, nil, nil)

var getCreateTargetGroup* = Call_GetCreateTargetGroup_603224(
    name: "getCreateTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateTargetGroup", validator: validate_GetCreateTargetGroup_603225,
    base: "/", url: url_GetCreateTargetGroup_603226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteListener_603299 = ref object of OpenApiRestCall_602433
proc url_PostDeleteListener_603301(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteListener_603300(path: JsonNode; query: JsonNode;
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
  var valid_603302 = query.getOrDefault("Action")
  valid_603302 = validateParameter(valid_603302, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_603302 != nil:
    section.add "Action", valid_603302
  var valid_603303 = query.getOrDefault("Version")
  valid_603303 = validateParameter(valid_603303, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603303 != nil:
    section.add "Version", valid_603303
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603304 = header.getOrDefault("X-Amz-Date")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Date", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Security-Token")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Security-Token", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Content-Sha256", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Algorithm")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Algorithm", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Signature")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Signature", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-SignedHeaders", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Credential")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Credential", valid_603310
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_603311 = formData.getOrDefault("ListenerArn")
  valid_603311 = validateParameter(valid_603311, JString, required = true,
                                 default = nil)
  if valid_603311 != nil:
    section.add "ListenerArn", valid_603311
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603312: Call_PostDeleteListener_603299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_603312.validator(path, query, header, formData, body)
  let scheme = call_603312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603312.url(scheme.get, call_603312.host, call_603312.base,
                         call_603312.route, valid.getOrDefault("path"))
  result = hook(call_603312, url, valid)

proc call*(call_603313: Call_PostDeleteListener_603299; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603314 = newJObject()
  var formData_603315 = newJObject()
  add(formData_603315, "ListenerArn", newJString(ListenerArn))
  add(query_603314, "Action", newJString(Action))
  add(query_603314, "Version", newJString(Version))
  result = call_603313.call(nil, query_603314, nil, formData_603315, nil)

var postDeleteListener* = Call_PostDeleteListener_603299(
    name: "postDeleteListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=DeleteListener",
    validator: validate_PostDeleteListener_603300, base: "/",
    url: url_PostDeleteListener_603301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteListener_603283 = ref object of OpenApiRestCall_602433
proc url_GetDeleteListener_603285(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteListener_603284(path: JsonNode; query: JsonNode;
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
  var valid_603286 = query.getOrDefault("Action")
  valid_603286 = validateParameter(valid_603286, JString, required = true,
                                 default = newJString("DeleteListener"))
  if valid_603286 != nil:
    section.add "Action", valid_603286
  var valid_603287 = query.getOrDefault("ListenerArn")
  valid_603287 = validateParameter(valid_603287, JString, required = true,
                                 default = nil)
  if valid_603287 != nil:
    section.add "ListenerArn", valid_603287
  var valid_603288 = query.getOrDefault("Version")
  valid_603288 = validateParameter(valid_603288, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603288 != nil:
    section.add "Version", valid_603288
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603289 = header.getOrDefault("X-Amz-Date")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Date", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Security-Token")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Security-Token", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Content-Sha256", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Algorithm")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Algorithm", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Signature")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Signature", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-SignedHeaders", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Credential")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Credential", valid_603295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603296: Call_GetDeleteListener_603283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ## 
  let valid = call_603296.validator(path, query, header, formData, body)
  let scheme = call_603296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603296.url(scheme.get, call_603296.host, call_603296.base,
                         call_603296.route, valid.getOrDefault("path"))
  result = hook(call_603296, url, valid)

proc call*(call_603297: Call_GetDeleteListener_603283; ListenerArn: string;
          Action: string = "DeleteListener"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteListener
  ## <p>Deletes the specified listener.</p> <p>Alternatively, your listener is deleted when you delete the load balancer to which it is attached, using <a>DeleteLoadBalancer</a>.</p>
  ##   Action: string (required)
  ##   ListenerArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  ##   Version: string (required)
  var query_603298 = newJObject()
  add(query_603298, "Action", newJString(Action))
  add(query_603298, "ListenerArn", newJString(ListenerArn))
  add(query_603298, "Version", newJString(Version))
  result = call_603297.call(nil, query_603298, nil, nil, nil)

var getDeleteListener* = Call_GetDeleteListener_603283(name: "getDeleteListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteListener", validator: validate_GetDeleteListener_603284,
    base: "/", url: url_GetDeleteListener_603285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_603332 = ref object of OpenApiRestCall_602433
proc url_PostDeleteLoadBalancer_603334(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteLoadBalancer_603333(path: JsonNode; query: JsonNode;
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
  var valid_603335 = query.getOrDefault("Action")
  valid_603335 = validateParameter(valid_603335, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
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
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_603344 = formData.getOrDefault("LoadBalancerArn")
  valid_603344 = validateParameter(valid_603344, JString, required = true,
                                 default = nil)
  if valid_603344 != nil:
    section.add "LoadBalancerArn", valid_603344
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603345: Call_PostDeleteLoadBalancer_603332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_603345.validator(path, query, header, formData, body)
  let scheme = call_603345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603345.url(scheme.get, call_603345.host, call_603345.base,
                         call_603345.route, valid.getOrDefault("path"))
  result = hook(call_603345, url, valid)

proc call*(call_603346: Call_PostDeleteLoadBalancer_603332;
          LoadBalancerArn: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2015-12-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603347 = newJObject()
  var formData_603348 = newJObject()
  add(formData_603348, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603347, "Action", newJString(Action))
  add(query_603347, "Version", newJString(Version))
  result = call_603346.call(nil, query_603347, nil, formData_603348, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_603332(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_603333, base: "/",
    url: url_PostDeleteLoadBalancer_603334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_603316 = ref object of OpenApiRestCall_602433
proc url_GetDeleteLoadBalancer_603318(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteLoadBalancer_603317(path: JsonNode; query: JsonNode;
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
  var valid_603319 = query.getOrDefault("Action")
  valid_603319 = validateParameter(valid_603319, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_603319 != nil:
    section.add "Action", valid_603319
  var valid_603320 = query.getOrDefault("LoadBalancerArn")
  valid_603320 = validateParameter(valid_603320, JString, required = true,
                                 default = nil)
  if valid_603320 != nil:
    section.add "LoadBalancerArn", valid_603320
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

proc call*(call_603329: Call_GetDeleteLoadBalancer_603316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ## 
  let valid = call_603329.validator(path, query, header, formData, body)
  let scheme = call_603329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603329.url(scheme.get, call_603329.host, call_603329.base,
                         call_603329.route, valid.getOrDefault("path"))
  result = hook(call_603329, url, valid)

proc call*(call_603330: Call_GetDeleteLoadBalancer_603316; LoadBalancerArn: string;
          Action: string = "DeleteLoadBalancer"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified Application Load Balancer or Network Load Balancer and its attached listeners.</p> <p>You can't delete a load balancer if deletion protection is enabled. If the load balancer does not exist or has already been deleted, the call succeeds.</p> <p>Deleting a load balancer does not affect its registered targets. For example, your EC2 instances continue to run and are still registered to their target groups. If you no longer need these EC2 instances, you can stop or terminate them.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_603331 = newJObject()
  add(query_603331, "Action", newJString(Action))
  add(query_603331, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603331, "Version", newJString(Version))
  result = call_603330.call(nil, query_603331, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_603316(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_603317, base: "/",
    url: url_GetDeleteLoadBalancer_603318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRule_603365 = ref object of OpenApiRestCall_602433
proc url_PostDeleteRule_603367(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteRule_603366(path: JsonNode; query: JsonNode;
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
  var valid_603368 = query.getOrDefault("Action")
  valid_603368 = validateParameter(valid_603368, JString, required = true,
                                 default = newJString("DeleteRule"))
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
  ##   RuleArn: JString (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RuleArn` field"
  var valid_603377 = formData.getOrDefault("RuleArn")
  valid_603377 = validateParameter(valid_603377, JString, required = true,
                                 default = nil)
  if valid_603377 != nil:
    section.add "RuleArn", valid_603377
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603378: Call_PostDeleteRule_603365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_603378.validator(path, query, header, formData, body)
  let scheme = call_603378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603378.url(scheme.get, call_603378.host, call_603378.base,
                         call_603378.route, valid.getOrDefault("path"))
  result = hook(call_603378, url, valid)

proc call*(call_603379: Call_PostDeleteRule_603365; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteRule
  ## Deletes the specified rule.
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603380 = newJObject()
  var formData_603381 = newJObject()
  add(formData_603381, "RuleArn", newJString(RuleArn))
  add(query_603380, "Action", newJString(Action))
  add(query_603380, "Version", newJString(Version))
  result = call_603379.call(nil, query_603380, nil, formData_603381, nil)

var postDeleteRule* = Call_PostDeleteRule_603365(name: "postDeleteRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_PostDeleteRule_603366,
    base: "/", url: url_PostDeleteRule_603367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRule_603349 = ref object of OpenApiRestCall_602433
proc url_GetDeleteRule_603351(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteRule_603350(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603352 = query.getOrDefault("Action")
  valid_603352 = validateParameter(valid_603352, JString, required = true,
                                 default = newJString("DeleteRule"))
  if valid_603352 != nil:
    section.add "Action", valid_603352
  var valid_603353 = query.getOrDefault("RuleArn")
  valid_603353 = validateParameter(valid_603353, JString, required = true,
                                 default = nil)
  if valid_603353 != nil:
    section.add "RuleArn", valid_603353
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

proc call*(call_603362: Call_GetDeleteRule_603349; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified rule.
  ## 
  let valid = call_603362.validator(path, query, header, formData, body)
  let scheme = call_603362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603362.url(scheme.get, call_603362.host, call_603362.base,
                         call_603362.route, valid.getOrDefault("path"))
  result = hook(call_603362, url, valid)

proc call*(call_603363: Call_GetDeleteRule_603349; RuleArn: string;
          Action: string = "DeleteRule"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteRule
  ## Deletes the specified rule.
  ##   Action: string (required)
  ##   RuleArn: string (required)
  ##          : The Amazon Resource Name (ARN) of the rule.
  ##   Version: string (required)
  var query_603364 = newJObject()
  add(query_603364, "Action", newJString(Action))
  add(query_603364, "RuleArn", newJString(RuleArn))
  add(query_603364, "Version", newJString(Version))
  result = call_603363.call(nil, query_603364, nil, nil, nil)

var getDeleteRule* = Call_GetDeleteRule_603349(name: "getDeleteRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteRule", validator: validate_GetDeleteRule_603350,
    base: "/", url: url_GetDeleteRule_603351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTargetGroup_603398 = ref object of OpenApiRestCall_602433
proc url_PostDeleteTargetGroup_603400(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteTargetGroup_603399(path: JsonNode; query: JsonNode;
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
  var valid_603401 = query.getOrDefault("Action")
  valid_603401 = validateParameter(valid_603401, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
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
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_603410 = formData.getOrDefault("TargetGroupArn")
  valid_603410 = validateParameter(valid_603410, JString, required = true,
                                 default = nil)
  if valid_603410 != nil:
    section.add "TargetGroupArn", valid_603410
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603411: Call_PostDeleteTargetGroup_603398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_603411.validator(path, query, header, formData, body)
  let scheme = call_603411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603411.url(scheme.get, call_603411.host, call_603411.base,
                         call_603411.route, valid.getOrDefault("path"))
  result = hook(call_603411, url, valid)

proc call*(call_603412: Call_PostDeleteTargetGroup_603398; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## postDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_603413 = newJObject()
  var formData_603414 = newJObject()
  add(query_603413, "Action", newJString(Action))
  add(formData_603414, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603413, "Version", newJString(Version))
  result = call_603412.call(nil, query_603413, nil, formData_603414, nil)

var postDeleteTargetGroup* = Call_PostDeleteTargetGroup_603398(
    name: "postDeleteTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup",
    validator: validate_PostDeleteTargetGroup_603399, base: "/",
    url: url_PostDeleteTargetGroup_603400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTargetGroup_603382 = ref object of OpenApiRestCall_602433
proc url_GetDeleteTargetGroup_603384(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteTargetGroup_603383(path: JsonNode; query: JsonNode;
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
  var valid_603385 = query.getOrDefault("TargetGroupArn")
  valid_603385 = validateParameter(valid_603385, JString, required = true,
                                 default = nil)
  if valid_603385 != nil:
    section.add "TargetGroupArn", valid_603385
  var valid_603386 = query.getOrDefault("Action")
  valid_603386 = validateParameter(valid_603386, JString, required = true,
                                 default = newJString("DeleteTargetGroup"))
  if valid_603386 != nil:
    section.add "Action", valid_603386
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

proc call*(call_603395: Call_GetDeleteTargetGroup_603382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ## 
  let valid = call_603395.validator(path, query, header, formData, body)
  let scheme = call_603395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603395.url(scheme.get, call_603395.host, call_603395.base,
                         call_603395.route, valid.getOrDefault("path"))
  result = hook(call_603395, url, valid)

proc call*(call_603396: Call_GetDeleteTargetGroup_603382; TargetGroupArn: string;
          Action: string = "DeleteTargetGroup"; Version: string = "2015-12-01"): Recallable =
  ## getDeleteTargetGroup
  ## <p>Deletes the specified target group.</p> <p>You can delete a target group if it is not referenced by any actions. Deleting a target group also deletes any associated health checks.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603397 = newJObject()
  add(query_603397, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603397, "Action", newJString(Action))
  add(query_603397, "Version", newJString(Version))
  result = call_603396.call(nil, query_603397, nil, nil, nil)

var getDeleteTargetGroup* = Call_GetDeleteTargetGroup_603382(
    name: "getDeleteTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteTargetGroup", validator: validate_GetDeleteTargetGroup_603383,
    base: "/", url: url_GetDeleteTargetGroup_603384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterTargets_603432 = ref object of OpenApiRestCall_602433
proc url_PostDeregisterTargets_603434(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeregisterTargets_603433(path: JsonNode; query: JsonNode;
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
  var valid_603435 = query.getOrDefault("Action")
  valid_603435 = validateParameter(valid_603435, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_603435 != nil:
    section.add "Action", valid_603435
  var valid_603436 = query.getOrDefault("Version")
  valid_603436 = validateParameter(valid_603436, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603436 != nil:
    section.add "Version", valid_603436
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603437 = header.getOrDefault("X-Amz-Date")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Date", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Security-Token")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Security-Token", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Content-Sha256", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Algorithm")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Algorithm", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Signature")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Signature", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-SignedHeaders", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Credential")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Credential", valid_603443
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : The targets. If you specified a port override when you registered a target, you must specify both the target ID and the port when you deregister it.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_603444 = formData.getOrDefault("Targets")
  valid_603444 = validateParameter(valid_603444, JArray, required = true, default = nil)
  if valid_603444 != nil:
    section.add "Targets", valid_603444
  var valid_603445 = formData.getOrDefault("TargetGroupArn")
  valid_603445 = validateParameter(valid_603445, JString, required = true,
                                 default = nil)
  if valid_603445 != nil:
    section.add "TargetGroupArn", valid_603445
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603446: Call_PostDeregisterTargets_603432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_603446.validator(path, query, header, formData, body)
  let scheme = call_603446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603446.url(scheme.get, call_603446.host, call_603446.base,
                         call_603446.route, valid.getOrDefault("path"))
  result = hook(call_603446, url, valid)

proc call*(call_603447: Call_PostDeregisterTargets_603432; Targets: JsonNode;
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
  var query_603448 = newJObject()
  var formData_603449 = newJObject()
  if Targets != nil:
    formData_603449.add "Targets", Targets
  add(query_603448, "Action", newJString(Action))
  add(formData_603449, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603448, "Version", newJString(Version))
  result = call_603447.call(nil, query_603448, nil, formData_603449, nil)

var postDeregisterTargets* = Call_PostDeregisterTargets_603432(
    name: "postDeregisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets",
    validator: validate_PostDeregisterTargets_603433, base: "/",
    url: url_PostDeregisterTargets_603434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterTargets_603415 = ref object of OpenApiRestCall_602433
proc url_GetDeregisterTargets_603417(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeregisterTargets_603416(path: JsonNode; query: JsonNode;
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
  var valid_603418 = query.getOrDefault("Targets")
  valid_603418 = validateParameter(valid_603418, JArray, required = true, default = nil)
  if valid_603418 != nil:
    section.add "Targets", valid_603418
  var valid_603419 = query.getOrDefault("TargetGroupArn")
  valid_603419 = validateParameter(valid_603419, JString, required = true,
                                 default = nil)
  if valid_603419 != nil:
    section.add "TargetGroupArn", valid_603419
  var valid_603420 = query.getOrDefault("Action")
  valid_603420 = validateParameter(valid_603420, JString, required = true,
                                 default = newJString("DeregisterTargets"))
  if valid_603420 != nil:
    section.add "Action", valid_603420
  var valid_603421 = query.getOrDefault("Version")
  valid_603421 = validateParameter(valid_603421, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603421 != nil:
    section.add "Version", valid_603421
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603422 = header.getOrDefault("X-Amz-Date")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Date", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Security-Token")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Security-Token", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Algorithm")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Algorithm", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-SignedHeaders", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Credential")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Credential", valid_603428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_GetDeregisterTargets_603415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters the specified targets from the specified target group. After the targets are deregistered, they no longer receive traffic from the load balancer.
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_GetDeregisterTargets_603415; Targets: JsonNode;
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
  var query_603431 = newJObject()
  if Targets != nil:
    query_603431.add "Targets", Targets
  add(query_603431, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603431, "Action", newJString(Action))
  add(query_603431, "Version", newJString(Version))
  result = call_603430.call(nil, query_603431, nil, nil, nil)

var getDeregisterTargets* = Call_GetDeregisterTargets_603415(
    name: "getDeregisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterTargets", validator: validate_GetDeregisterTargets_603416,
    base: "/", url: url_GetDeregisterTargets_603417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_603467 = ref object of OpenApiRestCall_602433
proc url_PostDescribeAccountLimits_603469(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAccountLimits_603468(path: JsonNode; query: JsonNode;
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
  var valid_603470 = query.getOrDefault("Action")
  valid_603470 = validateParameter(valid_603470, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_603470 != nil:
    section.add "Action", valid_603470
  var valid_603471 = query.getOrDefault("Version")
  valid_603471 = validateParameter(valid_603471, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603471 != nil:
    section.add "Version", valid_603471
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603472 = header.getOrDefault("X-Amz-Date")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Date", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Security-Token")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Security-Token", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Content-Sha256", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Algorithm")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Algorithm", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Signature")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Signature", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-SignedHeaders", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Credential")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Credential", valid_603478
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_603479 = formData.getOrDefault("Marker")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "Marker", valid_603479
  var valid_603480 = formData.getOrDefault("PageSize")
  valid_603480 = validateParameter(valid_603480, JInt, required = false, default = nil)
  if valid_603480 != nil:
    section.add "PageSize", valid_603480
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603481: Call_PostDescribeAccountLimits_603467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603481.validator(path, query, header, formData, body)
  let scheme = call_603481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603481.url(scheme.get, call_603481.host, call_603481.base,
                         call_603481.route, valid.getOrDefault("path"))
  result = hook(call_603481, url, valid)

proc call*(call_603482: Call_PostDescribeAccountLimits_603467; Marker: string = "";
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
  var query_603483 = newJObject()
  var formData_603484 = newJObject()
  add(formData_603484, "Marker", newJString(Marker))
  add(query_603483, "Action", newJString(Action))
  add(formData_603484, "PageSize", newJInt(PageSize))
  add(query_603483, "Version", newJString(Version))
  result = call_603482.call(nil, query_603483, nil, formData_603484, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_603467(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_603468, base: "/",
    url: url_PostDescribeAccountLimits_603469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_603450 = ref object of OpenApiRestCall_602433
proc url_GetDescribeAccountLimits_603452(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAccountLimits_603451(path: JsonNode; query: JsonNode;
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
  var valid_603453 = query.getOrDefault("PageSize")
  valid_603453 = validateParameter(valid_603453, JInt, required = false, default = nil)
  if valid_603453 != nil:
    section.add "PageSize", valid_603453
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603454 = query.getOrDefault("Action")
  valid_603454 = validateParameter(valid_603454, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_603454 != nil:
    section.add "Action", valid_603454
  var valid_603455 = query.getOrDefault("Marker")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "Marker", valid_603455
  var valid_603456 = query.getOrDefault("Version")
  valid_603456 = validateParameter(valid_603456, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603456 != nil:
    section.add "Version", valid_603456
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603457 = header.getOrDefault("X-Amz-Date")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Date", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Security-Token")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Security-Token", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Content-Sha256", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Algorithm")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Algorithm", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Signature")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Signature", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-SignedHeaders", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Credential")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Credential", valid_603463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603464: Call_GetDescribeAccountLimits_603450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-limits.html">Limits for Your Application Load Balancers</a> in the <i>Application Load Balancer Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html">Limits for Your Network Load Balancers</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603464.validator(path, query, header, formData, body)
  let scheme = call_603464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603464.url(scheme.get, call_603464.host, call_603464.base,
                         call_603464.route, valid.getOrDefault("path"))
  result = hook(call_603464, url, valid)

proc call*(call_603465: Call_GetDescribeAccountLimits_603450; PageSize: int = 0;
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
  var query_603466 = newJObject()
  add(query_603466, "PageSize", newJInt(PageSize))
  add(query_603466, "Action", newJString(Action))
  add(query_603466, "Marker", newJString(Marker))
  add(query_603466, "Version", newJString(Version))
  result = call_603465.call(nil, query_603466, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_603450(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_603451, base: "/",
    url: url_GetDescribeAccountLimits_603452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListenerCertificates_603503 = ref object of OpenApiRestCall_602433
proc url_PostDescribeListenerCertificates_603505(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeListenerCertificates_603504(path: JsonNode;
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
  var valid_603506 = query.getOrDefault("Action")
  valid_603506 = validateParameter(valid_603506, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_603506 != nil:
    section.add "Action", valid_603506
  var valid_603507 = query.getOrDefault("Version")
  valid_603507 = validateParameter(valid_603507, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603507 != nil:
    section.add "Version", valid_603507
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603508 = header.getOrDefault("X-Amz-Date")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Date", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Security-Token")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Security-Token", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Content-Sha256", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Algorithm")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Algorithm", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Signature")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Signature", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-SignedHeaders", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Credential")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Credential", valid_603514
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
  var valid_603515 = formData.getOrDefault("ListenerArn")
  valid_603515 = validateParameter(valid_603515, JString, required = true,
                                 default = nil)
  if valid_603515 != nil:
    section.add "ListenerArn", valid_603515
  var valid_603516 = formData.getOrDefault("Marker")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "Marker", valid_603516
  var valid_603517 = formData.getOrDefault("PageSize")
  valid_603517 = validateParameter(valid_603517, JInt, required = false, default = nil)
  if valid_603517 != nil:
    section.add "PageSize", valid_603517
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603518: Call_PostDescribeListenerCertificates_603503;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603518.validator(path, query, header, formData, body)
  let scheme = call_603518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603518.url(scheme.get, call_603518.host, call_603518.base,
                         call_603518.route, valid.getOrDefault("path"))
  result = hook(call_603518, url, valid)

proc call*(call_603519: Call_PostDescribeListenerCertificates_603503;
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
  var query_603520 = newJObject()
  var formData_603521 = newJObject()
  add(formData_603521, "ListenerArn", newJString(ListenerArn))
  add(formData_603521, "Marker", newJString(Marker))
  add(query_603520, "Action", newJString(Action))
  add(formData_603521, "PageSize", newJInt(PageSize))
  add(query_603520, "Version", newJString(Version))
  result = call_603519.call(nil, query_603520, nil, formData_603521, nil)

var postDescribeListenerCertificates* = Call_PostDescribeListenerCertificates_603503(
    name: "postDescribeListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_PostDescribeListenerCertificates_603504, base: "/",
    url: url_PostDescribeListenerCertificates_603505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListenerCertificates_603485 = ref object of OpenApiRestCall_602433
proc url_GetDescribeListenerCertificates_603487(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeListenerCertificates_603486(path: JsonNode;
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
  var valid_603488 = query.getOrDefault("PageSize")
  valid_603488 = validateParameter(valid_603488, JInt, required = false, default = nil)
  if valid_603488 != nil:
    section.add "PageSize", valid_603488
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603489 = query.getOrDefault("Action")
  valid_603489 = validateParameter(valid_603489, JString, required = true, default = newJString(
      "DescribeListenerCertificates"))
  if valid_603489 != nil:
    section.add "Action", valid_603489
  var valid_603490 = query.getOrDefault("Marker")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "Marker", valid_603490
  var valid_603491 = query.getOrDefault("ListenerArn")
  valid_603491 = validateParameter(valid_603491, JString, required = true,
                                 default = nil)
  if valid_603491 != nil:
    section.add "ListenerArn", valid_603491
  var valid_603492 = query.getOrDefault("Version")
  valid_603492 = validateParameter(valid_603492, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603492 != nil:
    section.add "Version", valid_603492
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603493 = header.getOrDefault("X-Amz-Date")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Date", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Security-Token")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Security-Token", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Content-Sha256", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Algorithm")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Algorithm", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Signature")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Signature", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-SignedHeaders", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Credential")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Credential", valid_603499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603500: Call_GetDescribeListenerCertificates_603485;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the default certificate and the certificate list for the specified HTTPS or TLS listener.</p> <p>If the default certificate is also in the certificate list, it appears twice in the results (once with <code>IsDefault</code> set to true and once with <code>IsDefault</code> set to false).</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#https-listener-certificates">SSL Certificates</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603500.validator(path, query, header, formData, body)
  let scheme = call_603500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603500.url(scheme.get, call_603500.host, call_603500.base,
                         call_603500.route, valid.getOrDefault("path"))
  result = hook(call_603500, url, valid)

proc call*(call_603501: Call_GetDescribeListenerCertificates_603485;
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
  var query_603502 = newJObject()
  add(query_603502, "PageSize", newJInt(PageSize))
  add(query_603502, "Action", newJString(Action))
  add(query_603502, "Marker", newJString(Marker))
  add(query_603502, "ListenerArn", newJString(ListenerArn))
  add(query_603502, "Version", newJString(Version))
  result = call_603501.call(nil, query_603502, nil, nil, nil)

var getDescribeListenerCertificates* = Call_GetDescribeListenerCertificates_603485(
    name: "getDescribeListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListenerCertificates",
    validator: validate_GetDescribeListenerCertificates_603486, base: "/",
    url: url_GetDescribeListenerCertificates_603487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeListeners_603541 = ref object of OpenApiRestCall_602433
proc url_PostDescribeListeners_603543(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeListeners_603542(path: JsonNode; query: JsonNode;
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
  var valid_603544 = query.getOrDefault("Action")
  valid_603544 = validateParameter(valid_603544, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_603544 != nil:
    section.add "Action", valid_603544
  var valid_603545 = query.getOrDefault("Version")
  valid_603545 = validateParameter(valid_603545, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603545 != nil:
    section.add "Version", valid_603545
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603546 = header.getOrDefault("X-Amz-Date")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Date", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Security-Token")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Security-Token", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Content-Sha256", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Algorithm")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Algorithm", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Signature")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Signature", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-SignedHeaders", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Credential")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Credential", valid_603552
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
  var valid_603553 = formData.getOrDefault("LoadBalancerArn")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "LoadBalancerArn", valid_603553
  var valid_603554 = formData.getOrDefault("Marker")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "Marker", valid_603554
  var valid_603555 = formData.getOrDefault("PageSize")
  valid_603555 = validateParameter(valid_603555, JInt, required = false, default = nil)
  if valid_603555 != nil:
    section.add "PageSize", valid_603555
  var valid_603556 = formData.getOrDefault("ListenerArns")
  valid_603556 = validateParameter(valid_603556, JArray, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "ListenerArns", valid_603556
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603557: Call_PostDescribeListeners_603541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_603557.validator(path, query, header, formData, body)
  let scheme = call_603557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603557.url(scheme.get, call_603557.host, call_603557.base,
                         call_603557.route, valid.getOrDefault("path"))
  result = hook(call_603557, url, valid)

proc call*(call_603558: Call_PostDescribeListeners_603541;
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
  var query_603559 = newJObject()
  var formData_603560 = newJObject()
  add(formData_603560, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_603560, "Marker", newJString(Marker))
  add(query_603559, "Action", newJString(Action))
  add(formData_603560, "PageSize", newJInt(PageSize))
  if ListenerArns != nil:
    formData_603560.add "ListenerArns", ListenerArns
  add(query_603559, "Version", newJString(Version))
  result = call_603558.call(nil, query_603559, nil, formData_603560, nil)

var postDescribeListeners* = Call_PostDescribeListeners_603541(
    name: "postDescribeListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners",
    validator: validate_PostDescribeListeners_603542, base: "/",
    url: url_PostDescribeListeners_603543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeListeners_603522 = ref object of OpenApiRestCall_602433
proc url_GetDescribeListeners_603524(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeListeners_603523(path: JsonNode; query: JsonNode;
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
  var valid_603525 = query.getOrDefault("ListenerArns")
  valid_603525 = validateParameter(valid_603525, JArray, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "ListenerArns", valid_603525
  var valid_603526 = query.getOrDefault("PageSize")
  valid_603526 = validateParameter(valid_603526, JInt, required = false, default = nil)
  if valid_603526 != nil:
    section.add "PageSize", valid_603526
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603527 = query.getOrDefault("Action")
  valid_603527 = validateParameter(valid_603527, JString, required = true,
                                 default = newJString("DescribeListeners"))
  if valid_603527 != nil:
    section.add "Action", valid_603527
  var valid_603528 = query.getOrDefault("Marker")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "Marker", valid_603528
  var valid_603529 = query.getOrDefault("LoadBalancerArn")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "LoadBalancerArn", valid_603529
  var valid_603530 = query.getOrDefault("Version")
  valid_603530 = validateParameter(valid_603530, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603530 != nil:
    section.add "Version", valid_603530
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603531 = header.getOrDefault("X-Amz-Date")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Date", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Security-Token")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Security-Token", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Content-Sha256", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Algorithm")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Algorithm", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Signature")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Signature", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-SignedHeaders", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Credential")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Credential", valid_603537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603538: Call_GetDescribeListeners_603522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified listeners or the listeners for the specified Application Load Balancer or Network Load Balancer. You must specify either a load balancer or one or more listeners.</p> <p>For an HTTPS or TLS listener, the output includes the default certificate for the listener. To describe the certificate list for the listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_603538.validator(path, query, header, formData, body)
  let scheme = call_603538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603538.url(scheme.get, call_603538.host, call_603538.base,
                         call_603538.route, valid.getOrDefault("path"))
  result = hook(call_603538, url, valid)

proc call*(call_603539: Call_GetDescribeListeners_603522;
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
  var query_603540 = newJObject()
  if ListenerArns != nil:
    query_603540.add "ListenerArns", ListenerArns
  add(query_603540, "PageSize", newJInt(PageSize))
  add(query_603540, "Action", newJString(Action))
  add(query_603540, "Marker", newJString(Marker))
  add(query_603540, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603540, "Version", newJString(Version))
  result = call_603539.call(nil, query_603540, nil, nil, nil)

var getDescribeListeners* = Call_GetDescribeListeners_603522(
    name: "getDescribeListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeListeners", validator: validate_GetDescribeListeners_603523,
    base: "/", url: url_GetDescribeListeners_603524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_603577 = ref object of OpenApiRestCall_602433
proc url_PostDescribeLoadBalancerAttributes_603579(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancerAttributes_603578(path: JsonNode;
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
  var valid_603580 = query.getOrDefault("Action")
  valid_603580 = validateParameter(valid_603580, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_603580 != nil:
    section.add "Action", valid_603580
  var valid_603581 = query.getOrDefault("Version")
  valid_603581 = validateParameter(valid_603581, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603581 != nil:
    section.add "Version", valid_603581
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603582 = header.getOrDefault("X-Amz-Date")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Date", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Security-Token")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Security-Token", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Content-Sha256", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Algorithm")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Algorithm", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Signature")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Signature", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-SignedHeaders", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Credential")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Credential", valid_603588
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_603589 = formData.getOrDefault("LoadBalancerArn")
  valid_603589 = validateParameter(valid_603589, JString, required = true,
                                 default = nil)
  if valid_603589 != nil:
    section.add "LoadBalancerArn", valid_603589
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603590: Call_PostDescribeLoadBalancerAttributes_603577;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603590.validator(path, query, header, formData, body)
  let scheme = call_603590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603590.url(scheme.get, call_603590.host, call_603590.base,
                         call_603590.route, valid.getOrDefault("path"))
  result = hook(call_603590, url, valid)

proc call*(call_603591: Call_PostDescribeLoadBalancerAttributes_603577;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603592 = newJObject()
  var formData_603593 = newJObject()
  add(formData_603593, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603592, "Action", newJString(Action))
  add(query_603592, "Version", newJString(Version))
  result = call_603591.call(nil, query_603592, nil, formData_603593, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_603577(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_603578, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_603579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_603561 = ref object of OpenApiRestCall_602433
proc url_GetDescribeLoadBalancerAttributes_603563(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancerAttributes_603562(path: JsonNode;
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
  var valid_603564 = query.getOrDefault("Action")
  valid_603564 = validateParameter(valid_603564, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_603564 != nil:
    section.add "Action", valid_603564
  var valid_603565 = query.getOrDefault("LoadBalancerArn")
  valid_603565 = validateParameter(valid_603565, JString, required = true,
                                 default = nil)
  if valid_603565 != nil:
    section.add "LoadBalancerArn", valid_603565
  var valid_603566 = query.getOrDefault("Version")
  valid_603566 = validateParameter(valid_603566, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603566 != nil:
    section.add "Version", valid_603566
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603567 = header.getOrDefault("X-Amz-Date")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Date", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Security-Token")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Security-Token", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Content-Sha256", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Algorithm")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Algorithm", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Signature")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Signature", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-SignedHeaders", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Credential")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Credential", valid_603573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603574: Call_GetDescribeLoadBalancerAttributes_603561;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603574.validator(path, query, header, formData, body)
  let scheme = call_603574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603574.url(scheme.get, call_603574.host, call_603574.base,
                         call_603574.route, valid.getOrDefault("path"))
  result = hook(call_603574, url, valid)

proc call*(call_603575: Call_GetDescribeLoadBalancerAttributes_603561;
          LoadBalancerArn: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## <p>Describes the attributes for the specified Application Load Balancer or Network Load Balancer.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancers.html#load-balancer-attributes">Load Balancer Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   LoadBalancerArn: string (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Version: string (required)
  var query_603576 = newJObject()
  add(query_603576, "Action", newJString(Action))
  add(query_603576, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603576, "Version", newJString(Version))
  result = call_603575.call(nil, query_603576, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_603561(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_603562, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_603563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_603613 = ref object of OpenApiRestCall_602433
proc url_PostDescribeLoadBalancers_603615(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancers_603614(path: JsonNode; query: JsonNode;
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
  var valid_603616 = query.getOrDefault("Action")
  valid_603616 = validateParameter(valid_603616, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_603616 != nil:
    section.add "Action", valid_603616
  var valid_603617 = query.getOrDefault("Version")
  valid_603617 = validateParameter(valid_603617, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603617 != nil:
    section.add "Version", valid_603617
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603618 = header.getOrDefault("X-Amz-Date")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Date", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Security-Token")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Security-Token", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Content-Sha256", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Algorithm")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Algorithm", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Signature")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Signature", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-SignedHeaders", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Credential")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Credential", valid_603624
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
  var valid_603625 = formData.getOrDefault("Names")
  valid_603625 = validateParameter(valid_603625, JArray, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "Names", valid_603625
  var valid_603626 = formData.getOrDefault("Marker")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "Marker", valid_603626
  var valid_603627 = formData.getOrDefault("LoadBalancerArns")
  valid_603627 = validateParameter(valid_603627, JArray, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "LoadBalancerArns", valid_603627
  var valid_603628 = formData.getOrDefault("PageSize")
  valid_603628 = validateParameter(valid_603628, JInt, required = false, default = nil)
  if valid_603628 != nil:
    section.add "PageSize", valid_603628
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603629: Call_PostDescribeLoadBalancers_603613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_603629.validator(path, query, header, formData, body)
  let scheme = call_603629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603629.url(scheme.get, call_603629.host, call_603629.base,
                         call_603629.route, valid.getOrDefault("path"))
  result = hook(call_603629, url, valid)

proc call*(call_603630: Call_PostDescribeLoadBalancers_603613;
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
  var query_603631 = newJObject()
  var formData_603632 = newJObject()
  if Names != nil:
    formData_603632.add "Names", Names
  add(formData_603632, "Marker", newJString(Marker))
  add(query_603631, "Action", newJString(Action))
  if LoadBalancerArns != nil:
    formData_603632.add "LoadBalancerArns", LoadBalancerArns
  add(formData_603632, "PageSize", newJInt(PageSize))
  add(query_603631, "Version", newJString(Version))
  result = call_603630.call(nil, query_603631, nil, formData_603632, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_603613(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_603614, base: "/",
    url: url_PostDescribeLoadBalancers_603615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_603594 = ref object of OpenApiRestCall_602433
proc url_GetDescribeLoadBalancers_603596(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancers_603595(path: JsonNode; query: JsonNode;
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
  var valid_603597 = query.getOrDefault("Names")
  valid_603597 = validateParameter(valid_603597, JArray, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "Names", valid_603597
  var valid_603598 = query.getOrDefault("PageSize")
  valid_603598 = validateParameter(valid_603598, JInt, required = false, default = nil)
  if valid_603598 != nil:
    section.add "PageSize", valid_603598
  var valid_603599 = query.getOrDefault("LoadBalancerArns")
  valid_603599 = validateParameter(valid_603599, JArray, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "LoadBalancerArns", valid_603599
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603600 = query.getOrDefault("Action")
  valid_603600 = validateParameter(valid_603600, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_603600 != nil:
    section.add "Action", valid_603600
  var valid_603601 = query.getOrDefault("Marker")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "Marker", valid_603601
  var valid_603602 = query.getOrDefault("Version")
  valid_603602 = validateParameter(valid_603602, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603602 != nil:
    section.add "Version", valid_603602
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603603 = header.getOrDefault("X-Amz-Date")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Date", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Security-Token")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Security-Token", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Content-Sha256", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Algorithm")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Algorithm", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Signature")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Signature", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-SignedHeaders", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Credential")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Credential", valid_603609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603610: Call_GetDescribeLoadBalancers_603594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified load balancers or all of your load balancers.</p> <p>To describe the listeners for a load balancer, use <a>DescribeListeners</a>. To describe the attributes for a load balancer, use <a>DescribeLoadBalancerAttributes</a>.</p>
  ## 
  let valid = call_603610.validator(path, query, header, formData, body)
  let scheme = call_603610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603610.url(scheme.get, call_603610.host, call_603610.base,
                         call_603610.route, valid.getOrDefault("path"))
  result = hook(call_603610, url, valid)

proc call*(call_603611: Call_GetDescribeLoadBalancers_603594;
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
  var query_603612 = newJObject()
  if Names != nil:
    query_603612.add "Names", Names
  add(query_603612, "PageSize", newJInt(PageSize))
  if LoadBalancerArns != nil:
    query_603612.add "LoadBalancerArns", LoadBalancerArns
  add(query_603612, "Action", newJString(Action))
  add(query_603612, "Marker", newJString(Marker))
  add(query_603612, "Version", newJString(Version))
  result = call_603611.call(nil, query_603612, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_603594(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_603595, base: "/",
    url: url_GetDescribeLoadBalancers_603596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRules_603652 = ref object of OpenApiRestCall_602433
proc url_PostDescribeRules_603654(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeRules_603653(path: JsonNode; query: JsonNode;
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
  var valid_603655 = query.getOrDefault("Action")
  valid_603655 = validateParameter(valid_603655, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_603655 != nil:
    section.add "Action", valid_603655
  var valid_603656 = query.getOrDefault("Version")
  valid_603656 = validateParameter(valid_603656, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603656 != nil:
    section.add "Version", valid_603656
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603657 = header.getOrDefault("X-Amz-Date")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Date", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Security-Token")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Security-Token", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Content-Sha256", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Algorithm")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Algorithm", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Signature")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Signature", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-SignedHeaders", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Credential")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Credential", valid_603663
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
  var valid_603664 = formData.getOrDefault("ListenerArn")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "ListenerArn", valid_603664
  var valid_603665 = formData.getOrDefault("RuleArns")
  valid_603665 = validateParameter(valid_603665, JArray, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "RuleArns", valid_603665
  var valid_603666 = formData.getOrDefault("Marker")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "Marker", valid_603666
  var valid_603667 = formData.getOrDefault("PageSize")
  valid_603667 = validateParameter(valid_603667, JInt, required = false, default = nil)
  if valid_603667 != nil:
    section.add "PageSize", valid_603667
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603668: Call_PostDescribeRules_603652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_603668.validator(path, query, header, formData, body)
  let scheme = call_603668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603668.url(scheme.get, call_603668.host, call_603668.base,
                         call_603668.route, valid.getOrDefault("path"))
  result = hook(call_603668, url, valid)

proc call*(call_603669: Call_PostDescribeRules_603652; ListenerArn: string = "";
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
  var query_603670 = newJObject()
  var formData_603671 = newJObject()
  add(formData_603671, "ListenerArn", newJString(ListenerArn))
  if RuleArns != nil:
    formData_603671.add "RuleArns", RuleArns
  add(formData_603671, "Marker", newJString(Marker))
  add(query_603670, "Action", newJString(Action))
  add(formData_603671, "PageSize", newJInt(PageSize))
  add(query_603670, "Version", newJString(Version))
  result = call_603669.call(nil, query_603670, nil, formData_603671, nil)

var postDescribeRules* = Call_PostDescribeRules_603652(name: "postDescribeRules",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_PostDescribeRules_603653,
    base: "/", url: url_PostDescribeRules_603654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRules_603633 = ref object of OpenApiRestCall_602433
proc url_GetDescribeRules_603635(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeRules_603634(path: JsonNode; query: JsonNode;
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
  var valid_603636 = query.getOrDefault("PageSize")
  valid_603636 = validateParameter(valid_603636, JInt, required = false, default = nil)
  if valid_603636 != nil:
    section.add "PageSize", valid_603636
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603637 = query.getOrDefault("Action")
  valid_603637 = validateParameter(valid_603637, JString, required = true,
                                 default = newJString("DescribeRules"))
  if valid_603637 != nil:
    section.add "Action", valid_603637
  var valid_603638 = query.getOrDefault("Marker")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "Marker", valid_603638
  var valid_603639 = query.getOrDefault("ListenerArn")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "ListenerArn", valid_603639
  var valid_603640 = query.getOrDefault("Version")
  valid_603640 = validateParameter(valid_603640, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603640 != nil:
    section.add "Version", valid_603640
  var valid_603641 = query.getOrDefault("RuleArns")
  valid_603641 = validateParameter(valid_603641, JArray, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "RuleArns", valid_603641
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603642 = header.getOrDefault("X-Amz-Date")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Date", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-Security-Token")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Security-Token", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Content-Sha256", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Algorithm")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Algorithm", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Signature")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Signature", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-SignedHeaders", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Credential")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Credential", valid_603648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603649: Call_GetDescribeRules_603633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified rules or the rules for the specified listener. You must specify either a listener or one or more rules.
  ## 
  let valid = call_603649.validator(path, query, header, formData, body)
  let scheme = call_603649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603649.url(scheme.get, call_603649.host, call_603649.base,
                         call_603649.route, valid.getOrDefault("path"))
  result = hook(call_603649, url, valid)

proc call*(call_603650: Call_GetDescribeRules_603633; PageSize: int = 0;
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
  var query_603651 = newJObject()
  add(query_603651, "PageSize", newJInt(PageSize))
  add(query_603651, "Action", newJString(Action))
  add(query_603651, "Marker", newJString(Marker))
  add(query_603651, "ListenerArn", newJString(ListenerArn))
  add(query_603651, "Version", newJString(Version))
  if RuleArns != nil:
    query_603651.add "RuleArns", RuleArns
  result = call_603650.call(nil, query_603651, nil, nil, nil)

var getDescribeRules* = Call_GetDescribeRules_603633(name: "getDescribeRules",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeRules", validator: validate_GetDescribeRules_603634,
    base: "/", url: url_GetDescribeRules_603635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSSLPolicies_603690 = ref object of OpenApiRestCall_602433
proc url_PostDescribeSSLPolicies_603692(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeSSLPolicies_603691(path: JsonNode; query: JsonNode;
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
  var valid_603693 = query.getOrDefault("Action")
  valid_603693 = validateParameter(valid_603693, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_603693 != nil:
    section.add "Action", valid_603693
  var valid_603694 = query.getOrDefault("Version")
  valid_603694 = validateParameter(valid_603694, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603694 != nil:
    section.add "Version", valid_603694
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603695 = header.getOrDefault("X-Amz-Date")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Date", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-Security-Token")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Security-Token", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Content-Sha256", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Algorithm")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Algorithm", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Signature")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Signature", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-SignedHeaders", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Credential")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Credential", valid_603701
  result.add "header", section
  ## parameters in `formData` object:
  ##   Names: JArray
  ##        : The names of the policies.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_603702 = formData.getOrDefault("Names")
  valid_603702 = validateParameter(valid_603702, JArray, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "Names", valid_603702
  var valid_603703 = formData.getOrDefault("Marker")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "Marker", valid_603703
  var valid_603704 = formData.getOrDefault("PageSize")
  valid_603704 = validateParameter(valid_603704, JInt, required = false, default = nil)
  if valid_603704 != nil:
    section.add "PageSize", valid_603704
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603705: Call_PostDescribeSSLPolicies_603690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603705.validator(path, query, header, formData, body)
  let scheme = call_603705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603705.url(scheme.get, call_603705.host, call_603705.base,
                         call_603705.route, valid.getOrDefault("path"))
  result = hook(call_603705, url, valid)

proc call*(call_603706: Call_PostDescribeSSLPolicies_603690; Names: JsonNode = nil;
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
  var query_603707 = newJObject()
  var formData_603708 = newJObject()
  if Names != nil:
    formData_603708.add "Names", Names
  add(formData_603708, "Marker", newJString(Marker))
  add(query_603707, "Action", newJString(Action))
  add(formData_603708, "PageSize", newJInt(PageSize))
  add(query_603707, "Version", newJString(Version))
  result = call_603706.call(nil, query_603707, nil, formData_603708, nil)

var postDescribeSSLPolicies* = Call_PostDescribeSSLPolicies_603690(
    name: "postDescribeSSLPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_PostDescribeSSLPolicies_603691, base: "/",
    url: url_PostDescribeSSLPolicies_603692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSSLPolicies_603672 = ref object of OpenApiRestCall_602433
proc url_GetDescribeSSLPolicies_603674(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeSSLPolicies_603673(path: JsonNode; query: JsonNode;
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
  var valid_603675 = query.getOrDefault("Names")
  valid_603675 = validateParameter(valid_603675, JArray, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "Names", valid_603675
  var valid_603676 = query.getOrDefault("PageSize")
  valid_603676 = validateParameter(valid_603676, JInt, required = false, default = nil)
  if valid_603676 != nil:
    section.add "PageSize", valid_603676
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603677 = query.getOrDefault("Action")
  valid_603677 = validateParameter(valid_603677, JString, required = true,
                                 default = newJString("DescribeSSLPolicies"))
  if valid_603677 != nil:
    section.add "Action", valid_603677
  var valid_603678 = query.getOrDefault("Marker")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "Marker", valid_603678
  var valid_603679 = query.getOrDefault("Version")
  valid_603679 = validateParameter(valid_603679, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603679 != nil:
    section.add "Version", valid_603679
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603680 = header.getOrDefault("X-Amz-Date")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Date", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-Security-Token")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-Security-Token", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Content-Sha256", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Algorithm")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Algorithm", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Signature")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Signature", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-SignedHeaders", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Credential")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Credential", valid_603686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603687: Call_GetDescribeSSLPolicies_603672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified policies or all policies used for SSL negotiation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies">Security Policies</a> in the <i>Application Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603687.validator(path, query, header, formData, body)
  let scheme = call_603687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603687.url(scheme.get, call_603687.host, call_603687.base,
                         call_603687.route, valid.getOrDefault("path"))
  result = hook(call_603687, url, valid)

proc call*(call_603688: Call_GetDescribeSSLPolicies_603672; Names: JsonNode = nil;
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
  var query_603689 = newJObject()
  if Names != nil:
    query_603689.add "Names", Names
  add(query_603689, "PageSize", newJInt(PageSize))
  add(query_603689, "Action", newJString(Action))
  add(query_603689, "Marker", newJString(Marker))
  add(query_603689, "Version", newJString(Version))
  result = call_603688.call(nil, query_603689, nil, nil, nil)

var getDescribeSSLPolicies* = Call_GetDescribeSSLPolicies_603672(
    name: "getDescribeSSLPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeSSLPolicies",
    validator: validate_GetDescribeSSLPolicies_603673, base: "/",
    url: url_GetDescribeSSLPolicies_603674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_603725 = ref object of OpenApiRestCall_602433
proc url_PostDescribeTags_603727(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTags_603726(path: JsonNode; query: JsonNode;
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
  var valid_603728 = query.getOrDefault("Action")
  valid_603728 = validateParameter(valid_603728, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_603728 != nil:
    section.add "Action", valid_603728
  var valid_603729 = query.getOrDefault("Version")
  valid_603729 = validateParameter(valid_603729, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603729 != nil:
    section.add "Version", valid_603729
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603730 = header.getOrDefault("X-Amz-Date")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Date", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Security-Token")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Security-Token", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Content-Sha256", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Algorithm")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Algorithm", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Signature")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Signature", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-SignedHeaders", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Credential")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Credential", valid_603736
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_603737 = formData.getOrDefault("ResourceArns")
  valid_603737 = validateParameter(valid_603737, JArray, required = true, default = nil)
  if valid_603737 != nil:
    section.add "ResourceArns", valid_603737
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603738: Call_PostDescribeTags_603725; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_603738.validator(path, query, header, formData, body)
  let scheme = call_603738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603738.url(scheme.get, call_603738.host, call_603738.base,
                         call_603738.route, valid.getOrDefault("path"))
  result = hook(call_603738, url, valid)

proc call*(call_603739: Call_PostDescribeTags_603725; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603740 = newJObject()
  var formData_603741 = newJObject()
  if ResourceArns != nil:
    formData_603741.add "ResourceArns", ResourceArns
  add(query_603740, "Action", newJString(Action))
  add(query_603740, "Version", newJString(Version))
  result = call_603739.call(nil, query_603740, nil, formData_603741, nil)

var postDescribeTags* = Call_PostDescribeTags_603725(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_603726,
    base: "/", url: url_PostDescribeTags_603727,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_603709 = ref object of OpenApiRestCall_602433
proc url_GetDescribeTags_603711(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTags_603710(path: JsonNode; query: JsonNode;
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
  var valid_603712 = query.getOrDefault("Action")
  valid_603712 = validateParameter(valid_603712, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_603712 != nil:
    section.add "Action", valid_603712
  var valid_603713 = query.getOrDefault("ResourceArns")
  valid_603713 = validateParameter(valid_603713, JArray, required = true, default = nil)
  if valid_603713 != nil:
    section.add "ResourceArns", valid_603713
  var valid_603714 = query.getOrDefault("Version")
  valid_603714 = validateParameter(valid_603714, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603714 != nil:
    section.add "Version", valid_603714
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603715 = header.getOrDefault("X-Amz-Date")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Date", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Security-Token")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Security-Token", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Content-Sha256", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Algorithm")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Algorithm", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Signature")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Signature", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-SignedHeaders", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Credential")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Credential", valid_603721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603722: Call_GetDescribeTags_603709; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ## 
  let valid = call_603722.validator(path, query, header, formData, body)
  let scheme = call_603722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603722.url(scheme.get, call_603722.host, call_603722.base,
                         call_603722.route, valid.getOrDefault("path"))
  result = hook(call_603722, url, valid)

proc call*(call_603723: Call_GetDescribeTags_603709; ResourceArns: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2015-12-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags for the specified resources. You can describe the tags for one or more Application Load Balancers, Network Load Balancers, and target groups.
  ##   Action: string (required)
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Names (ARN) of the resources.
  ##   Version: string (required)
  var query_603724 = newJObject()
  add(query_603724, "Action", newJString(Action))
  if ResourceArns != nil:
    query_603724.add "ResourceArns", ResourceArns
  add(query_603724, "Version", newJString(Version))
  result = call_603723.call(nil, query_603724, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_603709(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_603710,
    base: "/", url: url_GetDescribeTags_603711, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroupAttributes_603758 = ref object of OpenApiRestCall_602433
proc url_PostDescribeTargetGroupAttributes_603760(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTargetGroupAttributes_603759(path: JsonNode;
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
  var valid_603761 = query.getOrDefault("Action")
  valid_603761 = validateParameter(valid_603761, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
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
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_603770 = formData.getOrDefault("TargetGroupArn")
  valid_603770 = validateParameter(valid_603770, JString, required = true,
                                 default = nil)
  if valid_603770 != nil:
    section.add "TargetGroupArn", valid_603770
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603771: Call_PostDescribeTargetGroupAttributes_603758;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603771.validator(path, query, header, formData, body)
  let scheme = call_603771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603771.url(scheme.get, call_603771.host, call_603771.base,
                         call_603771.route, valid.getOrDefault("path"))
  result = hook(call_603771, url, valid)

proc call*(call_603772: Call_PostDescribeTargetGroupAttributes_603758;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## postDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Version: string (required)
  var query_603773 = newJObject()
  var formData_603774 = newJObject()
  add(query_603773, "Action", newJString(Action))
  add(formData_603774, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603773, "Version", newJString(Version))
  result = call_603772.call(nil, query_603773, nil, formData_603774, nil)

var postDescribeTargetGroupAttributes* = Call_PostDescribeTargetGroupAttributes_603758(
    name: "postDescribeTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_PostDescribeTargetGroupAttributes_603759, base: "/",
    url: url_PostDescribeTargetGroupAttributes_603760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroupAttributes_603742 = ref object of OpenApiRestCall_602433
proc url_GetDescribeTargetGroupAttributes_603744(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTargetGroupAttributes_603743(path: JsonNode;
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
  var valid_603745 = query.getOrDefault("TargetGroupArn")
  valid_603745 = validateParameter(valid_603745, JString, required = true,
                                 default = nil)
  if valid_603745 != nil:
    section.add "TargetGroupArn", valid_603745
  var valid_603746 = query.getOrDefault("Action")
  valid_603746 = validateParameter(valid_603746, JString, required = true, default = newJString(
      "DescribeTargetGroupAttributes"))
  if valid_603746 != nil:
    section.add "Action", valid_603746
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

proc call*(call_603755: Call_GetDescribeTargetGroupAttributes_603742;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603755.validator(path, query, header, formData, body)
  let scheme = call_603755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603755.url(scheme.get, call_603755.host, call_603755.base,
                         call_603755.route, valid.getOrDefault("path"))
  result = hook(call_603755, url, valid)

proc call*(call_603756: Call_GetDescribeTargetGroupAttributes_603742;
          TargetGroupArn: string;
          Action: string = "DescribeTargetGroupAttributes";
          Version: string = "2015-12-01"): Recallable =
  ## getDescribeTargetGroupAttributes
  ## <p>Describes the attributes for the specified target group.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Application Load Balancers Guide</i> or <a href="https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#target-group-attributes">Target Group Attributes</a> in the <i>Network Load Balancers Guide</i>.</p>
  ##   TargetGroupArn: string (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603757 = newJObject()
  add(query_603757, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603757, "Action", newJString(Action))
  add(query_603757, "Version", newJString(Version))
  result = call_603756.call(nil, query_603757, nil, nil, nil)

var getDescribeTargetGroupAttributes* = Call_GetDescribeTargetGroupAttributes_603742(
    name: "getDescribeTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroupAttributes",
    validator: validate_GetDescribeTargetGroupAttributes_603743, base: "/",
    url: url_GetDescribeTargetGroupAttributes_603744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetGroups_603795 = ref object of OpenApiRestCall_602433
proc url_PostDescribeTargetGroups_603797(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTargetGroups_603796(path: JsonNode; query: JsonNode;
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
  var valid_603798 = query.getOrDefault("Action")
  valid_603798 = validateParameter(valid_603798, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_603798 != nil:
    section.add "Action", valid_603798
  var valid_603799 = query.getOrDefault("Version")
  valid_603799 = validateParameter(valid_603799, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603799 != nil:
    section.add "Version", valid_603799
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603800 = header.getOrDefault("X-Amz-Date")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Date", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Security-Token")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Security-Token", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Content-Sha256", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Algorithm")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Algorithm", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Signature")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Signature", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-SignedHeaders", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Credential")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Credential", valid_603806
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
  var valid_603807 = formData.getOrDefault("LoadBalancerArn")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "LoadBalancerArn", valid_603807
  var valid_603808 = formData.getOrDefault("TargetGroupArns")
  valid_603808 = validateParameter(valid_603808, JArray, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "TargetGroupArns", valid_603808
  var valid_603809 = formData.getOrDefault("Names")
  valid_603809 = validateParameter(valid_603809, JArray, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "Names", valid_603809
  var valid_603810 = formData.getOrDefault("Marker")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "Marker", valid_603810
  var valid_603811 = formData.getOrDefault("PageSize")
  valid_603811 = validateParameter(valid_603811, JInt, required = false, default = nil)
  if valid_603811 != nil:
    section.add "PageSize", valid_603811
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603812: Call_PostDescribeTargetGroups_603795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_603812.validator(path, query, header, formData, body)
  let scheme = call_603812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603812.url(scheme.get, call_603812.host, call_603812.base,
                         call_603812.route, valid.getOrDefault("path"))
  result = hook(call_603812, url, valid)

proc call*(call_603813: Call_PostDescribeTargetGroups_603795;
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
  var query_603814 = newJObject()
  var formData_603815 = newJObject()
  add(formData_603815, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    formData_603815.add "TargetGroupArns", TargetGroupArns
  if Names != nil:
    formData_603815.add "Names", Names
  add(formData_603815, "Marker", newJString(Marker))
  add(query_603814, "Action", newJString(Action))
  add(formData_603815, "PageSize", newJInt(PageSize))
  add(query_603814, "Version", newJString(Version))
  result = call_603813.call(nil, query_603814, nil, formData_603815, nil)

var postDescribeTargetGroups* = Call_PostDescribeTargetGroups_603795(
    name: "postDescribeTargetGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_PostDescribeTargetGroups_603796, base: "/",
    url: url_PostDescribeTargetGroups_603797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetGroups_603775 = ref object of OpenApiRestCall_602433
proc url_GetDescribeTargetGroups_603777(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTargetGroups_603776(path: JsonNode; query: JsonNode;
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
  var valid_603778 = query.getOrDefault("Names")
  valid_603778 = validateParameter(valid_603778, JArray, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "Names", valid_603778
  var valid_603779 = query.getOrDefault("PageSize")
  valid_603779 = validateParameter(valid_603779, JInt, required = false, default = nil)
  if valid_603779 != nil:
    section.add "PageSize", valid_603779
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603780 = query.getOrDefault("Action")
  valid_603780 = validateParameter(valid_603780, JString, required = true,
                                 default = newJString("DescribeTargetGroups"))
  if valid_603780 != nil:
    section.add "Action", valid_603780
  var valid_603781 = query.getOrDefault("Marker")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "Marker", valid_603781
  var valid_603782 = query.getOrDefault("LoadBalancerArn")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "LoadBalancerArn", valid_603782
  var valid_603783 = query.getOrDefault("TargetGroupArns")
  valid_603783 = validateParameter(valid_603783, JArray, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "TargetGroupArns", valid_603783
  var valid_603784 = query.getOrDefault("Version")
  valid_603784 = validateParameter(valid_603784, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603784 != nil:
    section.add "Version", valid_603784
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603785 = header.getOrDefault("X-Amz-Date")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Date", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Security-Token")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Security-Token", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Content-Sha256", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Algorithm")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Algorithm", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Signature")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Signature", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-SignedHeaders", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Credential")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Credential", valid_603791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603792: Call_GetDescribeTargetGroups_603775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified target groups or all of your target groups. By default, all target groups are described. Alternatively, you can specify one of the following to filter the results: the ARN of the load balancer, the names of one or more target groups, or the ARNs of one or more target groups.</p> <p>To describe the targets for a target group, use <a>DescribeTargetHealth</a>. To describe the attributes of a target group, use <a>DescribeTargetGroupAttributes</a>.</p>
  ## 
  let valid = call_603792.validator(path, query, header, formData, body)
  let scheme = call_603792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603792.url(scheme.get, call_603792.host, call_603792.base,
                         call_603792.route, valid.getOrDefault("path"))
  result = hook(call_603792, url, valid)

proc call*(call_603793: Call_GetDescribeTargetGroups_603775; Names: JsonNode = nil;
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
  var query_603794 = newJObject()
  if Names != nil:
    query_603794.add "Names", Names
  add(query_603794, "PageSize", newJInt(PageSize))
  add(query_603794, "Action", newJString(Action))
  add(query_603794, "Marker", newJString(Marker))
  add(query_603794, "LoadBalancerArn", newJString(LoadBalancerArn))
  if TargetGroupArns != nil:
    query_603794.add "TargetGroupArns", TargetGroupArns
  add(query_603794, "Version", newJString(Version))
  result = call_603793.call(nil, query_603794, nil, nil, nil)

var getDescribeTargetGroups* = Call_GetDescribeTargetGroups_603775(
    name: "getDescribeTargetGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetGroups",
    validator: validate_GetDescribeTargetGroups_603776, base: "/",
    url: url_GetDescribeTargetGroups_603777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTargetHealth_603833 = ref object of OpenApiRestCall_602433
proc url_PostDescribeTargetHealth_603835(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTargetHealth_603834(path: JsonNode; query: JsonNode;
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
  var valid_603836 = query.getOrDefault("Action")
  valid_603836 = validateParameter(valid_603836, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_603836 != nil:
    section.add "Action", valid_603836
  var valid_603837 = query.getOrDefault("Version")
  valid_603837 = validateParameter(valid_603837, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603837 != nil:
    section.add "Version", valid_603837
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603838 = header.getOrDefault("X-Amz-Date")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Date", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Security-Token")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Security-Token", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Content-Sha256", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Algorithm")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Algorithm", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Signature")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Signature", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-SignedHeaders", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-Credential")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Credential", valid_603844
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray
  ##          : The targets.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  var valid_603845 = formData.getOrDefault("Targets")
  valid_603845 = validateParameter(valid_603845, JArray, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "Targets", valid_603845
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_603846 = formData.getOrDefault("TargetGroupArn")
  valid_603846 = validateParameter(valid_603846, JString, required = true,
                                 default = nil)
  if valid_603846 != nil:
    section.add "TargetGroupArn", valid_603846
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603847: Call_PostDescribeTargetHealth_603833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_603847.validator(path, query, header, formData, body)
  let scheme = call_603847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603847.url(scheme.get, call_603847.host, call_603847.base,
                         call_603847.route, valid.getOrDefault("path"))
  result = hook(call_603847, url, valid)

proc call*(call_603848: Call_PostDescribeTargetHealth_603833;
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
  var query_603849 = newJObject()
  var formData_603850 = newJObject()
  if Targets != nil:
    formData_603850.add "Targets", Targets
  add(query_603849, "Action", newJString(Action))
  add(formData_603850, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603849, "Version", newJString(Version))
  result = call_603848.call(nil, query_603849, nil, formData_603850, nil)

var postDescribeTargetHealth* = Call_PostDescribeTargetHealth_603833(
    name: "postDescribeTargetHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_PostDescribeTargetHealth_603834, base: "/",
    url: url_PostDescribeTargetHealth_603835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTargetHealth_603816 = ref object of OpenApiRestCall_602433
proc url_GetDescribeTargetHealth_603818(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTargetHealth_603817(path: JsonNode; query: JsonNode;
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
  var valid_603819 = query.getOrDefault("Targets")
  valid_603819 = validateParameter(valid_603819, JArray, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "Targets", valid_603819
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_603820 = query.getOrDefault("TargetGroupArn")
  valid_603820 = validateParameter(valid_603820, JString, required = true,
                                 default = nil)
  if valid_603820 != nil:
    section.add "TargetGroupArn", valid_603820
  var valid_603821 = query.getOrDefault("Action")
  valid_603821 = validateParameter(valid_603821, JString, required = true,
                                 default = newJString("DescribeTargetHealth"))
  if valid_603821 != nil:
    section.add "Action", valid_603821
  var valid_603822 = query.getOrDefault("Version")
  valid_603822 = validateParameter(valid_603822, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603822 != nil:
    section.add "Version", valid_603822
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603823 = header.getOrDefault("X-Amz-Date")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Date", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Security-Token")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Security-Token", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Content-Sha256", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Algorithm")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Algorithm", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Signature")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Signature", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-SignedHeaders", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Credential")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Credential", valid_603829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603830: Call_GetDescribeTargetHealth_603816; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the health of the specified targets or all of your targets.
  ## 
  let valid = call_603830.validator(path, query, header, formData, body)
  let scheme = call_603830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603830.url(scheme.get, call_603830.host, call_603830.base,
                         call_603830.route, valid.getOrDefault("path"))
  result = hook(call_603830, url, valid)

proc call*(call_603831: Call_GetDescribeTargetHealth_603816;
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
  var query_603832 = newJObject()
  if Targets != nil:
    query_603832.add "Targets", Targets
  add(query_603832, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603832, "Action", newJString(Action))
  add(query_603832, "Version", newJString(Version))
  result = call_603831.call(nil, query_603832, nil, nil, nil)

var getDescribeTargetHealth* = Call_GetDescribeTargetHealth_603816(
    name: "getDescribeTargetHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTargetHealth",
    validator: validate_GetDescribeTargetHealth_603817, base: "/",
    url: url_GetDescribeTargetHealth_603818, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyListener_603872 = ref object of OpenApiRestCall_602433
proc url_PostModifyListener_603874(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyListener_603873(path: JsonNode; query: JsonNode;
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
  var valid_603875 = query.getOrDefault("Action")
  valid_603875 = validateParameter(valid_603875, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_603875 != nil:
    section.add "Action", valid_603875
  var valid_603876 = query.getOrDefault("Version")
  valid_603876 = validateParameter(valid_603876, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603876 != nil:
    section.add "Version", valid_603876
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603877 = header.getOrDefault("X-Amz-Date")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Date", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Security-Token")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Security-Token", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-Content-Sha256", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-Algorithm")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Algorithm", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Signature")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Signature", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-SignedHeaders", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-Credential")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Credential", valid_603883
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
  var valid_603884 = formData.getOrDefault("Certificates")
  valid_603884 = validateParameter(valid_603884, JArray, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "Certificates", valid_603884
  assert formData != nil,
        "formData argument is necessary due to required `ListenerArn` field"
  var valid_603885 = formData.getOrDefault("ListenerArn")
  valid_603885 = validateParameter(valid_603885, JString, required = true,
                                 default = nil)
  if valid_603885 != nil:
    section.add "ListenerArn", valid_603885
  var valid_603886 = formData.getOrDefault("Port")
  valid_603886 = validateParameter(valid_603886, JInt, required = false, default = nil)
  if valid_603886 != nil:
    section.add "Port", valid_603886
  var valid_603887 = formData.getOrDefault("Protocol")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603887 != nil:
    section.add "Protocol", valid_603887
  var valid_603888 = formData.getOrDefault("SslPolicy")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "SslPolicy", valid_603888
  var valid_603889 = formData.getOrDefault("DefaultActions")
  valid_603889 = validateParameter(valid_603889, JArray, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "DefaultActions", valid_603889
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603890: Call_PostModifyListener_603872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_603890.validator(path, query, header, formData, body)
  let scheme = call_603890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603890.url(scheme.get, call_603890.host, call_603890.base,
                         call_603890.route, valid.getOrDefault("path"))
  result = hook(call_603890, url, valid)

proc call*(call_603891: Call_PostModifyListener_603872; ListenerArn: string;
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
  var query_603892 = newJObject()
  var formData_603893 = newJObject()
  if Certificates != nil:
    formData_603893.add "Certificates", Certificates
  add(formData_603893, "ListenerArn", newJString(ListenerArn))
  add(formData_603893, "Port", newJInt(Port))
  add(formData_603893, "Protocol", newJString(Protocol))
  add(query_603892, "Action", newJString(Action))
  add(formData_603893, "SslPolicy", newJString(SslPolicy))
  if DefaultActions != nil:
    formData_603893.add "DefaultActions", DefaultActions
  add(query_603892, "Version", newJString(Version))
  result = call_603891.call(nil, query_603892, nil, formData_603893, nil)

var postModifyListener* = Call_PostModifyListener_603872(
    name: "postModifyListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=ModifyListener",
    validator: validate_PostModifyListener_603873, base: "/",
    url: url_PostModifyListener_603874, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyListener_603851 = ref object of OpenApiRestCall_602433
proc url_GetModifyListener_603853(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyListener_603852(path: JsonNode; query: JsonNode;
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
  var valid_603854 = query.getOrDefault("DefaultActions")
  valid_603854 = validateParameter(valid_603854, JArray, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "DefaultActions", valid_603854
  var valid_603855 = query.getOrDefault("SslPolicy")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "SslPolicy", valid_603855
  var valid_603856 = query.getOrDefault("Protocol")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603856 != nil:
    section.add "Protocol", valid_603856
  var valid_603857 = query.getOrDefault("Certificates")
  valid_603857 = validateParameter(valid_603857, JArray, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "Certificates", valid_603857
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603858 = query.getOrDefault("Action")
  valid_603858 = validateParameter(valid_603858, JString, required = true,
                                 default = newJString("ModifyListener"))
  if valid_603858 != nil:
    section.add "Action", valid_603858
  var valid_603859 = query.getOrDefault("ListenerArn")
  valid_603859 = validateParameter(valid_603859, JString, required = true,
                                 default = nil)
  if valid_603859 != nil:
    section.add "ListenerArn", valid_603859
  var valid_603860 = query.getOrDefault("Port")
  valid_603860 = validateParameter(valid_603860, JInt, required = false, default = nil)
  if valid_603860 != nil:
    section.add "Port", valid_603860
  var valid_603861 = query.getOrDefault("Version")
  valid_603861 = validateParameter(valid_603861, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603861 != nil:
    section.add "Version", valid_603861
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603862 = header.getOrDefault("X-Amz-Date")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Date", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Security-Token")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Security-Token", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Content-Sha256", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Algorithm")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Algorithm", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Signature")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Signature", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-SignedHeaders", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Credential")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Credential", valid_603868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603869: Call_GetModifyListener_603851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified properties of the specified listener.</p> <p>Any properties that you do not specify retain their current values. However, changing the protocol from HTTPS to HTTP, or from TLS to TCP, removes the security policy and default certificate properties. If you change the protocol from HTTP to HTTPS, or from TCP to TLS, you must add the security policy and default certificate properties.</p>
  ## 
  let valid = call_603869.validator(path, query, header, formData, body)
  let scheme = call_603869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603869.url(scheme.get, call_603869.host, call_603869.base,
                         call_603869.route, valid.getOrDefault("path"))
  result = hook(call_603869, url, valid)

proc call*(call_603870: Call_GetModifyListener_603851; ListenerArn: string;
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
  var query_603871 = newJObject()
  if DefaultActions != nil:
    query_603871.add "DefaultActions", DefaultActions
  add(query_603871, "SslPolicy", newJString(SslPolicy))
  add(query_603871, "Protocol", newJString(Protocol))
  if Certificates != nil:
    query_603871.add "Certificates", Certificates
  add(query_603871, "Action", newJString(Action))
  add(query_603871, "ListenerArn", newJString(ListenerArn))
  add(query_603871, "Port", newJInt(Port))
  add(query_603871, "Version", newJString(Version))
  result = call_603870.call(nil, query_603871, nil, nil, nil)

var getModifyListener* = Call_GetModifyListener_603851(name: "getModifyListener",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyListener", validator: validate_GetModifyListener_603852,
    base: "/", url: url_GetModifyListener_603853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_603911 = ref object of OpenApiRestCall_602433
proc url_PostModifyLoadBalancerAttributes_603913(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyLoadBalancerAttributes_603912(path: JsonNode;
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
  var valid_603914 = query.getOrDefault("Action")
  valid_603914 = validateParameter(valid_603914, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_603914 != nil:
    section.add "Action", valid_603914
  var valid_603915 = query.getOrDefault("Version")
  valid_603915 = validateParameter(valid_603915, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603915 != nil:
    section.add "Version", valid_603915
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603916 = header.getOrDefault("X-Amz-Date")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Date", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Security-Token")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Security-Token", valid_603917
  var valid_603918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Content-Sha256", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Algorithm")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Algorithm", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Signature")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Signature", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-SignedHeaders", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Credential")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Credential", valid_603922
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   Attributes: JArray (required)
  ##             : The load balancer attributes.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_603923 = formData.getOrDefault("LoadBalancerArn")
  valid_603923 = validateParameter(valid_603923, JString, required = true,
                                 default = nil)
  if valid_603923 != nil:
    section.add "LoadBalancerArn", valid_603923
  var valid_603924 = formData.getOrDefault("Attributes")
  valid_603924 = validateParameter(valid_603924, JArray, required = true, default = nil)
  if valid_603924 != nil:
    section.add "Attributes", valid_603924
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603925: Call_PostModifyLoadBalancerAttributes_603911;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_603925.validator(path, query, header, formData, body)
  let scheme = call_603925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603925.url(scheme.get, call_603925.host, call_603925.base,
                         call_603925.route, valid.getOrDefault("path"))
  result = hook(call_603925, url, valid)

proc call*(call_603926: Call_PostModifyLoadBalancerAttributes_603911;
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
  var query_603927 = newJObject()
  var formData_603928 = newJObject()
  add(formData_603928, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Attributes != nil:
    formData_603928.add "Attributes", Attributes
  add(query_603927, "Action", newJString(Action))
  add(query_603927, "Version", newJString(Version))
  result = call_603926.call(nil, query_603927, nil, formData_603928, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_603911(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_603912, base: "/",
    url: url_PostModifyLoadBalancerAttributes_603913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_603894 = ref object of OpenApiRestCall_602433
proc url_GetModifyLoadBalancerAttributes_603896(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyLoadBalancerAttributes_603895(path: JsonNode;
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
  var valid_603897 = query.getOrDefault("Attributes")
  valid_603897 = validateParameter(valid_603897, JArray, required = true, default = nil)
  if valid_603897 != nil:
    section.add "Attributes", valid_603897
  var valid_603898 = query.getOrDefault("Action")
  valid_603898 = validateParameter(valid_603898, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_603898 != nil:
    section.add "Action", valid_603898
  var valid_603899 = query.getOrDefault("LoadBalancerArn")
  valid_603899 = validateParameter(valid_603899, JString, required = true,
                                 default = nil)
  if valid_603899 != nil:
    section.add "LoadBalancerArn", valid_603899
  var valid_603900 = query.getOrDefault("Version")
  valid_603900 = validateParameter(valid_603900, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603900 != nil:
    section.add "Version", valid_603900
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603901 = header.getOrDefault("X-Amz-Date")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Date", valid_603901
  var valid_603902 = header.getOrDefault("X-Amz-Security-Token")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Security-Token", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Content-Sha256", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Algorithm")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Algorithm", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-Signature")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-Signature", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-SignedHeaders", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Credential")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Credential", valid_603907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603908: Call_GetModifyLoadBalancerAttributes_603894;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the specified attributes of the specified Application Load Balancer or Network Load Balancer.</p> <p>If any of the specified attributes can't be modified as requested, the call fails. Any existing attributes that you do not modify retain their current values.</p>
  ## 
  let valid = call_603908.validator(path, query, header, formData, body)
  let scheme = call_603908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603908.url(scheme.get, call_603908.host, call_603908.base,
                         call_603908.route, valid.getOrDefault("path"))
  result = hook(call_603908, url, valid)

proc call*(call_603909: Call_GetModifyLoadBalancerAttributes_603894;
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
  var query_603910 = newJObject()
  if Attributes != nil:
    query_603910.add "Attributes", Attributes
  add(query_603910, "Action", newJString(Action))
  add(query_603910, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_603910, "Version", newJString(Version))
  result = call_603909.call(nil, query_603910, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_603894(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_603895, base: "/",
    url: url_GetModifyLoadBalancerAttributes_603896,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyRule_603947 = ref object of OpenApiRestCall_602433
proc url_PostModifyRule_603949(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyRule_603948(path: JsonNode; query: JsonNode;
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
  var valid_603950 = query.getOrDefault("Action")
  valid_603950 = validateParameter(valid_603950, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_603950 != nil:
    section.add "Action", valid_603950
  var valid_603951 = query.getOrDefault("Version")
  valid_603951 = validateParameter(valid_603951, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603951 != nil:
    section.add "Version", valid_603951
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603952 = header.getOrDefault("X-Amz-Date")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Date", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Security-Token")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Security-Token", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Content-Sha256", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Algorithm")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Algorithm", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Signature")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Signature", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-SignedHeaders", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Credential")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Credential", valid_603958
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
  var valid_603959 = formData.getOrDefault("RuleArn")
  valid_603959 = validateParameter(valid_603959, JString, required = true,
                                 default = nil)
  if valid_603959 != nil:
    section.add "RuleArn", valid_603959
  var valid_603960 = formData.getOrDefault("Actions")
  valid_603960 = validateParameter(valid_603960, JArray, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "Actions", valid_603960
  var valid_603961 = formData.getOrDefault("Conditions")
  valid_603961 = validateParameter(valid_603961, JArray, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "Conditions", valid_603961
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603962: Call_PostModifyRule_603947; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_603962.validator(path, query, header, formData, body)
  let scheme = call_603962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603962.url(scheme.get, call_603962.host, call_603962.base,
                         call_603962.route, valid.getOrDefault("path"))
  result = hook(call_603962, url, valid)

proc call*(call_603963: Call_PostModifyRule_603947; RuleArn: string;
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
  var query_603964 = newJObject()
  var formData_603965 = newJObject()
  add(formData_603965, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    formData_603965.add "Actions", Actions
  if Conditions != nil:
    formData_603965.add "Conditions", Conditions
  add(query_603964, "Action", newJString(Action))
  add(query_603964, "Version", newJString(Version))
  result = call_603963.call(nil, query_603964, nil, formData_603965, nil)

var postModifyRule* = Call_PostModifyRule_603947(name: "postModifyRule",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_PostModifyRule_603948,
    base: "/", url: url_PostModifyRule_603949, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyRule_603929 = ref object of OpenApiRestCall_602433
proc url_GetModifyRule_603931(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyRule_603930(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603932 = query.getOrDefault("Conditions")
  valid_603932 = validateParameter(valid_603932, JArray, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "Conditions", valid_603932
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603933 = query.getOrDefault("Action")
  valid_603933 = validateParameter(valid_603933, JString, required = true,
                                 default = newJString("ModifyRule"))
  if valid_603933 != nil:
    section.add "Action", valid_603933
  var valid_603934 = query.getOrDefault("RuleArn")
  valid_603934 = validateParameter(valid_603934, JString, required = true,
                                 default = nil)
  if valid_603934 != nil:
    section.add "RuleArn", valid_603934
  var valid_603935 = query.getOrDefault("Actions")
  valid_603935 = validateParameter(valid_603935, JArray, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "Actions", valid_603935
  var valid_603936 = query.getOrDefault("Version")
  valid_603936 = validateParameter(valid_603936, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603936 != nil:
    section.add "Version", valid_603936
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603937 = header.getOrDefault("X-Amz-Date")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Date", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Security-Token")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Security-Token", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Content-Sha256", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Algorithm")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Algorithm", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Signature")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Signature", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-SignedHeaders", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-Credential")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Credential", valid_603943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603944: Call_GetModifyRule_603929; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified rule.</p> <p>Any existing properties that you do not modify retain their current values.</p> <p>To modify the actions for the default rule, use <a>ModifyListener</a>.</p>
  ## 
  let valid = call_603944.validator(path, query, header, formData, body)
  let scheme = call_603944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603944.url(scheme.get, call_603944.host, call_603944.base,
                         call_603944.route, valid.getOrDefault("path"))
  result = hook(call_603944, url, valid)

proc call*(call_603945: Call_GetModifyRule_603929; RuleArn: string;
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
  var query_603946 = newJObject()
  if Conditions != nil:
    query_603946.add "Conditions", Conditions
  add(query_603946, "Action", newJString(Action))
  add(query_603946, "RuleArn", newJString(RuleArn))
  if Actions != nil:
    query_603946.add "Actions", Actions
  add(query_603946, "Version", newJString(Version))
  result = call_603945.call(nil, query_603946, nil, nil, nil)

var getModifyRule* = Call_GetModifyRule_603929(name: "getModifyRule",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyRule", validator: validate_GetModifyRule_603930,
    base: "/", url: url_GetModifyRule_603931, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroup_603991 = ref object of OpenApiRestCall_602433
proc url_PostModifyTargetGroup_603993(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyTargetGroup_603992(path: JsonNode; query: JsonNode;
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
  var valid_603994 = query.getOrDefault("Action")
  valid_603994 = validateParameter(valid_603994, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_603994 != nil:
    section.add "Action", valid_603994
  var valid_603995 = query.getOrDefault("Version")
  valid_603995 = validateParameter(valid_603995, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603995 != nil:
    section.add "Version", valid_603995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603996 = header.getOrDefault("X-Amz-Date")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-Date", valid_603996
  var valid_603997 = header.getOrDefault("X-Amz-Security-Token")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-Security-Token", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Content-Sha256", valid_603998
  var valid_603999 = header.getOrDefault("X-Amz-Algorithm")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "X-Amz-Algorithm", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-Signature")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Signature", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-SignedHeaders", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Credential")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Credential", valid_604002
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
  var valid_604003 = formData.getOrDefault("HealthCheckTimeoutSeconds")
  valid_604003 = validateParameter(valid_604003, JInt, required = false, default = nil)
  if valid_604003 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_604003
  var valid_604004 = formData.getOrDefault("HealthCheckPort")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "HealthCheckPort", valid_604004
  var valid_604005 = formData.getOrDefault("UnhealthyThresholdCount")
  valid_604005 = validateParameter(valid_604005, JInt, required = false, default = nil)
  if valid_604005 != nil:
    section.add "UnhealthyThresholdCount", valid_604005
  var valid_604006 = formData.getOrDefault("HealthCheckPath")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "HealthCheckPath", valid_604006
  var valid_604007 = formData.getOrDefault("HealthCheckEnabled")
  valid_604007 = validateParameter(valid_604007, JBool, required = false, default = nil)
  if valid_604007 != nil:
    section.add "HealthCheckEnabled", valid_604007
  var valid_604008 = formData.getOrDefault("HealthCheckIntervalSeconds")
  valid_604008 = validateParameter(valid_604008, JInt, required = false, default = nil)
  if valid_604008 != nil:
    section.add "HealthCheckIntervalSeconds", valid_604008
  var valid_604009 = formData.getOrDefault("HealthyThresholdCount")
  valid_604009 = validateParameter(valid_604009, JInt, required = false, default = nil)
  if valid_604009 != nil:
    section.add "HealthyThresholdCount", valid_604009
  var valid_604010 = formData.getOrDefault("HealthCheckProtocol")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_604010 != nil:
    section.add "HealthCheckProtocol", valid_604010
  var valid_604011 = formData.getOrDefault("Matcher.HttpCode")
  valid_604011 = validateParameter(valid_604011, JString, required = false,
                                 default = nil)
  if valid_604011 != nil:
    section.add "Matcher.HttpCode", valid_604011
  assert formData != nil,
        "formData argument is necessary due to required `TargetGroupArn` field"
  var valid_604012 = formData.getOrDefault("TargetGroupArn")
  valid_604012 = validateParameter(valid_604012, JString, required = true,
                                 default = nil)
  if valid_604012 != nil:
    section.add "TargetGroupArn", valid_604012
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604013: Call_PostModifyTargetGroup_603991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_604013.validator(path, query, header, formData, body)
  let scheme = call_604013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604013.url(scheme.get, call_604013.host, call_604013.base,
                         call_604013.route, valid.getOrDefault("path"))
  result = hook(call_604013, url, valid)

proc call*(call_604014: Call_PostModifyTargetGroup_603991; TargetGroupArn: string;
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
  var query_604015 = newJObject()
  var formData_604016 = newJObject()
  add(formData_604016, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(formData_604016, "HealthCheckPort", newJString(HealthCheckPort))
  add(formData_604016, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(formData_604016, "HealthCheckPath", newJString(HealthCheckPath))
  add(formData_604016, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_604015, "Action", newJString(Action))
  add(formData_604016, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(formData_604016, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(formData_604016, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(formData_604016, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(formData_604016, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_604015, "Version", newJString(Version))
  result = call_604014.call(nil, query_604015, nil, formData_604016, nil)

var postModifyTargetGroup* = Call_PostModifyTargetGroup_603991(
    name: "postModifyTargetGroup", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup",
    validator: validate_PostModifyTargetGroup_603992, base: "/",
    url: url_PostModifyTargetGroup_603993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroup_603966 = ref object of OpenApiRestCall_602433
proc url_GetModifyTargetGroup_603968(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyTargetGroup_603967(path: JsonNode; query: JsonNode;
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
  var valid_603969 = query.getOrDefault("HealthCheckEnabled")
  valid_603969 = validateParameter(valid_603969, JBool, required = false, default = nil)
  if valid_603969 != nil:
    section.add "HealthCheckEnabled", valid_603969
  var valid_603970 = query.getOrDefault("HealthCheckIntervalSeconds")
  valid_603970 = validateParameter(valid_603970, JInt, required = false, default = nil)
  if valid_603970 != nil:
    section.add "HealthCheckIntervalSeconds", valid_603970
  assert query != nil,
        "query argument is necessary due to required `TargetGroupArn` field"
  var valid_603971 = query.getOrDefault("TargetGroupArn")
  valid_603971 = validateParameter(valid_603971, JString, required = true,
                                 default = nil)
  if valid_603971 != nil:
    section.add "TargetGroupArn", valid_603971
  var valid_603972 = query.getOrDefault("HealthCheckPort")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "HealthCheckPort", valid_603972
  var valid_603973 = query.getOrDefault("Action")
  valid_603973 = validateParameter(valid_603973, JString, required = true,
                                 default = newJString("ModifyTargetGroup"))
  if valid_603973 != nil:
    section.add "Action", valid_603973
  var valid_603974 = query.getOrDefault("HealthCheckTimeoutSeconds")
  valid_603974 = validateParameter(valid_603974, JInt, required = false, default = nil)
  if valid_603974 != nil:
    section.add "HealthCheckTimeoutSeconds", valid_603974
  var valid_603975 = query.getOrDefault("Matcher.HttpCode")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "Matcher.HttpCode", valid_603975
  var valid_603976 = query.getOrDefault("UnhealthyThresholdCount")
  valid_603976 = validateParameter(valid_603976, JInt, required = false, default = nil)
  if valid_603976 != nil:
    section.add "UnhealthyThresholdCount", valid_603976
  var valid_603977 = query.getOrDefault("HealthCheckProtocol")
  valid_603977 = validateParameter(valid_603977, JString, required = false,
                                 default = newJString("HTTP"))
  if valid_603977 != nil:
    section.add "HealthCheckProtocol", valid_603977
  var valid_603978 = query.getOrDefault("HealthyThresholdCount")
  valid_603978 = validateParameter(valid_603978, JInt, required = false, default = nil)
  if valid_603978 != nil:
    section.add "HealthyThresholdCount", valid_603978
  var valid_603979 = query.getOrDefault("Version")
  valid_603979 = validateParameter(valid_603979, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_603979 != nil:
    section.add "Version", valid_603979
  var valid_603980 = query.getOrDefault("HealthCheckPath")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "HealthCheckPath", valid_603980
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603981 = header.getOrDefault("X-Amz-Date")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "X-Amz-Date", valid_603981
  var valid_603982 = header.getOrDefault("X-Amz-Security-Token")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-Security-Token", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Content-Sha256", valid_603983
  var valid_603984 = header.getOrDefault("X-Amz-Algorithm")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Algorithm", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Signature")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Signature", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-SignedHeaders", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Credential")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Credential", valid_603987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603988: Call_GetModifyTargetGroup_603966; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the health checks used when evaluating the health state of the targets in the specified target group.</p> <p>To monitor the health of the targets, use <a>DescribeTargetHealth</a>.</p>
  ## 
  let valid = call_603988.validator(path, query, header, formData, body)
  let scheme = call_603988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603988.url(scheme.get, call_603988.host, call_603988.base,
                         call_603988.route, valid.getOrDefault("path"))
  result = hook(call_603988, url, valid)

proc call*(call_603989: Call_GetModifyTargetGroup_603966; TargetGroupArn: string;
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
  var query_603990 = newJObject()
  add(query_603990, "HealthCheckEnabled", newJBool(HealthCheckEnabled))
  add(query_603990, "HealthCheckIntervalSeconds",
      newJInt(HealthCheckIntervalSeconds))
  add(query_603990, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_603990, "HealthCheckPort", newJString(HealthCheckPort))
  add(query_603990, "Action", newJString(Action))
  add(query_603990, "HealthCheckTimeoutSeconds",
      newJInt(HealthCheckTimeoutSeconds))
  add(query_603990, "Matcher.HttpCode", newJString(MatcherHttpCode))
  add(query_603990, "UnhealthyThresholdCount", newJInt(UnhealthyThresholdCount))
  add(query_603990, "HealthCheckProtocol", newJString(HealthCheckProtocol))
  add(query_603990, "HealthyThresholdCount", newJInt(HealthyThresholdCount))
  add(query_603990, "Version", newJString(Version))
  add(query_603990, "HealthCheckPath", newJString(HealthCheckPath))
  result = call_603989.call(nil, query_603990, nil, nil, nil)

var getModifyTargetGroup* = Call_GetModifyTargetGroup_603966(
    name: "getModifyTargetGroup", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroup", validator: validate_GetModifyTargetGroup_603967,
    base: "/", url: url_GetModifyTargetGroup_603968,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyTargetGroupAttributes_604034 = ref object of OpenApiRestCall_602433
proc url_PostModifyTargetGroupAttributes_604036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyTargetGroupAttributes_604035(path: JsonNode;
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
  var valid_604037 = query.getOrDefault("Action")
  valid_604037 = validateParameter(valid_604037, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_604037 != nil:
    section.add "Action", valid_604037
  var valid_604038 = query.getOrDefault("Version")
  valid_604038 = validateParameter(valid_604038, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604038 != nil:
    section.add "Version", valid_604038
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604039 = header.getOrDefault("X-Amz-Date")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Date", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Security-Token")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Security-Token", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Content-Sha256", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Algorithm")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Algorithm", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Signature")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Signature", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-SignedHeaders", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-Credential")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-Credential", valid_604045
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes: JArray (required)
  ##             : The attributes.
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Attributes` field"
  var valid_604046 = formData.getOrDefault("Attributes")
  valid_604046 = validateParameter(valid_604046, JArray, required = true, default = nil)
  if valid_604046 != nil:
    section.add "Attributes", valid_604046
  var valid_604047 = formData.getOrDefault("TargetGroupArn")
  valid_604047 = validateParameter(valid_604047, JString, required = true,
                                 default = nil)
  if valid_604047 != nil:
    section.add "TargetGroupArn", valid_604047
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604048: Call_PostModifyTargetGroupAttributes_604034;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_604048.validator(path, query, header, formData, body)
  let scheme = call_604048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604048.url(scheme.get, call_604048.host, call_604048.base,
                         call_604048.route, valid.getOrDefault("path"))
  result = hook(call_604048, url, valid)

proc call*(call_604049: Call_PostModifyTargetGroupAttributes_604034;
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
  var query_604050 = newJObject()
  var formData_604051 = newJObject()
  if Attributes != nil:
    formData_604051.add "Attributes", Attributes
  add(query_604050, "Action", newJString(Action))
  add(formData_604051, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_604050, "Version", newJString(Version))
  result = call_604049.call(nil, query_604050, nil, formData_604051, nil)

var postModifyTargetGroupAttributes* = Call_PostModifyTargetGroupAttributes_604034(
    name: "postModifyTargetGroupAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_PostModifyTargetGroupAttributes_604035, base: "/",
    url: url_PostModifyTargetGroupAttributes_604036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyTargetGroupAttributes_604017 = ref object of OpenApiRestCall_602433
proc url_GetModifyTargetGroupAttributes_604019(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyTargetGroupAttributes_604018(path: JsonNode;
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
  var valid_604020 = query.getOrDefault("TargetGroupArn")
  valid_604020 = validateParameter(valid_604020, JString, required = true,
                                 default = nil)
  if valid_604020 != nil:
    section.add "TargetGroupArn", valid_604020
  var valid_604021 = query.getOrDefault("Attributes")
  valid_604021 = validateParameter(valid_604021, JArray, required = true, default = nil)
  if valid_604021 != nil:
    section.add "Attributes", valid_604021
  var valid_604022 = query.getOrDefault("Action")
  valid_604022 = validateParameter(valid_604022, JString, required = true, default = newJString(
      "ModifyTargetGroupAttributes"))
  if valid_604022 != nil:
    section.add "Action", valid_604022
  var valid_604023 = query.getOrDefault("Version")
  valid_604023 = validateParameter(valid_604023, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604023 != nil:
    section.add "Version", valid_604023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604024 = header.getOrDefault("X-Amz-Date")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Date", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-Security-Token")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Security-Token", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-Content-Sha256", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-Algorithm")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-Algorithm", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-Signature")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Signature", valid_604028
  var valid_604029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "X-Amz-SignedHeaders", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-Credential")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-Credential", valid_604030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604031: Call_GetModifyTargetGroupAttributes_604017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified attributes of the specified target group.
  ## 
  let valid = call_604031.validator(path, query, header, formData, body)
  let scheme = call_604031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604031.url(scheme.get, call_604031.host, call_604031.base,
                         call_604031.route, valid.getOrDefault("path"))
  result = hook(call_604031, url, valid)

proc call*(call_604032: Call_GetModifyTargetGroupAttributes_604017;
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
  var query_604033 = newJObject()
  add(query_604033, "TargetGroupArn", newJString(TargetGroupArn))
  if Attributes != nil:
    query_604033.add "Attributes", Attributes
  add(query_604033, "Action", newJString(Action))
  add(query_604033, "Version", newJString(Version))
  result = call_604032.call(nil, query_604033, nil, nil, nil)

var getModifyTargetGroupAttributes* = Call_GetModifyTargetGroupAttributes_604017(
    name: "getModifyTargetGroupAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyTargetGroupAttributes",
    validator: validate_GetModifyTargetGroupAttributes_604018, base: "/",
    url: url_GetModifyTargetGroupAttributes_604019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterTargets_604069 = ref object of OpenApiRestCall_602433
proc url_PostRegisterTargets_604071(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRegisterTargets_604070(path: JsonNode; query: JsonNode;
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
  var valid_604072 = query.getOrDefault("Action")
  valid_604072 = validateParameter(valid_604072, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_604072 != nil:
    section.add "Action", valid_604072
  var valid_604073 = query.getOrDefault("Version")
  valid_604073 = validateParameter(valid_604073, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604073 != nil:
    section.add "Version", valid_604073
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604074 = header.getOrDefault("X-Amz-Date")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Date", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Security-Token")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Security-Token", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Content-Sha256", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Algorithm")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Algorithm", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-Signature")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Signature", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-SignedHeaders", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-Credential")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Credential", valid_604080
  result.add "header", section
  ## parameters in `formData` object:
  ##   Targets: JArray (required)
  ##          : <p>The targets.</p> <p>To register a target by instance ID, specify the instance ID. To register a target by IP address, specify the IP address. To register a Lambda function, specify the ARN of the Lambda function.</p>
  ##   TargetGroupArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) of the target group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Targets` field"
  var valid_604081 = formData.getOrDefault("Targets")
  valid_604081 = validateParameter(valid_604081, JArray, required = true, default = nil)
  if valid_604081 != nil:
    section.add "Targets", valid_604081
  var valid_604082 = formData.getOrDefault("TargetGroupArn")
  valid_604082 = validateParameter(valid_604082, JString, required = true,
                                 default = nil)
  if valid_604082 != nil:
    section.add "TargetGroupArn", valid_604082
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604083: Call_PostRegisterTargets_604069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_604083.validator(path, query, header, formData, body)
  let scheme = call_604083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604083.url(scheme.get, call_604083.host, call_604083.base,
                         call_604083.route, valid.getOrDefault("path"))
  result = hook(call_604083, url, valid)

proc call*(call_604084: Call_PostRegisterTargets_604069; Targets: JsonNode;
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
  var query_604085 = newJObject()
  var formData_604086 = newJObject()
  if Targets != nil:
    formData_604086.add "Targets", Targets
  add(query_604085, "Action", newJString(Action))
  add(formData_604086, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_604085, "Version", newJString(Version))
  result = call_604084.call(nil, query_604085, nil, formData_604086, nil)

var postRegisterTargets* = Call_PostRegisterTargets_604069(
    name: "postRegisterTargets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_PostRegisterTargets_604070, base: "/",
    url: url_PostRegisterTargets_604071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterTargets_604052 = ref object of OpenApiRestCall_602433
proc url_GetRegisterTargets_604054(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRegisterTargets_604053(path: JsonNode; query: JsonNode;
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
  var valid_604055 = query.getOrDefault("Targets")
  valid_604055 = validateParameter(valid_604055, JArray, required = true, default = nil)
  if valid_604055 != nil:
    section.add "Targets", valid_604055
  var valid_604056 = query.getOrDefault("TargetGroupArn")
  valid_604056 = validateParameter(valid_604056, JString, required = true,
                                 default = nil)
  if valid_604056 != nil:
    section.add "TargetGroupArn", valid_604056
  var valid_604057 = query.getOrDefault("Action")
  valid_604057 = validateParameter(valid_604057, JString, required = true,
                                 default = newJString("RegisterTargets"))
  if valid_604057 != nil:
    section.add "Action", valid_604057
  var valid_604058 = query.getOrDefault("Version")
  valid_604058 = validateParameter(valid_604058, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604058 != nil:
    section.add "Version", valid_604058
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604059 = header.getOrDefault("X-Amz-Date")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "X-Amz-Date", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-Security-Token")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Security-Token", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Content-Sha256", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-Algorithm")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-Algorithm", valid_604062
  var valid_604063 = header.getOrDefault("X-Amz-Signature")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-Signature", valid_604063
  var valid_604064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-SignedHeaders", valid_604064
  var valid_604065 = header.getOrDefault("X-Amz-Credential")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "X-Amz-Credential", valid_604065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604066: Call_GetRegisterTargets_604052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers the specified targets with the specified target group.</p> <p>If the target is an EC2 instance, it must be in the <code>running</code> state when you register it.</p> <p>By default, the load balancer routes requests to registered targets using the protocol and port for the target group. Alternatively, you can override the port for a target when you register it. You can register each EC2 instance or IP address with the same target group multiple times using different ports.</p> <p>With a Network Load Balancer, you cannot register instances by instance ID if they have the following instance types: C1, CC1, CC2, CG1, CG2, CR1, CS1, G1, G2, HI1, HS1, M1, M2, M3, and T1. You can register instances of these types by IP address.</p> <p>To remove a target from a target group, use <a>DeregisterTargets</a>.</p>
  ## 
  let valid = call_604066.validator(path, query, header, formData, body)
  let scheme = call_604066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604066.url(scheme.get, call_604066.host, call_604066.base,
                         call_604066.route, valid.getOrDefault("path"))
  result = hook(call_604066, url, valid)

proc call*(call_604067: Call_GetRegisterTargets_604052; Targets: JsonNode;
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
  var query_604068 = newJObject()
  if Targets != nil:
    query_604068.add "Targets", Targets
  add(query_604068, "TargetGroupArn", newJString(TargetGroupArn))
  add(query_604068, "Action", newJString(Action))
  add(query_604068, "Version", newJString(Version))
  result = call_604067.call(nil, query_604068, nil, nil, nil)

var getRegisterTargets* = Call_GetRegisterTargets_604052(
    name: "getRegisterTargets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com", route: "/#Action=RegisterTargets",
    validator: validate_GetRegisterTargets_604053, base: "/",
    url: url_GetRegisterTargets_604054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveListenerCertificates_604104 = ref object of OpenApiRestCall_602433
proc url_PostRemoveListenerCertificates_604106(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveListenerCertificates_604105(path: JsonNode;
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
  var valid_604107 = query.getOrDefault("Action")
  valid_604107 = validateParameter(valid_604107, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_604107 != nil:
    section.add "Action", valid_604107
  var valid_604108 = query.getOrDefault("Version")
  valid_604108 = validateParameter(valid_604108, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604108 != nil:
    section.add "Version", valid_604108
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604109 = header.getOrDefault("X-Amz-Date")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Date", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-Security-Token")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Security-Token", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Content-Sha256", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Algorithm")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Algorithm", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Signature")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Signature", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-SignedHeaders", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Credential")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Credential", valid_604115
  result.add "header", section
  ## parameters in `formData` object:
  ##   Certificates: JArray (required)
  ##               : The certificate to remove. You can specify one certificate per call. Set <code>CertificateArn</code> to the certificate ARN but do not set <code>IsDefault</code>.
  ##   ListenerArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the listener.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Certificates` field"
  var valid_604116 = formData.getOrDefault("Certificates")
  valid_604116 = validateParameter(valid_604116, JArray, required = true, default = nil)
  if valid_604116 != nil:
    section.add "Certificates", valid_604116
  var valid_604117 = formData.getOrDefault("ListenerArn")
  valid_604117 = validateParameter(valid_604117, JString, required = true,
                                 default = nil)
  if valid_604117 != nil:
    section.add "ListenerArn", valid_604117
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604118: Call_PostRemoveListenerCertificates_604104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_604118.validator(path, query, header, formData, body)
  let scheme = call_604118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604118.url(scheme.get, call_604118.host, call_604118.base,
                         call_604118.route, valid.getOrDefault("path"))
  result = hook(call_604118, url, valid)

proc call*(call_604119: Call_PostRemoveListenerCertificates_604104;
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
  var query_604120 = newJObject()
  var formData_604121 = newJObject()
  if Certificates != nil:
    formData_604121.add "Certificates", Certificates
  add(formData_604121, "ListenerArn", newJString(ListenerArn))
  add(query_604120, "Action", newJString(Action))
  add(query_604120, "Version", newJString(Version))
  result = call_604119.call(nil, query_604120, nil, formData_604121, nil)

var postRemoveListenerCertificates* = Call_PostRemoveListenerCertificates_604104(
    name: "postRemoveListenerCertificates", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_PostRemoveListenerCertificates_604105, base: "/",
    url: url_PostRemoveListenerCertificates_604106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveListenerCertificates_604087 = ref object of OpenApiRestCall_602433
proc url_GetRemoveListenerCertificates_604089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveListenerCertificates_604088(path: JsonNode; query: JsonNode;
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
  var valid_604090 = query.getOrDefault("Certificates")
  valid_604090 = validateParameter(valid_604090, JArray, required = true, default = nil)
  if valid_604090 != nil:
    section.add "Certificates", valid_604090
  var valid_604091 = query.getOrDefault("Action")
  valid_604091 = validateParameter(valid_604091, JString, required = true, default = newJString(
      "RemoveListenerCertificates"))
  if valid_604091 != nil:
    section.add "Action", valid_604091
  var valid_604092 = query.getOrDefault("ListenerArn")
  valid_604092 = validateParameter(valid_604092, JString, required = true,
                                 default = nil)
  if valid_604092 != nil:
    section.add "ListenerArn", valid_604092
  var valid_604093 = query.getOrDefault("Version")
  valid_604093 = validateParameter(valid_604093, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604093 != nil:
    section.add "Version", valid_604093
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604094 = header.getOrDefault("X-Amz-Date")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Date", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Security-Token")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Security-Token", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Content-Sha256", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-Algorithm")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Algorithm", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-Signature")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-Signature", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-SignedHeaders", valid_604099
  var valid_604100 = header.getOrDefault("X-Amz-Credential")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "X-Amz-Credential", valid_604100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604101: Call_GetRemoveListenerCertificates_604087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified certificate from the certificate list for the specified HTTPS or TLS listener.</p> <p>You can't remove the default certificate for a listener. To replace the default certificate, call <a>ModifyListener</a>.</p> <p>To list the certificates for your listener, use <a>DescribeListenerCertificates</a>.</p>
  ## 
  let valid = call_604101.validator(path, query, header, formData, body)
  let scheme = call_604101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604101.url(scheme.get, call_604101.host, call_604101.base,
                         call_604101.route, valid.getOrDefault("path"))
  result = hook(call_604101, url, valid)

proc call*(call_604102: Call_GetRemoveListenerCertificates_604087;
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
  var query_604103 = newJObject()
  if Certificates != nil:
    query_604103.add "Certificates", Certificates
  add(query_604103, "Action", newJString(Action))
  add(query_604103, "ListenerArn", newJString(ListenerArn))
  add(query_604103, "Version", newJString(Version))
  result = call_604102.call(nil, query_604103, nil, nil, nil)

var getRemoveListenerCertificates* = Call_GetRemoveListenerCertificates_604087(
    name: "getRemoveListenerCertificates", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveListenerCertificates",
    validator: validate_GetRemoveListenerCertificates_604088, base: "/",
    url: url_GetRemoveListenerCertificates_604089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_604139 = ref object of OpenApiRestCall_602433
proc url_PostRemoveTags_604141(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTags_604140(path: JsonNode; query: JsonNode;
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
  var valid_604142 = query.getOrDefault("Action")
  valid_604142 = validateParameter(valid_604142, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_604142 != nil:
    section.add "Action", valid_604142
  var valid_604143 = query.getOrDefault("Version")
  valid_604143 = validateParameter(valid_604143, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604143 != nil:
    section.add "Version", valid_604143
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604144 = header.getOrDefault("X-Amz-Date")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Date", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Security-Token")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Security-Token", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Content-Sha256", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-Algorithm")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-Algorithm", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-Signature")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-Signature", valid_604148
  var valid_604149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "X-Amz-SignedHeaders", valid_604149
  var valid_604150 = header.getOrDefault("X-Amz-Credential")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "X-Amz-Credential", valid_604150
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArns: JArray (required)
  ##               : The Amazon Resource Name (ARN) of the resource.
  ##   TagKeys: JArray (required)
  ##          : The tag keys for the tags to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArns` field"
  var valid_604151 = formData.getOrDefault("ResourceArns")
  valid_604151 = validateParameter(valid_604151, JArray, required = true, default = nil)
  if valid_604151 != nil:
    section.add "ResourceArns", valid_604151
  var valid_604152 = formData.getOrDefault("TagKeys")
  valid_604152 = validateParameter(valid_604152, JArray, required = true, default = nil)
  if valid_604152 != nil:
    section.add "TagKeys", valid_604152
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604153: Call_PostRemoveTags_604139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_604153.validator(path, query, header, formData, body)
  let scheme = call_604153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604153.url(scheme.get, call_604153.host, call_604153.base,
                         call_604153.route, valid.getOrDefault("path"))
  result = hook(call_604153, url, valid)

proc call*(call_604154: Call_PostRemoveTags_604139; ResourceArns: JsonNode;
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
  var query_604155 = newJObject()
  var formData_604156 = newJObject()
  if ResourceArns != nil:
    formData_604156.add "ResourceArns", ResourceArns
  add(query_604155, "Action", newJString(Action))
  if TagKeys != nil:
    formData_604156.add "TagKeys", TagKeys
  add(query_604155, "Version", newJString(Version))
  result = call_604154.call(nil, query_604155, nil, formData_604156, nil)

var postRemoveTags* = Call_PostRemoveTags_604139(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_604140,
    base: "/", url: url_PostRemoveTags_604141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_604122 = ref object of OpenApiRestCall_602433
proc url_GetRemoveTags_604124(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTags_604123(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604125 = query.getOrDefault("Action")
  valid_604125 = validateParameter(valid_604125, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_604125 != nil:
    section.add "Action", valid_604125
  var valid_604126 = query.getOrDefault("ResourceArns")
  valid_604126 = validateParameter(valid_604126, JArray, required = true, default = nil)
  if valid_604126 != nil:
    section.add "ResourceArns", valid_604126
  var valid_604127 = query.getOrDefault("TagKeys")
  valid_604127 = validateParameter(valid_604127, JArray, required = true, default = nil)
  if valid_604127 != nil:
    section.add "TagKeys", valid_604127
  var valid_604128 = query.getOrDefault("Version")
  valid_604128 = validateParameter(valid_604128, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604128 != nil:
    section.add "Version", valid_604128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604129 = header.getOrDefault("X-Amz-Date")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Date", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Security-Token")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Security-Token", valid_604130
  var valid_604131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-Content-Sha256", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-Algorithm")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-Algorithm", valid_604132
  var valid_604133 = header.getOrDefault("X-Amz-Signature")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "X-Amz-Signature", valid_604133
  var valid_604134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604134 = validateParameter(valid_604134, JString, required = false,
                                 default = nil)
  if valid_604134 != nil:
    section.add "X-Amz-SignedHeaders", valid_604134
  var valid_604135 = header.getOrDefault("X-Amz-Credential")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "X-Amz-Credential", valid_604135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604136: Call_GetRemoveTags_604122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified Elastic Load Balancing resource.</p> <p>To list the current tags for your resources, use <a>DescribeTags</a>.</p>
  ## 
  let valid = call_604136.validator(path, query, header, formData, body)
  let scheme = call_604136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604136.url(scheme.get, call_604136.host, call_604136.base,
                         call_604136.route, valid.getOrDefault("path"))
  result = hook(call_604136, url, valid)

proc call*(call_604137: Call_GetRemoveTags_604122; ResourceArns: JsonNode;
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
  var query_604138 = newJObject()
  add(query_604138, "Action", newJString(Action))
  if ResourceArns != nil:
    query_604138.add "ResourceArns", ResourceArns
  if TagKeys != nil:
    query_604138.add "TagKeys", TagKeys
  add(query_604138, "Version", newJString(Version))
  result = call_604137.call(nil, query_604138, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_604122(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_604123,
    base: "/", url: url_GetRemoveTags_604124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetIpAddressType_604174 = ref object of OpenApiRestCall_602433
proc url_PostSetIpAddressType_604176(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetIpAddressType_604175(path: JsonNode; query: JsonNode;
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
  var valid_604177 = query.getOrDefault("Action")
  valid_604177 = validateParameter(valid_604177, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_604177 != nil:
    section.add "Action", valid_604177
  var valid_604178 = query.getOrDefault("Version")
  valid_604178 = validateParameter(valid_604178, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604178 != nil:
    section.add "Version", valid_604178
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604179 = header.getOrDefault("X-Amz-Date")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "X-Amz-Date", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-Security-Token")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-Security-Token", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Content-Sha256", valid_604181
  var valid_604182 = header.getOrDefault("X-Amz-Algorithm")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "X-Amz-Algorithm", valid_604182
  var valid_604183 = header.getOrDefault("X-Amz-Signature")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "X-Amz-Signature", valid_604183
  var valid_604184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "X-Amz-SignedHeaders", valid_604184
  var valid_604185 = header.getOrDefault("X-Amz-Credential")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-Credential", valid_604185
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   IpAddressType: JString (required)
  ##                : The IP address type. The possible values are <code>ipv4</code> (for IPv4 addresses) and <code>dualstack</code> (for IPv4 and IPv6 addresses). Internal load balancers must use <code>ipv4</code>. Network Load Balancers must use <code>ipv4</code>.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_604186 = formData.getOrDefault("LoadBalancerArn")
  valid_604186 = validateParameter(valid_604186, JString, required = true,
                                 default = nil)
  if valid_604186 != nil:
    section.add "LoadBalancerArn", valid_604186
  var valid_604187 = formData.getOrDefault("IpAddressType")
  valid_604187 = validateParameter(valid_604187, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_604187 != nil:
    section.add "IpAddressType", valid_604187
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604188: Call_PostSetIpAddressType_604174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_604188.validator(path, query, header, formData, body)
  let scheme = call_604188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604188.url(scheme.get, call_604188.host, call_604188.base,
                         call_604188.route, valid.getOrDefault("path"))
  result = hook(call_604188, url, valid)

proc call*(call_604189: Call_PostSetIpAddressType_604174; LoadBalancerArn: string;
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
  var query_604190 = newJObject()
  var formData_604191 = newJObject()
  add(formData_604191, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(formData_604191, "IpAddressType", newJString(IpAddressType))
  add(query_604190, "Action", newJString(Action))
  add(query_604190, "Version", newJString(Version))
  result = call_604189.call(nil, query_604190, nil, formData_604191, nil)

var postSetIpAddressType* = Call_PostSetIpAddressType_604174(
    name: "postSetIpAddressType", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_PostSetIpAddressType_604175,
    base: "/", url: url_PostSetIpAddressType_604176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetIpAddressType_604157 = ref object of OpenApiRestCall_602433
proc url_GetSetIpAddressType_604159(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetIpAddressType_604158(path: JsonNode; query: JsonNode;
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
  var valid_604160 = query.getOrDefault("IpAddressType")
  valid_604160 = validateParameter(valid_604160, JString, required = true,
                                 default = newJString("ipv4"))
  if valid_604160 != nil:
    section.add "IpAddressType", valid_604160
  var valid_604161 = query.getOrDefault("Action")
  valid_604161 = validateParameter(valid_604161, JString, required = true,
                                 default = newJString("SetIpAddressType"))
  if valid_604161 != nil:
    section.add "Action", valid_604161
  var valid_604162 = query.getOrDefault("LoadBalancerArn")
  valid_604162 = validateParameter(valid_604162, JString, required = true,
                                 default = nil)
  if valid_604162 != nil:
    section.add "LoadBalancerArn", valid_604162
  var valid_604163 = query.getOrDefault("Version")
  valid_604163 = validateParameter(valid_604163, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604163 != nil:
    section.add "Version", valid_604163
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604164 = header.getOrDefault("X-Amz-Date")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-Date", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Security-Token")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Security-Token", valid_604165
  var valid_604166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "X-Amz-Content-Sha256", valid_604166
  var valid_604167 = header.getOrDefault("X-Amz-Algorithm")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "X-Amz-Algorithm", valid_604167
  var valid_604168 = header.getOrDefault("X-Amz-Signature")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-Signature", valid_604168
  var valid_604169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "X-Amz-SignedHeaders", valid_604169
  var valid_604170 = header.getOrDefault("X-Amz-Credential")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "X-Amz-Credential", valid_604170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604171: Call_GetSetIpAddressType_604157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the type of IP addresses used by the subnets of the specified Application Load Balancer or Network Load Balancer.
  ## 
  let valid = call_604171.validator(path, query, header, formData, body)
  let scheme = call_604171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604171.url(scheme.get, call_604171.host, call_604171.base,
                         call_604171.route, valid.getOrDefault("path"))
  result = hook(call_604171, url, valid)

proc call*(call_604172: Call_GetSetIpAddressType_604157; LoadBalancerArn: string;
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
  var query_604173 = newJObject()
  add(query_604173, "IpAddressType", newJString(IpAddressType))
  add(query_604173, "Action", newJString(Action))
  add(query_604173, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_604173, "Version", newJString(Version))
  result = call_604172.call(nil, query_604173, nil, nil, nil)

var getSetIpAddressType* = Call_GetSetIpAddressType_604157(
    name: "getSetIpAddressType", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetIpAddressType", validator: validate_GetSetIpAddressType_604158,
    base: "/", url: url_GetSetIpAddressType_604159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetRulePriorities_604208 = ref object of OpenApiRestCall_602433
proc url_PostSetRulePriorities_604210(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetRulePriorities_604209(path: JsonNode; query: JsonNode;
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
  var valid_604211 = query.getOrDefault("Action")
  valid_604211 = validateParameter(valid_604211, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_604211 != nil:
    section.add "Action", valid_604211
  var valid_604212 = query.getOrDefault("Version")
  valid_604212 = validateParameter(valid_604212, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604212 != nil:
    section.add "Version", valid_604212
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604213 = header.getOrDefault("X-Amz-Date")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Date", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Security-Token")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Security-Token", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Content-Sha256", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Algorithm")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Algorithm", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-Signature")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-Signature", valid_604217
  var valid_604218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "X-Amz-SignedHeaders", valid_604218
  var valid_604219 = header.getOrDefault("X-Amz-Credential")
  valid_604219 = validateParameter(valid_604219, JString, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "X-Amz-Credential", valid_604219
  result.add "header", section
  ## parameters in `formData` object:
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RulePriorities` field"
  var valid_604220 = formData.getOrDefault("RulePriorities")
  valid_604220 = validateParameter(valid_604220, JArray, required = true, default = nil)
  if valid_604220 != nil:
    section.add "RulePriorities", valid_604220
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604221: Call_PostSetRulePriorities_604208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_604221.validator(path, query, header, formData, body)
  let scheme = call_604221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604221.url(scheme.get, call_604221.host, call_604221.base,
                         call_604221.route, valid.getOrDefault("path"))
  result = hook(call_604221, url, valid)

proc call*(call_604222: Call_PostSetRulePriorities_604208;
          RulePriorities: JsonNode; Action: string = "SetRulePriorities";
          Version: string = "2015-12-01"): Recallable =
  ## postSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604223 = newJObject()
  var formData_604224 = newJObject()
  if RulePriorities != nil:
    formData_604224.add "RulePriorities", RulePriorities
  add(query_604223, "Action", newJString(Action))
  add(query_604223, "Version", newJString(Version))
  result = call_604222.call(nil, query_604223, nil, formData_604224, nil)

var postSetRulePriorities* = Call_PostSetRulePriorities_604208(
    name: "postSetRulePriorities", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities",
    validator: validate_PostSetRulePriorities_604209, base: "/",
    url: url_PostSetRulePriorities_604210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetRulePriorities_604192 = ref object of OpenApiRestCall_602433
proc url_GetSetRulePriorities_604194(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetRulePriorities_604193(path: JsonNode; query: JsonNode;
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
  var valid_604195 = query.getOrDefault("RulePriorities")
  valid_604195 = validateParameter(valid_604195, JArray, required = true, default = nil)
  if valid_604195 != nil:
    section.add "RulePriorities", valid_604195
  var valid_604196 = query.getOrDefault("Action")
  valid_604196 = validateParameter(valid_604196, JString, required = true,
                                 default = newJString("SetRulePriorities"))
  if valid_604196 != nil:
    section.add "Action", valid_604196
  var valid_604197 = query.getOrDefault("Version")
  valid_604197 = validateParameter(valid_604197, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604197 != nil:
    section.add "Version", valid_604197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604198 = header.getOrDefault("X-Amz-Date")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Date", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-Security-Token")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Security-Token", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Content-Sha256", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-Algorithm")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Algorithm", valid_604201
  var valid_604202 = header.getOrDefault("X-Amz-Signature")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "X-Amz-Signature", valid_604202
  var valid_604203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-SignedHeaders", valid_604203
  var valid_604204 = header.getOrDefault("X-Amz-Credential")
  valid_604204 = validateParameter(valid_604204, JString, required = false,
                                 default = nil)
  if valid_604204 != nil:
    section.add "X-Amz-Credential", valid_604204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604205: Call_GetSetRulePriorities_604192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ## 
  let valid = call_604205.validator(path, query, header, formData, body)
  let scheme = call_604205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604205.url(scheme.get, call_604205.host, call_604205.base,
                         call_604205.route, valid.getOrDefault("path"))
  result = hook(call_604205, url, valid)

proc call*(call_604206: Call_GetSetRulePriorities_604192; RulePriorities: JsonNode;
          Action: string = "SetRulePriorities"; Version: string = "2015-12-01"): Recallable =
  ## getSetRulePriorities
  ## <p>Sets the priorities of the specified rules.</p> <p>You can reorder the rules as long as there are no priority conflicts in the new order. Any existing rules that you do not specify retain their current priority.</p>
  ##   RulePriorities: JArray (required)
  ##                 : The rule priorities.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604207 = newJObject()
  if RulePriorities != nil:
    query_604207.add "RulePriorities", RulePriorities
  add(query_604207, "Action", newJString(Action))
  add(query_604207, "Version", newJString(Version))
  result = call_604206.call(nil, query_604207, nil, nil, nil)

var getSetRulePriorities* = Call_GetSetRulePriorities_604192(
    name: "getSetRulePriorities", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetRulePriorities", validator: validate_GetSetRulePriorities_604193,
    base: "/", url: url_GetSetRulePriorities_604194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSecurityGroups_604242 = ref object of OpenApiRestCall_602433
proc url_PostSetSecurityGroups_604244(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSecurityGroups_604243(path: JsonNode; query: JsonNode;
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
  var valid_604245 = query.getOrDefault("Action")
  valid_604245 = validateParameter(valid_604245, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_604245 != nil:
    section.add "Action", valid_604245
  var valid_604246 = query.getOrDefault("Version")
  valid_604246 = validateParameter(valid_604246, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604246 != nil:
    section.add "Version", valid_604246
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604247 = header.getOrDefault("X-Amz-Date")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Date", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Security-Token")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Security-Token", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Content-Sha256", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Algorithm")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Algorithm", valid_604250
  var valid_604251 = header.getOrDefault("X-Amz-Signature")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "X-Amz-Signature", valid_604251
  var valid_604252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "X-Amz-SignedHeaders", valid_604252
  var valid_604253 = header.getOrDefault("X-Amz-Credential")
  valid_604253 = validateParameter(valid_604253, JString, required = false,
                                 default = nil)
  if valid_604253 != nil:
    section.add "X-Amz-Credential", valid_604253
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerArn: JString (required)
  ##                  : The Amazon Resource Name (ARN) of the load balancer.
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerArn` field"
  var valid_604254 = formData.getOrDefault("LoadBalancerArn")
  valid_604254 = validateParameter(valid_604254, JString, required = true,
                                 default = nil)
  if valid_604254 != nil:
    section.add "LoadBalancerArn", valid_604254
  var valid_604255 = formData.getOrDefault("SecurityGroups")
  valid_604255 = validateParameter(valid_604255, JArray, required = true, default = nil)
  if valid_604255 != nil:
    section.add "SecurityGroups", valid_604255
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604256: Call_PostSetSecurityGroups_604242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_604256.validator(path, query, header, formData, body)
  let scheme = call_604256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604256.url(scheme.get, call_604256.host, call_604256.base,
                         call_604256.route, valid.getOrDefault("path"))
  result = hook(call_604256, url, valid)

proc call*(call_604257: Call_PostSetSecurityGroups_604242; LoadBalancerArn: string;
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
  var query_604258 = newJObject()
  var formData_604259 = newJObject()
  add(formData_604259, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_604258, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_604259.add "SecurityGroups", SecurityGroups
  add(query_604258, "Version", newJString(Version))
  result = call_604257.call(nil, query_604258, nil, formData_604259, nil)

var postSetSecurityGroups* = Call_PostSetSecurityGroups_604242(
    name: "postSetSecurityGroups", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups",
    validator: validate_PostSetSecurityGroups_604243, base: "/",
    url: url_PostSetSecurityGroups_604244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSecurityGroups_604225 = ref object of OpenApiRestCall_602433
proc url_GetSetSecurityGroups_604227(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSecurityGroups_604226(path: JsonNode; query: JsonNode;
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
  var valid_604228 = query.getOrDefault("Action")
  valid_604228 = validateParameter(valid_604228, JString, required = true,
                                 default = newJString("SetSecurityGroups"))
  if valid_604228 != nil:
    section.add "Action", valid_604228
  var valid_604229 = query.getOrDefault("LoadBalancerArn")
  valid_604229 = validateParameter(valid_604229, JString, required = true,
                                 default = nil)
  if valid_604229 != nil:
    section.add "LoadBalancerArn", valid_604229
  var valid_604230 = query.getOrDefault("Version")
  valid_604230 = validateParameter(valid_604230, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604230 != nil:
    section.add "Version", valid_604230
  var valid_604231 = query.getOrDefault("SecurityGroups")
  valid_604231 = validateParameter(valid_604231, JArray, required = true, default = nil)
  if valid_604231 != nil:
    section.add "SecurityGroups", valid_604231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604232 = header.getOrDefault("X-Amz-Date")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-Date", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-Security-Token")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Security-Token", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Content-Sha256", valid_604234
  var valid_604235 = header.getOrDefault("X-Amz-Algorithm")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "X-Amz-Algorithm", valid_604235
  var valid_604236 = header.getOrDefault("X-Amz-Signature")
  valid_604236 = validateParameter(valid_604236, JString, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "X-Amz-Signature", valid_604236
  var valid_604237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "X-Amz-SignedHeaders", valid_604237
  var valid_604238 = header.getOrDefault("X-Amz-Credential")
  valid_604238 = validateParameter(valid_604238, JString, required = false,
                                 default = nil)
  if valid_604238 != nil:
    section.add "X-Amz-Credential", valid_604238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604239: Call_GetSetSecurityGroups_604225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates the specified security groups with the specified Application Load Balancer. The specified security groups override the previously associated security groups.</p> <p>You can't specify a security group for a Network Load Balancer.</p>
  ## 
  let valid = call_604239.validator(path, query, header, formData, body)
  let scheme = call_604239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604239.url(scheme.get, call_604239.host, call_604239.base,
                         call_604239.route, valid.getOrDefault("path"))
  result = hook(call_604239, url, valid)

proc call*(call_604240: Call_GetSetSecurityGroups_604225; LoadBalancerArn: string;
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
  var query_604241 = newJObject()
  add(query_604241, "Action", newJString(Action))
  add(query_604241, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_604241, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_604241.add "SecurityGroups", SecurityGroups
  result = call_604240.call(nil, query_604241, nil, nil, nil)

var getSetSecurityGroups* = Call_GetSetSecurityGroups_604225(
    name: "getSetSecurityGroups", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSecurityGroups", validator: validate_GetSetSecurityGroups_604226,
    base: "/", url: url_GetSetSecurityGroups_604227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubnets_604278 = ref object of OpenApiRestCall_602433
proc url_PostSetSubnets_604280(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSubnets_604279(path: JsonNode; query: JsonNode;
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
  var valid_604281 = query.getOrDefault("Action")
  valid_604281 = validateParameter(valid_604281, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_604281 != nil:
    section.add "Action", valid_604281
  var valid_604282 = query.getOrDefault("Version")
  valid_604282 = validateParameter(valid_604282, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604282 != nil:
    section.add "Version", valid_604282
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604283 = header.getOrDefault("X-Amz-Date")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-Date", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-Security-Token")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-Security-Token", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-Content-Sha256", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-Algorithm")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-Algorithm", valid_604286
  var valid_604287 = header.getOrDefault("X-Amz-Signature")
  valid_604287 = validateParameter(valid_604287, JString, required = false,
                                 default = nil)
  if valid_604287 != nil:
    section.add "X-Amz-Signature", valid_604287
  var valid_604288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604288 = validateParameter(valid_604288, JString, required = false,
                                 default = nil)
  if valid_604288 != nil:
    section.add "X-Amz-SignedHeaders", valid_604288
  var valid_604289 = header.getOrDefault("X-Amz-Credential")
  valid_604289 = validateParameter(valid_604289, JString, required = false,
                                 default = nil)
  if valid_604289 != nil:
    section.add "X-Amz-Credential", valid_604289
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
  var valid_604290 = formData.getOrDefault("LoadBalancerArn")
  valid_604290 = validateParameter(valid_604290, JString, required = true,
                                 default = nil)
  if valid_604290 != nil:
    section.add "LoadBalancerArn", valid_604290
  var valid_604291 = formData.getOrDefault("Subnets")
  valid_604291 = validateParameter(valid_604291, JArray, required = false,
                                 default = nil)
  if valid_604291 != nil:
    section.add "Subnets", valid_604291
  var valid_604292 = formData.getOrDefault("SubnetMappings")
  valid_604292 = validateParameter(valid_604292, JArray, required = false,
                                 default = nil)
  if valid_604292 != nil:
    section.add "SubnetMappings", valid_604292
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604293: Call_PostSetSubnets_604278; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_604293.validator(path, query, header, formData, body)
  let scheme = call_604293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604293.url(scheme.get, call_604293.host, call_604293.base,
                         call_604293.route, valid.getOrDefault("path"))
  result = hook(call_604293, url, valid)

proc call*(call_604294: Call_PostSetSubnets_604278; LoadBalancerArn: string;
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
  var query_604295 = newJObject()
  var formData_604296 = newJObject()
  add(formData_604296, "LoadBalancerArn", newJString(LoadBalancerArn))
  add(query_604295, "Action", newJString(Action))
  if Subnets != nil:
    formData_604296.add "Subnets", Subnets
  if SubnetMappings != nil:
    formData_604296.add "SubnetMappings", SubnetMappings
  add(query_604295, "Version", newJString(Version))
  result = call_604294.call(nil, query_604295, nil, formData_604296, nil)

var postSetSubnets* = Call_PostSetSubnets_604278(name: "postSetSubnets",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_PostSetSubnets_604279,
    base: "/", url: url_PostSetSubnets_604280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubnets_604260 = ref object of OpenApiRestCall_602433
proc url_GetSetSubnets_604262(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSubnets_604261(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604263 = query.getOrDefault("SubnetMappings")
  valid_604263 = validateParameter(valid_604263, JArray, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "SubnetMappings", valid_604263
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604264 = query.getOrDefault("Action")
  valid_604264 = validateParameter(valid_604264, JString, required = true,
                                 default = newJString("SetSubnets"))
  if valid_604264 != nil:
    section.add "Action", valid_604264
  var valid_604265 = query.getOrDefault("LoadBalancerArn")
  valid_604265 = validateParameter(valid_604265, JString, required = true,
                                 default = nil)
  if valid_604265 != nil:
    section.add "LoadBalancerArn", valid_604265
  var valid_604266 = query.getOrDefault("Subnets")
  valid_604266 = validateParameter(valid_604266, JArray, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "Subnets", valid_604266
  var valid_604267 = query.getOrDefault("Version")
  valid_604267 = validateParameter(valid_604267, JString, required = true,
                                 default = newJString("2015-12-01"))
  if valid_604267 != nil:
    section.add "Version", valid_604267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604268 = header.getOrDefault("X-Amz-Date")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-Date", valid_604268
  var valid_604269 = header.getOrDefault("X-Amz-Security-Token")
  valid_604269 = validateParameter(valid_604269, JString, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "X-Amz-Security-Token", valid_604269
  var valid_604270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "X-Amz-Content-Sha256", valid_604270
  var valid_604271 = header.getOrDefault("X-Amz-Algorithm")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Algorithm", valid_604271
  var valid_604272 = header.getOrDefault("X-Amz-Signature")
  valid_604272 = validateParameter(valid_604272, JString, required = false,
                                 default = nil)
  if valid_604272 != nil:
    section.add "X-Amz-Signature", valid_604272
  var valid_604273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604273 = validateParameter(valid_604273, JString, required = false,
                                 default = nil)
  if valid_604273 != nil:
    section.add "X-Amz-SignedHeaders", valid_604273
  var valid_604274 = header.getOrDefault("X-Amz-Credential")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "X-Amz-Credential", valid_604274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604275: Call_GetSetSubnets_604260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the Availability Zone for the specified public subnets for the specified Application Load Balancer. The specified subnets replace the previously enabled subnets.</p> <p>You can't change the subnets for a Network Load Balancer.</p>
  ## 
  let valid = call_604275.validator(path, query, header, formData, body)
  let scheme = call_604275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604275.url(scheme.get, call_604275.host, call_604275.base,
                         call_604275.route, valid.getOrDefault("path"))
  result = hook(call_604275, url, valid)

proc call*(call_604276: Call_GetSetSubnets_604260; LoadBalancerArn: string;
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
  var query_604277 = newJObject()
  if SubnetMappings != nil:
    query_604277.add "SubnetMappings", SubnetMappings
  add(query_604277, "Action", newJString(Action))
  add(query_604277, "LoadBalancerArn", newJString(LoadBalancerArn))
  if Subnets != nil:
    query_604277.add "Subnets", Subnets
  add(query_604277, "Version", newJString(Version))
  result = call_604276.call(nil, query_604277, nil, nil, nil)

var getSetSubnets* = Call_GetSetSubnets_604260(name: "getSetSubnets",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetSubnets", validator: validate_GetSetSubnets_604261,
    base: "/", url: url_GetSetSubnets_604262, schemes: {Scheme.Https, Scheme.Http})
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
