
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateHttpNamespace_600774 = ref object of OpenApiRestCall_600437
proc url_CreateHttpNamespace_600776(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateHttpNamespace_600775(path: JsonNode; query: JsonNode;
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
  var valid_600888 = header.getOrDefault("X-Amz-Date")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Date", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Security-Token")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Security-Token", valid_600889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600903 = header.getOrDefault("X-Amz-Target")
  valid_600903 = validateParameter(valid_600903, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreateHttpNamespace"))
  if valid_600903 != nil:
    section.add "X-Amz-Target", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Content-Sha256", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Algorithm")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Algorithm", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Signature")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Signature", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-SignedHeaders", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Credential")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Credential", valid_600908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600932: Call_CreateHttpNamespace_600774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an HTTP namespace. Service instances that you register using an HTTP namespace can be discovered using a <code>DiscoverInstances</code> request but can't be discovered using DNS. </p> <p>For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ## 
  let valid = call_600932.validator(path, query, header, formData, body)
  let scheme = call_600932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600932.url(scheme.get, call_600932.host, call_600932.base,
                         call_600932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600932, url, valid)

proc call*(call_601003: Call_CreateHttpNamespace_600774; body: JsonNode): Recallable =
  ## createHttpNamespace
  ## <p>Creates an HTTP namespace. Service instances that you register using an HTTP namespace can be discovered using a <code>DiscoverInstances</code> request but can't be discovered using DNS. </p> <p>For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601004 = newJObject()
  if body != nil:
    body_601004 = body
  result = call_601003.call(nil, nil, nil, nil, body_601004)

var createHttpNamespace* = Call_CreateHttpNamespace_600774(
    name: "createHttpNamespace", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreateHttpNamespace",
    validator: validate_CreateHttpNamespace_600775, base: "/",
    url: url_CreateHttpNamespace_600776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePrivateDnsNamespace_601043 = ref object of OpenApiRestCall_600437
proc url_CreatePrivateDnsNamespace_601045(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePrivateDnsNamespace_601044(path: JsonNode; query: JsonNode;
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
  var valid_601046 = header.getOrDefault("X-Amz-Date")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Date", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Security-Token")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Security-Token", valid_601047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601048 = header.getOrDefault("X-Amz-Target")
  valid_601048 = validateParameter(valid_601048, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreatePrivateDnsNamespace"))
  if valid_601048 != nil:
    section.add "X-Amz-Target", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Content-Sha256", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Algorithm")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Algorithm", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Signature")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Signature", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-SignedHeaders", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Credential")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Credential", valid_601053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601055: Call_CreatePrivateDnsNamespace_601043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a private namespace based on DNS, which will be visible only inside a specified Amazon VPC. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ## 
  let valid = call_601055.validator(path, query, header, formData, body)
  let scheme = call_601055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601055.url(scheme.get, call_601055.host, call_601055.base,
                         call_601055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601055, url, valid)

proc call*(call_601056: Call_CreatePrivateDnsNamespace_601043; body: JsonNode): Recallable =
  ## createPrivateDnsNamespace
  ## Creates a private namespace based on DNS, which will be visible only inside a specified Amazon VPC. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ##   body: JObject (required)
  var body_601057 = newJObject()
  if body != nil:
    body_601057 = body
  result = call_601056.call(nil, nil, nil, nil, body_601057)

var createPrivateDnsNamespace* = Call_CreatePrivateDnsNamespace_601043(
    name: "createPrivateDnsNamespace", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreatePrivateDnsNamespace",
    validator: validate_CreatePrivateDnsNamespace_601044, base: "/",
    url: url_CreatePrivateDnsNamespace_601045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicDnsNamespace_601058 = ref object of OpenApiRestCall_600437
proc url_CreatePublicDnsNamespace_601060(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePublicDnsNamespace_601059(path: JsonNode; query: JsonNode;
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
  var valid_601061 = header.getOrDefault("X-Amz-Date")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Date", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Security-Token")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Security-Token", valid_601062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601063 = header.getOrDefault("X-Amz-Target")
  valid_601063 = validateParameter(valid_601063, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreatePublicDnsNamespace"))
  if valid_601063 != nil:
    section.add "X-Amz-Target", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Content-Sha256", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Algorithm")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Algorithm", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Signature")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Signature", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-SignedHeaders", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Credential")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Credential", valid_601068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601070: Call_CreatePublicDnsNamespace_601058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a public namespace based on DNS, which will be visible on the internet. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ## 
  let valid = call_601070.validator(path, query, header, formData, body)
  let scheme = call_601070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601070.url(scheme.get, call_601070.host, call_601070.base,
                         call_601070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601070, url, valid)

proc call*(call_601071: Call_CreatePublicDnsNamespace_601058; body: JsonNode): Recallable =
  ## createPublicDnsNamespace
  ## Creates a public namespace based on DNS, which will be visible on the internet. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ##   body: JObject (required)
  var body_601072 = newJObject()
  if body != nil:
    body_601072 = body
  result = call_601071.call(nil, nil, nil, nil, body_601072)

var createPublicDnsNamespace* = Call_CreatePublicDnsNamespace_601058(
    name: "createPublicDnsNamespace", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreatePublicDnsNamespace",
    validator: validate_CreatePublicDnsNamespace_601059, base: "/",
    url: url_CreatePublicDnsNamespace_601060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateService_601073 = ref object of OpenApiRestCall_600437
proc url_CreateService_601075(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateService_601074(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601076 = header.getOrDefault("X-Amz-Date")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Date", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Security-Token")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Security-Token", valid_601077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601078 = header.getOrDefault("X-Amz-Target")
  valid_601078 = validateParameter(valid_601078, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreateService"))
  if valid_601078 != nil:
    section.add "X-Amz-Target", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Content-Sha256", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Algorithm")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Algorithm", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Signature")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Signature", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-SignedHeaders", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Credential")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Credential", valid_601083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601085: Call_CreateService_601073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a service, which defines the configuration for the following entities:</p> <ul> <li> <p>For public and private DNS namespaces, one of the following combinations of DNS records in Amazon Route 53:</p> <ul> <li> <p>A</p> </li> <li> <p>AAAA</p> </li> <li> <p>A and AAAA</p> </li> <li> <p>SRV</p> </li> <li> <p>CNAME</p> </li> </ul> </li> <li> <p>Optionally, a health check</p> </li> </ul> <p>After you create the service, you can submit a <a>RegisterInstance</a> request, and AWS Cloud Map uses the values in the configuration to create the specified entities.</p> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ## 
  let valid = call_601085.validator(path, query, header, formData, body)
  let scheme = call_601085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601085.url(scheme.get, call_601085.host, call_601085.base,
                         call_601085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601085, url, valid)

proc call*(call_601086: Call_CreateService_601073; body: JsonNode): Recallable =
  ## createService
  ## <p>Creates a service, which defines the configuration for the following entities:</p> <ul> <li> <p>For public and private DNS namespaces, one of the following combinations of DNS records in Amazon Route 53:</p> <ul> <li> <p>A</p> </li> <li> <p>AAAA</p> </li> <li> <p>A and AAAA</p> </li> <li> <p>SRV</p> </li> <li> <p>CNAME</p> </li> </ul> </li> <li> <p>Optionally, a health check</p> </li> </ul> <p>After you create the service, you can submit a <a>RegisterInstance</a> request, and AWS Cloud Map uses the values in the configuration to create the specified entities.</p> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601087 = newJObject()
  if body != nil:
    body_601087 = body
  result = call_601086.call(nil, nil, nil, nil, body_601087)

var createService* = Call_CreateService_601073(name: "createService",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreateService",
    validator: validate_CreateService_601074, base: "/", url: url_CreateService_601075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNamespace_601088 = ref object of OpenApiRestCall_600437
proc url_DeleteNamespace_601090(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteNamespace_601089(path: JsonNode; query: JsonNode;
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
  var valid_601091 = header.getOrDefault("X-Amz-Date")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Date", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Security-Token")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Security-Token", valid_601092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601093 = header.getOrDefault("X-Amz-Target")
  valid_601093 = validateParameter(valid_601093, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DeleteNamespace"))
  if valid_601093 != nil:
    section.add "X-Amz-Target", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Content-Sha256", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Algorithm")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Algorithm", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Signature")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Signature", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-SignedHeaders", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Credential")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Credential", valid_601098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601100: Call_DeleteNamespace_601088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a namespace from the current account. If the namespace still contains one or more services, the request fails.
  ## 
  let valid = call_601100.validator(path, query, header, formData, body)
  let scheme = call_601100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601100.url(scheme.get, call_601100.host, call_601100.base,
                         call_601100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601100, url, valid)

proc call*(call_601101: Call_DeleteNamespace_601088; body: JsonNode): Recallable =
  ## deleteNamespace
  ## Deletes a namespace from the current account. If the namespace still contains one or more services, the request fails.
  ##   body: JObject (required)
  var body_601102 = newJObject()
  if body != nil:
    body_601102 = body
  result = call_601101.call(nil, nil, nil, nil, body_601102)

var deleteNamespace* = Call_DeleteNamespace_601088(name: "deleteNamespace",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DeleteNamespace",
    validator: validate_DeleteNamespace_601089, base: "/", url: url_DeleteNamespace_601090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteService_601103 = ref object of OpenApiRestCall_600437
proc url_DeleteService_601105(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteService_601104(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601106 = header.getOrDefault("X-Amz-Date")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Date", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Security-Token")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Security-Token", valid_601107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601108 = header.getOrDefault("X-Amz-Target")
  valid_601108 = validateParameter(valid_601108, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DeleteService"))
  if valid_601108 != nil:
    section.add "X-Amz-Target", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Content-Sha256", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Algorithm")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Algorithm", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Signature")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Signature", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-SignedHeaders", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Credential")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Credential", valid_601113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601115: Call_DeleteService_601103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified service. If the service still contains one or more registered instances, the request fails.
  ## 
  let valid = call_601115.validator(path, query, header, formData, body)
  let scheme = call_601115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601115.url(scheme.get, call_601115.host, call_601115.base,
                         call_601115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601115, url, valid)

proc call*(call_601116: Call_DeleteService_601103; body: JsonNode): Recallable =
  ## deleteService
  ## Deletes a specified service. If the service still contains one or more registered instances, the request fails.
  ##   body: JObject (required)
  var body_601117 = newJObject()
  if body != nil:
    body_601117 = body
  result = call_601116.call(nil, nil, nil, nil, body_601117)

var deleteService* = Call_DeleteService_601103(name: "deleteService",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DeleteService",
    validator: validate_DeleteService_601104, base: "/", url: url_DeleteService_601105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterInstance_601118 = ref object of OpenApiRestCall_600437
proc url_DeregisterInstance_601120(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterInstance_601119(path: JsonNode; query: JsonNode;
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
  var valid_601121 = header.getOrDefault("X-Amz-Date")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Date", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Security-Token")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Security-Token", valid_601122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601123 = header.getOrDefault("X-Amz-Target")
  valid_601123 = validateParameter(valid_601123, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DeregisterInstance"))
  if valid_601123 != nil:
    section.add "X-Amz-Target", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Content-Sha256", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Algorithm")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Algorithm", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Signature")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Signature", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-SignedHeaders", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Credential")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Credential", valid_601128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601130: Call_DeregisterInstance_601118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the Amazon Route 53 DNS records and health check, if any, that AWS Cloud Map created for the specified instance.
  ## 
  let valid = call_601130.validator(path, query, header, formData, body)
  let scheme = call_601130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601130.url(scheme.get, call_601130.host, call_601130.base,
                         call_601130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601130, url, valid)

proc call*(call_601131: Call_DeregisterInstance_601118; body: JsonNode): Recallable =
  ## deregisterInstance
  ## Deletes the Amazon Route 53 DNS records and health check, if any, that AWS Cloud Map created for the specified instance.
  ##   body: JObject (required)
  var body_601132 = newJObject()
  if body != nil:
    body_601132 = body
  result = call_601131.call(nil, nil, nil, nil, body_601132)

var deregisterInstance* = Call_DeregisterInstance_601118(
    name: "deregisterInstance", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DeregisterInstance",
    validator: validate_DeregisterInstance_601119, base: "/",
    url: url_DeregisterInstance_601120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DiscoverInstances_601133 = ref object of OpenApiRestCall_600437
proc url_DiscoverInstances_601135(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DiscoverInstances_601134(path: JsonNode; query: JsonNode;
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
  var valid_601136 = header.getOrDefault("X-Amz-Date")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Date", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Security-Token")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Security-Token", valid_601137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601138 = header.getOrDefault("X-Amz-Target")
  valid_601138 = validateParameter(valid_601138, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DiscoverInstances"))
  if valid_601138 != nil:
    section.add "X-Amz-Target", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Content-Sha256", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Algorithm")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Algorithm", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Signature", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-SignedHeaders", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Credential")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Credential", valid_601143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601145: Call_DiscoverInstances_601133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Discovers registered instances for a specified namespace and service.
  ## 
  let valid = call_601145.validator(path, query, header, formData, body)
  let scheme = call_601145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601145.url(scheme.get, call_601145.host, call_601145.base,
                         call_601145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601145, url, valid)

proc call*(call_601146: Call_DiscoverInstances_601133; body: JsonNode): Recallable =
  ## discoverInstances
  ## Discovers registered instances for a specified namespace and service.
  ##   body: JObject (required)
  var body_601147 = newJObject()
  if body != nil:
    body_601147 = body
  result = call_601146.call(nil, nil, nil, nil, body_601147)

var discoverInstances* = Call_DiscoverInstances_601133(name: "discoverInstances",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DiscoverInstances",
    validator: validate_DiscoverInstances_601134, base: "/",
    url: url_DiscoverInstances_601135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstance_601148 = ref object of OpenApiRestCall_600437
proc url_GetInstance_601150(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstance_601149(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601151 = header.getOrDefault("X-Amz-Date")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Date", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Security-Token")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Security-Token", valid_601152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601153 = header.getOrDefault("X-Amz-Target")
  valid_601153 = validateParameter(valid_601153, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetInstance"))
  if valid_601153 != nil:
    section.add "X-Amz-Target", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601160: Call_GetInstance_601148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified instance.
  ## 
  let valid = call_601160.validator(path, query, header, formData, body)
  let scheme = call_601160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601160.url(scheme.get, call_601160.host, call_601160.base,
                         call_601160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601160, url, valid)

proc call*(call_601161: Call_GetInstance_601148; body: JsonNode): Recallable =
  ## getInstance
  ## Gets information about a specified instance.
  ##   body: JObject (required)
  var body_601162 = newJObject()
  if body != nil:
    body_601162 = body
  result = call_601161.call(nil, nil, nil, nil, body_601162)

var getInstance* = Call_GetInstance_601148(name: "getInstance",
                                        meth: HttpMethod.HttpPost,
                                        host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetInstance",
                                        validator: validate_GetInstance_601149,
                                        base: "/", url: url_GetInstance_601150,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstancesHealthStatus_601163 = ref object of OpenApiRestCall_600437
proc url_GetInstancesHealthStatus_601165(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstancesHealthStatus_601164(path: JsonNode; query: JsonNode;
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
  var valid_601166 = query.getOrDefault("NextToken")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "NextToken", valid_601166
  var valid_601167 = query.getOrDefault("MaxResults")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "MaxResults", valid_601167
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
  var valid_601168 = header.getOrDefault("X-Amz-Date")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Date", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Security-Token")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Security-Token", valid_601169
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601170 = header.getOrDefault("X-Amz-Target")
  valid_601170 = validateParameter(valid_601170, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetInstancesHealthStatus"))
  if valid_601170 != nil:
    section.add "X-Amz-Target", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Content-Sha256", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Algorithm")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Algorithm", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Signature")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Signature", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-SignedHeaders", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-Credential")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Credential", valid_601175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601177: Call_GetInstancesHealthStatus_601163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the current health status (<code>Healthy</code>, <code>Unhealthy</code>, or <code>Unknown</code>) of one or more instances that are associated with a specified service.</p> <note> <p>There is a brief delay between when you register an instance and when the health status for the instance is available. </p> </note>
  ## 
  let valid = call_601177.validator(path, query, header, formData, body)
  let scheme = call_601177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601177.url(scheme.get, call_601177.host, call_601177.base,
                         call_601177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601177, url, valid)

proc call*(call_601178: Call_GetInstancesHealthStatus_601163; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getInstancesHealthStatus
  ## <p>Gets the current health status (<code>Healthy</code>, <code>Unhealthy</code>, or <code>Unknown</code>) of one or more instances that are associated with a specified service.</p> <note> <p>There is a brief delay between when you register an instance and when the health status for the instance is available. </p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601179 = newJObject()
  var body_601180 = newJObject()
  add(query_601179, "NextToken", newJString(NextToken))
  if body != nil:
    body_601180 = body
  add(query_601179, "MaxResults", newJString(MaxResults))
  result = call_601178.call(nil, query_601179, nil, nil, body_601180)

var getInstancesHealthStatus* = Call_GetInstancesHealthStatus_601163(
    name: "getInstancesHealthStatus", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetInstancesHealthStatus",
    validator: validate_GetInstancesHealthStatus_601164, base: "/",
    url: url_GetInstancesHealthStatus_601165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNamespace_601182 = ref object of OpenApiRestCall_600437
proc url_GetNamespace_601184(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetNamespace_601183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601185 = header.getOrDefault("X-Amz-Date")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Date", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Security-Token")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Security-Token", valid_601186
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601187 = header.getOrDefault("X-Amz-Target")
  valid_601187 = validateParameter(valid_601187, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetNamespace"))
  if valid_601187 != nil:
    section.add "X-Amz-Target", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Content-Sha256", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Algorithm")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Algorithm", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Signature")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Signature", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-SignedHeaders", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Credential")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Credential", valid_601192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601194: Call_GetNamespace_601182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a namespace.
  ## 
  let valid = call_601194.validator(path, query, header, formData, body)
  let scheme = call_601194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601194.url(scheme.get, call_601194.host, call_601194.base,
                         call_601194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601194, url, valid)

proc call*(call_601195: Call_GetNamespace_601182; body: JsonNode): Recallable =
  ## getNamespace
  ## Gets information about a namespace.
  ##   body: JObject (required)
  var body_601196 = newJObject()
  if body != nil:
    body_601196 = body
  result = call_601195.call(nil, nil, nil, nil, body_601196)

var getNamespace* = Call_GetNamespace_601182(name: "getNamespace",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetNamespace",
    validator: validate_GetNamespace_601183, base: "/", url: url_GetNamespace_601184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperation_601197 = ref object of OpenApiRestCall_600437
proc url_GetOperation_601199(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOperation_601198(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601200 = header.getOrDefault("X-Amz-Date")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Date", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Security-Token")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Security-Token", valid_601201
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601202 = header.getOrDefault("X-Amz-Target")
  valid_601202 = validateParameter(valid_601202, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetOperation"))
  if valid_601202 != nil:
    section.add "X-Amz-Target", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Content-Sha256", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Algorithm")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Algorithm", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Signature")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Signature", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-SignedHeaders", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Credential")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Credential", valid_601207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601209: Call_GetOperation_601197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about any operation that returns an operation ID in the response, such as a <code>CreateService</code> request.</p> <note> <p>To get a list of operations that match specified criteria, see <a>ListOperations</a>.</p> </note>
  ## 
  let valid = call_601209.validator(path, query, header, formData, body)
  let scheme = call_601209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601209.url(scheme.get, call_601209.host, call_601209.base,
                         call_601209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601209, url, valid)

proc call*(call_601210: Call_GetOperation_601197; body: JsonNode): Recallable =
  ## getOperation
  ## <p>Gets information about any operation that returns an operation ID in the response, such as a <code>CreateService</code> request.</p> <note> <p>To get a list of operations that match specified criteria, see <a>ListOperations</a>.</p> </note>
  ##   body: JObject (required)
  var body_601211 = newJObject()
  if body != nil:
    body_601211 = body
  result = call_601210.call(nil, nil, nil, nil, body_601211)

var getOperation* = Call_GetOperation_601197(name: "getOperation",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetOperation",
    validator: validate_GetOperation_601198, base: "/", url: url_GetOperation_601199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetService_601212 = ref object of OpenApiRestCall_600437
proc url_GetService_601214(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetService_601213(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601215 = header.getOrDefault("X-Amz-Date")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Date", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Security-Token")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Security-Token", valid_601216
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601217 = header.getOrDefault("X-Amz-Target")
  valid_601217 = validateParameter(valid_601217, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetService"))
  if valid_601217 != nil:
    section.add "X-Amz-Target", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Content-Sha256", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Algorithm")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Algorithm", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Signature")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Signature", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-SignedHeaders", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Credential")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Credential", valid_601222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601224: Call_GetService_601212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the settings for a specified service.
  ## 
  let valid = call_601224.validator(path, query, header, formData, body)
  let scheme = call_601224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601224.url(scheme.get, call_601224.host, call_601224.base,
                         call_601224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601224, url, valid)

proc call*(call_601225: Call_GetService_601212; body: JsonNode): Recallable =
  ## getService
  ## Gets the settings for a specified service.
  ##   body: JObject (required)
  var body_601226 = newJObject()
  if body != nil:
    body_601226 = body
  result = call_601225.call(nil, nil, nil, nil, body_601226)

var getService* = Call_GetService_601212(name: "getService",
                                      meth: HttpMethod.HttpPost,
                                      host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetService",
                                      validator: validate_GetService_601213,
                                      base: "/", url: url_GetService_601214,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstances_601227 = ref object of OpenApiRestCall_600437
proc url_ListInstances_601229(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInstances_601228(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601230 = query.getOrDefault("NextToken")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "NextToken", valid_601230
  var valid_601231 = query.getOrDefault("MaxResults")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "MaxResults", valid_601231
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
  var valid_601232 = header.getOrDefault("X-Amz-Date")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Date", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Security-Token")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Security-Token", valid_601233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601234 = header.getOrDefault("X-Amz-Target")
  valid_601234 = validateParameter(valid_601234, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListInstances"))
  if valid_601234 != nil:
    section.add "X-Amz-Target", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Content-Sha256", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Algorithm")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Algorithm", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Signature")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Signature", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-SignedHeaders", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Credential")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Credential", valid_601239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601241: Call_ListInstances_601227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists summary information about the instances that you registered by using a specified service.
  ## 
  let valid = call_601241.validator(path, query, header, formData, body)
  let scheme = call_601241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601241.url(scheme.get, call_601241.host, call_601241.base,
                         call_601241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601241, url, valid)

proc call*(call_601242: Call_ListInstances_601227; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listInstances
  ## Lists summary information about the instances that you registered by using a specified service.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601243 = newJObject()
  var body_601244 = newJObject()
  add(query_601243, "NextToken", newJString(NextToken))
  if body != nil:
    body_601244 = body
  add(query_601243, "MaxResults", newJString(MaxResults))
  result = call_601242.call(nil, query_601243, nil, nil, body_601244)

var listInstances* = Call_ListInstances_601227(name: "listInstances",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListInstances",
    validator: validate_ListInstances_601228, base: "/", url: url_ListInstances_601229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNamespaces_601245 = ref object of OpenApiRestCall_600437
proc url_ListNamespaces_601247(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNamespaces_601246(path: JsonNode; query: JsonNode;
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
  var valid_601248 = query.getOrDefault("NextToken")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "NextToken", valid_601248
  var valid_601249 = query.getOrDefault("MaxResults")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "MaxResults", valid_601249
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
  var valid_601250 = header.getOrDefault("X-Amz-Date")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Date", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Security-Token")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Security-Token", valid_601251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601252 = header.getOrDefault("X-Amz-Target")
  valid_601252 = validateParameter(valid_601252, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListNamespaces"))
  if valid_601252 != nil:
    section.add "X-Amz-Target", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Content-Sha256", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Algorithm")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Algorithm", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Signature")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Signature", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-SignedHeaders", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Credential")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Credential", valid_601257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601259: Call_ListNamespaces_601245; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists summary information about the namespaces that were created by the current AWS account.
  ## 
  let valid = call_601259.validator(path, query, header, formData, body)
  let scheme = call_601259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601259.url(scheme.get, call_601259.host, call_601259.base,
                         call_601259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601259, url, valid)

proc call*(call_601260: Call_ListNamespaces_601245; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listNamespaces
  ## Lists summary information about the namespaces that were created by the current AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601261 = newJObject()
  var body_601262 = newJObject()
  add(query_601261, "NextToken", newJString(NextToken))
  if body != nil:
    body_601262 = body
  add(query_601261, "MaxResults", newJString(MaxResults))
  result = call_601260.call(nil, query_601261, nil, nil, body_601262)

var listNamespaces* = Call_ListNamespaces_601245(name: "listNamespaces",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListNamespaces",
    validator: validate_ListNamespaces_601246, base: "/", url: url_ListNamespaces_601247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOperations_601263 = ref object of OpenApiRestCall_600437
proc url_ListOperations_601265(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOperations_601264(path: JsonNode; query: JsonNode;
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
  var valid_601266 = query.getOrDefault("NextToken")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "NextToken", valid_601266
  var valid_601267 = query.getOrDefault("MaxResults")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "MaxResults", valid_601267
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
  var valid_601268 = header.getOrDefault("X-Amz-Date")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Date", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Security-Token")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Security-Token", valid_601269
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601270 = header.getOrDefault("X-Amz-Target")
  valid_601270 = validateParameter(valid_601270, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListOperations"))
  if valid_601270 != nil:
    section.add "X-Amz-Target", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Content-Sha256", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Algorithm")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Algorithm", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Signature")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Signature", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-SignedHeaders", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Credential")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Credential", valid_601275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601277: Call_ListOperations_601263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists operations that match the criteria that you specify.
  ## 
  let valid = call_601277.validator(path, query, header, formData, body)
  let scheme = call_601277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601277.url(scheme.get, call_601277.host, call_601277.base,
                         call_601277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601277, url, valid)

proc call*(call_601278: Call_ListOperations_601263; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listOperations
  ## Lists operations that match the criteria that you specify.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601279 = newJObject()
  var body_601280 = newJObject()
  add(query_601279, "NextToken", newJString(NextToken))
  if body != nil:
    body_601280 = body
  add(query_601279, "MaxResults", newJString(MaxResults))
  result = call_601278.call(nil, query_601279, nil, nil, body_601280)

var listOperations* = Call_ListOperations_601263(name: "listOperations",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListOperations",
    validator: validate_ListOperations_601264, base: "/", url: url_ListOperations_601265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_601281 = ref object of OpenApiRestCall_600437
proc url_ListServices_601283(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListServices_601282(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601284 = query.getOrDefault("NextToken")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "NextToken", valid_601284
  var valid_601285 = query.getOrDefault("MaxResults")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "MaxResults", valid_601285
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
  var valid_601286 = header.getOrDefault("X-Amz-Date")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Date", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Security-Token")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Security-Token", valid_601287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601288 = header.getOrDefault("X-Amz-Target")
  valid_601288 = validateParameter(valid_601288, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListServices"))
  if valid_601288 != nil:
    section.add "X-Amz-Target", valid_601288
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601295: Call_ListServices_601281; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists summary information for all the services that are associated with one or more specified namespaces.
  ## 
  let valid = call_601295.validator(path, query, header, formData, body)
  let scheme = call_601295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601295.url(scheme.get, call_601295.host, call_601295.base,
                         call_601295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601295, url, valid)

proc call*(call_601296: Call_ListServices_601281; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listServices
  ## Lists summary information for all the services that are associated with one or more specified namespaces.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601297 = newJObject()
  var body_601298 = newJObject()
  add(query_601297, "NextToken", newJString(NextToken))
  if body != nil:
    body_601298 = body
  add(query_601297, "MaxResults", newJString(MaxResults))
  result = call_601296.call(nil, query_601297, nil, nil, body_601298)

var listServices* = Call_ListServices_601281(name: "listServices",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListServices",
    validator: validate_ListServices_601282, base: "/", url: url_ListServices_601283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterInstance_601299 = ref object of OpenApiRestCall_600437
proc url_RegisterInstance_601301(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterInstance_601300(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601304 = header.getOrDefault("X-Amz-Target")
  valid_601304 = validateParameter(valid_601304, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.RegisterInstance"))
  if valid_601304 != nil:
    section.add "X-Amz-Target", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Content-Sha256", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Algorithm")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Algorithm", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Signature")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Signature", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-SignedHeaders", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Credential")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Credential", valid_601309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601311: Call_RegisterInstance_601299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates one or more records and, optionally, creates a health check based on the settings in a specified service. When you submit a <code>RegisterInstance</code> request, the following occurs:</p> <ul> <li> <p>For each DNS record that you define in the service that is specified by <code>ServiceId</code>, a record is created or updated in the hosted zone that is associated with the corresponding namespace.</p> </li> <li> <p>If the service includes <code>HealthCheckConfig</code>, a health check is created based on the settings in the health check configuration.</p> </li> <li> <p>The health check, if any, is associated with each of the new or updated records.</p> </li> </ul> <important> <p>One <code>RegisterInstance</code> request must complete before you can submit another request and specify the same service ID and instance ID.</p> </important> <p>For more information, see <a>CreateService</a>.</p> <p>When AWS Cloud Map receives a DNS query for the specified DNS name, it returns the applicable value:</p> <ul> <li> <p> <b>If the health check is healthy</b>: returns all the records</p> </li> <li> <p> <b>If the health check is unhealthy</b>: returns the applicable value for the last healthy instance</p> </li> <li> <p> <b>If you didn't specify a health check configuration</b>: returns all the records</p> </li> </ul> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ## 
  let valid = call_601311.validator(path, query, header, formData, body)
  let scheme = call_601311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601311.url(scheme.get, call_601311.host, call_601311.base,
                         call_601311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601311, url, valid)

proc call*(call_601312: Call_RegisterInstance_601299; body: JsonNode): Recallable =
  ## registerInstance
  ## <p>Creates or updates one or more records and, optionally, creates a health check based on the settings in a specified service. When you submit a <code>RegisterInstance</code> request, the following occurs:</p> <ul> <li> <p>For each DNS record that you define in the service that is specified by <code>ServiceId</code>, a record is created or updated in the hosted zone that is associated with the corresponding namespace.</p> </li> <li> <p>If the service includes <code>HealthCheckConfig</code>, a health check is created based on the settings in the health check configuration.</p> </li> <li> <p>The health check, if any, is associated with each of the new or updated records.</p> </li> </ul> <important> <p>One <code>RegisterInstance</code> request must complete before you can submit another request and specify the same service ID and instance ID.</p> </important> <p>For more information, see <a>CreateService</a>.</p> <p>When AWS Cloud Map receives a DNS query for the specified DNS name, it returns the applicable value:</p> <ul> <li> <p> <b>If the health check is healthy</b>: returns all the records</p> </li> <li> <p> <b>If the health check is unhealthy</b>: returns the applicable value for the last healthy instance</p> </li> <li> <p> <b>If you didn't specify a health check configuration</b>: returns all the records</p> </li> </ul> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601313 = newJObject()
  if body != nil:
    body_601313 = body
  result = call_601312.call(nil, nil, nil, nil, body_601313)

var registerInstance* = Call_RegisterInstance_601299(name: "registerInstance",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.RegisterInstance",
    validator: validate_RegisterInstance_601300, base: "/",
    url: url_RegisterInstance_601301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceCustomHealthStatus_601314 = ref object of OpenApiRestCall_600437
proc url_UpdateInstanceCustomHealthStatus_601316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateInstanceCustomHealthStatus_601315(path: JsonNode;
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
  var valid_601317 = header.getOrDefault("X-Amz-Date")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Date", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Security-Token")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Security-Token", valid_601318
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601319 = header.getOrDefault("X-Amz-Target")
  valid_601319 = validateParameter(valid_601319, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.UpdateInstanceCustomHealthStatus"))
  if valid_601319 != nil:
    section.add "X-Amz-Target", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Content-Sha256", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Algorithm")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Algorithm", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Signature")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Signature", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-SignedHeaders", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Credential")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Credential", valid_601324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601326: Call_UpdateInstanceCustomHealthStatus_601314;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Submits a request to change the health status of a custom health check to healthy or unhealthy.</p> <p>You can use <code>UpdateInstanceCustomHealthStatus</code> to change the status only for custom health checks, which you define using <code>HealthCheckCustomConfig</code> when you create a service. You can't use it to change the status for Route 53 health checks, which you define using <code>HealthCheckConfig</code>.</p> <p>For more information, see <a>HealthCheckCustomConfig</a>.</p>
  ## 
  let valid = call_601326.validator(path, query, header, formData, body)
  let scheme = call_601326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601326.url(scheme.get, call_601326.host, call_601326.base,
                         call_601326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601326, url, valid)

proc call*(call_601327: Call_UpdateInstanceCustomHealthStatus_601314;
          body: JsonNode): Recallable =
  ## updateInstanceCustomHealthStatus
  ## <p>Submits a request to change the health status of a custom health check to healthy or unhealthy.</p> <p>You can use <code>UpdateInstanceCustomHealthStatus</code> to change the status only for custom health checks, which you define using <code>HealthCheckCustomConfig</code> when you create a service. You can't use it to change the status for Route 53 health checks, which you define using <code>HealthCheckConfig</code>.</p> <p>For more information, see <a>HealthCheckCustomConfig</a>.</p>
  ##   body: JObject (required)
  var body_601328 = newJObject()
  if body != nil:
    body_601328 = body
  result = call_601327.call(nil, nil, nil, nil, body_601328)

var updateInstanceCustomHealthStatus* = Call_UpdateInstanceCustomHealthStatus_601314(
    name: "updateInstanceCustomHealthStatus", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.UpdateInstanceCustomHealthStatus",
    validator: validate_UpdateInstanceCustomHealthStatus_601315, base: "/",
    url: url_UpdateInstanceCustomHealthStatus_601316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateService_601329 = ref object of OpenApiRestCall_600437
proc url_UpdateService_601331(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateService_601330(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601332 = header.getOrDefault("X-Amz-Date")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Date", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Security-Token")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Security-Token", valid_601333
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601334 = header.getOrDefault("X-Amz-Target")
  valid_601334 = validateParameter(valid_601334, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.UpdateService"))
  if valid_601334 != nil:
    section.add "X-Amz-Target", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Content-Sha256", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Algorithm")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Algorithm", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Signature")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Signature", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-SignedHeaders", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Credential")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Credential", valid_601339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601341: Call_UpdateService_601329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Submits a request to perform the following operations:</p> <ul> <li> <p>Add or delete <code>DnsRecords</code> configurations</p> </li> <li> <p>Update the TTL setting for existing <code>DnsRecords</code> configurations</p> </li> <li> <p>Add, update, or delete <code>HealthCheckConfig</code> for a specified service</p> </li> </ul> <p>For public and private DNS namespaces, you must specify all <code>DnsRecords</code> configurations (and, optionally, <code>HealthCheckConfig</code>) that you want to appear in the updated service. Any current configurations that don't appear in an <code>UpdateService</code> request are deleted.</p> <p>When you update the TTL setting for a service, AWS Cloud Map also updates the corresponding settings in all the records and health checks that were created by using the specified service.</p>
  ## 
  let valid = call_601341.validator(path, query, header, formData, body)
  let scheme = call_601341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601341.url(scheme.get, call_601341.host, call_601341.base,
                         call_601341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601341, url, valid)

proc call*(call_601342: Call_UpdateService_601329; body: JsonNode): Recallable =
  ## updateService
  ## <p>Submits a request to perform the following operations:</p> <ul> <li> <p>Add or delete <code>DnsRecords</code> configurations</p> </li> <li> <p>Update the TTL setting for existing <code>DnsRecords</code> configurations</p> </li> <li> <p>Add, update, or delete <code>HealthCheckConfig</code> for a specified service</p> </li> </ul> <p>For public and private DNS namespaces, you must specify all <code>DnsRecords</code> configurations (and, optionally, <code>HealthCheckConfig</code>) that you want to appear in the updated service. Any current configurations that don't appear in an <code>UpdateService</code> request are deleted.</p> <p>When you update the TTL setting for a service, AWS Cloud Map also updates the corresponding settings in all the records and health checks that were created by using the specified service.</p>
  ##   body: JObject (required)
  var body_601343 = newJObject()
  if body != nil:
    body_601343 = body
  result = call_601342.call(nil, nil, nil, nil, body_601343)

var updateService* = Call_UpdateService_601329(name: "updateService",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.UpdateService",
    validator: validate_UpdateService_601330, base: "/", url: url_UpdateService_601331,
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
