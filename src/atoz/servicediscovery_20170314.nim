
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Cloud Map
## version: 2017-03-14
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Cloud Map lets you configure public DNS, private DNS, or HTTP namespaces that your microservice applications run in. When an instance of the service becomes available, you can call the AWS Cloud Map API to register the instance with AWS Cloud Map. For public or private DNS namespaces, AWS Cloud Map automatically creates DNS records and an optional health check. Clients that submit public or private DNS queries, or HTTP requests, for the service receive an answer that contains up to eight healthy records. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/servicediscovery/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "servicediscovery.ap-northeast-1.amazonaws.com", "ap-southeast-1": "servicediscovery.ap-southeast-1.amazonaws.com", "us-west-2": "servicediscovery.us-west-2.amazonaws.com", "eu-west-2": "servicediscovery.eu-west-2.amazonaws.com", "ap-northeast-3": "servicediscovery.ap-northeast-3.amazonaws.com", "eu-central-1": "servicediscovery.eu-central-1.amazonaws.com", "us-east-2": "servicediscovery.us-east-2.amazonaws.com", "us-east-1": "servicediscovery.us-east-1.amazonaws.com", "cn-northwest-1": "servicediscovery.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "servicediscovery.ap-south-1.amazonaws.com", "eu-north-1": "servicediscovery.eu-north-1.amazonaws.com", "ap-northeast-2": "servicediscovery.ap-northeast-2.amazonaws.com", "us-west-1": "servicediscovery.us-west-1.amazonaws.com", "us-gov-east-1": "servicediscovery.us-gov-east-1.amazonaws.com", "eu-west-3": "servicediscovery.eu-west-3.amazonaws.com", "cn-north-1": "servicediscovery.cn-north-1.amazonaws.com.cn", "sa-east-1": "servicediscovery.sa-east-1.amazonaws.com", "eu-west-1": "servicediscovery.eu-west-1.amazonaws.com", "us-gov-west-1": "servicediscovery.us-gov-west-1.amazonaws.com", "ap-southeast-2": "servicediscovery.ap-southeast-2.amazonaws.com", "ca-central-1": "servicediscovery.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "servicediscovery.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "servicediscovery.ap-southeast-1.amazonaws.com",
      "us-west-2": "servicediscovery.us-west-2.amazonaws.com",
      "eu-west-2": "servicediscovery.eu-west-2.amazonaws.com",
      "ap-northeast-3": "servicediscovery.ap-northeast-3.amazonaws.com",
      "eu-central-1": "servicediscovery.eu-central-1.amazonaws.com",
      "us-east-2": "servicediscovery.us-east-2.amazonaws.com",
      "us-east-1": "servicediscovery.us-east-1.amazonaws.com",
      "cn-northwest-1": "servicediscovery.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "servicediscovery.ap-south-1.amazonaws.com",
      "eu-north-1": "servicediscovery.eu-north-1.amazonaws.com",
      "ap-northeast-2": "servicediscovery.ap-northeast-2.amazonaws.com",
      "us-west-1": "servicediscovery.us-west-1.amazonaws.com",
      "us-gov-east-1": "servicediscovery.us-gov-east-1.amazonaws.com",
      "eu-west-3": "servicediscovery.eu-west-3.amazonaws.com",
      "cn-north-1": "servicediscovery.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "servicediscovery.sa-east-1.amazonaws.com",
      "eu-west-1": "servicediscovery.eu-west-1.amazonaws.com",
      "us-gov-west-1": "servicediscovery.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "servicediscovery.ap-southeast-2.amazonaws.com",
      "ca-central-1": "servicediscovery.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "servicediscovery"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateHttpNamespace_600768 = ref object of OpenApiRestCall_600426
proc url_CreateHttpNamespace_600770(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateHttpNamespace_600769(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates an HTTP namespace. Service instances that you register using an HTTP namespace can be discovered using a <code>DiscoverInstances</code> request but can't be discovered using DNS. </p> <p>For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
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
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreateHttpNamespace"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_CreateHttpNamespace_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an HTTP namespace. Service instances that you register using an HTTP namespace can be discovered using a <code>DiscoverInstances</code> request but can't be discovered using DNS. </p> <p>For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_CreateHttpNamespace_600768; body: JsonNode): Recallable =
  ## createHttpNamespace
  ## <p>Creates an HTTP namespace. Service instances that you register using an HTTP namespace can be discovered using a <code>DiscoverInstances</code> request but can't be discovered using DNS. </p> <p>For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var createHttpNamespace* = Call_CreateHttpNamespace_600768(
    name: "createHttpNamespace", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreateHttpNamespace",
    validator: validate_CreateHttpNamespace_600769, base: "/",
    url: url_CreateHttpNamespace_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePrivateDnsNamespace_601037 = ref object of OpenApiRestCall_600426
proc url_CreatePrivateDnsNamespace_601039(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePrivateDnsNamespace_601038(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a private namespace based on DNS, which will be visible only inside a specified Amazon VPC. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
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
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreatePrivateDnsNamespace"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_CreatePrivateDnsNamespace_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a private namespace based on DNS, which will be visible only inside a specified Amazon VPC. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_CreatePrivateDnsNamespace_601037; body: JsonNode): Recallable =
  ## createPrivateDnsNamespace
  ## Creates a private namespace based on DNS, which will be visible only inside a specified Amazon VPC. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var createPrivateDnsNamespace* = Call_CreatePrivateDnsNamespace_601037(
    name: "createPrivateDnsNamespace", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreatePrivateDnsNamespace",
    validator: validate_CreatePrivateDnsNamespace_601038, base: "/",
    url: url_CreatePrivateDnsNamespace_601039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicDnsNamespace_601052 = ref object of OpenApiRestCall_600426
proc url_CreatePublicDnsNamespace_601054(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePublicDnsNamespace_601053(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a public namespace based on DNS, which will be visible on the internet. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
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
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreatePublicDnsNamespace"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_CreatePublicDnsNamespace_601052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a public namespace based on DNS, which will be visible on the internet. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_CreatePublicDnsNamespace_601052; body: JsonNode): Recallable =
  ## createPublicDnsNamespace
  ## Creates a public namespace based on DNS, which will be visible on the internet. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var createPublicDnsNamespace* = Call_CreatePublicDnsNamespace_601052(
    name: "createPublicDnsNamespace", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreatePublicDnsNamespace",
    validator: validate_CreatePublicDnsNamespace_601053, base: "/",
    url: url_CreatePublicDnsNamespace_601054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateService_601067 = ref object of OpenApiRestCall_600426
proc url_CreateService_601069(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateService_601068(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a service, which defines the configuration for the following entities:</p> <ul> <li> <p>For public and private DNS namespaces, one of the following combinations of DNS records in Amazon Route 53:</p> <ul> <li> <p>A</p> </li> <li> <p>AAAA</p> </li> <li> <p>A and AAAA</p> </li> <li> <p>SRV</p> </li> <li> <p>CNAME</p> </li> </ul> </li> <li> <p>Optionally, a health check</p> </li> </ul> <p>After you create the service, you can submit a <a>RegisterInstance</a> request, and AWS Cloud Map uses the values in the configuration to create the specified entities.</p> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
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
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreateService"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_CreateService_601067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a service, which defines the configuration for the following entities:</p> <ul> <li> <p>For public and private DNS namespaces, one of the following combinations of DNS records in Amazon Route 53:</p> <ul> <li> <p>A</p> </li> <li> <p>AAAA</p> </li> <li> <p>A and AAAA</p> </li> <li> <p>SRV</p> </li> <li> <p>CNAME</p> </li> </ul> </li> <li> <p>Optionally, a health check</p> </li> </ul> <p>After you create the service, you can submit a <a>RegisterInstance</a> request, and AWS Cloud Map uses the values in the configuration to create the specified entities.</p> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_CreateService_601067; body: JsonNode): Recallable =
  ## createService
  ## <p>Creates a service, which defines the configuration for the following entities:</p> <ul> <li> <p>For public and private DNS namespaces, one of the following combinations of DNS records in Amazon Route 53:</p> <ul> <li> <p>A</p> </li> <li> <p>AAAA</p> </li> <li> <p>A and AAAA</p> </li> <li> <p>SRV</p> </li> <li> <p>CNAME</p> </li> </ul> </li> <li> <p>Optionally, a health check</p> </li> </ul> <p>After you create the service, you can submit a <a>RegisterInstance</a> request, and AWS Cloud Map uses the values in the configuration to create the specified entities.</p> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var createService* = Call_CreateService_601067(name: "createService",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreateService",
    validator: validate_CreateService_601068, base: "/", url: url_CreateService_601069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNamespace_601082 = ref object of OpenApiRestCall_600426
proc url_DeleteNamespace_601084(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteNamespace_601083(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a namespace from the current account. If the namespace still contains one or more services, the request fails.
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
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DeleteNamespace"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_DeleteNamespace_601082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a namespace from the current account. If the namespace still contains one or more services, the request fails.
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_DeleteNamespace_601082; body: JsonNode): Recallable =
  ## deleteNamespace
  ## Deletes a namespace from the current account. If the namespace still contains one or more services, the request fails.
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var deleteNamespace* = Call_DeleteNamespace_601082(name: "deleteNamespace",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DeleteNamespace",
    validator: validate_DeleteNamespace_601083, base: "/", url: url_DeleteNamespace_601084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteService_601097 = ref object of OpenApiRestCall_600426
proc url_DeleteService_601099(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteService_601098(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified service. If the service still contains one or more registered instances, the request fails.
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
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DeleteService"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_DeleteService_601097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified service. If the service still contains one or more registered instances, the request fails.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_DeleteService_601097; body: JsonNode): Recallable =
  ## deleteService
  ## Deletes a specified service. If the service still contains one or more registered instances, the request fails.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var deleteService* = Call_DeleteService_601097(name: "deleteService",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DeleteService",
    validator: validate_DeleteService_601098, base: "/", url: url_DeleteService_601099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterInstance_601112 = ref object of OpenApiRestCall_600426
proc url_DeregisterInstance_601114(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterInstance_601113(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes the Amazon Route 53 DNS records and health check, if any, that AWS Cloud Map created for the specified instance.
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
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DeregisterInstance"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_DeregisterInstance_601112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the Amazon Route 53 DNS records and health check, if any, that AWS Cloud Map created for the specified instance.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_DeregisterInstance_601112; body: JsonNode): Recallable =
  ## deregisterInstance
  ## Deletes the Amazon Route 53 DNS records and health check, if any, that AWS Cloud Map created for the specified instance.
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var deregisterInstance* = Call_DeregisterInstance_601112(
    name: "deregisterInstance", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DeregisterInstance",
    validator: validate_DeregisterInstance_601113, base: "/",
    url: url_DeregisterInstance_601114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DiscoverInstances_601127 = ref object of OpenApiRestCall_600426
proc url_DiscoverInstances_601129(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DiscoverInstances_601128(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Discovers registered instances for a specified namespace and service.
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
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DiscoverInstances"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_DiscoverInstances_601127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Discovers registered instances for a specified namespace and service.
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_DiscoverInstances_601127; body: JsonNode): Recallable =
  ## discoverInstances
  ## Discovers registered instances for a specified namespace and service.
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var discoverInstances* = Call_DiscoverInstances_601127(name: "discoverInstances",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DiscoverInstances",
    validator: validate_DiscoverInstances_601128, base: "/",
    url: url_DiscoverInstances_601129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstance_601142 = ref object of OpenApiRestCall_600426
proc url_GetInstance_601144(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInstance_601143(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specified instance.
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
  var valid_601145 = header.getOrDefault("X-Amz-Date")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Date", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Security-Token")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Security-Token", valid_601146
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601147 = header.getOrDefault("X-Amz-Target")
  valid_601147 = validateParameter(valid_601147, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetInstance"))
  if valid_601147 != nil:
    section.add "X-Amz-Target", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_GetInstance_601142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified instance.
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_GetInstance_601142; body: JsonNode): Recallable =
  ## getInstance
  ## Gets information about a specified instance.
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var getInstance* = Call_GetInstance_601142(name: "getInstance",
                                        meth: HttpMethod.HttpPost,
                                        host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetInstance",
                                        validator: validate_GetInstance_601143,
                                        base: "/", url: url_GetInstance_601144,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstancesHealthStatus_601157 = ref object of OpenApiRestCall_600426
proc url_GetInstancesHealthStatus_601159(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInstancesHealthStatus_601158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the current health status (<code>Healthy</code>, <code>Unhealthy</code>, or <code>Unknown</code>) of one or more instances that are associated with a specified service.</p> <note> <p>There is a brief delay between when you register an instance and when the health status for the instance is available. </p> </note>
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
  var valid_601160 = query.getOrDefault("NextToken")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "NextToken", valid_601160
  var valid_601161 = query.getOrDefault("MaxResults")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "MaxResults", valid_601161
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
  var valid_601162 = header.getOrDefault("X-Amz-Date")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Date", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Security-Token")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Security-Token", valid_601163
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601164 = header.getOrDefault("X-Amz-Target")
  valid_601164 = validateParameter(valid_601164, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetInstancesHealthStatus"))
  if valid_601164 != nil:
    section.add "X-Amz-Target", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Content-Sha256", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Algorithm")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Algorithm", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Signature")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Signature", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-SignedHeaders", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Credential")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Credential", valid_601169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601171: Call_GetInstancesHealthStatus_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the current health status (<code>Healthy</code>, <code>Unhealthy</code>, or <code>Unknown</code>) of one or more instances that are associated with a specified service.</p> <note> <p>There is a brief delay between when you register an instance and when the health status for the instance is available. </p> </note>
  ## 
  let valid = call_601171.validator(path, query, header, formData, body)
  let scheme = call_601171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601171.url(scheme.get, call_601171.host, call_601171.base,
                         call_601171.route, valid.getOrDefault("path"))
  result = hook(call_601171, url, valid)

proc call*(call_601172: Call_GetInstancesHealthStatus_601157; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getInstancesHealthStatus
  ## <p>Gets the current health status (<code>Healthy</code>, <code>Unhealthy</code>, or <code>Unknown</code>) of one or more instances that are associated with a specified service.</p> <note> <p>There is a brief delay between when you register an instance and when the health status for the instance is available. </p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601173 = newJObject()
  var body_601174 = newJObject()
  add(query_601173, "NextToken", newJString(NextToken))
  if body != nil:
    body_601174 = body
  add(query_601173, "MaxResults", newJString(MaxResults))
  result = call_601172.call(nil, query_601173, nil, nil, body_601174)

var getInstancesHealthStatus* = Call_GetInstancesHealthStatus_601157(
    name: "getInstancesHealthStatus", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetInstancesHealthStatus",
    validator: validate_GetInstancesHealthStatus_601158, base: "/",
    url: url_GetInstancesHealthStatus_601159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNamespace_601176 = ref object of OpenApiRestCall_600426
proc url_GetNamespace_601178(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetNamespace_601177(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a namespace.
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
  var valid_601179 = header.getOrDefault("X-Amz-Date")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Date", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Security-Token")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Security-Token", valid_601180
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601181 = header.getOrDefault("X-Amz-Target")
  valid_601181 = validateParameter(valid_601181, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetNamespace"))
  if valid_601181 != nil:
    section.add "X-Amz-Target", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Content-Sha256", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Algorithm")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Algorithm", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Signature")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Signature", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-SignedHeaders", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Credential")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Credential", valid_601186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601188: Call_GetNamespace_601176; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a namespace.
  ## 
  let valid = call_601188.validator(path, query, header, formData, body)
  let scheme = call_601188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601188.url(scheme.get, call_601188.host, call_601188.base,
                         call_601188.route, valid.getOrDefault("path"))
  result = hook(call_601188, url, valid)

proc call*(call_601189: Call_GetNamespace_601176; body: JsonNode): Recallable =
  ## getNamespace
  ## Gets information about a namespace.
  ##   body: JObject (required)
  var body_601190 = newJObject()
  if body != nil:
    body_601190 = body
  result = call_601189.call(nil, nil, nil, nil, body_601190)

var getNamespace* = Call_GetNamespace_601176(name: "getNamespace",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetNamespace",
    validator: validate_GetNamespace_601177, base: "/", url: url_GetNamespace_601178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperation_601191 = ref object of OpenApiRestCall_600426
proc url_GetOperation_601193(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOperation_601192(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about any operation that returns an operation ID in the response, such as a <code>CreateService</code> request.</p> <note> <p>To get a list of operations that match specified criteria, see <a>ListOperations</a>.</p> </note>
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
  var valid_601194 = header.getOrDefault("X-Amz-Date")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Date", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Security-Token")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Security-Token", valid_601195
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601196 = header.getOrDefault("X-Amz-Target")
  valid_601196 = validateParameter(valid_601196, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetOperation"))
  if valid_601196 != nil:
    section.add "X-Amz-Target", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Content-Sha256", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Algorithm")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Algorithm", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Signature")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Signature", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-SignedHeaders", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Credential")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Credential", valid_601201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601203: Call_GetOperation_601191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about any operation that returns an operation ID in the response, such as a <code>CreateService</code> request.</p> <note> <p>To get a list of operations that match specified criteria, see <a>ListOperations</a>.</p> </note>
  ## 
  let valid = call_601203.validator(path, query, header, formData, body)
  let scheme = call_601203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601203.url(scheme.get, call_601203.host, call_601203.base,
                         call_601203.route, valid.getOrDefault("path"))
  result = hook(call_601203, url, valid)

proc call*(call_601204: Call_GetOperation_601191; body: JsonNode): Recallable =
  ## getOperation
  ## <p>Gets information about any operation that returns an operation ID in the response, such as a <code>CreateService</code> request.</p> <note> <p>To get a list of operations that match specified criteria, see <a>ListOperations</a>.</p> </note>
  ##   body: JObject (required)
  var body_601205 = newJObject()
  if body != nil:
    body_601205 = body
  result = call_601204.call(nil, nil, nil, nil, body_601205)

var getOperation* = Call_GetOperation_601191(name: "getOperation",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetOperation",
    validator: validate_GetOperation_601192, base: "/", url: url_GetOperation_601193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetService_601206 = ref object of OpenApiRestCall_600426
proc url_GetService_601208(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetService_601207(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the settings for a specified service.
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
  var valid_601209 = header.getOrDefault("X-Amz-Date")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Date", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Security-Token")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Security-Token", valid_601210
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601211 = header.getOrDefault("X-Amz-Target")
  valid_601211 = validateParameter(valid_601211, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetService"))
  if valid_601211 != nil:
    section.add "X-Amz-Target", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Content-Sha256", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Algorithm")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Algorithm", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Signature")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Signature", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-SignedHeaders", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Credential")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Credential", valid_601216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601218: Call_GetService_601206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the settings for a specified service.
  ## 
  let valid = call_601218.validator(path, query, header, formData, body)
  let scheme = call_601218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601218.url(scheme.get, call_601218.host, call_601218.base,
                         call_601218.route, valid.getOrDefault("path"))
  result = hook(call_601218, url, valid)

proc call*(call_601219: Call_GetService_601206; body: JsonNode): Recallable =
  ## getService
  ## Gets the settings for a specified service.
  ##   body: JObject (required)
  var body_601220 = newJObject()
  if body != nil:
    body_601220 = body
  result = call_601219.call(nil, nil, nil, nil, body_601220)

var getService* = Call_GetService_601206(name: "getService",
                                      meth: HttpMethod.HttpPost,
                                      host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetService",
                                      validator: validate_GetService_601207,
                                      base: "/", url: url_GetService_601208,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstances_601221 = ref object of OpenApiRestCall_600426
proc url_ListInstances_601223(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInstances_601222(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists summary information about the instances that you registered by using a specified service.
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
  var valid_601224 = query.getOrDefault("NextToken")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "NextToken", valid_601224
  var valid_601225 = query.getOrDefault("MaxResults")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "MaxResults", valid_601225
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
  var valid_601226 = header.getOrDefault("X-Amz-Date")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Date", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Security-Token")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Security-Token", valid_601227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601228 = header.getOrDefault("X-Amz-Target")
  valid_601228 = validateParameter(valid_601228, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListInstances"))
  if valid_601228 != nil:
    section.add "X-Amz-Target", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Content-Sha256", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Algorithm")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Algorithm", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Signature")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Signature", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-SignedHeaders", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Credential")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Credential", valid_601233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_ListInstances_601221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists summary information about the instances that you registered by using a specified service.
  ## 
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"))
  result = hook(call_601235, url, valid)

proc call*(call_601236: Call_ListInstances_601221; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listInstances
  ## Lists summary information about the instances that you registered by using a specified service.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601237 = newJObject()
  var body_601238 = newJObject()
  add(query_601237, "NextToken", newJString(NextToken))
  if body != nil:
    body_601238 = body
  add(query_601237, "MaxResults", newJString(MaxResults))
  result = call_601236.call(nil, query_601237, nil, nil, body_601238)

var listInstances* = Call_ListInstances_601221(name: "listInstances",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListInstances",
    validator: validate_ListInstances_601222, base: "/", url: url_ListInstances_601223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNamespaces_601239 = ref object of OpenApiRestCall_600426
proc url_ListNamespaces_601241(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListNamespaces_601240(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists summary information about the namespaces that were created by the current AWS account.
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
  var valid_601242 = query.getOrDefault("NextToken")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "NextToken", valid_601242
  var valid_601243 = query.getOrDefault("MaxResults")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "MaxResults", valid_601243
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
  var valid_601244 = header.getOrDefault("X-Amz-Date")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Date", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Security-Token")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Security-Token", valid_601245
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601246 = header.getOrDefault("X-Amz-Target")
  valid_601246 = validateParameter(valid_601246, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListNamespaces"))
  if valid_601246 != nil:
    section.add "X-Amz-Target", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Content-Sha256", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Algorithm")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Algorithm", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Signature")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Signature", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-SignedHeaders", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Credential")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Credential", valid_601251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601253: Call_ListNamespaces_601239; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists summary information about the namespaces that were created by the current AWS account.
  ## 
  let valid = call_601253.validator(path, query, header, formData, body)
  let scheme = call_601253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601253.url(scheme.get, call_601253.host, call_601253.base,
                         call_601253.route, valid.getOrDefault("path"))
  result = hook(call_601253, url, valid)

proc call*(call_601254: Call_ListNamespaces_601239; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listNamespaces
  ## Lists summary information about the namespaces that were created by the current AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601255 = newJObject()
  var body_601256 = newJObject()
  add(query_601255, "NextToken", newJString(NextToken))
  if body != nil:
    body_601256 = body
  add(query_601255, "MaxResults", newJString(MaxResults))
  result = call_601254.call(nil, query_601255, nil, nil, body_601256)

var listNamespaces* = Call_ListNamespaces_601239(name: "listNamespaces",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListNamespaces",
    validator: validate_ListNamespaces_601240, base: "/", url: url_ListNamespaces_601241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOperations_601257 = ref object of OpenApiRestCall_600426
proc url_ListOperations_601259(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOperations_601258(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists operations that match the criteria that you specify.
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
  var valid_601260 = query.getOrDefault("NextToken")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "NextToken", valid_601260
  var valid_601261 = query.getOrDefault("MaxResults")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "MaxResults", valid_601261
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
  var valid_601262 = header.getOrDefault("X-Amz-Date")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Date", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Security-Token")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Security-Token", valid_601263
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601264 = header.getOrDefault("X-Amz-Target")
  valid_601264 = validateParameter(valid_601264, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListOperations"))
  if valid_601264 != nil:
    section.add "X-Amz-Target", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Content-Sha256", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Algorithm")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Algorithm", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Signature")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Signature", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-SignedHeaders", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Credential")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Credential", valid_601269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601271: Call_ListOperations_601257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists operations that match the criteria that you specify.
  ## 
  let valid = call_601271.validator(path, query, header, formData, body)
  let scheme = call_601271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601271.url(scheme.get, call_601271.host, call_601271.base,
                         call_601271.route, valid.getOrDefault("path"))
  result = hook(call_601271, url, valid)

proc call*(call_601272: Call_ListOperations_601257; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listOperations
  ## Lists operations that match the criteria that you specify.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601273 = newJObject()
  var body_601274 = newJObject()
  add(query_601273, "NextToken", newJString(NextToken))
  if body != nil:
    body_601274 = body
  add(query_601273, "MaxResults", newJString(MaxResults))
  result = call_601272.call(nil, query_601273, nil, nil, body_601274)

var listOperations* = Call_ListOperations_601257(name: "listOperations",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListOperations",
    validator: validate_ListOperations_601258, base: "/", url: url_ListOperations_601259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_601275 = ref object of OpenApiRestCall_600426
proc url_ListServices_601277(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListServices_601276(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists summary information for all the services that are associated with one or more specified namespaces.
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
  var valid_601278 = query.getOrDefault("NextToken")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "NextToken", valid_601278
  var valid_601279 = query.getOrDefault("MaxResults")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "MaxResults", valid_601279
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
  var valid_601280 = header.getOrDefault("X-Amz-Date")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Date", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Security-Token")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Security-Token", valid_601281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601282 = header.getOrDefault("X-Amz-Target")
  valid_601282 = validateParameter(valid_601282, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListServices"))
  if valid_601282 != nil:
    section.add "X-Amz-Target", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Content-Sha256", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Algorithm")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Algorithm", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Signature")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Signature", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-SignedHeaders", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Credential")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Credential", valid_601287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601289: Call_ListServices_601275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists summary information for all the services that are associated with one or more specified namespaces.
  ## 
  let valid = call_601289.validator(path, query, header, formData, body)
  let scheme = call_601289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601289.url(scheme.get, call_601289.host, call_601289.base,
                         call_601289.route, valid.getOrDefault("path"))
  result = hook(call_601289, url, valid)

proc call*(call_601290: Call_ListServices_601275; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listServices
  ## Lists summary information for all the services that are associated with one or more specified namespaces.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601291 = newJObject()
  var body_601292 = newJObject()
  add(query_601291, "NextToken", newJString(NextToken))
  if body != nil:
    body_601292 = body
  add(query_601291, "MaxResults", newJString(MaxResults))
  result = call_601290.call(nil, query_601291, nil, nil, body_601292)

var listServices* = Call_ListServices_601275(name: "listServices",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListServices",
    validator: validate_ListServices_601276, base: "/", url: url_ListServices_601277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterInstance_601293 = ref object of OpenApiRestCall_600426
proc url_RegisterInstance_601295(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterInstance_601294(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates or updates one or more records and, optionally, creates a health check based on the settings in a specified service. When you submit a <code>RegisterInstance</code> request, the following occurs:</p> <ul> <li> <p>For each DNS record that you define in the service that is specified by <code>ServiceId</code>, a record is created or updated in the hosted zone that is associated with the corresponding namespace.</p> </li> <li> <p>If the service includes <code>HealthCheckConfig</code>, a health check is created based on the settings in the health check configuration.</p> </li> <li> <p>The health check, if any, is associated with each of the new or updated records.</p> </li> </ul> <important> <p>One <code>RegisterInstance</code> request must complete before you can submit another request and specify the same service ID and instance ID.</p> </important> <p>For more information, see <a>CreateService</a>.</p> <p>When AWS Cloud Map receives a DNS query for the specified DNS name, it returns the applicable value:</p> <ul> <li> <p> <b>If the health check is healthy</b>: returns all the records</p> </li> <li> <p> <b>If the health check is unhealthy</b>: returns the applicable value for the last healthy instance</p> </li> <li> <p> <b>If you didn't specify a health check configuration</b>: returns all the records</p> </li> </ul> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
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
  var valid_601296 = header.getOrDefault("X-Amz-Date")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Date", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Security-Token")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Security-Token", valid_601297
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601298 = header.getOrDefault("X-Amz-Target")
  valid_601298 = validateParameter(valid_601298, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.RegisterInstance"))
  if valid_601298 != nil:
    section.add "X-Amz-Target", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Content-Sha256", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Algorithm")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Algorithm", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Signature")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Signature", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-SignedHeaders", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Credential")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Credential", valid_601303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601305: Call_RegisterInstance_601293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates one or more records and, optionally, creates a health check based on the settings in a specified service. When you submit a <code>RegisterInstance</code> request, the following occurs:</p> <ul> <li> <p>For each DNS record that you define in the service that is specified by <code>ServiceId</code>, a record is created or updated in the hosted zone that is associated with the corresponding namespace.</p> </li> <li> <p>If the service includes <code>HealthCheckConfig</code>, a health check is created based on the settings in the health check configuration.</p> </li> <li> <p>The health check, if any, is associated with each of the new or updated records.</p> </li> </ul> <important> <p>One <code>RegisterInstance</code> request must complete before you can submit another request and specify the same service ID and instance ID.</p> </important> <p>For more information, see <a>CreateService</a>.</p> <p>When AWS Cloud Map receives a DNS query for the specified DNS name, it returns the applicable value:</p> <ul> <li> <p> <b>If the health check is healthy</b>: returns all the records</p> </li> <li> <p> <b>If the health check is unhealthy</b>: returns the applicable value for the last healthy instance</p> </li> <li> <p> <b>If you didn't specify a health check configuration</b>: returns all the records</p> </li> </ul> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ## 
  let valid = call_601305.validator(path, query, header, formData, body)
  let scheme = call_601305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601305.url(scheme.get, call_601305.host, call_601305.base,
                         call_601305.route, valid.getOrDefault("path"))
  result = hook(call_601305, url, valid)

proc call*(call_601306: Call_RegisterInstance_601293; body: JsonNode): Recallable =
  ## registerInstance
  ## <p>Creates or updates one or more records and, optionally, creates a health check based on the settings in a specified service. When you submit a <code>RegisterInstance</code> request, the following occurs:</p> <ul> <li> <p>For each DNS record that you define in the service that is specified by <code>ServiceId</code>, a record is created or updated in the hosted zone that is associated with the corresponding namespace.</p> </li> <li> <p>If the service includes <code>HealthCheckConfig</code>, a health check is created based on the settings in the health check configuration.</p> </li> <li> <p>The health check, if any, is associated with each of the new or updated records.</p> </li> </ul> <important> <p>One <code>RegisterInstance</code> request must complete before you can submit another request and specify the same service ID and instance ID.</p> </important> <p>For more information, see <a>CreateService</a>.</p> <p>When AWS Cloud Map receives a DNS query for the specified DNS name, it returns the applicable value:</p> <ul> <li> <p> <b>If the health check is healthy</b>: returns all the records</p> </li> <li> <p> <b>If the health check is unhealthy</b>: returns the applicable value for the last healthy instance</p> </li> <li> <p> <b>If you didn't specify a health check configuration</b>: returns all the records</p> </li> </ul> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601307 = newJObject()
  if body != nil:
    body_601307 = body
  result = call_601306.call(nil, nil, nil, nil, body_601307)

var registerInstance* = Call_RegisterInstance_601293(name: "registerInstance",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.RegisterInstance",
    validator: validate_RegisterInstance_601294, base: "/",
    url: url_RegisterInstance_601295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceCustomHealthStatus_601308 = ref object of OpenApiRestCall_600426
proc url_UpdateInstanceCustomHealthStatus_601310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateInstanceCustomHealthStatus_601309(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Submits a request to change the health status of a custom health check to healthy or unhealthy.</p> <p>You can use <code>UpdateInstanceCustomHealthStatus</code> to change the status only for custom health checks, which you define using <code>HealthCheckCustomConfig</code> when you create a service. You can't use it to change the status for Route 53 health checks, which you define using <code>HealthCheckConfig</code>.</p> <p>For more information, see <a>HealthCheckCustomConfig</a>.</p>
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
  var valid_601311 = header.getOrDefault("X-Amz-Date")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Date", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Security-Token")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Security-Token", valid_601312
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601313 = header.getOrDefault("X-Amz-Target")
  valid_601313 = validateParameter(valid_601313, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.UpdateInstanceCustomHealthStatus"))
  if valid_601313 != nil:
    section.add "X-Amz-Target", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Content-Sha256", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Algorithm")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Algorithm", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Signature")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Signature", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-SignedHeaders", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Credential")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Credential", valid_601318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601320: Call_UpdateInstanceCustomHealthStatus_601308;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Submits a request to change the health status of a custom health check to healthy or unhealthy.</p> <p>You can use <code>UpdateInstanceCustomHealthStatus</code> to change the status only for custom health checks, which you define using <code>HealthCheckCustomConfig</code> when you create a service. You can't use it to change the status for Route 53 health checks, which you define using <code>HealthCheckConfig</code>.</p> <p>For more information, see <a>HealthCheckCustomConfig</a>.</p>
  ## 
  let valid = call_601320.validator(path, query, header, formData, body)
  let scheme = call_601320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601320.url(scheme.get, call_601320.host, call_601320.base,
                         call_601320.route, valid.getOrDefault("path"))
  result = hook(call_601320, url, valid)

proc call*(call_601321: Call_UpdateInstanceCustomHealthStatus_601308;
          body: JsonNode): Recallable =
  ## updateInstanceCustomHealthStatus
  ## <p>Submits a request to change the health status of a custom health check to healthy or unhealthy.</p> <p>You can use <code>UpdateInstanceCustomHealthStatus</code> to change the status only for custom health checks, which you define using <code>HealthCheckCustomConfig</code> when you create a service. You can't use it to change the status for Route 53 health checks, which you define using <code>HealthCheckConfig</code>.</p> <p>For more information, see <a>HealthCheckCustomConfig</a>.</p>
  ##   body: JObject (required)
  var body_601322 = newJObject()
  if body != nil:
    body_601322 = body
  result = call_601321.call(nil, nil, nil, nil, body_601322)

var updateInstanceCustomHealthStatus* = Call_UpdateInstanceCustomHealthStatus_601308(
    name: "updateInstanceCustomHealthStatus", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.UpdateInstanceCustomHealthStatus",
    validator: validate_UpdateInstanceCustomHealthStatus_601309, base: "/",
    url: url_UpdateInstanceCustomHealthStatus_601310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateService_601323 = ref object of OpenApiRestCall_600426
proc url_UpdateService_601325(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateService_601324(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Submits a request to perform the following operations:</p> <ul> <li> <p>Add or delete <code>DnsRecords</code> configurations</p> </li> <li> <p>Update the TTL setting for existing <code>DnsRecords</code> configurations</p> </li> <li> <p>Add, update, or delete <code>HealthCheckConfig</code> for a specified service</p> </li> </ul> <p>For public and private DNS namespaces, you must specify all <code>DnsRecords</code> configurations (and, optionally, <code>HealthCheckConfig</code>) that you want to appear in the updated service. Any current configurations that don't appear in an <code>UpdateService</code> request are deleted.</p> <p>When you update the TTL setting for a service, AWS Cloud Map also updates the corresponding settings in all the records and health checks that were created by using the specified service.</p>
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
  var valid_601326 = header.getOrDefault("X-Amz-Date")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Date", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Security-Token")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Security-Token", valid_601327
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601328 = header.getOrDefault("X-Amz-Target")
  valid_601328 = validateParameter(valid_601328, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.UpdateService"))
  if valid_601328 != nil:
    section.add "X-Amz-Target", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Content-Sha256", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Algorithm")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Algorithm", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Signature")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Signature", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-SignedHeaders", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Credential")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Credential", valid_601333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601335: Call_UpdateService_601323; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Submits a request to perform the following operations:</p> <ul> <li> <p>Add or delete <code>DnsRecords</code> configurations</p> </li> <li> <p>Update the TTL setting for existing <code>DnsRecords</code> configurations</p> </li> <li> <p>Add, update, or delete <code>HealthCheckConfig</code> for a specified service</p> </li> </ul> <p>For public and private DNS namespaces, you must specify all <code>DnsRecords</code> configurations (and, optionally, <code>HealthCheckConfig</code>) that you want to appear in the updated service. Any current configurations that don't appear in an <code>UpdateService</code> request are deleted.</p> <p>When you update the TTL setting for a service, AWS Cloud Map also updates the corresponding settings in all the records and health checks that were created by using the specified service.</p>
  ## 
  let valid = call_601335.validator(path, query, header, formData, body)
  let scheme = call_601335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601335.url(scheme.get, call_601335.host, call_601335.base,
                         call_601335.route, valid.getOrDefault("path"))
  result = hook(call_601335, url, valid)

proc call*(call_601336: Call_UpdateService_601323; body: JsonNode): Recallable =
  ## updateService
  ## <p>Submits a request to perform the following operations:</p> <ul> <li> <p>Add or delete <code>DnsRecords</code> configurations</p> </li> <li> <p>Update the TTL setting for existing <code>DnsRecords</code> configurations</p> </li> <li> <p>Add, update, or delete <code>HealthCheckConfig</code> for a specified service</p> </li> </ul> <p>For public and private DNS namespaces, you must specify all <code>DnsRecords</code> configurations (and, optionally, <code>HealthCheckConfig</code>) that you want to appear in the updated service. Any current configurations that don't appear in an <code>UpdateService</code> request are deleted.</p> <p>When you update the TTL setting for a service, AWS Cloud Map also updates the corresponding settings in all the records and health checks that were created by using the specified service.</p>
  ##   body: JObject (required)
  var body_601337 = newJObject()
  if body != nil:
    body_601337 = body
  result = call_601336.call(nil, nil, nil, nil, body_601337)

var updateService* = Call_UpdateService_601323(name: "updateService",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.UpdateService",
    validator: validate_UpdateService_601324, base: "/", url: url_UpdateService_601325,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
