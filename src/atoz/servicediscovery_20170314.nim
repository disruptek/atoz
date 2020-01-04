
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateHttpNamespace_601727 = ref object of OpenApiRestCall_601389
proc url_CreateHttpNamespace_601729(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHttpNamespace_601728(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreateHttpNamespace"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_CreateHttpNamespace_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an HTTP namespace. Service instances that you register using an HTTP namespace can be discovered using a <code>DiscoverInstances</code> request but can't be discovered using DNS. </p> <p>For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_CreateHttpNamespace_601727; body: JsonNode): Recallable =
  ## createHttpNamespace
  ## <p>Creates an HTTP namespace. Service instances that you register using an HTTP namespace can be discovered using a <code>DiscoverInstances</code> request but can't be discovered using DNS. </p> <p>For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var createHttpNamespace* = Call_CreateHttpNamespace_601727(
    name: "createHttpNamespace", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreateHttpNamespace",
    validator: validate_CreateHttpNamespace_601728, base: "/",
    url: url_CreateHttpNamespace_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePrivateDnsNamespace_601996 = ref object of OpenApiRestCall_601389
proc url_CreatePrivateDnsNamespace_601998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePrivateDnsNamespace_601997(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreatePrivateDnsNamespace"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_CreatePrivateDnsNamespace_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a private namespace based on DNS, which will be visible only inside a specified Amazon VPC. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CreatePrivateDnsNamespace_601996; body: JsonNode): Recallable =
  ## createPrivateDnsNamespace
  ## Creates a private namespace based on DNS, which will be visible only inside a specified Amazon VPC. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var createPrivateDnsNamespace* = Call_CreatePrivateDnsNamespace_601996(
    name: "createPrivateDnsNamespace", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreatePrivateDnsNamespace",
    validator: validate_CreatePrivateDnsNamespace_601997, base: "/",
    url: url_CreatePrivateDnsNamespace_601998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicDnsNamespace_602011 = ref object of OpenApiRestCall_601389
proc url_CreatePublicDnsNamespace_602013(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePublicDnsNamespace_602012(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreatePublicDnsNamespace"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_CreatePublicDnsNamespace_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a public namespace based on DNS, which will be visible on the internet. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_CreatePublicDnsNamespace_602011; body: JsonNode): Recallable =
  ## createPublicDnsNamespace
  ## Creates a public namespace based on DNS, which will be visible on the internet. The namespace defines your service naming scheme. For example, if you name your namespace <code>example.com</code> and name your service <code>backend</code>, the resulting DNS name for the service will be <code>backend.example.com</code>. For the current limit on the number of namespaces that you can create using the same AWS account, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var createPublicDnsNamespace* = Call_CreatePublicDnsNamespace_602011(
    name: "createPublicDnsNamespace", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreatePublicDnsNamespace",
    validator: validate_CreatePublicDnsNamespace_602012, base: "/",
    url: url_CreatePublicDnsNamespace_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateService_602026 = ref object of OpenApiRestCall_601389
proc url_CreateService_602028(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateService_602027(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.CreateService"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_CreateService_602026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a service, which defines the configuration for the following entities:</p> <ul> <li> <p>For public and private DNS namespaces, one of the following combinations of DNS records in Amazon Route 53:</p> <ul> <li> <p>A</p> </li> <li> <p>AAAA</p> </li> <li> <p>A and AAAA</p> </li> <li> <p>SRV</p> </li> <li> <p>CNAME</p> </li> </ul> </li> <li> <p>Optionally, a health check</p> </li> </ul> <p>After you create the service, you can submit a <a>RegisterInstance</a> request, and AWS Cloud Map uses the values in the configuration to create the specified entities.</p> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_CreateService_602026; body: JsonNode): Recallable =
  ## createService
  ## <p>Creates a service, which defines the configuration for the following entities:</p> <ul> <li> <p>For public and private DNS namespaces, one of the following combinations of DNS records in Amazon Route 53:</p> <ul> <li> <p>A</p> </li> <li> <p>AAAA</p> </li> <li> <p>A and AAAA</p> </li> <li> <p>SRV</p> </li> <li> <p>CNAME</p> </li> </ul> </li> <li> <p>Optionally, a health check</p> </li> </ul> <p>After you create the service, you can submit a <a>RegisterInstance</a> request, and AWS Cloud Map uses the values in the configuration to create the specified entities.</p> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var createService* = Call_CreateService_602026(name: "createService",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.CreateService",
    validator: validate_CreateService_602027, base: "/", url: url_CreateService_602028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNamespace_602041 = ref object of OpenApiRestCall_601389
proc url_DeleteNamespace_602043(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNamespace_602042(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DeleteNamespace"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_DeleteNamespace_602041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a namespace from the current account. If the namespace still contains one or more services, the request fails.
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_DeleteNamespace_602041; body: JsonNode): Recallable =
  ## deleteNamespace
  ## Deletes a namespace from the current account. If the namespace still contains one or more services, the request fails.
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var deleteNamespace* = Call_DeleteNamespace_602041(name: "deleteNamespace",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DeleteNamespace",
    validator: validate_DeleteNamespace_602042, base: "/", url: url_DeleteNamespace_602043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteService_602056 = ref object of OpenApiRestCall_601389
proc url_DeleteService_602058(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteService_602057(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DeleteService"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_DeleteService_602056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified service. If the service still contains one or more registered instances, the request fails.
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_DeleteService_602056; body: JsonNode): Recallable =
  ## deleteService
  ## Deletes a specified service. If the service still contains one or more registered instances, the request fails.
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var deleteService* = Call_DeleteService_602056(name: "deleteService",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DeleteService",
    validator: validate_DeleteService_602057, base: "/", url: url_DeleteService_602058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterInstance_602071 = ref object of OpenApiRestCall_601389
proc url_DeregisterInstance_602073(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterInstance_602072(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DeregisterInstance"))
  if valid_602074 != nil:
    section.add "X-Amz-Target", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_DeregisterInstance_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the Amazon Route 53 DNS records and health check, if any, that AWS Cloud Map created for the specified instance.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_DeregisterInstance_602071; body: JsonNode): Recallable =
  ## deregisterInstance
  ## Deletes the Amazon Route 53 DNS records and health check, if any, that AWS Cloud Map created for the specified instance.
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var deregisterInstance* = Call_DeregisterInstance_602071(
    name: "deregisterInstance", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DeregisterInstance",
    validator: validate_DeregisterInstance_602072, base: "/",
    url: url_DeregisterInstance_602073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DiscoverInstances_602086 = ref object of OpenApiRestCall_601389
proc url_DiscoverInstances_602088(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DiscoverInstances_602087(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.DiscoverInstances"))
  if valid_602089 != nil:
    section.add "X-Amz-Target", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_DiscoverInstances_602086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Discovers registered instances for a specified namespace and service.
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_DiscoverInstances_602086; body: JsonNode): Recallable =
  ## discoverInstances
  ## Discovers registered instances for a specified namespace and service.
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var discoverInstances* = Call_DiscoverInstances_602086(name: "discoverInstances",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.DiscoverInstances",
    validator: validate_DiscoverInstances_602087, base: "/",
    url: url_DiscoverInstances_602088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstance_602101 = ref object of OpenApiRestCall_601389
proc url_GetInstance_602103(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstance_602102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetInstance"))
  if valid_602104 != nil:
    section.add "X-Amz-Target", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602113: Call_GetInstance_602101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified instance.
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_GetInstance_602101; body: JsonNode): Recallable =
  ## getInstance
  ## Gets information about a specified instance.
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var getInstance* = Call_GetInstance_602101(name: "getInstance",
                                        meth: HttpMethod.HttpPost,
                                        host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetInstance",
                                        validator: validate_GetInstance_602102,
                                        base: "/", url: url_GetInstance_602103,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstancesHealthStatus_602116 = ref object of OpenApiRestCall_601389
proc url_GetInstancesHealthStatus_602118(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstancesHealthStatus_602117(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the current health status (<code>Healthy</code>, <code>Unhealthy</code>, or <code>Unknown</code>) of one or more instances that are associated with a specified service.</p> <note> <p>There is a brief delay between when you register an instance and when the health status for the instance is available. </p> </note>
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
  var valid_602119 = query.getOrDefault("MaxResults")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "MaxResults", valid_602119
  var valid_602120 = query.getOrDefault("NextToken")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "NextToken", valid_602120
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602121 = header.getOrDefault("X-Amz-Target")
  valid_602121 = validateParameter(valid_602121, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetInstancesHealthStatus"))
  if valid_602121 != nil:
    section.add "X-Amz-Target", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Signature")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Signature", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Content-Sha256", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Date")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Date", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Credential")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Credential", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Security-Token")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Security-Token", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Algorithm")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Algorithm", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-SignedHeaders", valid_602128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602130: Call_GetInstancesHealthStatus_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the current health status (<code>Healthy</code>, <code>Unhealthy</code>, or <code>Unknown</code>) of one or more instances that are associated with a specified service.</p> <note> <p>There is a brief delay between when you register an instance and when the health status for the instance is available. </p> </note>
  ## 
  let valid = call_602130.validator(path, query, header, formData, body)
  let scheme = call_602130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602130.url(scheme.get, call_602130.host, call_602130.base,
                         call_602130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602130, url, valid)

proc call*(call_602131: Call_GetInstancesHealthStatus_602116; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getInstancesHealthStatus
  ## <p>Gets the current health status (<code>Healthy</code>, <code>Unhealthy</code>, or <code>Unknown</code>) of one or more instances that are associated with a specified service.</p> <note> <p>There is a brief delay between when you register an instance and when the health status for the instance is available. </p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602132 = newJObject()
  var body_602133 = newJObject()
  add(query_602132, "MaxResults", newJString(MaxResults))
  add(query_602132, "NextToken", newJString(NextToken))
  if body != nil:
    body_602133 = body
  result = call_602131.call(nil, query_602132, nil, nil, body_602133)

var getInstancesHealthStatus* = Call_GetInstancesHealthStatus_602116(
    name: "getInstancesHealthStatus", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetInstancesHealthStatus",
    validator: validate_GetInstancesHealthStatus_602117, base: "/",
    url: url_GetInstancesHealthStatus_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetNamespace_602135 = ref object of OpenApiRestCall_601389
proc url_GetNamespace_602137(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetNamespace_602136(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602138 = header.getOrDefault("X-Amz-Target")
  valid_602138 = validateParameter(valid_602138, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetNamespace"))
  if valid_602138 != nil:
    section.add "X-Amz-Target", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Signature")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Signature", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Content-Sha256", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Date")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Date", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Credential")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Credential", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Security-Token")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Security-Token", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Algorithm")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Algorithm", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-SignedHeaders", valid_602145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602147: Call_GetNamespace_602135; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a namespace.
  ## 
  let valid = call_602147.validator(path, query, header, formData, body)
  let scheme = call_602147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602147.url(scheme.get, call_602147.host, call_602147.base,
                         call_602147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602147, url, valid)

proc call*(call_602148: Call_GetNamespace_602135; body: JsonNode): Recallable =
  ## getNamespace
  ## Gets information about a namespace.
  ##   body: JObject (required)
  var body_602149 = newJObject()
  if body != nil:
    body_602149 = body
  result = call_602148.call(nil, nil, nil, nil, body_602149)

var getNamespace* = Call_GetNamespace_602135(name: "getNamespace",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetNamespace",
    validator: validate_GetNamespace_602136, base: "/", url: url_GetNamespace_602137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperation_602150 = ref object of OpenApiRestCall_601389
proc url_GetOperation_602152(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOperation_602151(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602153 = header.getOrDefault("X-Amz-Target")
  valid_602153 = validateParameter(valid_602153, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetOperation"))
  if valid_602153 != nil:
    section.add "X-Amz-Target", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Signature")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Signature", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Content-Sha256", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Date")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Date", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Credential")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Credential", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Security-Token")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Security-Token", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Algorithm")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Algorithm", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-SignedHeaders", valid_602160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602162: Call_GetOperation_602150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about any operation that returns an operation ID in the response, such as a <code>CreateService</code> request.</p> <note> <p>To get a list of operations that match specified criteria, see <a>ListOperations</a>.</p> </note>
  ## 
  let valid = call_602162.validator(path, query, header, formData, body)
  let scheme = call_602162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602162.url(scheme.get, call_602162.host, call_602162.base,
                         call_602162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602162, url, valid)

proc call*(call_602163: Call_GetOperation_602150; body: JsonNode): Recallable =
  ## getOperation
  ## <p>Gets information about any operation that returns an operation ID in the response, such as a <code>CreateService</code> request.</p> <note> <p>To get a list of operations that match specified criteria, see <a>ListOperations</a>.</p> </note>
  ##   body: JObject (required)
  var body_602164 = newJObject()
  if body != nil:
    body_602164 = body
  result = call_602163.call(nil, nil, nil, nil, body_602164)

var getOperation* = Call_GetOperation_602150(name: "getOperation",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetOperation",
    validator: validate_GetOperation_602151, base: "/", url: url_GetOperation_602152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetService_602165 = ref object of OpenApiRestCall_601389
proc url_GetService_602167(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetService_602166(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602168 = header.getOrDefault("X-Amz-Target")
  valid_602168 = validateParameter(valid_602168, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.GetService"))
  if valid_602168 != nil:
    section.add "X-Amz-Target", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Signature")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Signature", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Content-Sha256", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Date")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Date", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Credential")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Credential", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Security-Token")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Security-Token", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Algorithm")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Algorithm", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-SignedHeaders", valid_602175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602177: Call_GetService_602165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the settings for a specified service.
  ## 
  let valid = call_602177.validator(path, query, header, formData, body)
  let scheme = call_602177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602177.url(scheme.get, call_602177.host, call_602177.base,
                         call_602177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602177, url, valid)

proc call*(call_602178: Call_GetService_602165; body: JsonNode): Recallable =
  ## getService
  ## Gets the settings for a specified service.
  ##   body: JObject (required)
  var body_602179 = newJObject()
  if body != nil:
    body_602179 = body
  result = call_602178.call(nil, nil, nil, nil, body_602179)

var getService* = Call_GetService_602165(name: "getService",
                                      meth: HttpMethod.HttpPost,
                                      host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.GetService",
                                      validator: validate_GetService_602166,
                                      base: "/", url: url_GetService_602167,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstances_602180 = ref object of OpenApiRestCall_601389
proc url_ListInstances_602182(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInstances_602181(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists summary information about the instances that you registered by using a specified service.
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
  var valid_602183 = query.getOrDefault("MaxResults")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "MaxResults", valid_602183
  var valid_602184 = query.getOrDefault("NextToken")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "NextToken", valid_602184
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602185 = header.getOrDefault("X-Amz-Target")
  valid_602185 = validateParameter(valid_602185, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListInstances"))
  if valid_602185 != nil:
    section.add "X-Amz-Target", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Signature")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Signature", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Content-Sha256", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Date")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Date", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Credential")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Credential", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Security-Token")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Security-Token", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Algorithm")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Algorithm", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-SignedHeaders", valid_602192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602194: Call_ListInstances_602180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists summary information about the instances that you registered by using a specified service.
  ## 
  let valid = call_602194.validator(path, query, header, formData, body)
  let scheme = call_602194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602194.url(scheme.get, call_602194.host, call_602194.base,
                         call_602194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602194, url, valid)

proc call*(call_602195: Call_ListInstances_602180; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listInstances
  ## Lists summary information about the instances that you registered by using a specified service.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602196 = newJObject()
  var body_602197 = newJObject()
  add(query_602196, "MaxResults", newJString(MaxResults))
  add(query_602196, "NextToken", newJString(NextToken))
  if body != nil:
    body_602197 = body
  result = call_602195.call(nil, query_602196, nil, nil, body_602197)

var listInstances* = Call_ListInstances_602180(name: "listInstances",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListInstances",
    validator: validate_ListInstances_602181, base: "/", url: url_ListInstances_602182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNamespaces_602198 = ref object of OpenApiRestCall_601389
proc url_ListNamespaces_602200(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNamespaces_602199(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists summary information about the namespaces that were created by the current AWS account.
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
  var valid_602201 = query.getOrDefault("MaxResults")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "MaxResults", valid_602201
  var valid_602202 = query.getOrDefault("NextToken")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "NextToken", valid_602202
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602203 = header.getOrDefault("X-Amz-Target")
  valid_602203 = validateParameter(valid_602203, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListNamespaces"))
  if valid_602203 != nil:
    section.add "X-Amz-Target", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Signature")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Signature", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Content-Sha256", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Date")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Date", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Credential")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Credential", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Security-Token")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Security-Token", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Algorithm")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Algorithm", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-SignedHeaders", valid_602210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602212: Call_ListNamespaces_602198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists summary information about the namespaces that were created by the current AWS account.
  ## 
  let valid = call_602212.validator(path, query, header, formData, body)
  let scheme = call_602212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602212.url(scheme.get, call_602212.host, call_602212.base,
                         call_602212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602212, url, valid)

proc call*(call_602213: Call_ListNamespaces_602198; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNamespaces
  ## Lists summary information about the namespaces that were created by the current AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602214 = newJObject()
  var body_602215 = newJObject()
  add(query_602214, "MaxResults", newJString(MaxResults))
  add(query_602214, "NextToken", newJString(NextToken))
  if body != nil:
    body_602215 = body
  result = call_602213.call(nil, query_602214, nil, nil, body_602215)

var listNamespaces* = Call_ListNamespaces_602198(name: "listNamespaces",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListNamespaces",
    validator: validate_ListNamespaces_602199, base: "/", url: url_ListNamespaces_602200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOperations_602216 = ref object of OpenApiRestCall_601389
proc url_ListOperations_602218(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOperations_602217(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists operations that match the criteria that you specify.
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
  var valid_602219 = query.getOrDefault("MaxResults")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "MaxResults", valid_602219
  var valid_602220 = query.getOrDefault("NextToken")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "NextToken", valid_602220
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602221 = header.getOrDefault("X-Amz-Target")
  valid_602221 = validateParameter(valid_602221, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListOperations"))
  if valid_602221 != nil:
    section.add "X-Amz-Target", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Signature")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Signature", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Content-Sha256", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Date")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Date", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Credential")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Credential", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Security-Token")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Security-Token", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Algorithm")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Algorithm", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-SignedHeaders", valid_602228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602230: Call_ListOperations_602216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists operations that match the criteria that you specify.
  ## 
  let valid = call_602230.validator(path, query, header, formData, body)
  let scheme = call_602230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602230.url(scheme.get, call_602230.host, call_602230.base,
                         call_602230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602230, url, valid)

proc call*(call_602231: Call_ListOperations_602216; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listOperations
  ## Lists operations that match the criteria that you specify.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602232 = newJObject()
  var body_602233 = newJObject()
  add(query_602232, "MaxResults", newJString(MaxResults))
  add(query_602232, "NextToken", newJString(NextToken))
  if body != nil:
    body_602233 = body
  result = call_602231.call(nil, query_602232, nil, nil, body_602233)

var listOperations* = Call_ListOperations_602216(name: "listOperations",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListOperations",
    validator: validate_ListOperations_602217, base: "/", url: url_ListOperations_602218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_602234 = ref object of OpenApiRestCall_601389
proc url_ListServices_602236(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServices_602235(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists summary information for all the services that are associated with one or more specified namespaces.
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
  var valid_602237 = query.getOrDefault("MaxResults")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "MaxResults", valid_602237
  var valid_602238 = query.getOrDefault("NextToken")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "NextToken", valid_602238
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602239 = header.getOrDefault("X-Amz-Target")
  valid_602239 = validateParameter(valid_602239, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.ListServices"))
  if valid_602239 != nil:
    section.add "X-Amz-Target", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Content-Sha256", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Credential")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Credential", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-SignedHeaders", valid_602246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602248: Call_ListServices_602234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists summary information for all the services that are associated with one or more specified namespaces.
  ## 
  let valid = call_602248.validator(path, query, header, formData, body)
  let scheme = call_602248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602248.url(scheme.get, call_602248.host, call_602248.base,
                         call_602248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602248, url, valid)

proc call*(call_602249: Call_ListServices_602234; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServices
  ## Lists summary information for all the services that are associated with one or more specified namespaces.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602250 = newJObject()
  var body_602251 = newJObject()
  add(query_602250, "MaxResults", newJString(MaxResults))
  add(query_602250, "NextToken", newJString(NextToken))
  if body != nil:
    body_602251 = body
  result = call_602249.call(nil, query_602250, nil, nil, body_602251)

var listServices* = Call_ListServices_602234(name: "listServices",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.ListServices",
    validator: validate_ListServices_602235, base: "/", url: url_ListServices_602236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterInstance_602252 = ref object of OpenApiRestCall_601389
proc url_RegisterInstance_602254(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterInstance_602253(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602255 = header.getOrDefault("X-Amz-Target")
  valid_602255 = validateParameter(valid_602255, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.RegisterInstance"))
  if valid_602255 != nil:
    section.add "X-Amz-Target", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Signature")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Signature", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Content-Sha256", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Date")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Date", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Credential")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Credential", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Security-Token")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Security-Token", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Algorithm")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Algorithm", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-SignedHeaders", valid_602262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602264: Call_RegisterInstance_602252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates one or more records and, optionally, creates a health check based on the settings in a specified service. When you submit a <code>RegisterInstance</code> request, the following occurs:</p> <ul> <li> <p>For each DNS record that you define in the service that is specified by <code>ServiceId</code>, a record is created or updated in the hosted zone that is associated with the corresponding namespace.</p> </li> <li> <p>If the service includes <code>HealthCheckConfig</code>, a health check is created based on the settings in the health check configuration.</p> </li> <li> <p>The health check, if any, is associated with each of the new or updated records.</p> </li> </ul> <important> <p>One <code>RegisterInstance</code> request must complete before you can submit another request and specify the same service ID and instance ID.</p> </important> <p>For more information, see <a>CreateService</a>.</p> <p>When AWS Cloud Map receives a DNS query for the specified DNS name, it returns the applicable value:</p> <ul> <li> <p> <b>If the health check is healthy</b>: returns all the records</p> </li> <li> <p> <b>If the health check is unhealthy</b>: returns the applicable value for the last healthy instance</p> </li> <li> <p> <b>If you didn't specify a health check configuration</b>: returns all the records</p> </li> </ul> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ## 
  let valid = call_602264.validator(path, query, header, formData, body)
  let scheme = call_602264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602264.url(scheme.get, call_602264.host, call_602264.base,
                         call_602264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602264, url, valid)

proc call*(call_602265: Call_RegisterInstance_602252; body: JsonNode): Recallable =
  ## registerInstance
  ## <p>Creates or updates one or more records and, optionally, creates a health check based on the settings in a specified service. When you submit a <code>RegisterInstance</code> request, the following occurs:</p> <ul> <li> <p>For each DNS record that you define in the service that is specified by <code>ServiceId</code>, a record is created or updated in the hosted zone that is associated with the corresponding namespace.</p> </li> <li> <p>If the service includes <code>HealthCheckConfig</code>, a health check is created based on the settings in the health check configuration.</p> </li> <li> <p>The health check, if any, is associated with each of the new or updated records.</p> </li> </ul> <important> <p>One <code>RegisterInstance</code> request must complete before you can submit another request and specify the same service ID and instance ID.</p> </important> <p>For more information, see <a>CreateService</a>.</p> <p>When AWS Cloud Map receives a DNS query for the specified DNS name, it returns the applicable value:</p> <ul> <li> <p> <b>If the health check is healthy</b>: returns all the records</p> </li> <li> <p> <b>If the health check is unhealthy</b>: returns the applicable value for the last healthy instance</p> </li> <li> <p> <b>If you didn't specify a health check configuration</b>: returns all the records</p> </li> </ul> <p>For the current limit on the number of instances that you can register using the same namespace and using the same service, see <a href="http://docs.aws.amazon.com/cloud-map/latest/dg/cloud-map-limits.html">AWS Cloud Map Limits</a> in the <i>AWS Cloud Map Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_602266 = newJObject()
  if body != nil:
    body_602266 = body
  result = call_602265.call(nil, nil, nil, nil, body_602266)

var registerInstance* = Call_RegisterInstance_602252(name: "registerInstance",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.RegisterInstance",
    validator: validate_RegisterInstance_602253, base: "/",
    url: url_RegisterInstance_602254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInstanceCustomHealthStatus_602267 = ref object of OpenApiRestCall_601389
proc url_UpdateInstanceCustomHealthStatus_602269(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateInstanceCustomHealthStatus_602268(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602270 = header.getOrDefault("X-Amz-Target")
  valid_602270 = validateParameter(valid_602270, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.UpdateInstanceCustomHealthStatus"))
  if valid_602270 != nil:
    section.add "X-Amz-Target", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Signature")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Signature", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Content-Sha256", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Date")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Date", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Credential")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Credential", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Security-Token")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Security-Token", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Algorithm")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Algorithm", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-SignedHeaders", valid_602277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602279: Call_UpdateInstanceCustomHealthStatus_602267;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Submits a request to change the health status of a custom health check to healthy or unhealthy.</p> <p>You can use <code>UpdateInstanceCustomHealthStatus</code> to change the status only for custom health checks, which you define using <code>HealthCheckCustomConfig</code> when you create a service. You can't use it to change the status for Route 53 health checks, which you define using <code>HealthCheckConfig</code>.</p> <p>For more information, see <a>HealthCheckCustomConfig</a>.</p>
  ## 
  let valid = call_602279.validator(path, query, header, formData, body)
  let scheme = call_602279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602279.url(scheme.get, call_602279.host, call_602279.base,
                         call_602279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602279, url, valid)

proc call*(call_602280: Call_UpdateInstanceCustomHealthStatus_602267;
          body: JsonNode): Recallable =
  ## updateInstanceCustomHealthStatus
  ## <p>Submits a request to change the health status of a custom health check to healthy or unhealthy.</p> <p>You can use <code>UpdateInstanceCustomHealthStatus</code> to change the status only for custom health checks, which you define using <code>HealthCheckCustomConfig</code> when you create a service. You can't use it to change the status for Route 53 health checks, which you define using <code>HealthCheckConfig</code>.</p> <p>For more information, see <a>HealthCheckCustomConfig</a>.</p>
  ##   body: JObject (required)
  var body_602281 = newJObject()
  if body != nil:
    body_602281 = body
  result = call_602280.call(nil, nil, nil, nil, body_602281)

var updateInstanceCustomHealthStatus* = Call_UpdateInstanceCustomHealthStatus_602267(
    name: "updateInstanceCustomHealthStatus", meth: HttpMethod.HttpPost,
    host: "servicediscovery.amazonaws.com", route: "/#X-Amz-Target=Route53AutoNaming_v20170314.UpdateInstanceCustomHealthStatus",
    validator: validate_UpdateInstanceCustomHealthStatus_602268, base: "/",
    url: url_UpdateInstanceCustomHealthStatus_602269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateService_602282 = ref object of OpenApiRestCall_601389
proc url_UpdateService_602284(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateService_602283(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602285 = header.getOrDefault("X-Amz-Target")
  valid_602285 = validateParameter(valid_602285, JString, required = true, default = newJString(
      "Route53AutoNaming_v20170314.UpdateService"))
  if valid_602285 != nil:
    section.add "X-Amz-Target", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Signature")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Signature", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Content-Sha256", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Date")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Date", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Credential")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Credential", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Security-Token")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Security-Token", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Algorithm")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Algorithm", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-SignedHeaders", valid_602292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602294: Call_UpdateService_602282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Submits a request to perform the following operations:</p> <ul> <li> <p>Add or delete <code>DnsRecords</code> configurations</p> </li> <li> <p>Update the TTL setting for existing <code>DnsRecords</code> configurations</p> </li> <li> <p>Add, update, or delete <code>HealthCheckConfig</code> for a specified service</p> </li> </ul> <p>For public and private DNS namespaces, you must specify all <code>DnsRecords</code> configurations (and, optionally, <code>HealthCheckConfig</code>) that you want to appear in the updated service. Any current configurations that don't appear in an <code>UpdateService</code> request are deleted.</p> <p>When you update the TTL setting for a service, AWS Cloud Map also updates the corresponding settings in all the records and health checks that were created by using the specified service.</p>
  ## 
  let valid = call_602294.validator(path, query, header, formData, body)
  let scheme = call_602294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602294.url(scheme.get, call_602294.host, call_602294.base,
                         call_602294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602294, url, valid)

proc call*(call_602295: Call_UpdateService_602282; body: JsonNode): Recallable =
  ## updateService
  ## <p>Submits a request to perform the following operations:</p> <ul> <li> <p>Add or delete <code>DnsRecords</code> configurations</p> </li> <li> <p>Update the TTL setting for existing <code>DnsRecords</code> configurations</p> </li> <li> <p>Add, update, or delete <code>HealthCheckConfig</code> for a specified service</p> </li> </ul> <p>For public and private DNS namespaces, you must specify all <code>DnsRecords</code> configurations (and, optionally, <code>HealthCheckConfig</code>) that you want to appear in the updated service. Any current configurations that don't appear in an <code>UpdateService</code> request are deleted.</p> <p>When you update the TTL setting for a service, AWS Cloud Map also updates the corresponding settings in all the records and health checks that were created by using the specified service.</p>
  ##   body: JObject (required)
  var body_602296 = newJObject()
  if body != nil:
    body_602296 = body
  result = call_602295.call(nil, nil, nil, nil, body_602296)

var updateService* = Call_UpdateService_602282(name: "updateService",
    meth: HttpMethod.HttpPost, host: "servicediscovery.amazonaws.com",
    route: "/#X-Amz-Target=Route53AutoNaming_v20170314.UpdateService",
    validator: validate_UpdateService_602283, base: "/", url: url_UpdateService_602284,
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
