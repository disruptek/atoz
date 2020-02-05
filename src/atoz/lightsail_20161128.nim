
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Lightsail
## version: 2016-11-28
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon Lightsail is the easiest way to get started with AWS for developers who just need virtual private servers. Lightsail includes everything you need to launch your project quickly - a virtual machine, a managed database, SSD-based storage, data transfer, DNS management, and a static IP - for a low, predictable price. You manage those Lightsail servers through the Lightsail console or by using the API or command-line interface (CLI).</p> <p>For more information about Lightsail concepts and tasks, see the <a href="https://lightsail.aws.amazon.com/ls/docs/all">Lightsail Dev Guide</a>.</p> <p>To use the Lightsail API or the CLI, you will need to use AWS Identity and Access Management (IAM) to generate access keys. For details about how to set this up, see the <a href="http://lightsail.aws.amazon.com/ls/docs/how-to/article/lightsail-how-to-set-up-access-keys-to-use-sdk-api-cli">Lightsail Dev Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/lightsail/
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "lightsail.ap-northeast-1.amazonaws.com", "ap-southeast-1": "lightsail.ap-southeast-1.amazonaws.com",
                           "us-west-2": "lightsail.us-west-2.amazonaws.com",
                           "eu-west-2": "lightsail.eu-west-2.amazonaws.com", "ap-northeast-3": "lightsail.ap-northeast-3.amazonaws.com", "eu-central-1": "lightsail.eu-central-1.amazonaws.com",
                           "us-east-2": "lightsail.us-east-2.amazonaws.com",
                           "us-east-1": "lightsail.us-east-1.amazonaws.com", "cn-northwest-1": "lightsail.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "lightsail.ap-south-1.amazonaws.com",
                           "eu-north-1": "lightsail.eu-north-1.amazonaws.com", "ap-northeast-2": "lightsail.ap-northeast-2.amazonaws.com",
                           "us-west-1": "lightsail.us-west-1.amazonaws.com", "us-gov-east-1": "lightsail.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "lightsail.eu-west-3.amazonaws.com", "cn-north-1": "lightsail.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "lightsail.sa-east-1.amazonaws.com",
                           "eu-west-1": "lightsail.eu-west-1.amazonaws.com", "us-gov-west-1": "lightsail.us-gov-west-1.amazonaws.com", "ap-southeast-2": "lightsail.ap-southeast-2.amazonaws.com", "ca-central-1": "lightsail.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "lightsail.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "lightsail.ap-southeast-1.amazonaws.com",
      "us-west-2": "lightsail.us-west-2.amazonaws.com",
      "eu-west-2": "lightsail.eu-west-2.amazonaws.com",
      "ap-northeast-3": "lightsail.ap-northeast-3.amazonaws.com",
      "eu-central-1": "lightsail.eu-central-1.amazonaws.com",
      "us-east-2": "lightsail.us-east-2.amazonaws.com",
      "us-east-1": "lightsail.us-east-1.amazonaws.com",
      "cn-northwest-1": "lightsail.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "lightsail.ap-south-1.amazonaws.com",
      "eu-north-1": "lightsail.eu-north-1.amazonaws.com",
      "ap-northeast-2": "lightsail.ap-northeast-2.amazonaws.com",
      "us-west-1": "lightsail.us-west-1.amazonaws.com",
      "us-gov-east-1": "lightsail.us-gov-east-1.amazonaws.com",
      "eu-west-3": "lightsail.eu-west-3.amazonaws.com",
      "cn-north-1": "lightsail.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "lightsail.sa-east-1.amazonaws.com",
      "eu-west-1": "lightsail.eu-west-1.amazonaws.com",
      "us-gov-west-1": "lightsail.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "lightsail.ap-southeast-2.amazonaws.com",
      "ca-central-1": "lightsail.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "lightsail"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AllocateStaticIp_612996 = ref object of OpenApiRestCall_612658
proc url_AllocateStaticIp_612998(protocol: Scheme; host: string; base: string;
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

proc validate_AllocateStaticIp_612997(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Allocates a static IP address.
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "Lightsail_20161128.AllocateStaticIp"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_AllocateStaticIp_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allocates a static IP address.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_AllocateStaticIp_612996; body: JsonNode): Recallable =
  ## allocateStaticIp
  ## Allocates a static IP address.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var allocateStaticIp* = Call_AllocateStaticIp_612996(name: "allocateStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AllocateStaticIp",
    validator: validate_AllocateStaticIp_612997, base: "/",
    url: url_AllocateStaticIp_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachDisk_613265 = ref object of OpenApiRestCall_612658
proc url_AttachDisk_613267(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_AttachDisk_613266(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name.</p> <p>The <code>attach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachDisk"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_AttachDisk_613265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name.</p> <p>The <code>attach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_AttachDisk_613265; body: JsonNode): Recallable =
  ## attachDisk
  ## <p>Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name.</p> <p>The <code>attach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var attachDisk* = Call_AttachDisk_613265(name: "attachDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.AttachDisk",
                                      validator: validate_AttachDisk_613266,
                                      base: "/", url: url_AttachDisk_613267,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachInstancesToLoadBalancer_613280 = ref object of OpenApiRestCall_612658
proc url_AttachInstancesToLoadBalancer_613282(protocol: Scheme; host: string;
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

proc validate_AttachInstancesToLoadBalancer_613281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Attaches one or more Lightsail instances to a load balancer.</p> <p>After some time, the instances are attached to the load balancer and the health check status is available.</p> <p>The <code>attach instances to load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachInstancesToLoadBalancer"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_AttachInstancesToLoadBalancer_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches one or more Lightsail instances to a load balancer.</p> <p>After some time, the instances are attached to the load balancer and the health check status is available.</p> <p>The <code>attach instances to load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_AttachInstancesToLoadBalancer_613280; body: JsonNode): Recallable =
  ## attachInstancesToLoadBalancer
  ## <p>Attaches one or more Lightsail instances to a load balancer.</p> <p>After some time, the instances are attached to the load balancer and the health check status is available.</p> <p>The <code>attach instances to load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var attachInstancesToLoadBalancer* = Call_AttachInstancesToLoadBalancer_613280(
    name: "attachInstancesToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AttachInstancesToLoadBalancer",
    validator: validate_AttachInstancesToLoadBalancer_613281, base: "/",
    url: url_AttachInstancesToLoadBalancer_613282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachLoadBalancerTlsCertificate_613295 = ref object of OpenApiRestCall_612658
proc url_AttachLoadBalancerTlsCertificate_613297(protocol: Scheme; host: string;
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

proc validate_AttachLoadBalancerTlsCertificate_613296(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>attach load balancer tls certificate</code> operation with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>attach load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachLoadBalancerTlsCertificate"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_AttachLoadBalancerTlsCertificate_613295;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>attach load balancer tls certificate</code> operation with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>attach load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_AttachLoadBalancerTlsCertificate_613295;
          body: JsonNode): Recallable =
  ## attachLoadBalancerTlsCertificate
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>attach load balancer tls certificate</code> operation with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>attach load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var attachLoadBalancerTlsCertificate* = Call_AttachLoadBalancerTlsCertificate_613295(
    name: "attachLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.AttachLoadBalancerTlsCertificate",
    validator: validate_AttachLoadBalancerTlsCertificate_613296, base: "/",
    url: url_AttachLoadBalancerTlsCertificate_613297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachStaticIp_613310 = ref object of OpenApiRestCall_612658
proc url_AttachStaticIp_613312(protocol: Scheme; host: string; base: string;
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

proc validate_AttachStaticIp_613311(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Attaches a static IP address to a specific Amazon Lightsail instance.
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
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachStaticIp"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_AttachStaticIp_613310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a static IP address to a specific Amazon Lightsail instance.
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_AttachStaticIp_613310; body: JsonNode): Recallable =
  ## attachStaticIp
  ## Attaches a static IP address to a specific Amazon Lightsail instance.
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var attachStaticIp* = Call_AttachStaticIp_613310(name: "attachStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AttachStaticIp",
    validator: validate_AttachStaticIp_613311, base: "/", url: url_AttachStaticIp_613312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CloseInstancePublicPorts_613325 = ref object of OpenApiRestCall_612658
proc url_CloseInstancePublicPorts_613327(protocol: Scheme; host: string;
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

proc validate_CloseInstancePublicPorts_613326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "Lightsail_20161128.CloseInstancePublicPorts"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_CloseInstancePublicPorts_613325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_CloseInstancePublicPorts_613325; body: JsonNode): Recallable =
  ## closeInstancePublicPorts
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var closeInstancePublicPorts* = Call_CloseInstancePublicPorts_613325(
    name: "closeInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CloseInstancePublicPorts",
    validator: validate_CloseInstancePublicPorts_613326, base: "/",
    url: url_CloseInstancePublicPorts_613327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopySnapshot_613340 = ref object of OpenApiRestCall_612658
proc url_CopySnapshot_613342(protocol: Scheme; host: string; base: string;
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

proc validate_CopySnapshot_613341(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Copies a manual snapshot of an instance or disk as another manual snapshot, or copies an automatic snapshot of an instance or disk as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p>
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
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "Lightsail_20161128.CopySnapshot"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_CopySnapshot_613340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a manual snapshot of an instance or disk as another manual snapshot, or copies an automatic snapshot of an instance or disk as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p>
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_CopySnapshot_613340; body: JsonNode): Recallable =
  ## copySnapshot
  ## <p>Copies a manual snapshot of an instance or disk as another manual snapshot, or copies an automatic snapshot of an instance or disk as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p>
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var copySnapshot* = Call_CopySnapshot_613340(name: "copySnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CopySnapshot",
    validator: validate_CopySnapshot_613341, base: "/", url: url_CopySnapshot_613342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationStack_613355 = ref object of OpenApiRestCall_612658
proc url_CreateCloudFormationStack_613357(protocol: Scheme; host: string;
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

proc validate_CreateCloudFormationStack_613356(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
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
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateCloudFormationStack"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_CreateCloudFormationStack_613355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_CreateCloudFormationStack_613355; body: JsonNode): Recallable =
  ## createCloudFormationStack
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var createCloudFormationStack* = Call_CreateCloudFormationStack_613355(
    name: "createCloudFormationStack", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateCloudFormationStack",
    validator: validate_CreateCloudFormationStack_613356, base: "/",
    url: url_CreateCloudFormationStack_613357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDisk_613370 = ref object of OpenApiRestCall_612658
proc url_CreateDisk_613372(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateDisk_613371(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDisk"))
  if valid_613373 != nil:
    section.add "X-Amz-Target", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_CreateDisk_613370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_CreateDisk_613370; body: JsonNode): Recallable =
  ## createDisk
  ## <p>Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var createDisk* = Call_CreateDisk_613370(name: "createDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateDisk",
                                      validator: validate_CreateDisk_613371,
                                      base: "/", url: url_CreateDisk_613372,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDiskFromSnapshot_613385 = ref object of OpenApiRestCall_612658
proc url_CreateDiskFromSnapshot_613387(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDiskFromSnapshot_613386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613388 = header.getOrDefault("X-Amz-Target")
  valid_613388 = validateParameter(valid_613388, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDiskFromSnapshot"))
  if valid_613388 != nil:
    section.add "X-Amz-Target", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Signature")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Signature", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Content-Sha256", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Date")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Date", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Credential")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Credential", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Security-Token")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Security-Token", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Algorithm")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Algorithm", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-SignedHeaders", valid_613395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_CreateDiskFromSnapshot_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_CreateDiskFromSnapshot_613385; body: JsonNode): Recallable =
  ## createDiskFromSnapshot
  ## <p>Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var createDiskFromSnapshot* = Call_CreateDiskFromSnapshot_613385(
    name: "createDiskFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDiskFromSnapshot",
    validator: validate_CreateDiskFromSnapshot_613386, base: "/",
    url: url_CreateDiskFromSnapshot_613387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDiskSnapshot_613400 = ref object of OpenApiRestCall_612658
proc url_CreateDiskSnapshot_613402(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDiskSnapshot_613401(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance.</p> <p>You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending.</p> <p>You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the <code>instance name</code> parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk.</p> <p>The <code>create disk snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613403 = header.getOrDefault("X-Amz-Target")
  valid_613403 = validateParameter(valid_613403, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDiskSnapshot"))
  if valid_613403 != nil:
    section.add "X-Amz-Target", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_CreateDiskSnapshot_613400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance.</p> <p>You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending.</p> <p>You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the <code>instance name</code> parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk.</p> <p>The <code>create disk snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_CreateDiskSnapshot_613400; body: JsonNode): Recallable =
  ## createDiskSnapshot
  ## <p>Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance.</p> <p>You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending.</p> <p>You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the <code>instance name</code> parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk.</p> <p>The <code>create disk snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var createDiskSnapshot* = Call_CreateDiskSnapshot_613400(
    name: "createDiskSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDiskSnapshot",
    validator: validate_CreateDiskSnapshot_613401, base: "/",
    url: url_CreateDiskSnapshot_613402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_613415 = ref object of OpenApiRestCall_612658
proc url_CreateDomain_613417(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomain_613416(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613418 = header.getOrDefault("X-Amz-Target")
  valid_613418 = validateParameter(valid_613418, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDomain"))
  if valid_613418 != nil:
    section.add "X-Amz-Target", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_CreateDomain_613415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_CreateDomain_613415; body: JsonNode): Recallable =
  ## createDomain
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613429 = newJObject()
  if body != nil:
    body_613429 = body
  result = call_613428.call(nil, nil, nil, nil, body_613429)

var createDomain* = Call_CreateDomain_613415(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDomain",
    validator: validate_CreateDomain_613416, base: "/", url: url_CreateDomain_613417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainEntry_613430 = ref object of OpenApiRestCall_612658
proc url_CreateDomainEntry_613432(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainEntry_613431(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates one of the following entry records associated with the domain: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT).</p> <p>The <code>create domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613433 = header.getOrDefault("X-Amz-Target")
  valid_613433 = validateParameter(valid_613433, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDomainEntry"))
  if valid_613433 != nil:
    section.add "X-Amz-Target", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Signature")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Signature", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Content-Sha256", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Date")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Date", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Credential")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Credential", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Security-Token")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Security-Token", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Algorithm")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Algorithm", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-SignedHeaders", valid_613440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613442: Call_CreateDomainEntry_613430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one of the following entry records associated with the domain: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT).</p> <p>The <code>create domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_CreateDomainEntry_613430; body: JsonNode): Recallable =
  ## createDomainEntry
  ## <p>Creates one of the following entry records associated with the domain: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT).</p> <p>The <code>create domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613444 = newJObject()
  if body != nil:
    body_613444 = body
  result = call_613443.call(nil, nil, nil, nil, body_613444)

var createDomainEntry* = Call_CreateDomainEntry_613430(name: "createDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDomainEntry",
    validator: validate_CreateDomainEntry_613431, base: "/",
    url: url_CreateDomainEntry_613432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceSnapshot_613445 = ref object of OpenApiRestCall_612658
proc url_CreateInstanceSnapshot_613447(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInstanceSnapshot_613446(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a snapshot of a specific virtual private server, or <i>instance</i>. You can use a snapshot to create a new instance that is based on that snapshot.</p> <p>The <code>create instance snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613448 = header.getOrDefault("X-Amz-Target")
  valid_613448 = validateParameter(valid_613448, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstanceSnapshot"))
  if valid_613448 != nil:
    section.add "X-Amz-Target", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Signature")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Signature", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Content-Sha256", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Date")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Date", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Credential")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Credential", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Security-Token")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Security-Token", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Algorithm")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Algorithm", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-SignedHeaders", valid_613455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613457: Call_CreateInstanceSnapshot_613445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a snapshot of a specific virtual private server, or <i>instance</i>. You can use a snapshot to create a new instance that is based on that snapshot.</p> <p>The <code>create instance snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_CreateInstanceSnapshot_613445; body: JsonNode): Recallable =
  ## createInstanceSnapshot
  ## <p>Creates a snapshot of a specific virtual private server, or <i>instance</i>. You can use a snapshot to create a new instance that is based on that snapshot.</p> <p>The <code>create instance snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613459 = newJObject()
  if body != nil:
    body_613459 = body
  result = call_613458.call(nil, nil, nil, nil, body_613459)

var createInstanceSnapshot* = Call_CreateInstanceSnapshot_613445(
    name: "createInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstanceSnapshot",
    validator: validate_CreateInstanceSnapshot_613446, base: "/",
    url: url_CreateInstanceSnapshot_613447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstances_613460 = ref object of OpenApiRestCall_612658
proc url_CreateInstances_613462(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInstances_613461(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates one or more Amazon Lightsail instances.</p> <p>The <code>create instances</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613463 = header.getOrDefault("X-Amz-Target")
  valid_613463 = validateParameter(valid_613463, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstances"))
  if valid_613463 != nil:
    section.add "X-Amz-Target", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_CreateInstances_613460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more Amazon Lightsail instances.</p> <p>The <code>create instances</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_CreateInstances_613460; body: JsonNode): Recallable =
  ## createInstances
  ## <p>Creates one or more Amazon Lightsail instances.</p> <p>The <code>create instances</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613474 = newJObject()
  if body != nil:
    body_613474 = body
  result = call_613473.call(nil, nil, nil, nil, body_613474)

var createInstances* = Call_CreateInstances_613460(name: "createInstances",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstances",
    validator: validate_CreateInstances_613461, base: "/", url: url_CreateInstances_613462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstancesFromSnapshot_613475 = ref object of OpenApiRestCall_612658
proc url_CreateInstancesFromSnapshot_613477(protocol: Scheme; host: string;
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

proc validate_CreateInstancesFromSnapshot_613476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613478 = header.getOrDefault("X-Amz-Target")
  valid_613478 = validateParameter(valid_613478, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstancesFromSnapshot"))
  if valid_613478 != nil:
    section.add "X-Amz-Target", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Signature")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Signature", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Content-Sha256", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Date")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Date", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Credential")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Credential", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Security-Token")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Security-Token", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Algorithm")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Algorithm", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-SignedHeaders", valid_613485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_CreateInstancesFromSnapshot_613475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_CreateInstancesFromSnapshot_613475; body: JsonNode): Recallable =
  ## createInstancesFromSnapshot
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613489 = newJObject()
  if body != nil:
    body_613489 = body
  result = call_613488.call(nil, nil, nil, nil, body_613489)

var createInstancesFromSnapshot* = Call_CreateInstancesFromSnapshot_613475(
    name: "createInstancesFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstancesFromSnapshot",
    validator: validate_CreateInstancesFromSnapshot_613476, base: "/",
    url: url_CreateInstancesFromSnapshot_613477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateKeyPair_613490 = ref object of OpenApiRestCall_612658
proc url_CreateKeyPair_613492(protocol: Scheme; host: string; base: string;
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

proc validate_CreateKeyPair_613491(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613493 = header.getOrDefault("X-Amz-Target")
  valid_613493 = validateParameter(valid_613493, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateKeyPair"))
  if valid_613493 != nil:
    section.add "X-Amz-Target", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Signature")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Signature", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Content-Sha256", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Date")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Date", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Credential")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Credential", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Security-Token")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Security-Token", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Algorithm")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Algorithm", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-SignedHeaders", valid_613500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613502: Call_CreateKeyPair_613490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_CreateKeyPair_613490; body: JsonNode): Recallable =
  ## createKeyPair
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613504 = newJObject()
  if body != nil:
    body_613504 = body
  result = call_613503.call(nil, nil, nil, nil, body_613504)

var createKeyPair* = Call_CreateKeyPair_613490(name: "createKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateKeyPair",
    validator: validate_CreateKeyPair_613491, base: "/", url: url_CreateKeyPair_613492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoadBalancer_613505 = ref object of OpenApiRestCall_612658
proc url_CreateLoadBalancer_613507(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLoadBalancer_613506(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see <a href="https://lightsail.aws.amazon.com/ls/docs/how-to/article/configure-lightsail-instances-for-load-balancing">Configure your Lightsail instances for load balancing</a>. You can create up to 5 load balancers per AWS Region in your account.</p> <p>When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the <code>UpdateLoadBalancerAttribute</code> operation.</p> <p>The <code>create load balancer</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613508 = header.getOrDefault("X-Amz-Target")
  valid_613508 = validateParameter(valid_613508, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateLoadBalancer"))
  if valid_613508 != nil:
    section.add "X-Amz-Target", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Signature")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Signature", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Content-Sha256", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Date")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Date", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Credential")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Credential", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Security-Token")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Security-Token", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Algorithm")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Algorithm", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-SignedHeaders", valid_613515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613517: Call_CreateLoadBalancer_613505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see <a href="https://lightsail.aws.amazon.com/ls/docs/how-to/article/configure-lightsail-instances-for-load-balancing">Configure your Lightsail instances for load balancing</a>. You can create up to 5 load balancers per AWS Region in your account.</p> <p>When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the <code>UpdateLoadBalancerAttribute</code> operation.</p> <p>The <code>create load balancer</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613517.validator(path, query, header, formData, body)
  let scheme = call_613517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613517.url(scheme.get, call_613517.host, call_613517.base,
                         call_613517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613517, url, valid)

proc call*(call_613518: Call_CreateLoadBalancer_613505; body: JsonNode): Recallable =
  ## createLoadBalancer
  ## <p>Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see <a href="https://lightsail.aws.amazon.com/ls/docs/how-to/article/configure-lightsail-instances-for-load-balancing">Configure your Lightsail instances for load balancing</a>. You can create up to 5 load balancers per AWS Region in your account.</p> <p>When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the <code>UpdateLoadBalancerAttribute</code> operation.</p> <p>The <code>create load balancer</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613519 = newJObject()
  if body != nil:
    body_613519 = body
  result = call_613518.call(nil, nil, nil, nil, body_613519)

var createLoadBalancer* = Call_CreateLoadBalancer_613505(
    name: "createLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateLoadBalancer",
    validator: validate_CreateLoadBalancer_613506, base: "/",
    url: url_CreateLoadBalancer_613507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoadBalancerTlsCertificate_613520 = ref object of OpenApiRestCall_612658
proc url_CreateLoadBalancerTlsCertificate_613522(protocol: Scheme; host: string;
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

proc validate_CreateLoadBalancerTlsCertificate_613521(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>create load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613523 = header.getOrDefault("X-Amz-Target")
  valid_613523 = validateParameter(valid_613523, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateLoadBalancerTlsCertificate"))
  if valid_613523 != nil:
    section.add "X-Amz-Target", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Signature")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Signature", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Content-Sha256", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Date")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Date", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Credential")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Credential", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Security-Token")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Security-Token", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Algorithm")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Algorithm", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-SignedHeaders", valid_613530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613532: Call_CreateLoadBalancerTlsCertificate_613520;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>create load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613532.validator(path, query, header, formData, body)
  let scheme = call_613532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613532.url(scheme.get, call_613532.host, call_613532.base,
                         call_613532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613532, url, valid)

proc call*(call_613533: Call_CreateLoadBalancerTlsCertificate_613520;
          body: JsonNode): Recallable =
  ## createLoadBalancerTlsCertificate
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>create load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613534 = newJObject()
  if body != nil:
    body_613534 = body
  result = call_613533.call(nil, nil, nil, nil, body_613534)

var createLoadBalancerTlsCertificate* = Call_CreateLoadBalancerTlsCertificate_613520(
    name: "createLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateLoadBalancerTlsCertificate",
    validator: validate_CreateLoadBalancerTlsCertificate_613521, base: "/",
    url: url_CreateLoadBalancerTlsCertificate_613522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabase_613535 = ref object of OpenApiRestCall_612658
proc url_CreateRelationalDatabase_613537(protocol: Scheme; host: string;
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

proc validate_CreateRelationalDatabase_613536(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613538 = header.getOrDefault("X-Amz-Target")
  valid_613538 = validateParameter(valid_613538, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabase"))
  if valid_613538 != nil:
    section.add "X-Amz-Target", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Signature")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Signature", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Content-Sha256", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Date")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Date", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Credential")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Credential", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Security-Token")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Security-Token", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Algorithm")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Algorithm", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-SignedHeaders", valid_613545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613547: Call_CreateRelationalDatabase_613535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613547.validator(path, query, header, formData, body)
  let scheme = call_613547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613547.url(scheme.get, call_613547.host, call_613547.base,
                         call_613547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613547, url, valid)

proc call*(call_613548: Call_CreateRelationalDatabase_613535; body: JsonNode): Recallable =
  ## createRelationalDatabase
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613549 = newJObject()
  if body != nil:
    body_613549 = body
  result = call_613548.call(nil, nil, nil, nil, body_613549)

var createRelationalDatabase* = Call_CreateRelationalDatabase_613535(
    name: "createRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabase",
    validator: validate_CreateRelationalDatabase_613536, base: "/",
    url: url_CreateRelationalDatabase_613537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabaseFromSnapshot_613550 = ref object of OpenApiRestCall_612658
proc url_CreateRelationalDatabaseFromSnapshot_613552(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRelationalDatabaseFromSnapshot_613551(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new database from an existing database snapshot in Amazon Lightsail.</p> <p>You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan.</p> <p>The <code>create relational database from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613553 = header.getOrDefault("X-Amz-Target")
  valid_613553 = validateParameter(valid_613553, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabaseFromSnapshot"))
  if valid_613553 != nil:
    section.add "X-Amz-Target", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Signature")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Signature", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Content-Sha256", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Date")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Date", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Credential")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Credential", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Security-Token")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Security-Token", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Algorithm")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Algorithm", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-SignedHeaders", valid_613560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613562: Call_CreateRelationalDatabaseFromSnapshot_613550;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new database from an existing database snapshot in Amazon Lightsail.</p> <p>You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan.</p> <p>The <code>create relational database from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613562.validator(path, query, header, formData, body)
  let scheme = call_613562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613562.url(scheme.get, call_613562.host, call_613562.base,
                         call_613562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613562, url, valid)

proc call*(call_613563: Call_CreateRelationalDatabaseFromSnapshot_613550;
          body: JsonNode): Recallable =
  ## createRelationalDatabaseFromSnapshot
  ## <p>Creates a new database from an existing database snapshot in Amazon Lightsail.</p> <p>You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan.</p> <p>The <code>create relational database from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613564 = newJObject()
  if body != nil:
    body_613564 = body
  result = call_613563.call(nil, nil, nil, nil, body_613564)

var createRelationalDatabaseFromSnapshot* = Call_CreateRelationalDatabaseFromSnapshot_613550(
    name: "createRelationalDatabaseFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabaseFromSnapshot",
    validator: validate_CreateRelationalDatabaseFromSnapshot_613551, base: "/",
    url: url_CreateRelationalDatabaseFromSnapshot_613552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabaseSnapshot_613565 = ref object of OpenApiRestCall_612658
proc url_CreateRelationalDatabaseSnapshot_613567(protocol: Scheme; host: string;
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

proc validate_CreateRelationalDatabaseSnapshot_613566(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database.</p> <p>The <code>create relational database snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613568 = header.getOrDefault("X-Amz-Target")
  valid_613568 = validateParameter(valid_613568, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabaseSnapshot"))
  if valid_613568 != nil:
    section.add "X-Amz-Target", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613577: Call_CreateRelationalDatabaseSnapshot_613565;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database.</p> <p>The <code>create relational database snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613577.validator(path, query, header, formData, body)
  let scheme = call_613577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613577.url(scheme.get, call_613577.host, call_613577.base,
                         call_613577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613577, url, valid)

proc call*(call_613578: Call_CreateRelationalDatabaseSnapshot_613565;
          body: JsonNode): Recallable =
  ## createRelationalDatabaseSnapshot
  ## <p>Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database.</p> <p>The <code>create relational database snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613579 = newJObject()
  if body != nil:
    body_613579 = body
  result = call_613578.call(nil, nil, nil, nil, body_613579)

var createRelationalDatabaseSnapshot* = Call_CreateRelationalDatabaseSnapshot_613565(
    name: "createRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabaseSnapshot",
    validator: validate_CreateRelationalDatabaseSnapshot_613566, base: "/",
    url: url_CreateRelationalDatabaseSnapshot_613567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAutoSnapshot_613580 = ref object of OpenApiRestCall_612658
proc url_DeleteAutoSnapshot_613582(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAutoSnapshot_613581(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes an automatic snapshot of an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
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
  var valid_613583 = header.getOrDefault("X-Amz-Target")
  valid_613583 = validateParameter(valid_613583, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteAutoSnapshot"))
  if valid_613583 != nil:
    section.add "X-Amz-Target", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Signature")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Signature", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Content-Sha256", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Date")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Date", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Credential")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Credential", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Security-Token")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Security-Token", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Algorithm")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Algorithm", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-SignedHeaders", valid_613590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613592: Call_DeleteAutoSnapshot_613580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an automatic snapshot of an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_613592.validator(path, query, header, formData, body)
  let scheme = call_613592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613592.url(scheme.get, call_613592.host, call_613592.base,
                         call_613592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613592, url, valid)

proc call*(call_613593: Call_DeleteAutoSnapshot_613580; body: JsonNode): Recallable =
  ## deleteAutoSnapshot
  ## Deletes an automatic snapshot of an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_613594 = newJObject()
  if body != nil:
    body_613594 = body
  result = call_613593.call(nil, nil, nil, nil, body_613594)

var deleteAutoSnapshot* = Call_DeleteAutoSnapshot_613580(
    name: "deleteAutoSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteAutoSnapshot",
    validator: validate_DeleteAutoSnapshot_613581, base: "/",
    url: url_DeleteAutoSnapshot_613582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDisk_613595 = ref object of OpenApiRestCall_612658
proc url_DeleteDisk_613597(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteDisk_613596(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified block storage disk. The disk must be in the <code>available</code> state (not attached to a Lightsail instance).</p> <note> <p>The disk may remain in the <code>deleting</code> state for several minutes.</p> </note> <p>The <code>delete disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613598 = header.getOrDefault("X-Amz-Target")
  valid_613598 = validateParameter(valid_613598, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDisk"))
  if valid_613598 != nil:
    section.add "X-Amz-Target", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Signature")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Signature", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Content-Sha256", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Date")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Date", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Credential")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Credential", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Security-Token")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Security-Token", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Algorithm")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Algorithm", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-SignedHeaders", valid_613605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613607: Call_DeleteDisk_613595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified block storage disk. The disk must be in the <code>available</code> state (not attached to a Lightsail instance).</p> <note> <p>The disk may remain in the <code>deleting</code> state for several minutes.</p> </note> <p>The <code>delete disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613607.validator(path, query, header, formData, body)
  let scheme = call_613607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613607.url(scheme.get, call_613607.host, call_613607.base,
                         call_613607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613607, url, valid)

proc call*(call_613608: Call_DeleteDisk_613595; body: JsonNode): Recallable =
  ## deleteDisk
  ## <p>Deletes the specified block storage disk. The disk must be in the <code>available</code> state (not attached to a Lightsail instance).</p> <note> <p>The disk may remain in the <code>deleting</code> state for several minutes.</p> </note> <p>The <code>delete disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613609 = newJObject()
  if body != nil:
    body_613609 = body
  result = call_613608.call(nil, nil, nil, nil, body_613609)

var deleteDisk* = Call_DeleteDisk_613595(name: "deleteDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteDisk",
                                      validator: validate_DeleteDisk_613596,
                                      base: "/", url: url_DeleteDisk_613597,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiskSnapshot_613610 = ref object of OpenApiRestCall_612658
proc url_DeleteDiskSnapshot_613612(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDiskSnapshot_613611(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes the specified disk snapshot.</p> <p>When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk.</p> <p>The <code>delete disk snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613613 = header.getOrDefault("X-Amz-Target")
  valid_613613 = validateParameter(valid_613613, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDiskSnapshot"))
  if valid_613613 != nil:
    section.add "X-Amz-Target", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Signature")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Signature", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Content-Sha256", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Date")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Date", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Credential")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Credential", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Security-Token")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Security-Token", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Algorithm")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Algorithm", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-SignedHeaders", valid_613620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613622: Call_DeleteDiskSnapshot_613610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified disk snapshot.</p> <p>When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk.</p> <p>The <code>delete disk snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613622.validator(path, query, header, formData, body)
  let scheme = call_613622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613622.url(scheme.get, call_613622.host, call_613622.base,
                         call_613622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613622, url, valid)

proc call*(call_613623: Call_DeleteDiskSnapshot_613610; body: JsonNode): Recallable =
  ## deleteDiskSnapshot
  ## <p>Deletes the specified disk snapshot.</p> <p>When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk.</p> <p>The <code>delete disk snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613624 = newJObject()
  if body != nil:
    body_613624 = body
  result = call_613623.call(nil, nil, nil, nil, body_613624)

var deleteDiskSnapshot* = Call_DeleteDiskSnapshot_613610(
    name: "deleteDiskSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDiskSnapshot",
    validator: validate_DeleteDiskSnapshot_613611, base: "/",
    url: url_DeleteDiskSnapshot_613612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_613625 = ref object of OpenApiRestCall_612658
proc url_DeleteDomain_613627(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomain_613626(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613628 = header.getOrDefault("X-Amz-Target")
  valid_613628 = validateParameter(valid_613628, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDomain"))
  if valid_613628 != nil:
    section.add "X-Amz-Target", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Signature")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Signature", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Content-Sha256", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Date")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Date", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Credential")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Credential", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Security-Token")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Security-Token", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Algorithm")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Algorithm", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-SignedHeaders", valid_613635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613637: Call_DeleteDomain_613625; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613637.validator(path, query, header, formData, body)
  let scheme = call_613637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613637.url(scheme.get, call_613637.host, call_613637.base,
                         call_613637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613637, url, valid)

proc call*(call_613638: Call_DeleteDomain_613625; body: JsonNode): Recallable =
  ## deleteDomain
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613639 = newJObject()
  if body != nil:
    body_613639 = body
  result = call_613638.call(nil, nil, nil, nil, body_613639)

var deleteDomain* = Call_DeleteDomain_613625(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDomain",
    validator: validate_DeleteDomain_613626, base: "/", url: url_DeleteDomain_613627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainEntry_613640 = ref object of OpenApiRestCall_612658
proc url_DeleteDomainEntry_613642(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainEntry_613641(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes a specific domain entry.</p> <p>The <code>delete domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613643 = header.getOrDefault("X-Amz-Target")
  valid_613643 = validateParameter(valid_613643, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDomainEntry"))
  if valid_613643 != nil:
    section.add "X-Amz-Target", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Signature")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Signature", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Content-Sha256", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Date")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Date", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-Credential")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Credential", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Security-Token")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Security-Token", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Algorithm")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Algorithm", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-SignedHeaders", valid_613650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613652: Call_DeleteDomainEntry_613640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific domain entry.</p> <p>The <code>delete domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613652.validator(path, query, header, formData, body)
  let scheme = call_613652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613652.url(scheme.get, call_613652.host, call_613652.base,
                         call_613652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613652, url, valid)

proc call*(call_613653: Call_DeleteDomainEntry_613640; body: JsonNode): Recallable =
  ## deleteDomainEntry
  ## <p>Deletes a specific domain entry.</p> <p>The <code>delete domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613654 = newJObject()
  if body != nil:
    body_613654 = body
  result = call_613653.call(nil, nil, nil, nil, body_613654)

var deleteDomainEntry* = Call_DeleteDomainEntry_613640(name: "deleteDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDomainEntry",
    validator: validate_DeleteDomainEntry_613641, base: "/",
    url: url_DeleteDomainEntry_613642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstance_613655 = ref object of OpenApiRestCall_612658
proc url_DeleteInstance_613657(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInstance_613656(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes an Amazon Lightsail instance.</p> <p>The <code>delete instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613658 = header.getOrDefault("X-Amz-Target")
  valid_613658 = validateParameter(valid_613658, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteInstance"))
  if valid_613658 != nil:
    section.add "X-Amz-Target", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Signature")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Signature", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Content-Sha256", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Date")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Date", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Credential")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Credential", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Security-Token")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Security-Token", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Algorithm")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Algorithm", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-SignedHeaders", valid_613665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613667: Call_DeleteInstance_613655; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an Amazon Lightsail instance.</p> <p>The <code>delete instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613667.validator(path, query, header, formData, body)
  let scheme = call_613667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613667.url(scheme.get, call_613667.host, call_613667.base,
                         call_613667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613667, url, valid)

proc call*(call_613668: Call_DeleteInstance_613655; body: JsonNode): Recallable =
  ## deleteInstance
  ## <p>Deletes an Amazon Lightsail instance.</p> <p>The <code>delete instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613669 = newJObject()
  if body != nil:
    body_613669 = body
  result = call_613668.call(nil, nil, nil, nil, body_613669)

var deleteInstance* = Call_DeleteInstance_613655(name: "deleteInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteInstance",
    validator: validate_DeleteInstance_613656, base: "/", url: url_DeleteInstance_613657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceSnapshot_613670 = ref object of OpenApiRestCall_612658
proc url_DeleteInstanceSnapshot_613672(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInstanceSnapshot_613671(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a specific snapshot of a virtual private server (or <i>instance</i>).</p> <p>The <code>delete instance snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613673 = header.getOrDefault("X-Amz-Target")
  valid_613673 = validateParameter(valid_613673, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteInstanceSnapshot"))
  if valid_613673 != nil:
    section.add "X-Amz-Target", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Signature")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Signature", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Content-Sha256", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Date")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Date", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Credential")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Credential", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Security-Token")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Security-Token", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Algorithm")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Algorithm", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-SignedHeaders", valid_613680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613682: Call_DeleteInstanceSnapshot_613670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific snapshot of a virtual private server (or <i>instance</i>).</p> <p>The <code>delete instance snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613682.validator(path, query, header, formData, body)
  let scheme = call_613682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613682.url(scheme.get, call_613682.host, call_613682.base,
                         call_613682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613682, url, valid)

proc call*(call_613683: Call_DeleteInstanceSnapshot_613670; body: JsonNode): Recallable =
  ## deleteInstanceSnapshot
  ## <p>Deletes a specific snapshot of a virtual private server (or <i>instance</i>).</p> <p>The <code>delete instance snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613684 = newJObject()
  if body != nil:
    body_613684 = body
  result = call_613683.call(nil, nil, nil, nil, body_613684)

var deleteInstanceSnapshot* = Call_DeleteInstanceSnapshot_613670(
    name: "deleteInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteInstanceSnapshot",
    validator: validate_DeleteInstanceSnapshot_613671, base: "/",
    url: url_DeleteInstanceSnapshot_613672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteKeyPair_613685 = ref object of OpenApiRestCall_612658
proc url_DeleteKeyPair_613687(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteKeyPair_613686(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613688 = header.getOrDefault("X-Amz-Target")
  valid_613688 = validateParameter(valid_613688, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteKeyPair"))
  if valid_613688 != nil:
    section.add "X-Amz-Target", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Signature")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Signature", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Content-Sha256", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Date")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Date", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Credential")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Credential", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Security-Token")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Security-Token", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Algorithm")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Algorithm", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-SignedHeaders", valid_613695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613697: Call_DeleteKeyPair_613685; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613697.validator(path, query, header, formData, body)
  let scheme = call_613697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613697.url(scheme.get, call_613697.host, call_613697.base,
                         call_613697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613697, url, valid)

proc call*(call_613698: Call_DeleteKeyPair_613685; body: JsonNode): Recallable =
  ## deleteKeyPair
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613699 = newJObject()
  if body != nil:
    body_613699 = body
  result = call_613698.call(nil, nil, nil, nil, body_613699)

var deleteKeyPair* = Call_DeleteKeyPair_613685(name: "deleteKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteKeyPair",
    validator: validate_DeleteKeyPair_613686, base: "/", url: url_DeleteKeyPair_613687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteKnownHostKeys_613700 = ref object of OpenApiRestCall_612658
proc url_DeleteKnownHostKeys_613702(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteKnownHostKeys_613701(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch.</p> <important> <p>Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection">Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client</a>.</p> </important>
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
  var valid_613703 = header.getOrDefault("X-Amz-Target")
  valid_613703 = validateParameter(valid_613703, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteKnownHostKeys"))
  if valid_613703 != nil:
    section.add "X-Amz-Target", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Signature")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Signature", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Content-Sha256", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Date")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Date", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Credential")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Credential", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Security-Token")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Security-Token", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Algorithm")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Algorithm", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-SignedHeaders", valid_613710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613712: Call_DeleteKnownHostKeys_613700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch.</p> <important> <p>Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection">Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client</a>.</p> </important>
  ## 
  let valid = call_613712.validator(path, query, header, formData, body)
  let scheme = call_613712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613712.url(scheme.get, call_613712.host, call_613712.base,
                         call_613712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613712, url, valid)

proc call*(call_613713: Call_DeleteKnownHostKeys_613700; body: JsonNode): Recallable =
  ## deleteKnownHostKeys
  ## <p>Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch.</p> <important> <p>Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection">Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client</a>.</p> </important>
  ##   body: JObject (required)
  var body_613714 = newJObject()
  if body != nil:
    body_613714 = body
  result = call_613713.call(nil, nil, nil, nil, body_613714)

var deleteKnownHostKeys* = Call_DeleteKnownHostKeys_613700(
    name: "deleteKnownHostKeys", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteKnownHostKeys",
    validator: validate_DeleteKnownHostKeys_613701, base: "/",
    url: url_DeleteKnownHostKeys_613702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoadBalancer_613715 = ref object of OpenApiRestCall_612658
proc url_DeleteLoadBalancer_613717(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLoadBalancer_613716(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again.</p> <p>The <code>delete load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613718 = header.getOrDefault("X-Amz-Target")
  valid_613718 = validateParameter(valid_613718, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteLoadBalancer"))
  if valid_613718 != nil:
    section.add "X-Amz-Target", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Signature")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Signature", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Content-Sha256", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Date")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Date", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Credential")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Credential", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Security-Token")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Security-Token", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Algorithm")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Algorithm", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-SignedHeaders", valid_613725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613727: Call_DeleteLoadBalancer_613715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again.</p> <p>The <code>delete load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613727.validator(path, query, header, formData, body)
  let scheme = call_613727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613727.url(scheme.get, call_613727.host, call_613727.base,
                         call_613727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613727, url, valid)

proc call*(call_613728: Call_DeleteLoadBalancer_613715; body: JsonNode): Recallable =
  ## deleteLoadBalancer
  ## <p>Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again.</p> <p>The <code>delete load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613729 = newJObject()
  if body != nil:
    body_613729 = body
  result = call_613728.call(nil, nil, nil, nil, body_613729)

var deleteLoadBalancer* = Call_DeleteLoadBalancer_613715(
    name: "deleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteLoadBalancer",
    validator: validate_DeleteLoadBalancer_613716, base: "/",
    url: url_DeleteLoadBalancer_613717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoadBalancerTlsCertificate_613730 = ref object of OpenApiRestCall_612658
proc url_DeleteLoadBalancerTlsCertificate_613732(protocol: Scheme; host: string;
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

proc validate_DeleteLoadBalancerTlsCertificate_613731(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>delete load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613733 = header.getOrDefault("X-Amz-Target")
  valid_613733 = validateParameter(valid_613733, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteLoadBalancerTlsCertificate"))
  if valid_613733 != nil:
    section.add "X-Amz-Target", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Signature")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Signature", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Content-Sha256", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Date")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Date", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-Credential")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Credential", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Security-Token")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Security-Token", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Algorithm")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Algorithm", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-SignedHeaders", valid_613740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613742: Call_DeleteLoadBalancerTlsCertificate_613730;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>delete load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613742.validator(path, query, header, formData, body)
  let scheme = call_613742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613742.url(scheme.get, call_613742.host, call_613742.base,
                         call_613742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613742, url, valid)

proc call*(call_613743: Call_DeleteLoadBalancerTlsCertificate_613730;
          body: JsonNode): Recallable =
  ## deleteLoadBalancerTlsCertificate
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>delete load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613744 = newJObject()
  if body != nil:
    body_613744 = body
  result = call_613743.call(nil, nil, nil, nil, body_613744)

var deleteLoadBalancerTlsCertificate* = Call_DeleteLoadBalancerTlsCertificate_613730(
    name: "deleteLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteLoadBalancerTlsCertificate",
    validator: validate_DeleteLoadBalancerTlsCertificate_613731, base: "/",
    url: url_DeleteLoadBalancerTlsCertificate_613732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRelationalDatabase_613745 = ref object of OpenApiRestCall_612658
proc url_DeleteRelationalDatabase_613747(protocol: Scheme; host: string;
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

proc validate_DeleteRelationalDatabase_613746(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613748 = header.getOrDefault("X-Amz-Target")
  valid_613748 = validateParameter(valid_613748, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteRelationalDatabase"))
  if valid_613748 != nil:
    section.add "X-Amz-Target", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Signature")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Signature", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Content-Sha256", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Date")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Date", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-Credential")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Credential", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Security-Token")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Security-Token", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Algorithm")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Algorithm", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-SignedHeaders", valid_613755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613757: Call_DeleteRelationalDatabase_613745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613757.validator(path, query, header, formData, body)
  let scheme = call_613757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613757.url(scheme.get, call_613757.host, call_613757.base,
                         call_613757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613757, url, valid)

proc call*(call_613758: Call_DeleteRelationalDatabase_613745; body: JsonNode): Recallable =
  ## deleteRelationalDatabase
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613759 = newJObject()
  if body != nil:
    body_613759 = body
  result = call_613758.call(nil, nil, nil, nil, body_613759)

var deleteRelationalDatabase* = Call_DeleteRelationalDatabase_613745(
    name: "deleteRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteRelationalDatabase",
    validator: validate_DeleteRelationalDatabase_613746, base: "/",
    url: url_DeleteRelationalDatabase_613747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRelationalDatabaseSnapshot_613760 = ref object of OpenApiRestCall_612658
proc url_DeleteRelationalDatabaseSnapshot_613762(protocol: Scheme; host: string;
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

proc validate_DeleteRelationalDatabaseSnapshot_613761(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a database snapshot in Amazon Lightsail.</p> <p>The <code>delete relational database snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613763 = header.getOrDefault("X-Amz-Target")
  valid_613763 = validateParameter(valid_613763, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteRelationalDatabaseSnapshot"))
  if valid_613763 != nil:
    section.add "X-Amz-Target", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Signature")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Signature", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Content-Sha256", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Date")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Date", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Credential")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Credential", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Security-Token")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Security-Token", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Algorithm")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Algorithm", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-SignedHeaders", valid_613770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613772: Call_DeleteRelationalDatabaseSnapshot_613760;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes a database snapshot in Amazon Lightsail.</p> <p>The <code>delete relational database snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613772.validator(path, query, header, formData, body)
  let scheme = call_613772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613772.url(scheme.get, call_613772.host, call_613772.base,
                         call_613772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613772, url, valid)

proc call*(call_613773: Call_DeleteRelationalDatabaseSnapshot_613760;
          body: JsonNode): Recallable =
  ## deleteRelationalDatabaseSnapshot
  ## <p>Deletes a database snapshot in Amazon Lightsail.</p> <p>The <code>delete relational database snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613774 = newJObject()
  if body != nil:
    body_613774 = body
  result = call_613773.call(nil, nil, nil, nil, body_613774)

var deleteRelationalDatabaseSnapshot* = Call_DeleteRelationalDatabaseSnapshot_613760(
    name: "deleteRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteRelationalDatabaseSnapshot",
    validator: validate_DeleteRelationalDatabaseSnapshot_613761, base: "/",
    url: url_DeleteRelationalDatabaseSnapshot_613762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachDisk_613775 = ref object of OpenApiRestCall_612658
proc url_DetachDisk_613777(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DetachDisk_613776(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk.</p> <p>The <code>detach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613778 = header.getOrDefault("X-Amz-Target")
  valid_613778 = validateParameter(valid_613778, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachDisk"))
  if valid_613778 != nil:
    section.add "X-Amz-Target", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Signature")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Signature", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Content-Sha256", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Date")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Date", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Credential")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Credential", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Security-Token")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Security-Token", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Algorithm")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Algorithm", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-SignedHeaders", valid_613785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613787: Call_DetachDisk_613775; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk.</p> <p>The <code>detach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613787.validator(path, query, header, formData, body)
  let scheme = call_613787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613787.url(scheme.get, call_613787.host, call_613787.base,
                         call_613787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613787, url, valid)

proc call*(call_613788: Call_DetachDisk_613775; body: JsonNode): Recallable =
  ## detachDisk
  ## <p>Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk.</p> <p>The <code>detach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613789 = newJObject()
  if body != nil:
    body_613789 = body
  result = call_613788.call(nil, nil, nil, nil, body_613789)

var detachDisk* = Call_DetachDisk_613775(name: "detachDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DetachDisk",
                                      validator: validate_DetachDisk_613776,
                                      base: "/", url: url_DetachDisk_613777,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachInstancesFromLoadBalancer_613790 = ref object of OpenApiRestCall_612658
proc url_DetachInstancesFromLoadBalancer_613792(protocol: Scheme; host: string;
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

proc validate_DetachInstancesFromLoadBalancer_613791(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Detaches the specified instances from a Lightsail load balancer.</p> <p>This operation waits until the instances are no longer needed before they are detached from the load balancer.</p> <p>The <code>detach instances from load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_613793 = header.getOrDefault("X-Amz-Target")
  valid_613793 = validateParameter(valid_613793, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachInstancesFromLoadBalancer"))
  if valid_613793 != nil:
    section.add "X-Amz-Target", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Signature")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Signature", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Content-Sha256", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Date")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Date", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Credential")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Credential", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Security-Token")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Security-Token", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Algorithm")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Algorithm", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-SignedHeaders", valid_613800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613802: Call_DetachInstancesFromLoadBalancer_613790;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Detaches the specified instances from a Lightsail load balancer.</p> <p>This operation waits until the instances are no longer needed before they are detached from the load balancer.</p> <p>The <code>detach instances from load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_613802.validator(path, query, header, formData, body)
  let scheme = call_613802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613802.url(scheme.get, call_613802.host, call_613802.base,
                         call_613802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613802, url, valid)

proc call*(call_613803: Call_DetachInstancesFromLoadBalancer_613790; body: JsonNode): Recallable =
  ## detachInstancesFromLoadBalancer
  ## <p>Detaches the specified instances from a Lightsail load balancer.</p> <p>This operation waits until the instances are no longer needed before they are detached from the load balancer.</p> <p>The <code>detach instances from load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_613804 = newJObject()
  if body != nil:
    body_613804 = body
  result = call_613803.call(nil, nil, nil, nil, body_613804)

var detachInstancesFromLoadBalancer* = Call_DetachInstancesFromLoadBalancer_613790(
    name: "detachInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DetachInstancesFromLoadBalancer",
    validator: validate_DetachInstancesFromLoadBalancer_613791, base: "/",
    url: url_DetachInstancesFromLoadBalancer_613792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachStaticIp_613805 = ref object of OpenApiRestCall_612658
proc url_DetachStaticIp_613807(protocol: Scheme; host: string; base: string;
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

proc validate_DetachStaticIp_613806(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Detaches a static IP from the Amazon Lightsail instance to which it is attached.
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
  var valid_613808 = header.getOrDefault("X-Amz-Target")
  valid_613808 = validateParameter(valid_613808, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachStaticIp"))
  if valid_613808 != nil:
    section.add "X-Amz-Target", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Signature")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Signature", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Content-Sha256", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Date")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Date", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Credential")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Credential", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Security-Token")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Security-Token", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Algorithm")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Algorithm", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-SignedHeaders", valid_613815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613817: Call_DetachStaticIp_613805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a static IP from the Amazon Lightsail instance to which it is attached.
  ## 
  let valid = call_613817.validator(path, query, header, formData, body)
  let scheme = call_613817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613817.url(scheme.get, call_613817.host, call_613817.base,
                         call_613817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613817, url, valid)

proc call*(call_613818: Call_DetachStaticIp_613805; body: JsonNode): Recallable =
  ## detachStaticIp
  ## Detaches a static IP from the Amazon Lightsail instance to which it is attached.
  ##   body: JObject (required)
  var body_613819 = newJObject()
  if body != nil:
    body_613819 = body
  result = call_613818.call(nil, nil, nil, nil, body_613819)

var detachStaticIp* = Call_DetachStaticIp_613805(name: "detachStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DetachStaticIp",
    validator: validate_DetachStaticIp_613806, base: "/", url: url_DetachStaticIp_613807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAddOn_613820 = ref object of OpenApiRestCall_612658
proc url_DisableAddOn_613822(protocol: Scheme; host: string; base: string;
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

proc validate_DisableAddOn_613821(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
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
  var valid_613823 = header.getOrDefault("X-Amz-Target")
  valid_613823 = validateParameter(valid_613823, JString, required = true, default = newJString(
      "Lightsail_20161128.DisableAddOn"))
  if valid_613823 != nil:
    section.add "X-Amz-Target", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Signature")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Signature", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Content-Sha256", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Date")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Date", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Credential")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Credential", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Security-Token")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Security-Token", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Algorithm")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Algorithm", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-SignedHeaders", valid_613830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613832: Call_DisableAddOn_613820; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_613832.validator(path, query, header, formData, body)
  let scheme = call_613832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613832.url(scheme.get, call_613832.host, call_613832.base,
                         call_613832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613832, url, valid)

proc call*(call_613833: Call_DisableAddOn_613820; body: JsonNode): Recallable =
  ## disableAddOn
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_613834 = newJObject()
  if body != nil:
    body_613834 = body
  result = call_613833.call(nil, nil, nil, nil, body_613834)

var disableAddOn* = Call_DisableAddOn_613820(name: "disableAddOn",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DisableAddOn",
    validator: validate_DisableAddOn_613821, base: "/", url: url_DisableAddOn_613822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DownloadDefaultKeyPair_613835 = ref object of OpenApiRestCall_612658
proc url_DownloadDefaultKeyPair_613837(protocol: Scheme; host: string; base: string;
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

proc validate_DownloadDefaultKeyPair_613836(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Downloads the default SSH key pair from the user's account.
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
  var valid_613838 = header.getOrDefault("X-Amz-Target")
  valid_613838 = validateParameter(valid_613838, JString, required = true, default = newJString(
      "Lightsail_20161128.DownloadDefaultKeyPair"))
  if valid_613838 != nil:
    section.add "X-Amz-Target", valid_613838
  var valid_613839 = header.getOrDefault("X-Amz-Signature")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-Signature", valid_613839
  var valid_613840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-Content-Sha256", valid_613840
  var valid_613841 = header.getOrDefault("X-Amz-Date")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-Date", valid_613841
  var valid_613842 = header.getOrDefault("X-Amz-Credential")
  valid_613842 = validateParameter(valid_613842, JString, required = false,
                                 default = nil)
  if valid_613842 != nil:
    section.add "X-Amz-Credential", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Security-Token")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Security-Token", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Algorithm")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Algorithm", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-SignedHeaders", valid_613845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613847: Call_DownloadDefaultKeyPair_613835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Downloads the default SSH key pair from the user's account.
  ## 
  let valid = call_613847.validator(path, query, header, formData, body)
  let scheme = call_613847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613847.url(scheme.get, call_613847.host, call_613847.base,
                         call_613847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613847, url, valid)

proc call*(call_613848: Call_DownloadDefaultKeyPair_613835; body: JsonNode): Recallable =
  ## downloadDefaultKeyPair
  ## Downloads the default SSH key pair from the user's account.
  ##   body: JObject (required)
  var body_613849 = newJObject()
  if body != nil:
    body_613849 = body
  result = call_613848.call(nil, nil, nil, nil, body_613849)

var downloadDefaultKeyPair* = Call_DownloadDefaultKeyPair_613835(
    name: "downloadDefaultKeyPair", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DownloadDefaultKeyPair",
    validator: validate_DownloadDefaultKeyPair_613836, base: "/",
    url: url_DownloadDefaultKeyPair_613837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAddOn_613850 = ref object of OpenApiRestCall_612658
proc url_EnableAddOn_613852(protocol: Scheme; host: string; base: string;
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

proc validate_EnableAddOn_613851(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
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
  var valid_613853 = header.getOrDefault("X-Amz-Target")
  valid_613853 = validateParameter(valid_613853, JString, required = true, default = newJString(
      "Lightsail_20161128.EnableAddOn"))
  if valid_613853 != nil:
    section.add "X-Amz-Target", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-Signature")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Signature", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Content-Sha256", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-Date")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Date", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-Credential")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-Credential", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-Security-Token")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-Security-Token", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Algorithm")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Algorithm", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-SignedHeaders", valid_613860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613862: Call_EnableAddOn_613850; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_613862.validator(path, query, header, formData, body)
  let scheme = call_613862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613862.url(scheme.get, call_613862.host, call_613862.base,
                         call_613862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613862, url, valid)

proc call*(call_613863: Call_EnableAddOn_613850; body: JsonNode): Recallable =
  ## enableAddOn
  ## Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_613864 = newJObject()
  if body != nil:
    body_613864 = body
  result = call_613863.call(nil, nil, nil, nil, body_613864)

var enableAddOn* = Call_EnableAddOn_613850(name: "enableAddOn",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.EnableAddOn",
                                        validator: validate_EnableAddOn_613851,
                                        base: "/", url: url_EnableAddOn_613852,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportSnapshot_613865 = ref object of OpenApiRestCall_612658
proc url_ExportSnapshot_613867(protocol: Scheme; host: string; base: string;
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

proc validate_ExportSnapshot_613866(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the <code>create cloud formation stack</code> operation to create new Amazon EC2 instances.</p> <p>Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot.</p> <p/> <p>The <code>export snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>source snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p> <note> <p>Use the <code>get instance snapshots</code> or <code>get disk snapshots</code> operations to get a list of snapshots that you can export to Amazon EC2.</p> </note>
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
  var valid_613868 = header.getOrDefault("X-Amz-Target")
  valid_613868 = validateParameter(valid_613868, JString, required = true, default = newJString(
      "Lightsail_20161128.ExportSnapshot"))
  if valid_613868 != nil:
    section.add "X-Amz-Target", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Signature")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Signature", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-Content-Sha256", valid_613870
  var valid_613871 = header.getOrDefault("X-Amz-Date")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "X-Amz-Date", valid_613871
  var valid_613872 = header.getOrDefault("X-Amz-Credential")
  valid_613872 = validateParameter(valid_613872, JString, required = false,
                                 default = nil)
  if valid_613872 != nil:
    section.add "X-Amz-Credential", valid_613872
  var valid_613873 = header.getOrDefault("X-Amz-Security-Token")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-Security-Token", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-Algorithm")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Algorithm", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-SignedHeaders", valid_613875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613877: Call_ExportSnapshot_613865; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the <code>create cloud formation stack</code> operation to create new Amazon EC2 instances.</p> <p>Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot.</p> <p/> <p>The <code>export snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>source snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p> <note> <p>Use the <code>get instance snapshots</code> or <code>get disk snapshots</code> operations to get a list of snapshots that you can export to Amazon EC2.</p> </note>
  ## 
  let valid = call_613877.validator(path, query, header, formData, body)
  let scheme = call_613877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613877.url(scheme.get, call_613877.host, call_613877.base,
                         call_613877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613877, url, valid)

proc call*(call_613878: Call_ExportSnapshot_613865; body: JsonNode): Recallable =
  ## exportSnapshot
  ## <p>Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the <code>create cloud formation stack</code> operation to create new Amazon EC2 instances.</p> <p>Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot.</p> <p/> <p>The <code>export snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>source snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p> <note> <p>Use the <code>get instance snapshots</code> or <code>get disk snapshots</code> operations to get a list of snapshots that you can export to Amazon EC2.</p> </note>
  ##   body: JObject (required)
  var body_613879 = newJObject()
  if body != nil:
    body_613879 = body
  result = call_613878.call(nil, nil, nil, nil, body_613879)

var exportSnapshot* = Call_ExportSnapshot_613865(name: "exportSnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ExportSnapshot",
    validator: validate_ExportSnapshot_613866, base: "/", url: url_ExportSnapshot_613867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetActiveNames_613880 = ref object of OpenApiRestCall_612658
proc url_GetActiveNames_613882(protocol: Scheme; host: string; base: string;
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

proc validate_GetActiveNames_613881(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns the names of all active (not deleted) resources.
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
  var valid_613883 = header.getOrDefault("X-Amz-Target")
  valid_613883 = validateParameter(valid_613883, JString, required = true, default = newJString(
      "Lightsail_20161128.GetActiveNames"))
  if valid_613883 != nil:
    section.add "X-Amz-Target", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Signature")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Signature", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Content-Sha256", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-Date")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-Date", valid_613886
  var valid_613887 = header.getOrDefault("X-Amz-Credential")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-Credential", valid_613887
  var valid_613888 = header.getOrDefault("X-Amz-Security-Token")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "X-Amz-Security-Token", valid_613888
  var valid_613889 = header.getOrDefault("X-Amz-Algorithm")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Algorithm", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-SignedHeaders", valid_613890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613892: Call_GetActiveNames_613880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the names of all active (not deleted) resources.
  ## 
  let valid = call_613892.validator(path, query, header, formData, body)
  let scheme = call_613892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613892.url(scheme.get, call_613892.host, call_613892.base,
                         call_613892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613892, url, valid)

proc call*(call_613893: Call_GetActiveNames_613880; body: JsonNode): Recallable =
  ## getActiveNames
  ## Returns the names of all active (not deleted) resources.
  ##   body: JObject (required)
  var body_613894 = newJObject()
  if body != nil:
    body_613894 = body
  result = call_613893.call(nil, nil, nil, nil, body_613894)

var getActiveNames* = Call_GetActiveNames_613880(name: "getActiveNames",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetActiveNames",
    validator: validate_GetActiveNames_613881, base: "/", url: url_GetActiveNames_613882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutoSnapshots_613895 = ref object of OpenApiRestCall_612658
proc url_GetAutoSnapshots_613897(protocol: Scheme; host: string; base: string;
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

proc validate_GetAutoSnapshots_613896(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the available automatic snapshots for an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
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
  var valid_613898 = header.getOrDefault("X-Amz-Target")
  valid_613898 = validateParameter(valid_613898, JString, required = true, default = newJString(
      "Lightsail_20161128.GetAutoSnapshots"))
  if valid_613898 != nil:
    section.add "X-Amz-Target", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Signature")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Signature", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Content-Sha256", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Date")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Date", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Credential")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Credential", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-Security-Token")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-Security-Token", valid_613903
  var valid_613904 = header.getOrDefault("X-Amz-Algorithm")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "X-Amz-Algorithm", valid_613904
  var valid_613905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "X-Amz-SignedHeaders", valid_613905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613907: Call_GetAutoSnapshots_613895; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the available automatic snapshots for an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_613907.validator(path, query, header, formData, body)
  let scheme = call_613907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613907.url(scheme.get, call_613907.host, call_613907.base,
                         call_613907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613907, url, valid)

proc call*(call_613908: Call_GetAutoSnapshots_613895; body: JsonNode): Recallable =
  ## getAutoSnapshots
  ## Returns the available automatic snapshots for an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_613909 = newJObject()
  if body != nil:
    body_613909 = body
  result = call_613908.call(nil, nil, nil, nil, body_613909)

var getAutoSnapshots* = Call_GetAutoSnapshots_613895(name: "getAutoSnapshots",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetAutoSnapshots",
    validator: validate_GetAutoSnapshots_613896, base: "/",
    url: url_GetAutoSnapshots_613897, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlueprints_613910 = ref object of OpenApiRestCall_612658
proc url_GetBlueprints_613912(protocol: Scheme; host: string; base: string;
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

proc validate_GetBlueprints_613911(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
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
  var valid_613913 = header.getOrDefault("X-Amz-Target")
  valid_613913 = validateParameter(valid_613913, JString, required = true, default = newJString(
      "Lightsail_20161128.GetBlueprints"))
  if valid_613913 != nil:
    section.add "X-Amz-Target", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Signature")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Signature", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Content-Sha256", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Date")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Date", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Credential")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Credential", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Security-Token")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Security-Token", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Algorithm")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Algorithm", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-SignedHeaders", valid_613920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613922: Call_GetBlueprints_613910; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
  ## 
  let valid = call_613922.validator(path, query, header, formData, body)
  let scheme = call_613922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613922.url(scheme.get, call_613922.host, call_613922.base,
                         call_613922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613922, url, valid)

proc call*(call_613923: Call_GetBlueprints_613910; body: JsonNode): Recallable =
  ## getBlueprints
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
  ##   body: JObject (required)
  var body_613924 = newJObject()
  if body != nil:
    body_613924 = body
  result = call_613923.call(nil, nil, nil, nil, body_613924)

var getBlueprints* = Call_GetBlueprints_613910(name: "getBlueprints",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetBlueprints",
    validator: validate_GetBlueprints_613911, base: "/", url: url_GetBlueprints_613912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBundles_613925 = ref object of OpenApiRestCall_612658
proc url_GetBundles_613927(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBundles_613926(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the list of bundles that are available for purchase. A bundle describes the specs for your virtual private server (or <i>instance</i>).
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
  var valid_613928 = header.getOrDefault("X-Amz-Target")
  valid_613928 = validateParameter(valid_613928, JString, required = true, default = newJString(
      "Lightsail_20161128.GetBundles"))
  if valid_613928 != nil:
    section.add "X-Amz-Target", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Signature")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Signature", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Content-Sha256", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-Date")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Date", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-Credential")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Credential", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Security-Token")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Security-Token", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Algorithm")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Algorithm", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-SignedHeaders", valid_613935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613937: Call_GetBundles_613925; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of bundles that are available for purchase. A bundle describes the specs for your virtual private server (or <i>instance</i>).
  ## 
  let valid = call_613937.validator(path, query, header, formData, body)
  let scheme = call_613937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613937.url(scheme.get, call_613937.host, call_613937.base,
                         call_613937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613937, url, valid)

proc call*(call_613938: Call_GetBundles_613925; body: JsonNode): Recallable =
  ## getBundles
  ## Returns the list of bundles that are available for purchase. A bundle describes the specs for your virtual private server (or <i>instance</i>).
  ##   body: JObject (required)
  var body_613939 = newJObject()
  if body != nil:
    body_613939 = body
  result = call_613938.call(nil, nil, nil, nil, body_613939)

var getBundles* = Call_GetBundles_613925(name: "getBundles",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetBundles",
                                      validator: validate_GetBundles_613926,
                                      base: "/", url: url_GetBundles_613927,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFormationStackRecords_613940 = ref object of OpenApiRestCall_612658
proc url_GetCloudFormationStackRecords_613942(protocol: Scheme; host: string;
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

proc validate_GetCloudFormationStackRecords_613941(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the CloudFormation stack record created as a result of the <code>create cloud formation stack</code> operation.</p> <p>An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.</p>
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
  var valid_613943 = header.getOrDefault("X-Amz-Target")
  valid_613943 = validateParameter(valid_613943, JString, required = true, default = newJString(
      "Lightsail_20161128.GetCloudFormationStackRecords"))
  if valid_613943 != nil:
    section.add "X-Amz-Target", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Signature")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Signature", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Content-Sha256", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Date")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Date", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Credential")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Credential", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Security-Token")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Security-Token", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-Algorithm")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-Algorithm", valid_613949
  var valid_613950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-SignedHeaders", valid_613950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613952: Call_GetCloudFormationStackRecords_613940; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the CloudFormation stack record created as a result of the <code>create cloud formation stack</code> operation.</p> <p>An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.</p>
  ## 
  let valid = call_613952.validator(path, query, header, formData, body)
  let scheme = call_613952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613952.url(scheme.get, call_613952.host, call_613952.base,
                         call_613952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613952, url, valid)

proc call*(call_613953: Call_GetCloudFormationStackRecords_613940; body: JsonNode): Recallable =
  ## getCloudFormationStackRecords
  ## <p>Returns the CloudFormation stack record created as a result of the <code>create cloud formation stack</code> operation.</p> <p>An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.</p>
  ##   body: JObject (required)
  var body_613954 = newJObject()
  if body != nil:
    body_613954 = body
  result = call_613953.call(nil, nil, nil, nil, body_613954)

var getCloudFormationStackRecords* = Call_GetCloudFormationStackRecords_613940(
    name: "getCloudFormationStackRecords", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetCloudFormationStackRecords",
    validator: validate_GetCloudFormationStackRecords_613941, base: "/",
    url: url_GetCloudFormationStackRecords_613942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisk_613955 = ref object of OpenApiRestCall_612658
proc url_GetDisk_613957(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDisk_613956(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specific block storage disk.
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
  var valid_613958 = header.getOrDefault("X-Amz-Target")
  valid_613958 = validateParameter(valid_613958, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDisk"))
  if valid_613958 != nil:
    section.add "X-Amz-Target", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Signature")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Signature", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Content-Sha256", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Date")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Date", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Credential")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Credential", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Security-Token")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Security-Token", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-Algorithm")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Algorithm", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-SignedHeaders", valid_613965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613967: Call_GetDisk_613955; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific block storage disk.
  ## 
  let valid = call_613967.validator(path, query, header, formData, body)
  let scheme = call_613967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613967.url(scheme.get, call_613967.host, call_613967.base,
                         call_613967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613967, url, valid)

proc call*(call_613968: Call_GetDisk_613955; body: JsonNode): Recallable =
  ## getDisk
  ## Returns information about a specific block storage disk.
  ##   body: JObject (required)
  var body_613969 = newJObject()
  if body != nil:
    body_613969 = body
  result = call_613968.call(nil, nil, nil, nil, body_613969)

var getDisk* = Call_GetDisk_613955(name: "getDisk", meth: HttpMethod.HttpPost,
                                host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDisk",
                                validator: validate_GetDisk_613956, base: "/",
                                url: url_GetDisk_613957,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiskSnapshot_613970 = ref object of OpenApiRestCall_612658
proc url_GetDiskSnapshot_613972(protocol: Scheme; host: string; base: string;
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

proc validate_GetDiskSnapshot_613971(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about a specific block storage disk snapshot.
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
  var valid_613973 = header.getOrDefault("X-Amz-Target")
  valid_613973 = validateParameter(valid_613973, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDiskSnapshot"))
  if valid_613973 != nil:
    section.add "X-Amz-Target", valid_613973
  var valid_613974 = header.getOrDefault("X-Amz-Signature")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-Signature", valid_613974
  var valid_613975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Content-Sha256", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Date")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Date", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Credential")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Credential", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Security-Token")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Security-Token", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Algorithm")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Algorithm", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-SignedHeaders", valid_613980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613982: Call_GetDiskSnapshot_613970; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific block storage disk snapshot.
  ## 
  let valid = call_613982.validator(path, query, header, formData, body)
  let scheme = call_613982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613982.url(scheme.get, call_613982.host, call_613982.base,
                         call_613982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613982, url, valid)

proc call*(call_613983: Call_GetDiskSnapshot_613970; body: JsonNode): Recallable =
  ## getDiskSnapshot
  ## Returns information about a specific block storage disk snapshot.
  ##   body: JObject (required)
  var body_613984 = newJObject()
  if body != nil:
    body_613984 = body
  result = call_613983.call(nil, nil, nil, nil, body_613984)

var getDiskSnapshot* = Call_GetDiskSnapshot_613970(name: "getDiskSnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDiskSnapshot",
    validator: validate_GetDiskSnapshot_613971, base: "/", url: url_GetDiskSnapshot_613972,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiskSnapshots_613985 = ref object of OpenApiRestCall_612658
proc url_GetDiskSnapshots_613987(protocol: Scheme; host: string; base: string;
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

proc validate_GetDiskSnapshots_613986(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns information about all block storage disk snapshots in your AWS account and region.</p> <p>If you are describing a long list of disk snapshots, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
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
  var valid_613988 = header.getOrDefault("X-Amz-Target")
  valid_613988 = validateParameter(valid_613988, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDiskSnapshots"))
  if valid_613988 != nil:
    section.add "X-Amz-Target", valid_613988
  var valid_613989 = header.getOrDefault("X-Amz-Signature")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-Signature", valid_613989
  var valid_613990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Content-Sha256", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Date")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Date", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Credential")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Credential", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Security-Token")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Security-Token", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Algorithm")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Algorithm", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-SignedHeaders", valid_613995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613997: Call_GetDiskSnapshots_613985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all block storage disk snapshots in your AWS account and region.</p> <p>If you are describing a long list of disk snapshots, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ## 
  let valid = call_613997.validator(path, query, header, formData, body)
  let scheme = call_613997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613997.url(scheme.get, call_613997.host, call_613997.base,
                         call_613997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613997, url, valid)

proc call*(call_613998: Call_GetDiskSnapshots_613985; body: JsonNode): Recallable =
  ## getDiskSnapshots
  ## <p>Returns information about all block storage disk snapshots in your AWS account and region.</p> <p>If you are describing a long list of disk snapshots, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ##   body: JObject (required)
  var body_613999 = newJObject()
  if body != nil:
    body_613999 = body
  result = call_613998.call(nil, nil, nil, nil, body_613999)

var getDiskSnapshots* = Call_GetDiskSnapshots_613985(name: "getDiskSnapshots",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDiskSnapshots",
    validator: validate_GetDiskSnapshots_613986, base: "/",
    url: url_GetDiskSnapshots_613987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisks_614000 = ref object of OpenApiRestCall_612658
proc url_GetDisks_614002(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDisks_614001(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about all block storage disks in your AWS account and region.</p> <p>If you are describing a long list of disks, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
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
  var valid_614003 = header.getOrDefault("X-Amz-Target")
  valid_614003 = validateParameter(valid_614003, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDisks"))
  if valid_614003 != nil:
    section.add "X-Amz-Target", valid_614003
  var valid_614004 = header.getOrDefault("X-Amz-Signature")
  valid_614004 = validateParameter(valid_614004, JString, required = false,
                                 default = nil)
  if valid_614004 != nil:
    section.add "X-Amz-Signature", valid_614004
  var valid_614005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614005 = validateParameter(valid_614005, JString, required = false,
                                 default = nil)
  if valid_614005 != nil:
    section.add "X-Amz-Content-Sha256", valid_614005
  var valid_614006 = header.getOrDefault("X-Amz-Date")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-Date", valid_614006
  var valid_614007 = header.getOrDefault("X-Amz-Credential")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "X-Amz-Credential", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-Security-Token")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Security-Token", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Algorithm")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Algorithm", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-SignedHeaders", valid_614010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614012: Call_GetDisks_614000; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all block storage disks in your AWS account and region.</p> <p>If you are describing a long list of disks, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ## 
  let valid = call_614012.validator(path, query, header, formData, body)
  let scheme = call_614012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614012.url(scheme.get, call_614012.host, call_614012.base,
                         call_614012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614012, url, valid)

proc call*(call_614013: Call_GetDisks_614000; body: JsonNode): Recallable =
  ## getDisks
  ## <p>Returns information about all block storage disks in your AWS account and region.</p> <p>If you are describing a long list of disks, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ##   body: JObject (required)
  var body_614014 = newJObject()
  if body != nil:
    body_614014 = body
  result = call_614013.call(nil, nil, nil, nil, body_614014)

var getDisks* = Call_GetDisks_614000(name: "getDisks", meth: HttpMethod.HttpPost,
                                  host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDisks",
                                  validator: validate_GetDisks_614001, base: "/",
                                  url: url_GetDisks_614002,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomain_614015 = ref object of OpenApiRestCall_612658
proc url_GetDomain_614017(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDomain_614016(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specific domain recordset.
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
  var valid_614018 = header.getOrDefault("X-Amz-Target")
  valid_614018 = validateParameter(valid_614018, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDomain"))
  if valid_614018 != nil:
    section.add "X-Amz-Target", valid_614018
  var valid_614019 = header.getOrDefault("X-Amz-Signature")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-Signature", valid_614019
  var valid_614020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614020 = validateParameter(valid_614020, JString, required = false,
                                 default = nil)
  if valid_614020 != nil:
    section.add "X-Amz-Content-Sha256", valid_614020
  var valid_614021 = header.getOrDefault("X-Amz-Date")
  valid_614021 = validateParameter(valid_614021, JString, required = false,
                                 default = nil)
  if valid_614021 != nil:
    section.add "X-Amz-Date", valid_614021
  var valid_614022 = header.getOrDefault("X-Amz-Credential")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "X-Amz-Credential", valid_614022
  var valid_614023 = header.getOrDefault("X-Amz-Security-Token")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Security-Token", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Algorithm")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Algorithm", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-SignedHeaders", valid_614025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614027: Call_GetDomain_614015; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific domain recordset.
  ## 
  let valid = call_614027.validator(path, query, header, formData, body)
  let scheme = call_614027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614027.url(scheme.get, call_614027.host, call_614027.base,
                         call_614027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614027, url, valid)

proc call*(call_614028: Call_GetDomain_614015; body: JsonNode): Recallable =
  ## getDomain
  ## Returns information about a specific domain recordset.
  ##   body: JObject (required)
  var body_614029 = newJObject()
  if body != nil:
    body_614029 = body
  result = call_614028.call(nil, nil, nil, nil, body_614029)

var getDomain* = Call_GetDomain_614015(name: "getDomain", meth: HttpMethod.HttpPost,
                                    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDomain",
                                    validator: validate_GetDomain_614016,
                                    base: "/", url: url_GetDomain_614017,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomains_614030 = ref object of OpenApiRestCall_612658
proc url_GetDomains_614032(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDomains_614031(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all domains in the user's account.
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
  var valid_614033 = header.getOrDefault("X-Amz-Target")
  valid_614033 = validateParameter(valid_614033, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDomains"))
  if valid_614033 != nil:
    section.add "X-Amz-Target", valid_614033
  var valid_614034 = header.getOrDefault("X-Amz-Signature")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-Signature", valid_614034
  var valid_614035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614035 = validateParameter(valid_614035, JString, required = false,
                                 default = nil)
  if valid_614035 != nil:
    section.add "X-Amz-Content-Sha256", valid_614035
  var valid_614036 = header.getOrDefault("X-Amz-Date")
  valid_614036 = validateParameter(valid_614036, JString, required = false,
                                 default = nil)
  if valid_614036 != nil:
    section.add "X-Amz-Date", valid_614036
  var valid_614037 = header.getOrDefault("X-Amz-Credential")
  valid_614037 = validateParameter(valid_614037, JString, required = false,
                                 default = nil)
  if valid_614037 != nil:
    section.add "X-Amz-Credential", valid_614037
  var valid_614038 = header.getOrDefault("X-Amz-Security-Token")
  valid_614038 = validateParameter(valid_614038, JString, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "X-Amz-Security-Token", valid_614038
  var valid_614039 = header.getOrDefault("X-Amz-Algorithm")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "X-Amz-Algorithm", valid_614039
  var valid_614040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "X-Amz-SignedHeaders", valid_614040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614042: Call_GetDomains_614030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all domains in the user's account.
  ## 
  let valid = call_614042.validator(path, query, header, formData, body)
  let scheme = call_614042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614042.url(scheme.get, call_614042.host, call_614042.base,
                         call_614042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614042, url, valid)

proc call*(call_614043: Call_GetDomains_614030; body: JsonNode): Recallable =
  ## getDomains
  ## Returns a list of all domains in the user's account.
  ##   body: JObject (required)
  var body_614044 = newJObject()
  if body != nil:
    body_614044 = body
  result = call_614043.call(nil, nil, nil, nil, body_614044)

var getDomains* = Call_GetDomains_614030(name: "getDomains",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDomains",
                                      validator: validate_GetDomains_614031,
                                      base: "/", url: url_GetDomains_614032,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportSnapshotRecords_614045 = ref object of OpenApiRestCall_612658
proc url_GetExportSnapshotRecords_614047(protocol: Scheme; host: string;
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

proc validate_GetExportSnapshotRecords_614046(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
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
  var valid_614048 = header.getOrDefault("X-Amz-Target")
  valid_614048 = validateParameter(valid_614048, JString, required = true, default = newJString(
      "Lightsail_20161128.GetExportSnapshotRecords"))
  if valid_614048 != nil:
    section.add "X-Amz-Target", valid_614048
  var valid_614049 = header.getOrDefault("X-Amz-Signature")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-Signature", valid_614049
  var valid_614050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-Content-Sha256", valid_614050
  var valid_614051 = header.getOrDefault("X-Amz-Date")
  valid_614051 = validateParameter(valid_614051, JString, required = false,
                                 default = nil)
  if valid_614051 != nil:
    section.add "X-Amz-Date", valid_614051
  var valid_614052 = header.getOrDefault("X-Amz-Credential")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-Credential", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Security-Token")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Security-Token", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Algorithm")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Algorithm", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-SignedHeaders", valid_614055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614057: Call_GetExportSnapshotRecords_614045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
  ## 
  let valid = call_614057.validator(path, query, header, formData, body)
  let scheme = call_614057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614057.url(scheme.get, call_614057.host, call_614057.base,
                         call_614057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614057, url, valid)

proc call*(call_614058: Call_GetExportSnapshotRecords_614045; body: JsonNode): Recallable =
  ## getExportSnapshotRecords
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
  ##   body: JObject (required)
  var body_614059 = newJObject()
  if body != nil:
    body_614059 = body
  result = call_614058.call(nil, nil, nil, nil, body_614059)

var getExportSnapshotRecords* = Call_GetExportSnapshotRecords_614045(
    name: "getExportSnapshotRecords", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetExportSnapshotRecords",
    validator: validate_GetExportSnapshotRecords_614046, base: "/",
    url: url_GetExportSnapshotRecords_614047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstance_614060 = ref object of OpenApiRestCall_612658
proc url_GetInstance_614062(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstance_614061(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
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
  var valid_614063 = header.getOrDefault("X-Amz-Target")
  valid_614063 = validateParameter(valid_614063, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstance"))
  if valid_614063 != nil:
    section.add "X-Amz-Target", valid_614063
  var valid_614064 = header.getOrDefault("X-Amz-Signature")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-Signature", valid_614064
  var valid_614065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-Content-Sha256", valid_614065
  var valid_614066 = header.getOrDefault("X-Amz-Date")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Date", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-Credential")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Credential", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Security-Token")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Security-Token", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Algorithm")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Algorithm", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-SignedHeaders", valid_614070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614072: Call_GetInstance_614060; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
  ## 
  let valid = call_614072.validator(path, query, header, formData, body)
  let scheme = call_614072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614072.url(scheme.get, call_614072.host, call_614072.base,
                         call_614072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614072, url, valid)

proc call*(call_614073: Call_GetInstance_614060; body: JsonNode): Recallable =
  ## getInstance
  ## Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
  ##   body: JObject (required)
  var body_614074 = newJObject()
  if body != nil:
    body_614074 = body
  result = call_614073.call(nil, nil, nil, nil, body_614074)

var getInstance* = Call_GetInstance_614060(name: "getInstance",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetInstance",
                                        validator: validate_GetInstance_614061,
                                        base: "/", url: url_GetInstance_614062,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceAccessDetails_614075 = ref object of OpenApiRestCall_612658
proc url_GetInstanceAccessDetails_614077(protocol: Scheme; host: string;
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

proc validate_GetInstanceAccessDetails_614076(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614078 = header.getOrDefault("X-Amz-Target")
  valid_614078 = validateParameter(valid_614078, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceAccessDetails"))
  if valid_614078 != nil:
    section.add "X-Amz-Target", valid_614078
  var valid_614079 = header.getOrDefault("X-Amz-Signature")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "X-Amz-Signature", valid_614079
  var valid_614080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "X-Amz-Content-Sha256", valid_614080
  var valid_614081 = header.getOrDefault("X-Amz-Date")
  valid_614081 = validateParameter(valid_614081, JString, required = false,
                                 default = nil)
  if valid_614081 != nil:
    section.add "X-Amz-Date", valid_614081
  var valid_614082 = header.getOrDefault("X-Amz-Credential")
  valid_614082 = validateParameter(valid_614082, JString, required = false,
                                 default = nil)
  if valid_614082 != nil:
    section.add "X-Amz-Credential", valid_614082
  var valid_614083 = header.getOrDefault("X-Amz-Security-Token")
  valid_614083 = validateParameter(valid_614083, JString, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "X-Amz-Security-Token", valid_614083
  var valid_614084 = header.getOrDefault("X-Amz-Algorithm")
  valid_614084 = validateParameter(valid_614084, JString, required = false,
                                 default = nil)
  if valid_614084 != nil:
    section.add "X-Amz-Algorithm", valid_614084
  var valid_614085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614085 = validateParameter(valid_614085, JString, required = false,
                                 default = nil)
  if valid_614085 != nil:
    section.add "X-Amz-SignedHeaders", valid_614085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614087: Call_GetInstanceAccessDetails_614075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614087.validator(path, query, header, formData, body)
  let scheme = call_614087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614087.url(scheme.get, call_614087.host, call_614087.base,
                         call_614087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614087, url, valid)

proc call*(call_614088: Call_GetInstanceAccessDetails_614075; body: JsonNode): Recallable =
  ## getInstanceAccessDetails
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614089 = newJObject()
  if body != nil:
    body_614089 = body
  result = call_614088.call(nil, nil, nil, nil, body_614089)

var getInstanceAccessDetails* = Call_GetInstanceAccessDetails_614075(
    name: "getInstanceAccessDetails", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceAccessDetails",
    validator: validate_GetInstanceAccessDetails_614076, base: "/",
    url: url_GetInstanceAccessDetails_614077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceMetricData_614090 = ref object of OpenApiRestCall_612658
proc url_GetInstanceMetricData_614092(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstanceMetricData_614091(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the data points for the specified Amazon Lightsail instance metric, given an instance name.
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
  var valid_614093 = header.getOrDefault("X-Amz-Target")
  valid_614093 = validateParameter(valid_614093, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceMetricData"))
  if valid_614093 != nil:
    section.add "X-Amz-Target", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-Signature")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-Signature", valid_614094
  var valid_614095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614095 = validateParameter(valid_614095, JString, required = false,
                                 default = nil)
  if valid_614095 != nil:
    section.add "X-Amz-Content-Sha256", valid_614095
  var valid_614096 = header.getOrDefault("X-Amz-Date")
  valid_614096 = validateParameter(valid_614096, JString, required = false,
                                 default = nil)
  if valid_614096 != nil:
    section.add "X-Amz-Date", valid_614096
  var valid_614097 = header.getOrDefault("X-Amz-Credential")
  valid_614097 = validateParameter(valid_614097, JString, required = false,
                                 default = nil)
  if valid_614097 != nil:
    section.add "X-Amz-Credential", valid_614097
  var valid_614098 = header.getOrDefault("X-Amz-Security-Token")
  valid_614098 = validateParameter(valid_614098, JString, required = false,
                                 default = nil)
  if valid_614098 != nil:
    section.add "X-Amz-Security-Token", valid_614098
  var valid_614099 = header.getOrDefault("X-Amz-Algorithm")
  valid_614099 = validateParameter(valid_614099, JString, required = false,
                                 default = nil)
  if valid_614099 != nil:
    section.add "X-Amz-Algorithm", valid_614099
  var valid_614100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614100 = validateParameter(valid_614100, JString, required = false,
                                 default = nil)
  if valid_614100 != nil:
    section.add "X-Amz-SignedHeaders", valid_614100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614102: Call_GetInstanceMetricData_614090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the data points for the specified Amazon Lightsail instance metric, given an instance name.
  ## 
  let valid = call_614102.validator(path, query, header, formData, body)
  let scheme = call_614102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614102.url(scheme.get, call_614102.host, call_614102.base,
                         call_614102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614102, url, valid)

proc call*(call_614103: Call_GetInstanceMetricData_614090; body: JsonNode): Recallable =
  ## getInstanceMetricData
  ## Returns the data points for the specified Amazon Lightsail instance metric, given an instance name.
  ##   body: JObject (required)
  var body_614104 = newJObject()
  if body != nil:
    body_614104 = body
  result = call_614103.call(nil, nil, nil, nil, body_614104)

var getInstanceMetricData* = Call_GetInstanceMetricData_614090(
    name: "getInstanceMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceMetricData",
    validator: validate_GetInstanceMetricData_614091, base: "/",
    url: url_GetInstanceMetricData_614092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstancePortStates_614105 = ref object of OpenApiRestCall_612658
proc url_GetInstancePortStates_614107(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstancePortStates_614106(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the port states for a specific virtual private server, or <i>instance</i>.
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
  var valid_614108 = header.getOrDefault("X-Amz-Target")
  valid_614108 = validateParameter(valid_614108, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstancePortStates"))
  if valid_614108 != nil:
    section.add "X-Amz-Target", valid_614108
  var valid_614109 = header.getOrDefault("X-Amz-Signature")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "X-Amz-Signature", valid_614109
  var valid_614110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614110 = validateParameter(valid_614110, JString, required = false,
                                 default = nil)
  if valid_614110 != nil:
    section.add "X-Amz-Content-Sha256", valid_614110
  var valid_614111 = header.getOrDefault("X-Amz-Date")
  valid_614111 = validateParameter(valid_614111, JString, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "X-Amz-Date", valid_614111
  var valid_614112 = header.getOrDefault("X-Amz-Credential")
  valid_614112 = validateParameter(valid_614112, JString, required = false,
                                 default = nil)
  if valid_614112 != nil:
    section.add "X-Amz-Credential", valid_614112
  var valid_614113 = header.getOrDefault("X-Amz-Security-Token")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "X-Amz-Security-Token", valid_614113
  var valid_614114 = header.getOrDefault("X-Amz-Algorithm")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "X-Amz-Algorithm", valid_614114
  var valid_614115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "X-Amz-SignedHeaders", valid_614115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614117: Call_GetInstancePortStates_614105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the port states for a specific virtual private server, or <i>instance</i>.
  ## 
  let valid = call_614117.validator(path, query, header, formData, body)
  let scheme = call_614117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614117.url(scheme.get, call_614117.host, call_614117.base,
                         call_614117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614117, url, valid)

proc call*(call_614118: Call_GetInstancePortStates_614105; body: JsonNode): Recallable =
  ## getInstancePortStates
  ## Returns the port states for a specific virtual private server, or <i>instance</i>.
  ##   body: JObject (required)
  var body_614119 = newJObject()
  if body != nil:
    body_614119 = body
  result = call_614118.call(nil, nil, nil, nil, body_614119)

var getInstancePortStates* = Call_GetInstancePortStates_614105(
    name: "getInstancePortStates", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstancePortStates",
    validator: validate_GetInstancePortStates_614106, base: "/",
    url: url_GetInstancePortStates_614107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceSnapshot_614120 = ref object of OpenApiRestCall_612658
proc url_GetInstanceSnapshot_614122(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstanceSnapshot_614121(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns information about a specific instance snapshot.
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
  var valid_614123 = header.getOrDefault("X-Amz-Target")
  valid_614123 = validateParameter(valid_614123, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceSnapshot"))
  if valid_614123 != nil:
    section.add "X-Amz-Target", valid_614123
  var valid_614124 = header.getOrDefault("X-Amz-Signature")
  valid_614124 = validateParameter(valid_614124, JString, required = false,
                                 default = nil)
  if valid_614124 != nil:
    section.add "X-Amz-Signature", valid_614124
  var valid_614125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614125 = validateParameter(valid_614125, JString, required = false,
                                 default = nil)
  if valid_614125 != nil:
    section.add "X-Amz-Content-Sha256", valid_614125
  var valid_614126 = header.getOrDefault("X-Amz-Date")
  valid_614126 = validateParameter(valid_614126, JString, required = false,
                                 default = nil)
  if valid_614126 != nil:
    section.add "X-Amz-Date", valid_614126
  var valid_614127 = header.getOrDefault("X-Amz-Credential")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "X-Amz-Credential", valid_614127
  var valid_614128 = header.getOrDefault("X-Amz-Security-Token")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "X-Amz-Security-Token", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Algorithm")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Algorithm", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-SignedHeaders", valid_614130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614132: Call_GetInstanceSnapshot_614120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific instance snapshot.
  ## 
  let valid = call_614132.validator(path, query, header, formData, body)
  let scheme = call_614132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614132.url(scheme.get, call_614132.host, call_614132.base,
                         call_614132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614132, url, valid)

proc call*(call_614133: Call_GetInstanceSnapshot_614120; body: JsonNode): Recallable =
  ## getInstanceSnapshot
  ## Returns information about a specific instance snapshot.
  ##   body: JObject (required)
  var body_614134 = newJObject()
  if body != nil:
    body_614134 = body
  result = call_614133.call(nil, nil, nil, nil, body_614134)

var getInstanceSnapshot* = Call_GetInstanceSnapshot_614120(
    name: "getInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceSnapshot",
    validator: validate_GetInstanceSnapshot_614121, base: "/",
    url: url_GetInstanceSnapshot_614122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceSnapshots_614135 = ref object of OpenApiRestCall_612658
proc url_GetInstanceSnapshots_614137(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstanceSnapshots_614136(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all instance snapshots for the user's account.
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
  var valid_614138 = header.getOrDefault("X-Amz-Target")
  valid_614138 = validateParameter(valid_614138, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceSnapshots"))
  if valid_614138 != nil:
    section.add "X-Amz-Target", valid_614138
  var valid_614139 = header.getOrDefault("X-Amz-Signature")
  valid_614139 = validateParameter(valid_614139, JString, required = false,
                                 default = nil)
  if valid_614139 != nil:
    section.add "X-Amz-Signature", valid_614139
  var valid_614140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614140 = validateParameter(valid_614140, JString, required = false,
                                 default = nil)
  if valid_614140 != nil:
    section.add "X-Amz-Content-Sha256", valid_614140
  var valid_614141 = header.getOrDefault("X-Amz-Date")
  valid_614141 = validateParameter(valid_614141, JString, required = false,
                                 default = nil)
  if valid_614141 != nil:
    section.add "X-Amz-Date", valid_614141
  var valid_614142 = header.getOrDefault("X-Amz-Credential")
  valid_614142 = validateParameter(valid_614142, JString, required = false,
                                 default = nil)
  if valid_614142 != nil:
    section.add "X-Amz-Credential", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-Security-Token")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-Security-Token", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Algorithm")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Algorithm", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-SignedHeaders", valid_614145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614147: Call_GetInstanceSnapshots_614135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all instance snapshots for the user's account.
  ## 
  let valid = call_614147.validator(path, query, header, formData, body)
  let scheme = call_614147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614147.url(scheme.get, call_614147.host, call_614147.base,
                         call_614147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614147, url, valid)

proc call*(call_614148: Call_GetInstanceSnapshots_614135; body: JsonNode): Recallable =
  ## getInstanceSnapshots
  ## Returns all instance snapshots for the user's account.
  ##   body: JObject (required)
  var body_614149 = newJObject()
  if body != nil:
    body_614149 = body
  result = call_614148.call(nil, nil, nil, nil, body_614149)

var getInstanceSnapshots* = Call_GetInstanceSnapshots_614135(
    name: "getInstanceSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceSnapshots",
    validator: validate_GetInstanceSnapshots_614136, base: "/",
    url: url_GetInstanceSnapshots_614137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceState_614150 = ref object of OpenApiRestCall_612658
proc url_GetInstanceState_614152(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstanceState_614151(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the state of a specific instance. Works on one instance at a time.
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
  var valid_614153 = header.getOrDefault("X-Amz-Target")
  valid_614153 = validateParameter(valid_614153, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceState"))
  if valid_614153 != nil:
    section.add "X-Amz-Target", valid_614153
  var valid_614154 = header.getOrDefault("X-Amz-Signature")
  valid_614154 = validateParameter(valid_614154, JString, required = false,
                                 default = nil)
  if valid_614154 != nil:
    section.add "X-Amz-Signature", valid_614154
  var valid_614155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614155 = validateParameter(valid_614155, JString, required = false,
                                 default = nil)
  if valid_614155 != nil:
    section.add "X-Amz-Content-Sha256", valid_614155
  var valid_614156 = header.getOrDefault("X-Amz-Date")
  valid_614156 = validateParameter(valid_614156, JString, required = false,
                                 default = nil)
  if valid_614156 != nil:
    section.add "X-Amz-Date", valid_614156
  var valid_614157 = header.getOrDefault("X-Amz-Credential")
  valid_614157 = validateParameter(valid_614157, JString, required = false,
                                 default = nil)
  if valid_614157 != nil:
    section.add "X-Amz-Credential", valid_614157
  var valid_614158 = header.getOrDefault("X-Amz-Security-Token")
  valid_614158 = validateParameter(valid_614158, JString, required = false,
                                 default = nil)
  if valid_614158 != nil:
    section.add "X-Amz-Security-Token", valid_614158
  var valid_614159 = header.getOrDefault("X-Amz-Algorithm")
  valid_614159 = validateParameter(valid_614159, JString, required = false,
                                 default = nil)
  if valid_614159 != nil:
    section.add "X-Amz-Algorithm", valid_614159
  var valid_614160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614160 = validateParameter(valid_614160, JString, required = false,
                                 default = nil)
  if valid_614160 != nil:
    section.add "X-Amz-SignedHeaders", valid_614160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614162: Call_GetInstanceState_614150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the state of a specific instance. Works on one instance at a time.
  ## 
  let valid = call_614162.validator(path, query, header, formData, body)
  let scheme = call_614162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614162.url(scheme.get, call_614162.host, call_614162.base,
                         call_614162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614162, url, valid)

proc call*(call_614163: Call_GetInstanceState_614150; body: JsonNode): Recallable =
  ## getInstanceState
  ## Returns the state of a specific instance. Works on one instance at a time.
  ##   body: JObject (required)
  var body_614164 = newJObject()
  if body != nil:
    body_614164 = body
  result = call_614163.call(nil, nil, nil, nil, body_614164)

var getInstanceState* = Call_GetInstanceState_614150(name: "getInstanceState",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceState",
    validator: validate_GetInstanceState_614151, base: "/",
    url: url_GetInstanceState_614152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstances_614165 = ref object of OpenApiRestCall_612658
proc url_GetInstances_614167(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstances_614166(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
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
  var valid_614168 = header.getOrDefault("X-Amz-Target")
  valid_614168 = validateParameter(valid_614168, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstances"))
  if valid_614168 != nil:
    section.add "X-Amz-Target", valid_614168
  var valid_614169 = header.getOrDefault("X-Amz-Signature")
  valid_614169 = validateParameter(valid_614169, JString, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "X-Amz-Signature", valid_614169
  var valid_614170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614170 = validateParameter(valid_614170, JString, required = false,
                                 default = nil)
  if valid_614170 != nil:
    section.add "X-Amz-Content-Sha256", valid_614170
  var valid_614171 = header.getOrDefault("X-Amz-Date")
  valid_614171 = validateParameter(valid_614171, JString, required = false,
                                 default = nil)
  if valid_614171 != nil:
    section.add "X-Amz-Date", valid_614171
  var valid_614172 = header.getOrDefault("X-Amz-Credential")
  valid_614172 = validateParameter(valid_614172, JString, required = false,
                                 default = nil)
  if valid_614172 != nil:
    section.add "X-Amz-Credential", valid_614172
  var valid_614173 = header.getOrDefault("X-Amz-Security-Token")
  valid_614173 = validateParameter(valid_614173, JString, required = false,
                                 default = nil)
  if valid_614173 != nil:
    section.add "X-Amz-Security-Token", valid_614173
  var valid_614174 = header.getOrDefault("X-Amz-Algorithm")
  valid_614174 = validateParameter(valid_614174, JString, required = false,
                                 default = nil)
  if valid_614174 != nil:
    section.add "X-Amz-Algorithm", valid_614174
  var valid_614175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614175 = validateParameter(valid_614175, JString, required = false,
                                 default = nil)
  if valid_614175 != nil:
    section.add "X-Amz-SignedHeaders", valid_614175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614177: Call_GetInstances_614165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
  ## 
  let valid = call_614177.validator(path, query, header, formData, body)
  let scheme = call_614177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614177.url(scheme.get, call_614177.host, call_614177.base,
                         call_614177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614177, url, valid)

proc call*(call_614178: Call_GetInstances_614165; body: JsonNode): Recallable =
  ## getInstances
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
  ##   body: JObject (required)
  var body_614179 = newJObject()
  if body != nil:
    body_614179 = body
  result = call_614178.call(nil, nil, nil, nil, body_614179)

var getInstances* = Call_GetInstances_614165(name: "getInstances",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstances",
    validator: validate_GetInstances_614166, base: "/", url: url_GetInstances_614167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPair_614180 = ref object of OpenApiRestCall_612658
proc url_GetKeyPair_614182(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetKeyPair_614181(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specific key pair.
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
  var valid_614183 = header.getOrDefault("X-Amz-Target")
  valid_614183 = validateParameter(valid_614183, JString, required = true, default = newJString(
      "Lightsail_20161128.GetKeyPair"))
  if valid_614183 != nil:
    section.add "X-Amz-Target", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-Signature")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-Signature", valid_614184
  var valid_614185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614185 = validateParameter(valid_614185, JString, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "X-Amz-Content-Sha256", valid_614185
  var valid_614186 = header.getOrDefault("X-Amz-Date")
  valid_614186 = validateParameter(valid_614186, JString, required = false,
                                 default = nil)
  if valid_614186 != nil:
    section.add "X-Amz-Date", valid_614186
  var valid_614187 = header.getOrDefault("X-Amz-Credential")
  valid_614187 = validateParameter(valid_614187, JString, required = false,
                                 default = nil)
  if valid_614187 != nil:
    section.add "X-Amz-Credential", valid_614187
  var valid_614188 = header.getOrDefault("X-Amz-Security-Token")
  valid_614188 = validateParameter(valid_614188, JString, required = false,
                                 default = nil)
  if valid_614188 != nil:
    section.add "X-Amz-Security-Token", valid_614188
  var valid_614189 = header.getOrDefault("X-Amz-Algorithm")
  valid_614189 = validateParameter(valid_614189, JString, required = false,
                                 default = nil)
  if valid_614189 != nil:
    section.add "X-Amz-Algorithm", valid_614189
  var valid_614190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614190 = validateParameter(valid_614190, JString, required = false,
                                 default = nil)
  if valid_614190 != nil:
    section.add "X-Amz-SignedHeaders", valid_614190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614192: Call_GetKeyPair_614180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific key pair.
  ## 
  let valid = call_614192.validator(path, query, header, formData, body)
  let scheme = call_614192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614192.url(scheme.get, call_614192.host, call_614192.base,
                         call_614192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614192, url, valid)

proc call*(call_614193: Call_GetKeyPair_614180; body: JsonNode): Recallable =
  ## getKeyPair
  ## Returns information about a specific key pair.
  ##   body: JObject (required)
  var body_614194 = newJObject()
  if body != nil:
    body_614194 = body
  result = call_614193.call(nil, nil, nil, nil, body_614194)

var getKeyPair* = Call_GetKeyPair_614180(name: "getKeyPair",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetKeyPair",
                                      validator: validate_GetKeyPair_614181,
                                      base: "/", url: url_GetKeyPair_614182,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPairs_614195 = ref object of OpenApiRestCall_612658
proc url_GetKeyPairs_614197(protocol: Scheme; host: string; base: string;
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

proc validate_GetKeyPairs_614196(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about all key pairs in the user's account.
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
  var valid_614198 = header.getOrDefault("X-Amz-Target")
  valid_614198 = validateParameter(valid_614198, JString, required = true, default = newJString(
      "Lightsail_20161128.GetKeyPairs"))
  if valid_614198 != nil:
    section.add "X-Amz-Target", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-Signature")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Signature", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-Content-Sha256", valid_614200
  var valid_614201 = header.getOrDefault("X-Amz-Date")
  valid_614201 = validateParameter(valid_614201, JString, required = false,
                                 default = nil)
  if valid_614201 != nil:
    section.add "X-Amz-Date", valid_614201
  var valid_614202 = header.getOrDefault("X-Amz-Credential")
  valid_614202 = validateParameter(valid_614202, JString, required = false,
                                 default = nil)
  if valid_614202 != nil:
    section.add "X-Amz-Credential", valid_614202
  var valid_614203 = header.getOrDefault("X-Amz-Security-Token")
  valid_614203 = validateParameter(valid_614203, JString, required = false,
                                 default = nil)
  if valid_614203 != nil:
    section.add "X-Amz-Security-Token", valid_614203
  var valid_614204 = header.getOrDefault("X-Amz-Algorithm")
  valid_614204 = validateParameter(valid_614204, JString, required = false,
                                 default = nil)
  if valid_614204 != nil:
    section.add "X-Amz-Algorithm", valid_614204
  var valid_614205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614205 = validateParameter(valid_614205, JString, required = false,
                                 default = nil)
  if valid_614205 != nil:
    section.add "X-Amz-SignedHeaders", valid_614205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614207: Call_GetKeyPairs_614195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all key pairs in the user's account.
  ## 
  let valid = call_614207.validator(path, query, header, formData, body)
  let scheme = call_614207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614207.url(scheme.get, call_614207.host, call_614207.base,
                         call_614207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614207, url, valid)

proc call*(call_614208: Call_GetKeyPairs_614195; body: JsonNode): Recallable =
  ## getKeyPairs
  ## Returns information about all key pairs in the user's account.
  ##   body: JObject (required)
  var body_614209 = newJObject()
  if body != nil:
    body_614209 = body
  result = call_614208.call(nil, nil, nil, nil, body_614209)

var getKeyPairs* = Call_GetKeyPairs_614195(name: "getKeyPairs",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetKeyPairs",
                                        validator: validate_GetKeyPairs_614196,
                                        base: "/", url: url_GetKeyPairs_614197,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancer_614210 = ref object of OpenApiRestCall_612658
proc url_GetLoadBalancer_614212(protocol: Scheme; host: string; base: string;
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

proc validate_GetLoadBalancer_614211(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about the specified Lightsail load balancer.
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
  var valid_614213 = header.getOrDefault("X-Amz-Target")
  valid_614213 = validateParameter(valid_614213, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancer"))
  if valid_614213 != nil:
    section.add "X-Amz-Target", valid_614213
  var valid_614214 = header.getOrDefault("X-Amz-Signature")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "X-Amz-Signature", valid_614214
  var valid_614215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "X-Amz-Content-Sha256", valid_614215
  var valid_614216 = header.getOrDefault("X-Amz-Date")
  valid_614216 = validateParameter(valid_614216, JString, required = false,
                                 default = nil)
  if valid_614216 != nil:
    section.add "X-Amz-Date", valid_614216
  var valid_614217 = header.getOrDefault("X-Amz-Credential")
  valid_614217 = validateParameter(valid_614217, JString, required = false,
                                 default = nil)
  if valid_614217 != nil:
    section.add "X-Amz-Credential", valid_614217
  var valid_614218 = header.getOrDefault("X-Amz-Security-Token")
  valid_614218 = validateParameter(valid_614218, JString, required = false,
                                 default = nil)
  if valid_614218 != nil:
    section.add "X-Amz-Security-Token", valid_614218
  var valid_614219 = header.getOrDefault("X-Amz-Algorithm")
  valid_614219 = validateParameter(valid_614219, JString, required = false,
                                 default = nil)
  if valid_614219 != nil:
    section.add "X-Amz-Algorithm", valid_614219
  var valid_614220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614220 = validateParameter(valid_614220, JString, required = false,
                                 default = nil)
  if valid_614220 != nil:
    section.add "X-Amz-SignedHeaders", valid_614220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614222: Call_GetLoadBalancer_614210; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified Lightsail load balancer.
  ## 
  let valid = call_614222.validator(path, query, header, formData, body)
  let scheme = call_614222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614222.url(scheme.get, call_614222.host, call_614222.base,
                         call_614222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614222, url, valid)

proc call*(call_614223: Call_GetLoadBalancer_614210; body: JsonNode): Recallable =
  ## getLoadBalancer
  ## Returns information about the specified Lightsail load balancer.
  ##   body: JObject (required)
  var body_614224 = newJObject()
  if body != nil:
    body_614224 = body
  result = call_614223.call(nil, nil, nil, nil, body_614224)

var getLoadBalancer* = Call_GetLoadBalancer_614210(name: "getLoadBalancer",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancer",
    validator: validate_GetLoadBalancer_614211, base: "/", url: url_GetLoadBalancer_614212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancerMetricData_614225 = ref object of OpenApiRestCall_612658
proc url_GetLoadBalancerMetricData_614227(protocol: Scheme; host: string;
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

proc validate_GetLoadBalancerMetricData_614226(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about health metrics for your Lightsail load balancer.
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
  var valid_614228 = header.getOrDefault("X-Amz-Target")
  valid_614228 = validateParameter(valid_614228, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancerMetricData"))
  if valid_614228 != nil:
    section.add "X-Amz-Target", valid_614228
  var valid_614229 = header.getOrDefault("X-Amz-Signature")
  valid_614229 = validateParameter(valid_614229, JString, required = false,
                                 default = nil)
  if valid_614229 != nil:
    section.add "X-Amz-Signature", valid_614229
  var valid_614230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614230 = validateParameter(valid_614230, JString, required = false,
                                 default = nil)
  if valid_614230 != nil:
    section.add "X-Amz-Content-Sha256", valid_614230
  var valid_614231 = header.getOrDefault("X-Amz-Date")
  valid_614231 = validateParameter(valid_614231, JString, required = false,
                                 default = nil)
  if valid_614231 != nil:
    section.add "X-Amz-Date", valid_614231
  var valid_614232 = header.getOrDefault("X-Amz-Credential")
  valid_614232 = validateParameter(valid_614232, JString, required = false,
                                 default = nil)
  if valid_614232 != nil:
    section.add "X-Amz-Credential", valid_614232
  var valid_614233 = header.getOrDefault("X-Amz-Security-Token")
  valid_614233 = validateParameter(valid_614233, JString, required = false,
                                 default = nil)
  if valid_614233 != nil:
    section.add "X-Amz-Security-Token", valid_614233
  var valid_614234 = header.getOrDefault("X-Amz-Algorithm")
  valid_614234 = validateParameter(valid_614234, JString, required = false,
                                 default = nil)
  if valid_614234 != nil:
    section.add "X-Amz-Algorithm", valid_614234
  var valid_614235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614235 = validateParameter(valid_614235, JString, required = false,
                                 default = nil)
  if valid_614235 != nil:
    section.add "X-Amz-SignedHeaders", valid_614235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614237: Call_GetLoadBalancerMetricData_614225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about health metrics for your Lightsail load balancer.
  ## 
  let valid = call_614237.validator(path, query, header, formData, body)
  let scheme = call_614237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614237.url(scheme.get, call_614237.host, call_614237.base,
                         call_614237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614237, url, valid)

proc call*(call_614238: Call_GetLoadBalancerMetricData_614225; body: JsonNode): Recallable =
  ## getLoadBalancerMetricData
  ## Returns information about health metrics for your Lightsail load balancer.
  ##   body: JObject (required)
  var body_614239 = newJObject()
  if body != nil:
    body_614239 = body
  result = call_614238.call(nil, nil, nil, nil, body_614239)

var getLoadBalancerMetricData* = Call_GetLoadBalancerMetricData_614225(
    name: "getLoadBalancerMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancerMetricData",
    validator: validate_GetLoadBalancerMetricData_614226, base: "/",
    url: url_GetLoadBalancerMetricData_614227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancerTlsCertificates_614240 = ref object of OpenApiRestCall_612658
proc url_GetLoadBalancerTlsCertificates_614242(protocol: Scheme; host: string;
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

proc validate_GetLoadBalancerTlsCertificates_614241(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about the TLS certificates that are associated with the specified Lightsail load balancer.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.</p>
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
  var valid_614243 = header.getOrDefault("X-Amz-Target")
  valid_614243 = validateParameter(valid_614243, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancerTlsCertificates"))
  if valid_614243 != nil:
    section.add "X-Amz-Target", valid_614243
  var valid_614244 = header.getOrDefault("X-Amz-Signature")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "X-Amz-Signature", valid_614244
  var valid_614245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "X-Amz-Content-Sha256", valid_614245
  var valid_614246 = header.getOrDefault("X-Amz-Date")
  valid_614246 = validateParameter(valid_614246, JString, required = false,
                                 default = nil)
  if valid_614246 != nil:
    section.add "X-Amz-Date", valid_614246
  var valid_614247 = header.getOrDefault("X-Amz-Credential")
  valid_614247 = validateParameter(valid_614247, JString, required = false,
                                 default = nil)
  if valid_614247 != nil:
    section.add "X-Amz-Credential", valid_614247
  var valid_614248 = header.getOrDefault("X-Amz-Security-Token")
  valid_614248 = validateParameter(valid_614248, JString, required = false,
                                 default = nil)
  if valid_614248 != nil:
    section.add "X-Amz-Security-Token", valid_614248
  var valid_614249 = header.getOrDefault("X-Amz-Algorithm")
  valid_614249 = validateParameter(valid_614249, JString, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "X-Amz-Algorithm", valid_614249
  var valid_614250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614250 = validateParameter(valid_614250, JString, required = false,
                                 default = nil)
  if valid_614250 != nil:
    section.add "X-Amz-SignedHeaders", valid_614250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614252: Call_GetLoadBalancerTlsCertificates_614240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the TLS certificates that are associated with the specified Lightsail load balancer.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.</p>
  ## 
  let valid = call_614252.validator(path, query, header, formData, body)
  let scheme = call_614252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614252.url(scheme.get, call_614252.host, call_614252.base,
                         call_614252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614252, url, valid)

proc call*(call_614253: Call_GetLoadBalancerTlsCertificates_614240; body: JsonNode): Recallable =
  ## getLoadBalancerTlsCertificates
  ## <p>Returns information about the TLS certificates that are associated with the specified Lightsail load balancer.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.</p>
  ##   body: JObject (required)
  var body_614254 = newJObject()
  if body != nil:
    body_614254 = body
  result = call_614253.call(nil, nil, nil, nil, body_614254)

var getLoadBalancerTlsCertificates* = Call_GetLoadBalancerTlsCertificates_614240(
    name: "getLoadBalancerTlsCertificates", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancerTlsCertificates",
    validator: validate_GetLoadBalancerTlsCertificates_614241, base: "/",
    url: url_GetLoadBalancerTlsCertificates_614242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancers_614255 = ref object of OpenApiRestCall_612658
proc url_GetLoadBalancers_614257(protocol: Scheme; host: string; base: string;
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

proc validate_GetLoadBalancers_614256(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns information about all load balancers in an account.</p> <p>If you are describing a long list of load balancers, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
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
  var valid_614258 = header.getOrDefault("X-Amz-Target")
  valid_614258 = validateParameter(valid_614258, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancers"))
  if valid_614258 != nil:
    section.add "X-Amz-Target", valid_614258
  var valid_614259 = header.getOrDefault("X-Amz-Signature")
  valid_614259 = validateParameter(valid_614259, JString, required = false,
                                 default = nil)
  if valid_614259 != nil:
    section.add "X-Amz-Signature", valid_614259
  var valid_614260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614260 = validateParameter(valid_614260, JString, required = false,
                                 default = nil)
  if valid_614260 != nil:
    section.add "X-Amz-Content-Sha256", valid_614260
  var valid_614261 = header.getOrDefault("X-Amz-Date")
  valid_614261 = validateParameter(valid_614261, JString, required = false,
                                 default = nil)
  if valid_614261 != nil:
    section.add "X-Amz-Date", valid_614261
  var valid_614262 = header.getOrDefault("X-Amz-Credential")
  valid_614262 = validateParameter(valid_614262, JString, required = false,
                                 default = nil)
  if valid_614262 != nil:
    section.add "X-Amz-Credential", valid_614262
  var valid_614263 = header.getOrDefault("X-Amz-Security-Token")
  valid_614263 = validateParameter(valid_614263, JString, required = false,
                                 default = nil)
  if valid_614263 != nil:
    section.add "X-Amz-Security-Token", valid_614263
  var valid_614264 = header.getOrDefault("X-Amz-Algorithm")
  valid_614264 = validateParameter(valid_614264, JString, required = false,
                                 default = nil)
  if valid_614264 != nil:
    section.add "X-Amz-Algorithm", valid_614264
  var valid_614265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614265 = validateParameter(valid_614265, JString, required = false,
                                 default = nil)
  if valid_614265 != nil:
    section.add "X-Amz-SignedHeaders", valid_614265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614267: Call_GetLoadBalancers_614255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all load balancers in an account.</p> <p>If you are describing a long list of load balancers, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ## 
  let valid = call_614267.validator(path, query, header, formData, body)
  let scheme = call_614267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614267.url(scheme.get, call_614267.host, call_614267.base,
                         call_614267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614267, url, valid)

proc call*(call_614268: Call_GetLoadBalancers_614255; body: JsonNode): Recallable =
  ## getLoadBalancers
  ## <p>Returns information about all load balancers in an account.</p> <p>If you are describing a long list of load balancers, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ##   body: JObject (required)
  var body_614269 = newJObject()
  if body != nil:
    body_614269 = body
  result = call_614268.call(nil, nil, nil, nil, body_614269)

var getLoadBalancers* = Call_GetLoadBalancers_614255(name: "getLoadBalancers",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancers",
    validator: validate_GetLoadBalancers_614256, base: "/",
    url: url_GetLoadBalancers_614257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperation_614270 = ref object of OpenApiRestCall_612658
proc url_GetOperation_614272(protocol: Scheme; host: string; base: string;
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

proc validate_GetOperation_614271(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
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
  var valid_614273 = header.getOrDefault("X-Amz-Target")
  valid_614273 = validateParameter(valid_614273, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperation"))
  if valid_614273 != nil:
    section.add "X-Amz-Target", valid_614273
  var valid_614274 = header.getOrDefault("X-Amz-Signature")
  valid_614274 = validateParameter(valid_614274, JString, required = false,
                                 default = nil)
  if valid_614274 != nil:
    section.add "X-Amz-Signature", valid_614274
  var valid_614275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "X-Amz-Content-Sha256", valid_614275
  var valid_614276 = header.getOrDefault("X-Amz-Date")
  valid_614276 = validateParameter(valid_614276, JString, required = false,
                                 default = nil)
  if valid_614276 != nil:
    section.add "X-Amz-Date", valid_614276
  var valid_614277 = header.getOrDefault("X-Amz-Credential")
  valid_614277 = validateParameter(valid_614277, JString, required = false,
                                 default = nil)
  if valid_614277 != nil:
    section.add "X-Amz-Credential", valid_614277
  var valid_614278 = header.getOrDefault("X-Amz-Security-Token")
  valid_614278 = validateParameter(valid_614278, JString, required = false,
                                 default = nil)
  if valid_614278 != nil:
    section.add "X-Amz-Security-Token", valid_614278
  var valid_614279 = header.getOrDefault("X-Amz-Algorithm")
  valid_614279 = validateParameter(valid_614279, JString, required = false,
                                 default = nil)
  if valid_614279 != nil:
    section.add "X-Amz-Algorithm", valid_614279
  var valid_614280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614280 = validateParameter(valid_614280, JString, required = false,
                                 default = nil)
  if valid_614280 != nil:
    section.add "X-Amz-SignedHeaders", valid_614280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614282: Call_GetOperation_614270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
  ## 
  let valid = call_614282.validator(path, query, header, formData, body)
  let scheme = call_614282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614282.url(scheme.get, call_614282.host, call_614282.base,
                         call_614282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614282, url, valid)

proc call*(call_614283: Call_GetOperation_614270; body: JsonNode): Recallable =
  ## getOperation
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
  ##   body: JObject (required)
  var body_614284 = newJObject()
  if body != nil:
    body_614284 = body
  result = call_614283.call(nil, nil, nil, nil, body_614284)

var getOperation* = Call_GetOperation_614270(name: "getOperation",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperation",
    validator: validate_GetOperation_614271, base: "/", url: url_GetOperation_614272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperations_614285 = ref object of OpenApiRestCall_612658
proc url_GetOperations_614287(protocol: Scheme; host: string; base: string;
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

proc validate_GetOperations_614286(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
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
  var valid_614288 = header.getOrDefault("X-Amz-Target")
  valid_614288 = validateParameter(valid_614288, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperations"))
  if valid_614288 != nil:
    section.add "X-Amz-Target", valid_614288
  var valid_614289 = header.getOrDefault("X-Amz-Signature")
  valid_614289 = validateParameter(valid_614289, JString, required = false,
                                 default = nil)
  if valid_614289 != nil:
    section.add "X-Amz-Signature", valid_614289
  var valid_614290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614290 = validateParameter(valid_614290, JString, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "X-Amz-Content-Sha256", valid_614290
  var valid_614291 = header.getOrDefault("X-Amz-Date")
  valid_614291 = validateParameter(valid_614291, JString, required = false,
                                 default = nil)
  if valid_614291 != nil:
    section.add "X-Amz-Date", valid_614291
  var valid_614292 = header.getOrDefault("X-Amz-Credential")
  valid_614292 = validateParameter(valid_614292, JString, required = false,
                                 default = nil)
  if valid_614292 != nil:
    section.add "X-Amz-Credential", valid_614292
  var valid_614293 = header.getOrDefault("X-Amz-Security-Token")
  valid_614293 = validateParameter(valid_614293, JString, required = false,
                                 default = nil)
  if valid_614293 != nil:
    section.add "X-Amz-Security-Token", valid_614293
  var valid_614294 = header.getOrDefault("X-Amz-Algorithm")
  valid_614294 = validateParameter(valid_614294, JString, required = false,
                                 default = nil)
  if valid_614294 != nil:
    section.add "X-Amz-Algorithm", valid_614294
  var valid_614295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614295 = validateParameter(valid_614295, JString, required = false,
                                 default = nil)
  if valid_614295 != nil:
    section.add "X-Amz-SignedHeaders", valid_614295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614297: Call_GetOperations_614285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
  ## 
  let valid = call_614297.validator(path, query, header, formData, body)
  let scheme = call_614297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614297.url(scheme.get, call_614297.host, call_614297.base,
                         call_614297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614297, url, valid)

proc call*(call_614298: Call_GetOperations_614285; body: JsonNode): Recallable =
  ## getOperations
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
  ##   body: JObject (required)
  var body_614299 = newJObject()
  if body != nil:
    body_614299 = body
  result = call_614298.call(nil, nil, nil, nil, body_614299)

var getOperations* = Call_GetOperations_614285(name: "getOperations",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperations",
    validator: validate_GetOperations_614286, base: "/", url: url_GetOperations_614287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperationsForResource_614300 = ref object of OpenApiRestCall_612658
proc url_GetOperationsForResource_614302(protocol: Scheme; host: string;
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

proc validate_GetOperationsForResource_614301(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
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
  var valid_614303 = header.getOrDefault("X-Amz-Target")
  valid_614303 = validateParameter(valid_614303, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperationsForResource"))
  if valid_614303 != nil:
    section.add "X-Amz-Target", valid_614303
  var valid_614304 = header.getOrDefault("X-Amz-Signature")
  valid_614304 = validateParameter(valid_614304, JString, required = false,
                                 default = nil)
  if valid_614304 != nil:
    section.add "X-Amz-Signature", valid_614304
  var valid_614305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614305 = validateParameter(valid_614305, JString, required = false,
                                 default = nil)
  if valid_614305 != nil:
    section.add "X-Amz-Content-Sha256", valid_614305
  var valid_614306 = header.getOrDefault("X-Amz-Date")
  valid_614306 = validateParameter(valid_614306, JString, required = false,
                                 default = nil)
  if valid_614306 != nil:
    section.add "X-Amz-Date", valid_614306
  var valid_614307 = header.getOrDefault("X-Amz-Credential")
  valid_614307 = validateParameter(valid_614307, JString, required = false,
                                 default = nil)
  if valid_614307 != nil:
    section.add "X-Amz-Credential", valid_614307
  var valid_614308 = header.getOrDefault("X-Amz-Security-Token")
  valid_614308 = validateParameter(valid_614308, JString, required = false,
                                 default = nil)
  if valid_614308 != nil:
    section.add "X-Amz-Security-Token", valid_614308
  var valid_614309 = header.getOrDefault("X-Amz-Algorithm")
  valid_614309 = validateParameter(valid_614309, JString, required = false,
                                 default = nil)
  if valid_614309 != nil:
    section.add "X-Amz-Algorithm", valid_614309
  var valid_614310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614310 = validateParameter(valid_614310, JString, required = false,
                                 default = nil)
  if valid_614310 != nil:
    section.add "X-Amz-SignedHeaders", valid_614310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614312: Call_GetOperationsForResource_614300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
  ## 
  let valid = call_614312.validator(path, query, header, formData, body)
  let scheme = call_614312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614312.url(scheme.get, call_614312.host, call_614312.base,
                         call_614312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614312, url, valid)

proc call*(call_614313: Call_GetOperationsForResource_614300; body: JsonNode): Recallable =
  ## getOperationsForResource
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
  ##   body: JObject (required)
  var body_614314 = newJObject()
  if body != nil:
    body_614314 = body
  result = call_614313.call(nil, nil, nil, nil, body_614314)

var getOperationsForResource* = Call_GetOperationsForResource_614300(
    name: "getOperationsForResource", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperationsForResource",
    validator: validate_GetOperationsForResource_614301, base: "/",
    url: url_GetOperationsForResource_614302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegions_614315 = ref object of OpenApiRestCall_612658
proc url_GetRegions_614317(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRegions_614316(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all valid regions for Amazon Lightsail. Use the <code>include availability zones</code> parameter to also return the Availability Zones in a region.
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
  var valid_614318 = header.getOrDefault("X-Amz-Target")
  valid_614318 = validateParameter(valid_614318, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRegions"))
  if valid_614318 != nil:
    section.add "X-Amz-Target", valid_614318
  var valid_614319 = header.getOrDefault("X-Amz-Signature")
  valid_614319 = validateParameter(valid_614319, JString, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "X-Amz-Signature", valid_614319
  var valid_614320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-Content-Sha256", valid_614320
  var valid_614321 = header.getOrDefault("X-Amz-Date")
  valid_614321 = validateParameter(valid_614321, JString, required = false,
                                 default = nil)
  if valid_614321 != nil:
    section.add "X-Amz-Date", valid_614321
  var valid_614322 = header.getOrDefault("X-Amz-Credential")
  valid_614322 = validateParameter(valid_614322, JString, required = false,
                                 default = nil)
  if valid_614322 != nil:
    section.add "X-Amz-Credential", valid_614322
  var valid_614323 = header.getOrDefault("X-Amz-Security-Token")
  valid_614323 = validateParameter(valid_614323, JString, required = false,
                                 default = nil)
  if valid_614323 != nil:
    section.add "X-Amz-Security-Token", valid_614323
  var valid_614324 = header.getOrDefault("X-Amz-Algorithm")
  valid_614324 = validateParameter(valid_614324, JString, required = false,
                                 default = nil)
  if valid_614324 != nil:
    section.add "X-Amz-Algorithm", valid_614324
  var valid_614325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614325 = validateParameter(valid_614325, JString, required = false,
                                 default = nil)
  if valid_614325 != nil:
    section.add "X-Amz-SignedHeaders", valid_614325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614327: Call_GetRegions_614315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all valid regions for Amazon Lightsail. Use the <code>include availability zones</code> parameter to also return the Availability Zones in a region.
  ## 
  let valid = call_614327.validator(path, query, header, formData, body)
  let scheme = call_614327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614327.url(scheme.get, call_614327.host, call_614327.base,
                         call_614327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614327, url, valid)

proc call*(call_614328: Call_GetRegions_614315; body: JsonNode): Recallable =
  ## getRegions
  ## Returns a list of all valid regions for Amazon Lightsail. Use the <code>include availability zones</code> parameter to also return the Availability Zones in a region.
  ##   body: JObject (required)
  var body_614329 = newJObject()
  if body != nil:
    body_614329 = body
  result = call_614328.call(nil, nil, nil, nil, body_614329)

var getRegions* = Call_GetRegions_614315(name: "getRegions",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetRegions",
                                      validator: validate_GetRegions_614316,
                                      base: "/", url: url_GetRegions_614317,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabase_614330 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabase_614332(protocol: Scheme; host: string; base: string;
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

proc validate_GetRelationalDatabase_614331(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specific database in Amazon Lightsail.
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
  var valid_614333 = header.getOrDefault("X-Amz-Target")
  valid_614333 = validateParameter(valid_614333, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabase"))
  if valid_614333 != nil:
    section.add "X-Amz-Target", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-Signature")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-Signature", valid_614334
  var valid_614335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-Content-Sha256", valid_614335
  var valid_614336 = header.getOrDefault("X-Amz-Date")
  valid_614336 = validateParameter(valid_614336, JString, required = false,
                                 default = nil)
  if valid_614336 != nil:
    section.add "X-Amz-Date", valid_614336
  var valid_614337 = header.getOrDefault("X-Amz-Credential")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "X-Amz-Credential", valid_614337
  var valid_614338 = header.getOrDefault("X-Amz-Security-Token")
  valid_614338 = validateParameter(valid_614338, JString, required = false,
                                 default = nil)
  if valid_614338 != nil:
    section.add "X-Amz-Security-Token", valid_614338
  var valid_614339 = header.getOrDefault("X-Amz-Algorithm")
  valid_614339 = validateParameter(valid_614339, JString, required = false,
                                 default = nil)
  if valid_614339 != nil:
    section.add "X-Amz-Algorithm", valid_614339
  var valid_614340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614340 = validateParameter(valid_614340, JString, required = false,
                                 default = nil)
  if valid_614340 != nil:
    section.add "X-Amz-SignedHeaders", valid_614340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614342: Call_GetRelationalDatabase_614330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific database in Amazon Lightsail.
  ## 
  let valid = call_614342.validator(path, query, header, formData, body)
  let scheme = call_614342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614342.url(scheme.get, call_614342.host, call_614342.base,
                         call_614342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614342, url, valid)

proc call*(call_614343: Call_GetRelationalDatabase_614330; body: JsonNode): Recallable =
  ## getRelationalDatabase
  ## Returns information about a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_614344 = newJObject()
  if body != nil:
    body_614344 = body
  result = call_614343.call(nil, nil, nil, nil, body_614344)

var getRelationalDatabase* = Call_GetRelationalDatabase_614330(
    name: "getRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabase",
    validator: validate_GetRelationalDatabase_614331, base: "/",
    url: url_GetRelationalDatabase_614332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseBlueprints_614345 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabaseBlueprints_614347(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseBlueprints_614346(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database.</p> <p>You can use a blueprint ID to create a new database that runs a specific database engine.</p>
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
  var valid_614348 = header.getOrDefault("X-Amz-Target")
  valid_614348 = validateParameter(valid_614348, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseBlueprints"))
  if valid_614348 != nil:
    section.add "X-Amz-Target", valid_614348
  var valid_614349 = header.getOrDefault("X-Amz-Signature")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Signature", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-Content-Sha256", valid_614350
  var valid_614351 = header.getOrDefault("X-Amz-Date")
  valid_614351 = validateParameter(valid_614351, JString, required = false,
                                 default = nil)
  if valid_614351 != nil:
    section.add "X-Amz-Date", valid_614351
  var valid_614352 = header.getOrDefault("X-Amz-Credential")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-Credential", valid_614352
  var valid_614353 = header.getOrDefault("X-Amz-Security-Token")
  valid_614353 = validateParameter(valid_614353, JString, required = false,
                                 default = nil)
  if valid_614353 != nil:
    section.add "X-Amz-Security-Token", valid_614353
  var valid_614354 = header.getOrDefault("X-Amz-Algorithm")
  valid_614354 = validateParameter(valid_614354, JString, required = false,
                                 default = nil)
  if valid_614354 != nil:
    section.add "X-Amz-Algorithm", valid_614354
  var valid_614355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614355 = validateParameter(valid_614355, JString, required = false,
                                 default = nil)
  if valid_614355 != nil:
    section.add "X-Amz-SignedHeaders", valid_614355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614357: Call_GetRelationalDatabaseBlueprints_614345;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database.</p> <p>You can use a blueprint ID to create a new database that runs a specific database engine.</p>
  ## 
  let valid = call_614357.validator(path, query, header, formData, body)
  let scheme = call_614357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614357.url(scheme.get, call_614357.host, call_614357.base,
                         call_614357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614357, url, valid)

proc call*(call_614358: Call_GetRelationalDatabaseBlueprints_614345; body: JsonNode): Recallable =
  ## getRelationalDatabaseBlueprints
  ## <p>Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database.</p> <p>You can use a blueprint ID to create a new database that runs a specific database engine.</p>
  ##   body: JObject (required)
  var body_614359 = newJObject()
  if body != nil:
    body_614359 = body
  result = call_614358.call(nil, nil, nil, nil, body_614359)

var getRelationalDatabaseBlueprints* = Call_GetRelationalDatabaseBlueprints_614345(
    name: "getRelationalDatabaseBlueprints", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseBlueprints",
    validator: validate_GetRelationalDatabaseBlueprints_614346, base: "/",
    url: url_GetRelationalDatabaseBlueprints_614347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseBundles_614360 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabaseBundles_614362(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseBundles_614361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database.</p> <p>You can use a bundle ID to create a new database with explicit performance specifications.</p>
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
  var valid_614363 = header.getOrDefault("X-Amz-Target")
  valid_614363 = validateParameter(valid_614363, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseBundles"))
  if valid_614363 != nil:
    section.add "X-Amz-Target", valid_614363
  var valid_614364 = header.getOrDefault("X-Amz-Signature")
  valid_614364 = validateParameter(valid_614364, JString, required = false,
                                 default = nil)
  if valid_614364 != nil:
    section.add "X-Amz-Signature", valid_614364
  var valid_614365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614365 = validateParameter(valid_614365, JString, required = false,
                                 default = nil)
  if valid_614365 != nil:
    section.add "X-Amz-Content-Sha256", valid_614365
  var valid_614366 = header.getOrDefault("X-Amz-Date")
  valid_614366 = validateParameter(valid_614366, JString, required = false,
                                 default = nil)
  if valid_614366 != nil:
    section.add "X-Amz-Date", valid_614366
  var valid_614367 = header.getOrDefault("X-Amz-Credential")
  valid_614367 = validateParameter(valid_614367, JString, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "X-Amz-Credential", valid_614367
  var valid_614368 = header.getOrDefault("X-Amz-Security-Token")
  valid_614368 = validateParameter(valid_614368, JString, required = false,
                                 default = nil)
  if valid_614368 != nil:
    section.add "X-Amz-Security-Token", valid_614368
  var valid_614369 = header.getOrDefault("X-Amz-Algorithm")
  valid_614369 = validateParameter(valid_614369, JString, required = false,
                                 default = nil)
  if valid_614369 != nil:
    section.add "X-Amz-Algorithm", valid_614369
  var valid_614370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "X-Amz-SignedHeaders", valid_614370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614372: Call_GetRelationalDatabaseBundles_614360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database.</p> <p>You can use a bundle ID to create a new database with explicit performance specifications.</p>
  ## 
  let valid = call_614372.validator(path, query, header, formData, body)
  let scheme = call_614372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614372.url(scheme.get, call_614372.host, call_614372.base,
                         call_614372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614372, url, valid)

proc call*(call_614373: Call_GetRelationalDatabaseBundles_614360; body: JsonNode): Recallable =
  ## getRelationalDatabaseBundles
  ## <p>Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database.</p> <p>You can use a bundle ID to create a new database with explicit performance specifications.</p>
  ##   body: JObject (required)
  var body_614374 = newJObject()
  if body != nil:
    body_614374 = body
  result = call_614373.call(nil, nil, nil, nil, body_614374)

var getRelationalDatabaseBundles* = Call_GetRelationalDatabaseBundles_614360(
    name: "getRelationalDatabaseBundles", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseBundles",
    validator: validate_GetRelationalDatabaseBundles_614361, base: "/",
    url: url_GetRelationalDatabaseBundles_614362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseEvents_614375 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabaseEvents_614377(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseEvents_614376(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of events for a specific database in Amazon Lightsail.
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
  var valid_614378 = header.getOrDefault("X-Amz-Target")
  valid_614378 = validateParameter(valid_614378, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseEvents"))
  if valid_614378 != nil:
    section.add "X-Amz-Target", valid_614378
  var valid_614379 = header.getOrDefault("X-Amz-Signature")
  valid_614379 = validateParameter(valid_614379, JString, required = false,
                                 default = nil)
  if valid_614379 != nil:
    section.add "X-Amz-Signature", valid_614379
  var valid_614380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614380 = validateParameter(valid_614380, JString, required = false,
                                 default = nil)
  if valid_614380 != nil:
    section.add "X-Amz-Content-Sha256", valid_614380
  var valid_614381 = header.getOrDefault("X-Amz-Date")
  valid_614381 = validateParameter(valid_614381, JString, required = false,
                                 default = nil)
  if valid_614381 != nil:
    section.add "X-Amz-Date", valid_614381
  var valid_614382 = header.getOrDefault("X-Amz-Credential")
  valid_614382 = validateParameter(valid_614382, JString, required = false,
                                 default = nil)
  if valid_614382 != nil:
    section.add "X-Amz-Credential", valid_614382
  var valid_614383 = header.getOrDefault("X-Amz-Security-Token")
  valid_614383 = validateParameter(valid_614383, JString, required = false,
                                 default = nil)
  if valid_614383 != nil:
    section.add "X-Amz-Security-Token", valid_614383
  var valid_614384 = header.getOrDefault("X-Amz-Algorithm")
  valid_614384 = validateParameter(valid_614384, JString, required = false,
                                 default = nil)
  if valid_614384 != nil:
    section.add "X-Amz-Algorithm", valid_614384
  var valid_614385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614385 = validateParameter(valid_614385, JString, required = false,
                                 default = nil)
  if valid_614385 != nil:
    section.add "X-Amz-SignedHeaders", valid_614385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614387: Call_GetRelationalDatabaseEvents_614375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of events for a specific database in Amazon Lightsail.
  ## 
  let valid = call_614387.validator(path, query, header, formData, body)
  let scheme = call_614387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614387.url(scheme.get, call_614387.host, call_614387.base,
                         call_614387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614387, url, valid)

proc call*(call_614388: Call_GetRelationalDatabaseEvents_614375; body: JsonNode): Recallable =
  ## getRelationalDatabaseEvents
  ## Returns a list of events for a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_614389 = newJObject()
  if body != nil:
    body_614389 = body
  result = call_614388.call(nil, nil, nil, nil, body_614389)

var getRelationalDatabaseEvents* = Call_GetRelationalDatabaseEvents_614375(
    name: "getRelationalDatabaseEvents", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseEvents",
    validator: validate_GetRelationalDatabaseEvents_614376, base: "/",
    url: url_GetRelationalDatabaseEvents_614377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseLogEvents_614390 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabaseLogEvents_614392(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseLogEvents_614391(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of log events for a database in Amazon Lightsail.
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
  var valid_614393 = header.getOrDefault("X-Amz-Target")
  valid_614393 = validateParameter(valid_614393, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseLogEvents"))
  if valid_614393 != nil:
    section.add "X-Amz-Target", valid_614393
  var valid_614394 = header.getOrDefault("X-Amz-Signature")
  valid_614394 = validateParameter(valid_614394, JString, required = false,
                                 default = nil)
  if valid_614394 != nil:
    section.add "X-Amz-Signature", valid_614394
  var valid_614395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614395 = validateParameter(valid_614395, JString, required = false,
                                 default = nil)
  if valid_614395 != nil:
    section.add "X-Amz-Content-Sha256", valid_614395
  var valid_614396 = header.getOrDefault("X-Amz-Date")
  valid_614396 = validateParameter(valid_614396, JString, required = false,
                                 default = nil)
  if valid_614396 != nil:
    section.add "X-Amz-Date", valid_614396
  var valid_614397 = header.getOrDefault("X-Amz-Credential")
  valid_614397 = validateParameter(valid_614397, JString, required = false,
                                 default = nil)
  if valid_614397 != nil:
    section.add "X-Amz-Credential", valid_614397
  var valid_614398 = header.getOrDefault("X-Amz-Security-Token")
  valid_614398 = validateParameter(valid_614398, JString, required = false,
                                 default = nil)
  if valid_614398 != nil:
    section.add "X-Amz-Security-Token", valid_614398
  var valid_614399 = header.getOrDefault("X-Amz-Algorithm")
  valid_614399 = validateParameter(valid_614399, JString, required = false,
                                 default = nil)
  if valid_614399 != nil:
    section.add "X-Amz-Algorithm", valid_614399
  var valid_614400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614400 = validateParameter(valid_614400, JString, required = false,
                                 default = nil)
  if valid_614400 != nil:
    section.add "X-Amz-SignedHeaders", valid_614400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614402: Call_GetRelationalDatabaseLogEvents_614390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of log events for a database in Amazon Lightsail.
  ## 
  let valid = call_614402.validator(path, query, header, formData, body)
  let scheme = call_614402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614402.url(scheme.get, call_614402.host, call_614402.base,
                         call_614402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614402, url, valid)

proc call*(call_614403: Call_GetRelationalDatabaseLogEvents_614390; body: JsonNode): Recallable =
  ## getRelationalDatabaseLogEvents
  ## Returns a list of log events for a database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_614404 = newJObject()
  if body != nil:
    body_614404 = body
  result = call_614403.call(nil, nil, nil, nil, body_614404)

var getRelationalDatabaseLogEvents* = Call_GetRelationalDatabaseLogEvents_614390(
    name: "getRelationalDatabaseLogEvents", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseLogEvents",
    validator: validate_GetRelationalDatabaseLogEvents_614391, base: "/",
    url: url_GetRelationalDatabaseLogEvents_614392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseLogStreams_614405 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabaseLogStreams_614407(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseLogStreams_614406(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of available log streams for a specific database in Amazon Lightsail.
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
  var valid_614408 = header.getOrDefault("X-Amz-Target")
  valid_614408 = validateParameter(valid_614408, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseLogStreams"))
  if valid_614408 != nil:
    section.add "X-Amz-Target", valid_614408
  var valid_614409 = header.getOrDefault("X-Amz-Signature")
  valid_614409 = validateParameter(valid_614409, JString, required = false,
                                 default = nil)
  if valid_614409 != nil:
    section.add "X-Amz-Signature", valid_614409
  var valid_614410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614410 = validateParameter(valid_614410, JString, required = false,
                                 default = nil)
  if valid_614410 != nil:
    section.add "X-Amz-Content-Sha256", valid_614410
  var valid_614411 = header.getOrDefault("X-Amz-Date")
  valid_614411 = validateParameter(valid_614411, JString, required = false,
                                 default = nil)
  if valid_614411 != nil:
    section.add "X-Amz-Date", valid_614411
  var valid_614412 = header.getOrDefault("X-Amz-Credential")
  valid_614412 = validateParameter(valid_614412, JString, required = false,
                                 default = nil)
  if valid_614412 != nil:
    section.add "X-Amz-Credential", valid_614412
  var valid_614413 = header.getOrDefault("X-Amz-Security-Token")
  valid_614413 = validateParameter(valid_614413, JString, required = false,
                                 default = nil)
  if valid_614413 != nil:
    section.add "X-Amz-Security-Token", valid_614413
  var valid_614414 = header.getOrDefault("X-Amz-Algorithm")
  valid_614414 = validateParameter(valid_614414, JString, required = false,
                                 default = nil)
  if valid_614414 != nil:
    section.add "X-Amz-Algorithm", valid_614414
  var valid_614415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614415 = validateParameter(valid_614415, JString, required = false,
                                 default = nil)
  if valid_614415 != nil:
    section.add "X-Amz-SignedHeaders", valid_614415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614417: Call_GetRelationalDatabaseLogStreams_614405;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of available log streams for a specific database in Amazon Lightsail.
  ## 
  let valid = call_614417.validator(path, query, header, formData, body)
  let scheme = call_614417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614417.url(scheme.get, call_614417.host, call_614417.base,
                         call_614417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614417, url, valid)

proc call*(call_614418: Call_GetRelationalDatabaseLogStreams_614405; body: JsonNode): Recallable =
  ## getRelationalDatabaseLogStreams
  ## Returns a list of available log streams for a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_614419 = newJObject()
  if body != nil:
    body_614419 = body
  result = call_614418.call(nil, nil, nil, nil, body_614419)

var getRelationalDatabaseLogStreams* = Call_GetRelationalDatabaseLogStreams_614405(
    name: "getRelationalDatabaseLogStreams", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseLogStreams",
    validator: validate_GetRelationalDatabaseLogStreams_614406, base: "/",
    url: url_GetRelationalDatabaseLogStreams_614407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseMasterUserPassword_614420 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabaseMasterUserPassword_614422(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseMasterUserPassword_614421(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the current, previous, or pending versions of the master user password for a Lightsail database.</p> <p>The <code>GetRelationalDatabaseMasterUserPassword</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.</p>
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
  var valid_614423 = header.getOrDefault("X-Amz-Target")
  valid_614423 = validateParameter(valid_614423, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseMasterUserPassword"))
  if valid_614423 != nil:
    section.add "X-Amz-Target", valid_614423
  var valid_614424 = header.getOrDefault("X-Amz-Signature")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "X-Amz-Signature", valid_614424
  var valid_614425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614425 = validateParameter(valid_614425, JString, required = false,
                                 default = nil)
  if valid_614425 != nil:
    section.add "X-Amz-Content-Sha256", valid_614425
  var valid_614426 = header.getOrDefault("X-Amz-Date")
  valid_614426 = validateParameter(valid_614426, JString, required = false,
                                 default = nil)
  if valid_614426 != nil:
    section.add "X-Amz-Date", valid_614426
  var valid_614427 = header.getOrDefault("X-Amz-Credential")
  valid_614427 = validateParameter(valid_614427, JString, required = false,
                                 default = nil)
  if valid_614427 != nil:
    section.add "X-Amz-Credential", valid_614427
  var valid_614428 = header.getOrDefault("X-Amz-Security-Token")
  valid_614428 = validateParameter(valid_614428, JString, required = false,
                                 default = nil)
  if valid_614428 != nil:
    section.add "X-Amz-Security-Token", valid_614428
  var valid_614429 = header.getOrDefault("X-Amz-Algorithm")
  valid_614429 = validateParameter(valid_614429, JString, required = false,
                                 default = nil)
  if valid_614429 != nil:
    section.add "X-Amz-Algorithm", valid_614429
  var valid_614430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614430 = validateParameter(valid_614430, JString, required = false,
                                 default = nil)
  if valid_614430 != nil:
    section.add "X-Amz-SignedHeaders", valid_614430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614432: Call_GetRelationalDatabaseMasterUserPassword_614420;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the current, previous, or pending versions of the master user password for a Lightsail database.</p> <p>The <code>GetRelationalDatabaseMasterUserPassword</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.</p>
  ## 
  let valid = call_614432.validator(path, query, header, formData, body)
  let scheme = call_614432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614432.url(scheme.get, call_614432.host, call_614432.base,
                         call_614432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614432, url, valid)

proc call*(call_614433: Call_GetRelationalDatabaseMasterUserPassword_614420;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseMasterUserPassword
  ## <p>Returns the current, previous, or pending versions of the master user password for a Lightsail database.</p> <p>The <code>GetRelationalDatabaseMasterUserPassword</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.</p>
  ##   body: JObject (required)
  var body_614434 = newJObject()
  if body != nil:
    body_614434 = body
  result = call_614433.call(nil, nil, nil, nil, body_614434)

var getRelationalDatabaseMasterUserPassword* = Call_GetRelationalDatabaseMasterUserPassword_614420(
    name: "getRelationalDatabaseMasterUserPassword", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseMasterUserPassword",
    validator: validate_GetRelationalDatabaseMasterUserPassword_614421, base: "/",
    url: url_GetRelationalDatabaseMasterUserPassword_614422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseMetricData_614435 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabaseMetricData_614437(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseMetricData_614436(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the data points of the specified metric for a database in Amazon Lightsail.
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
  var valid_614438 = header.getOrDefault("X-Amz-Target")
  valid_614438 = validateParameter(valid_614438, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseMetricData"))
  if valid_614438 != nil:
    section.add "X-Amz-Target", valid_614438
  var valid_614439 = header.getOrDefault("X-Amz-Signature")
  valid_614439 = validateParameter(valid_614439, JString, required = false,
                                 default = nil)
  if valid_614439 != nil:
    section.add "X-Amz-Signature", valid_614439
  var valid_614440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "X-Amz-Content-Sha256", valid_614440
  var valid_614441 = header.getOrDefault("X-Amz-Date")
  valid_614441 = validateParameter(valid_614441, JString, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "X-Amz-Date", valid_614441
  var valid_614442 = header.getOrDefault("X-Amz-Credential")
  valid_614442 = validateParameter(valid_614442, JString, required = false,
                                 default = nil)
  if valid_614442 != nil:
    section.add "X-Amz-Credential", valid_614442
  var valid_614443 = header.getOrDefault("X-Amz-Security-Token")
  valid_614443 = validateParameter(valid_614443, JString, required = false,
                                 default = nil)
  if valid_614443 != nil:
    section.add "X-Amz-Security-Token", valid_614443
  var valid_614444 = header.getOrDefault("X-Amz-Algorithm")
  valid_614444 = validateParameter(valid_614444, JString, required = false,
                                 default = nil)
  if valid_614444 != nil:
    section.add "X-Amz-Algorithm", valid_614444
  var valid_614445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614445 = validateParameter(valid_614445, JString, required = false,
                                 default = nil)
  if valid_614445 != nil:
    section.add "X-Amz-SignedHeaders", valid_614445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614447: Call_GetRelationalDatabaseMetricData_614435;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the data points of the specified metric for a database in Amazon Lightsail.
  ## 
  let valid = call_614447.validator(path, query, header, formData, body)
  let scheme = call_614447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614447.url(scheme.get, call_614447.host, call_614447.base,
                         call_614447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614447, url, valid)

proc call*(call_614448: Call_GetRelationalDatabaseMetricData_614435; body: JsonNode): Recallable =
  ## getRelationalDatabaseMetricData
  ## Returns the data points of the specified metric for a database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_614449 = newJObject()
  if body != nil:
    body_614449 = body
  result = call_614448.call(nil, nil, nil, nil, body_614449)

var getRelationalDatabaseMetricData* = Call_GetRelationalDatabaseMetricData_614435(
    name: "getRelationalDatabaseMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseMetricData",
    validator: validate_GetRelationalDatabaseMetricData_614436, base: "/",
    url: url_GetRelationalDatabaseMetricData_614437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseParameters_614450 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabaseParameters_614452(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseParameters_614451(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail.</p> <p>In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.</p>
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
  var valid_614453 = header.getOrDefault("X-Amz-Target")
  valid_614453 = validateParameter(valid_614453, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseParameters"))
  if valid_614453 != nil:
    section.add "X-Amz-Target", valid_614453
  var valid_614454 = header.getOrDefault("X-Amz-Signature")
  valid_614454 = validateParameter(valid_614454, JString, required = false,
                                 default = nil)
  if valid_614454 != nil:
    section.add "X-Amz-Signature", valid_614454
  var valid_614455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614455 = validateParameter(valid_614455, JString, required = false,
                                 default = nil)
  if valid_614455 != nil:
    section.add "X-Amz-Content-Sha256", valid_614455
  var valid_614456 = header.getOrDefault("X-Amz-Date")
  valid_614456 = validateParameter(valid_614456, JString, required = false,
                                 default = nil)
  if valid_614456 != nil:
    section.add "X-Amz-Date", valid_614456
  var valid_614457 = header.getOrDefault("X-Amz-Credential")
  valid_614457 = validateParameter(valid_614457, JString, required = false,
                                 default = nil)
  if valid_614457 != nil:
    section.add "X-Amz-Credential", valid_614457
  var valid_614458 = header.getOrDefault("X-Amz-Security-Token")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-Security-Token", valid_614458
  var valid_614459 = header.getOrDefault("X-Amz-Algorithm")
  valid_614459 = validateParameter(valid_614459, JString, required = false,
                                 default = nil)
  if valid_614459 != nil:
    section.add "X-Amz-Algorithm", valid_614459
  var valid_614460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614460 = validateParameter(valid_614460, JString, required = false,
                                 default = nil)
  if valid_614460 != nil:
    section.add "X-Amz-SignedHeaders", valid_614460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614462: Call_GetRelationalDatabaseParameters_614450;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail.</p> <p>In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.</p>
  ## 
  let valid = call_614462.validator(path, query, header, formData, body)
  let scheme = call_614462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614462.url(scheme.get, call_614462.host, call_614462.base,
                         call_614462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614462, url, valid)

proc call*(call_614463: Call_GetRelationalDatabaseParameters_614450; body: JsonNode): Recallable =
  ## getRelationalDatabaseParameters
  ## <p>Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail.</p> <p>In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.</p>
  ##   body: JObject (required)
  var body_614464 = newJObject()
  if body != nil:
    body_614464 = body
  result = call_614463.call(nil, nil, nil, nil, body_614464)

var getRelationalDatabaseParameters* = Call_GetRelationalDatabaseParameters_614450(
    name: "getRelationalDatabaseParameters", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseParameters",
    validator: validate_GetRelationalDatabaseParameters_614451, base: "/",
    url: url_GetRelationalDatabaseParameters_614452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseSnapshot_614465 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabaseSnapshot_614467(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseSnapshot_614466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specific database snapshot in Amazon Lightsail.
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
  var valid_614468 = header.getOrDefault("X-Amz-Target")
  valid_614468 = validateParameter(valid_614468, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseSnapshot"))
  if valid_614468 != nil:
    section.add "X-Amz-Target", valid_614468
  var valid_614469 = header.getOrDefault("X-Amz-Signature")
  valid_614469 = validateParameter(valid_614469, JString, required = false,
                                 default = nil)
  if valid_614469 != nil:
    section.add "X-Amz-Signature", valid_614469
  var valid_614470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614470 = validateParameter(valid_614470, JString, required = false,
                                 default = nil)
  if valid_614470 != nil:
    section.add "X-Amz-Content-Sha256", valid_614470
  var valid_614471 = header.getOrDefault("X-Amz-Date")
  valid_614471 = validateParameter(valid_614471, JString, required = false,
                                 default = nil)
  if valid_614471 != nil:
    section.add "X-Amz-Date", valid_614471
  var valid_614472 = header.getOrDefault("X-Amz-Credential")
  valid_614472 = validateParameter(valid_614472, JString, required = false,
                                 default = nil)
  if valid_614472 != nil:
    section.add "X-Amz-Credential", valid_614472
  var valid_614473 = header.getOrDefault("X-Amz-Security-Token")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-Security-Token", valid_614473
  var valid_614474 = header.getOrDefault("X-Amz-Algorithm")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "X-Amz-Algorithm", valid_614474
  var valid_614475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "X-Amz-SignedHeaders", valid_614475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614477: Call_GetRelationalDatabaseSnapshot_614465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific database snapshot in Amazon Lightsail.
  ## 
  let valid = call_614477.validator(path, query, header, formData, body)
  let scheme = call_614477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614477.url(scheme.get, call_614477.host, call_614477.base,
                         call_614477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614477, url, valid)

proc call*(call_614478: Call_GetRelationalDatabaseSnapshot_614465; body: JsonNode): Recallable =
  ## getRelationalDatabaseSnapshot
  ## Returns information about a specific database snapshot in Amazon Lightsail.
  ##   body: JObject (required)
  var body_614479 = newJObject()
  if body != nil:
    body_614479 = body
  result = call_614478.call(nil, nil, nil, nil, body_614479)

var getRelationalDatabaseSnapshot* = Call_GetRelationalDatabaseSnapshot_614465(
    name: "getRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseSnapshot",
    validator: validate_GetRelationalDatabaseSnapshot_614466, base: "/",
    url: url_GetRelationalDatabaseSnapshot_614467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseSnapshots_614480 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabaseSnapshots_614482(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseSnapshots_614481(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about all of your database snapshots in Amazon Lightsail.
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
  var valid_614483 = header.getOrDefault("X-Amz-Target")
  valid_614483 = validateParameter(valid_614483, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseSnapshots"))
  if valid_614483 != nil:
    section.add "X-Amz-Target", valid_614483
  var valid_614484 = header.getOrDefault("X-Amz-Signature")
  valid_614484 = validateParameter(valid_614484, JString, required = false,
                                 default = nil)
  if valid_614484 != nil:
    section.add "X-Amz-Signature", valid_614484
  var valid_614485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614485 = validateParameter(valid_614485, JString, required = false,
                                 default = nil)
  if valid_614485 != nil:
    section.add "X-Amz-Content-Sha256", valid_614485
  var valid_614486 = header.getOrDefault("X-Amz-Date")
  valid_614486 = validateParameter(valid_614486, JString, required = false,
                                 default = nil)
  if valid_614486 != nil:
    section.add "X-Amz-Date", valid_614486
  var valid_614487 = header.getOrDefault("X-Amz-Credential")
  valid_614487 = validateParameter(valid_614487, JString, required = false,
                                 default = nil)
  if valid_614487 != nil:
    section.add "X-Amz-Credential", valid_614487
  var valid_614488 = header.getOrDefault("X-Amz-Security-Token")
  valid_614488 = validateParameter(valid_614488, JString, required = false,
                                 default = nil)
  if valid_614488 != nil:
    section.add "X-Amz-Security-Token", valid_614488
  var valid_614489 = header.getOrDefault("X-Amz-Algorithm")
  valid_614489 = validateParameter(valid_614489, JString, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "X-Amz-Algorithm", valid_614489
  var valid_614490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614490 = validateParameter(valid_614490, JString, required = false,
                                 default = nil)
  if valid_614490 != nil:
    section.add "X-Amz-SignedHeaders", valid_614490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614492: Call_GetRelationalDatabaseSnapshots_614480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all of your database snapshots in Amazon Lightsail.
  ## 
  let valid = call_614492.validator(path, query, header, formData, body)
  let scheme = call_614492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614492.url(scheme.get, call_614492.host, call_614492.base,
                         call_614492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614492, url, valid)

proc call*(call_614493: Call_GetRelationalDatabaseSnapshots_614480; body: JsonNode): Recallable =
  ## getRelationalDatabaseSnapshots
  ## Returns information about all of your database snapshots in Amazon Lightsail.
  ##   body: JObject (required)
  var body_614494 = newJObject()
  if body != nil:
    body_614494 = body
  result = call_614493.call(nil, nil, nil, nil, body_614494)

var getRelationalDatabaseSnapshots* = Call_GetRelationalDatabaseSnapshots_614480(
    name: "getRelationalDatabaseSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseSnapshots",
    validator: validate_GetRelationalDatabaseSnapshots_614481, base: "/",
    url: url_GetRelationalDatabaseSnapshots_614482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabases_614495 = ref object of OpenApiRestCall_612658
proc url_GetRelationalDatabases_614497(protocol: Scheme; host: string; base: string;
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

proc validate_GetRelationalDatabases_614496(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about all of your databases in Amazon Lightsail.
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
  var valid_614498 = header.getOrDefault("X-Amz-Target")
  valid_614498 = validateParameter(valid_614498, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabases"))
  if valid_614498 != nil:
    section.add "X-Amz-Target", valid_614498
  var valid_614499 = header.getOrDefault("X-Amz-Signature")
  valid_614499 = validateParameter(valid_614499, JString, required = false,
                                 default = nil)
  if valid_614499 != nil:
    section.add "X-Amz-Signature", valid_614499
  var valid_614500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614500 = validateParameter(valid_614500, JString, required = false,
                                 default = nil)
  if valid_614500 != nil:
    section.add "X-Amz-Content-Sha256", valid_614500
  var valid_614501 = header.getOrDefault("X-Amz-Date")
  valid_614501 = validateParameter(valid_614501, JString, required = false,
                                 default = nil)
  if valid_614501 != nil:
    section.add "X-Amz-Date", valid_614501
  var valid_614502 = header.getOrDefault("X-Amz-Credential")
  valid_614502 = validateParameter(valid_614502, JString, required = false,
                                 default = nil)
  if valid_614502 != nil:
    section.add "X-Amz-Credential", valid_614502
  var valid_614503 = header.getOrDefault("X-Amz-Security-Token")
  valid_614503 = validateParameter(valid_614503, JString, required = false,
                                 default = nil)
  if valid_614503 != nil:
    section.add "X-Amz-Security-Token", valid_614503
  var valid_614504 = header.getOrDefault("X-Amz-Algorithm")
  valid_614504 = validateParameter(valid_614504, JString, required = false,
                                 default = nil)
  if valid_614504 != nil:
    section.add "X-Amz-Algorithm", valid_614504
  var valid_614505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614505 = validateParameter(valid_614505, JString, required = false,
                                 default = nil)
  if valid_614505 != nil:
    section.add "X-Amz-SignedHeaders", valid_614505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614507: Call_GetRelationalDatabases_614495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all of your databases in Amazon Lightsail.
  ## 
  let valid = call_614507.validator(path, query, header, formData, body)
  let scheme = call_614507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614507.url(scheme.get, call_614507.host, call_614507.base,
                         call_614507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614507, url, valid)

proc call*(call_614508: Call_GetRelationalDatabases_614495; body: JsonNode): Recallable =
  ## getRelationalDatabases
  ## Returns information about all of your databases in Amazon Lightsail.
  ##   body: JObject (required)
  var body_614509 = newJObject()
  if body != nil:
    body_614509 = body
  result = call_614508.call(nil, nil, nil, nil, body_614509)

var getRelationalDatabases* = Call_GetRelationalDatabases_614495(
    name: "getRelationalDatabases", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabases",
    validator: validate_GetRelationalDatabases_614496, base: "/",
    url: url_GetRelationalDatabases_614497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStaticIp_614510 = ref object of OpenApiRestCall_612658
proc url_GetStaticIp_614512(protocol: Scheme; host: string; base: string;
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

proc validate_GetStaticIp_614511(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specific static IP.
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
  var valid_614513 = header.getOrDefault("X-Amz-Target")
  valid_614513 = validateParameter(valid_614513, JString, required = true, default = newJString(
      "Lightsail_20161128.GetStaticIp"))
  if valid_614513 != nil:
    section.add "X-Amz-Target", valid_614513
  var valid_614514 = header.getOrDefault("X-Amz-Signature")
  valid_614514 = validateParameter(valid_614514, JString, required = false,
                                 default = nil)
  if valid_614514 != nil:
    section.add "X-Amz-Signature", valid_614514
  var valid_614515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614515 = validateParameter(valid_614515, JString, required = false,
                                 default = nil)
  if valid_614515 != nil:
    section.add "X-Amz-Content-Sha256", valid_614515
  var valid_614516 = header.getOrDefault("X-Amz-Date")
  valid_614516 = validateParameter(valid_614516, JString, required = false,
                                 default = nil)
  if valid_614516 != nil:
    section.add "X-Amz-Date", valid_614516
  var valid_614517 = header.getOrDefault("X-Amz-Credential")
  valid_614517 = validateParameter(valid_614517, JString, required = false,
                                 default = nil)
  if valid_614517 != nil:
    section.add "X-Amz-Credential", valid_614517
  var valid_614518 = header.getOrDefault("X-Amz-Security-Token")
  valid_614518 = validateParameter(valid_614518, JString, required = false,
                                 default = nil)
  if valid_614518 != nil:
    section.add "X-Amz-Security-Token", valid_614518
  var valid_614519 = header.getOrDefault("X-Amz-Algorithm")
  valid_614519 = validateParameter(valid_614519, JString, required = false,
                                 default = nil)
  if valid_614519 != nil:
    section.add "X-Amz-Algorithm", valid_614519
  var valid_614520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614520 = validateParameter(valid_614520, JString, required = false,
                                 default = nil)
  if valid_614520 != nil:
    section.add "X-Amz-SignedHeaders", valid_614520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614522: Call_GetStaticIp_614510; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific static IP.
  ## 
  let valid = call_614522.validator(path, query, header, formData, body)
  let scheme = call_614522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614522.url(scheme.get, call_614522.host, call_614522.base,
                         call_614522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614522, url, valid)

proc call*(call_614523: Call_GetStaticIp_614510; body: JsonNode): Recallable =
  ## getStaticIp
  ## Returns information about a specific static IP.
  ##   body: JObject (required)
  var body_614524 = newJObject()
  if body != nil:
    body_614524 = body
  result = call_614523.call(nil, nil, nil, nil, body_614524)

var getStaticIp* = Call_GetStaticIp_614510(name: "getStaticIp",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetStaticIp",
                                        validator: validate_GetStaticIp_614511,
                                        base: "/", url: url_GetStaticIp_614512,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStaticIps_614525 = ref object of OpenApiRestCall_612658
proc url_GetStaticIps_614527(protocol: Scheme; host: string; base: string;
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

proc validate_GetStaticIps_614526(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about all static IPs in the user's account.
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
  var valid_614528 = header.getOrDefault("X-Amz-Target")
  valid_614528 = validateParameter(valid_614528, JString, required = true, default = newJString(
      "Lightsail_20161128.GetStaticIps"))
  if valid_614528 != nil:
    section.add "X-Amz-Target", valid_614528
  var valid_614529 = header.getOrDefault("X-Amz-Signature")
  valid_614529 = validateParameter(valid_614529, JString, required = false,
                                 default = nil)
  if valid_614529 != nil:
    section.add "X-Amz-Signature", valid_614529
  var valid_614530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614530 = validateParameter(valid_614530, JString, required = false,
                                 default = nil)
  if valid_614530 != nil:
    section.add "X-Amz-Content-Sha256", valid_614530
  var valid_614531 = header.getOrDefault("X-Amz-Date")
  valid_614531 = validateParameter(valid_614531, JString, required = false,
                                 default = nil)
  if valid_614531 != nil:
    section.add "X-Amz-Date", valid_614531
  var valid_614532 = header.getOrDefault("X-Amz-Credential")
  valid_614532 = validateParameter(valid_614532, JString, required = false,
                                 default = nil)
  if valid_614532 != nil:
    section.add "X-Amz-Credential", valid_614532
  var valid_614533 = header.getOrDefault("X-Amz-Security-Token")
  valid_614533 = validateParameter(valid_614533, JString, required = false,
                                 default = nil)
  if valid_614533 != nil:
    section.add "X-Amz-Security-Token", valid_614533
  var valid_614534 = header.getOrDefault("X-Amz-Algorithm")
  valid_614534 = validateParameter(valid_614534, JString, required = false,
                                 default = nil)
  if valid_614534 != nil:
    section.add "X-Amz-Algorithm", valid_614534
  var valid_614535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614535 = validateParameter(valid_614535, JString, required = false,
                                 default = nil)
  if valid_614535 != nil:
    section.add "X-Amz-SignedHeaders", valid_614535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614537: Call_GetStaticIps_614525; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all static IPs in the user's account.
  ## 
  let valid = call_614537.validator(path, query, header, formData, body)
  let scheme = call_614537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614537.url(scheme.get, call_614537.host, call_614537.base,
                         call_614537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614537, url, valid)

proc call*(call_614538: Call_GetStaticIps_614525; body: JsonNode): Recallable =
  ## getStaticIps
  ## Returns information about all static IPs in the user's account.
  ##   body: JObject (required)
  var body_614539 = newJObject()
  if body != nil:
    body_614539 = body
  result = call_614538.call(nil, nil, nil, nil, body_614539)

var getStaticIps* = Call_GetStaticIps_614525(name: "getStaticIps",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetStaticIps",
    validator: validate_GetStaticIps_614526, base: "/", url: url_GetStaticIps_614527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportKeyPair_614540 = ref object of OpenApiRestCall_612658
proc url_ImportKeyPair_614542(protocol: Scheme; host: string; base: string;
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

proc validate_ImportKeyPair_614541(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Imports a public SSH key from a specific key pair.
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
  var valid_614543 = header.getOrDefault("X-Amz-Target")
  valid_614543 = validateParameter(valid_614543, JString, required = true, default = newJString(
      "Lightsail_20161128.ImportKeyPair"))
  if valid_614543 != nil:
    section.add "X-Amz-Target", valid_614543
  var valid_614544 = header.getOrDefault("X-Amz-Signature")
  valid_614544 = validateParameter(valid_614544, JString, required = false,
                                 default = nil)
  if valid_614544 != nil:
    section.add "X-Amz-Signature", valid_614544
  var valid_614545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614545 = validateParameter(valid_614545, JString, required = false,
                                 default = nil)
  if valid_614545 != nil:
    section.add "X-Amz-Content-Sha256", valid_614545
  var valid_614546 = header.getOrDefault("X-Amz-Date")
  valid_614546 = validateParameter(valid_614546, JString, required = false,
                                 default = nil)
  if valid_614546 != nil:
    section.add "X-Amz-Date", valid_614546
  var valid_614547 = header.getOrDefault("X-Amz-Credential")
  valid_614547 = validateParameter(valid_614547, JString, required = false,
                                 default = nil)
  if valid_614547 != nil:
    section.add "X-Amz-Credential", valid_614547
  var valid_614548 = header.getOrDefault("X-Amz-Security-Token")
  valid_614548 = validateParameter(valid_614548, JString, required = false,
                                 default = nil)
  if valid_614548 != nil:
    section.add "X-Amz-Security-Token", valid_614548
  var valid_614549 = header.getOrDefault("X-Amz-Algorithm")
  valid_614549 = validateParameter(valid_614549, JString, required = false,
                                 default = nil)
  if valid_614549 != nil:
    section.add "X-Amz-Algorithm", valid_614549
  var valid_614550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614550 = validateParameter(valid_614550, JString, required = false,
                                 default = nil)
  if valid_614550 != nil:
    section.add "X-Amz-SignedHeaders", valid_614550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614552: Call_ImportKeyPair_614540; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports a public SSH key from a specific key pair.
  ## 
  let valid = call_614552.validator(path, query, header, formData, body)
  let scheme = call_614552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614552.url(scheme.get, call_614552.host, call_614552.base,
                         call_614552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614552, url, valid)

proc call*(call_614553: Call_ImportKeyPair_614540; body: JsonNode): Recallable =
  ## importKeyPair
  ## Imports a public SSH key from a specific key pair.
  ##   body: JObject (required)
  var body_614554 = newJObject()
  if body != nil:
    body_614554 = body
  result = call_614553.call(nil, nil, nil, nil, body_614554)

var importKeyPair* = Call_ImportKeyPair_614540(name: "importKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ImportKeyPair",
    validator: validate_ImportKeyPair_614541, base: "/", url: url_ImportKeyPair_614542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_IsVpcPeered_614555 = ref object of OpenApiRestCall_612658
proc url_IsVpcPeered_614557(protocol: Scheme; host: string; base: string;
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

proc validate_IsVpcPeered_614556(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a Boolean value indicating whether your Lightsail VPC is peered.
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
  var valid_614558 = header.getOrDefault("X-Amz-Target")
  valid_614558 = validateParameter(valid_614558, JString, required = true, default = newJString(
      "Lightsail_20161128.IsVpcPeered"))
  if valid_614558 != nil:
    section.add "X-Amz-Target", valid_614558
  var valid_614559 = header.getOrDefault("X-Amz-Signature")
  valid_614559 = validateParameter(valid_614559, JString, required = false,
                                 default = nil)
  if valid_614559 != nil:
    section.add "X-Amz-Signature", valid_614559
  var valid_614560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614560 = validateParameter(valid_614560, JString, required = false,
                                 default = nil)
  if valid_614560 != nil:
    section.add "X-Amz-Content-Sha256", valid_614560
  var valid_614561 = header.getOrDefault("X-Amz-Date")
  valid_614561 = validateParameter(valid_614561, JString, required = false,
                                 default = nil)
  if valid_614561 != nil:
    section.add "X-Amz-Date", valid_614561
  var valid_614562 = header.getOrDefault("X-Amz-Credential")
  valid_614562 = validateParameter(valid_614562, JString, required = false,
                                 default = nil)
  if valid_614562 != nil:
    section.add "X-Amz-Credential", valid_614562
  var valid_614563 = header.getOrDefault("X-Amz-Security-Token")
  valid_614563 = validateParameter(valid_614563, JString, required = false,
                                 default = nil)
  if valid_614563 != nil:
    section.add "X-Amz-Security-Token", valid_614563
  var valid_614564 = header.getOrDefault("X-Amz-Algorithm")
  valid_614564 = validateParameter(valid_614564, JString, required = false,
                                 default = nil)
  if valid_614564 != nil:
    section.add "X-Amz-Algorithm", valid_614564
  var valid_614565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614565 = validateParameter(valid_614565, JString, required = false,
                                 default = nil)
  if valid_614565 != nil:
    section.add "X-Amz-SignedHeaders", valid_614565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614567: Call_IsVpcPeered_614555; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a Boolean value indicating whether your Lightsail VPC is peered.
  ## 
  let valid = call_614567.validator(path, query, header, formData, body)
  let scheme = call_614567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614567.url(scheme.get, call_614567.host, call_614567.base,
                         call_614567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614567, url, valid)

proc call*(call_614568: Call_IsVpcPeered_614555; body: JsonNode): Recallable =
  ## isVpcPeered
  ## Returns a Boolean value indicating whether your Lightsail VPC is peered.
  ##   body: JObject (required)
  var body_614569 = newJObject()
  if body != nil:
    body_614569 = body
  result = call_614568.call(nil, nil, nil, nil, body_614569)

var isVpcPeered* = Call_IsVpcPeered_614555(name: "isVpcPeered",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.IsVpcPeered",
                                        validator: validate_IsVpcPeered_614556,
                                        base: "/", url: url_IsVpcPeered_614557,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_OpenInstancePublicPorts_614570 = ref object of OpenApiRestCall_612658
proc url_OpenInstancePublicPorts_614572(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_OpenInstancePublicPorts_614571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds public ports to an Amazon Lightsail instance.</p> <p>The <code>open instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614573 = header.getOrDefault("X-Amz-Target")
  valid_614573 = validateParameter(valid_614573, JString, required = true, default = newJString(
      "Lightsail_20161128.OpenInstancePublicPorts"))
  if valid_614573 != nil:
    section.add "X-Amz-Target", valid_614573
  var valid_614574 = header.getOrDefault("X-Amz-Signature")
  valid_614574 = validateParameter(valid_614574, JString, required = false,
                                 default = nil)
  if valid_614574 != nil:
    section.add "X-Amz-Signature", valid_614574
  var valid_614575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614575 = validateParameter(valid_614575, JString, required = false,
                                 default = nil)
  if valid_614575 != nil:
    section.add "X-Amz-Content-Sha256", valid_614575
  var valid_614576 = header.getOrDefault("X-Amz-Date")
  valid_614576 = validateParameter(valid_614576, JString, required = false,
                                 default = nil)
  if valid_614576 != nil:
    section.add "X-Amz-Date", valid_614576
  var valid_614577 = header.getOrDefault("X-Amz-Credential")
  valid_614577 = validateParameter(valid_614577, JString, required = false,
                                 default = nil)
  if valid_614577 != nil:
    section.add "X-Amz-Credential", valid_614577
  var valid_614578 = header.getOrDefault("X-Amz-Security-Token")
  valid_614578 = validateParameter(valid_614578, JString, required = false,
                                 default = nil)
  if valid_614578 != nil:
    section.add "X-Amz-Security-Token", valid_614578
  var valid_614579 = header.getOrDefault("X-Amz-Algorithm")
  valid_614579 = validateParameter(valid_614579, JString, required = false,
                                 default = nil)
  if valid_614579 != nil:
    section.add "X-Amz-Algorithm", valid_614579
  var valid_614580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614580 = validateParameter(valid_614580, JString, required = false,
                                 default = nil)
  if valid_614580 != nil:
    section.add "X-Amz-SignedHeaders", valid_614580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614582: Call_OpenInstancePublicPorts_614570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds public ports to an Amazon Lightsail instance.</p> <p>The <code>open instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614582.validator(path, query, header, formData, body)
  let scheme = call_614582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614582.url(scheme.get, call_614582.host, call_614582.base,
                         call_614582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614582, url, valid)

proc call*(call_614583: Call_OpenInstancePublicPorts_614570; body: JsonNode): Recallable =
  ## openInstancePublicPorts
  ## <p>Adds public ports to an Amazon Lightsail instance.</p> <p>The <code>open instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614584 = newJObject()
  if body != nil:
    body_614584 = body
  result = call_614583.call(nil, nil, nil, nil, body_614584)

var openInstancePublicPorts* = Call_OpenInstancePublicPorts_614570(
    name: "openInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.OpenInstancePublicPorts",
    validator: validate_OpenInstancePublicPorts_614571, base: "/",
    url: url_OpenInstancePublicPorts_614572, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PeerVpc_614585 = ref object of OpenApiRestCall_612658
proc url_PeerVpc_614587(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PeerVpc_614586(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Tries to peer the Lightsail VPC with the user's default VPC.
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
  var valid_614588 = header.getOrDefault("X-Amz-Target")
  valid_614588 = validateParameter(valid_614588, JString, required = true, default = newJString(
      "Lightsail_20161128.PeerVpc"))
  if valid_614588 != nil:
    section.add "X-Amz-Target", valid_614588
  var valid_614589 = header.getOrDefault("X-Amz-Signature")
  valid_614589 = validateParameter(valid_614589, JString, required = false,
                                 default = nil)
  if valid_614589 != nil:
    section.add "X-Amz-Signature", valid_614589
  var valid_614590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614590 = validateParameter(valid_614590, JString, required = false,
                                 default = nil)
  if valid_614590 != nil:
    section.add "X-Amz-Content-Sha256", valid_614590
  var valid_614591 = header.getOrDefault("X-Amz-Date")
  valid_614591 = validateParameter(valid_614591, JString, required = false,
                                 default = nil)
  if valid_614591 != nil:
    section.add "X-Amz-Date", valid_614591
  var valid_614592 = header.getOrDefault("X-Amz-Credential")
  valid_614592 = validateParameter(valid_614592, JString, required = false,
                                 default = nil)
  if valid_614592 != nil:
    section.add "X-Amz-Credential", valid_614592
  var valid_614593 = header.getOrDefault("X-Amz-Security-Token")
  valid_614593 = validateParameter(valid_614593, JString, required = false,
                                 default = nil)
  if valid_614593 != nil:
    section.add "X-Amz-Security-Token", valid_614593
  var valid_614594 = header.getOrDefault("X-Amz-Algorithm")
  valid_614594 = validateParameter(valid_614594, JString, required = false,
                                 default = nil)
  if valid_614594 != nil:
    section.add "X-Amz-Algorithm", valid_614594
  var valid_614595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614595 = validateParameter(valid_614595, JString, required = false,
                                 default = nil)
  if valid_614595 != nil:
    section.add "X-Amz-SignedHeaders", valid_614595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614597: Call_PeerVpc_614585; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tries to peer the Lightsail VPC with the user's default VPC.
  ## 
  let valid = call_614597.validator(path, query, header, formData, body)
  let scheme = call_614597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614597.url(scheme.get, call_614597.host, call_614597.base,
                         call_614597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614597, url, valid)

proc call*(call_614598: Call_PeerVpc_614585; body: JsonNode): Recallable =
  ## peerVpc
  ## Tries to peer the Lightsail VPC with the user's default VPC.
  ##   body: JObject (required)
  var body_614599 = newJObject()
  if body != nil:
    body_614599 = body
  result = call_614598.call(nil, nil, nil, nil, body_614599)

var peerVpc* = Call_PeerVpc_614585(name: "peerVpc", meth: HttpMethod.HttpPost,
                                host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.PeerVpc",
                                validator: validate_PeerVpc_614586, base: "/",
                                url: url_PeerVpc_614587,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInstancePublicPorts_614600 = ref object of OpenApiRestCall_612658
proc url_PutInstancePublicPorts_614602(protocol: Scheme; host: string; base: string;
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

proc validate_PutInstancePublicPorts_614601(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the specified open ports for an Amazon Lightsail instance, and closes all ports for every protocol not included in the current request.</p> <p>The <code>put instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614603 = header.getOrDefault("X-Amz-Target")
  valid_614603 = validateParameter(valid_614603, JString, required = true, default = newJString(
      "Lightsail_20161128.PutInstancePublicPorts"))
  if valid_614603 != nil:
    section.add "X-Amz-Target", valid_614603
  var valid_614604 = header.getOrDefault("X-Amz-Signature")
  valid_614604 = validateParameter(valid_614604, JString, required = false,
                                 default = nil)
  if valid_614604 != nil:
    section.add "X-Amz-Signature", valid_614604
  var valid_614605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614605 = validateParameter(valid_614605, JString, required = false,
                                 default = nil)
  if valid_614605 != nil:
    section.add "X-Amz-Content-Sha256", valid_614605
  var valid_614606 = header.getOrDefault("X-Amz-Date")
  valid_614606 = validateParameter(valid_614606, JString, required = false,
                                 default = nil)
  if valid_614606 != nil:
    section.add "X-Amz-Date", valid_614606
  var valid_614607 = header.getOrDefault("X-Amz-Credential")
  valid_614607 = validateParameter(valid_614607, JString, required = false,
                                 default = nil)
  if valid_614607 != nil:
    section.add "X-Amz-Credential", valid_614607
  var valid_614608 = header.getOrDefault("X-Amz-Security-Token")
  valid_614608 = validateParameter(valid_614608, JString, required = false,
                                 default = nil)
  if valid_614608 != nil:
    section.add "X-Amz-Security-Token", valid_614608
  var valid_614609 = header.getOrDefault("X-Amz-Algorithm")
  valid_614609 = validateParameter(valid_614609, JString, required = false,
                                 default = nil)
  if valid_614609 != nil:
    section.add "X-Amz-Algorithm", valid_614609
  var valid_614610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614610 = validateParameter(valid_614610, JString, required = false,
                                 default = nil)
  if valid_614610 != nil:
    section.add "X-Amz-SignedHeaders", valid_614610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614612: Call_PutInstancePublicPorts_614600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the specified open ports for an Amazon Lightsail instance, and closes all ports for every protocol not included in the current request.</p> <p>The <code>put instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614612.validator(path, query, header, formData, body)
  let scheme = call_614612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614612.url(scheme.get, call_614612.host, call_614612.base,
                         call_614612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614612, url, valid)

proc call*(call_614613: Call_PutInstancePublicPorts_614600; body: JsonNode): Recallable =
  ## putInstancePublicPorts
  ## <p>Sets the specified open ports for an Amazon Lightsail instance, and closes all ports for every protocol not included in the current request.</p> <p>The <code>put instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614614 = newJObject()
  if body != nil:
    body_614614 = body
  result = call_614613.call(nil, nil, nil, nil, body_614614)

var putInstancePublicPorts* = Call_PutInstancePublicPorts_614600(
    name: "putInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.PutInstancePublicPorts",
    validator: validate_PutInstancePublicPorts_614601, base: "/",
    url: url_PutInstancePublicPorts_614602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootInstance_614615 = ref object of OpenApiRestCall_612658
proc url_RebootInstance_614617(protocol: Scheme; host: string; base: string;
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

proc validate_RebootInstance_614616(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Restarts a specific instance.</p> <p>The <code>reboot instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614618 = header.getOrDefault("X-Amz-Target")
  valid_614618 = validateParameter(valid_614618, JString, required = true, default = newJString(
      "Lightsail_20161128.RebootInstance"))
  if valid_614618 != nil:
    section.add "X-Amz-Target", valid_614618
  var valid_614619 = header.getOrDefault("X-Amz-Signature")
  valid_614619 = validateParameter(valid_614619, JString, required = false,
                                 default = nil)
  if valid_614619 != nil:
    section.add "X-Amz-Signature", valid_614619
  var valid_614620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614620 = validateParameter(valid_614620, JString, required = false,
                                 default = nil)
  if valid_614620 != nil:
    section.add "X-Amz-Content-Sha256", valid_614620
  var valid_614621 = header.getOrDefault("X-Amz-Date")
  valid_614621 = validateParameter(valid_614621, JString, required = false,
                                 default = nil)
  if valid_614621 != nil:
    section.add "X-Amz-Date", valid_614621
  var valid_614622 = header.getOrDefault("X-Amz-Credential")
  valid_614622 = validateParameter(valid_614622, JString, required = false,
                                 default = nil)
  if valid_614622 != nil:
    section.add "X-Amz-Credential", valid_614622
  var valid_614623 = header.getOrDefault("X-Amz-Security-Token")
  valid_614623 = validateParameter(valid_614623, JString, required = false,
                                 default = nil)
  if valid_614623 != nil:
    section.add "X-Amz-Security-Token", valid_614623
  var valid_614624 = header.getOrDefault("X-Amz-Algorithm")
  valid_614624 = validateParameter(valid_614624, JString, required = false,
                                 default = nil)
  if valid_614624 != nil:
    section.add "X-Amz-Algorithm", valid_614624
  var valid_614625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614625 = validateParameter(valid_614625, JString, required = false,
                                 default = nil)
  if valid_614625 != nil:
    section.add "X-Amz-SignedHeaders", valid_614625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614627: Call_RebootInstance_614615; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restarts a specific instance.</p> <p>The <code>reboot instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614627.validator(path, query, header, formData, body)
  let scheme = call_614627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614627.url(scheme.get, call_614627.host, call_614627.base,
                         call_614627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614627, url, valid)

proc call*(call_614628: Call_RebootInstance_614615; body: JsonNode): Recallable =
  ## rebootInstance
  ## <p>Restarts a specific instance.</p> <p>The <code>reboot instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614629 = newJObject()
  if body != nil:
    body_614629 = body
  result = call_614628.call(nil, nil, nil, nil, body_614629)

var rebootInstance* = Call_RebootInstance_614615(name: "rebootInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.RebootInstance",
    validator: validate_RebootInstance_614616, base: "/", url: url_RebootInstance_614617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootRelationalDatabase_614630 = ref object of OpenApiRestCall_612658
proc url_RebootRelationalDatabase_614632(protocol: Scheme; host: string;
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

proc validate_RebootRelationalDatabase_614631(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614633 = header.getOrDefault("X-Amz-Target")
  valid_614633 = validateParameter(valid_614633, JString, required = true, default = newJString(
      "Lightsail_20161128.RebootRelationalDatabase"))
  if valid_614633 != nil:
    section.add "X-Amz-Target", valid_614633
  var valid_614634 = header.getOrDefault("X-Amz-Signature")
  valid_614634 = validateParameter(valid_614634, JString, required = false,
                                 default = nil)
  if valid_614634 != nil:
    section.add "X-Amz-Signature", valid_614634
  var valid_614635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614635 = validateParameter(valid_614635, JString, required = false,
                                 default = nil)
  if valid_614635 != nil:
    section.add "X-Amz-Content-Sha256", valid_614635
  var valid_614636 = header.getOrDefault("X-Amz-Date")
  valid_614636 = validateParameter(valid_614636, JString, required = false,
                                 default = nil)
  if valid_614636 != nil:
    section.add "X-Amz-Date", valid_614636
  var valid_614637 = header.getOrDefault("X-Amz-Credential")
  valid_614637 = validateParameter(valid_614637, JString, required = false,
                                 default = nil)
  if valid_614637 != nil:
    section.add "X-Amz-Credential", valid_614637
  var valid_614638 = header.getOrDefault("X-Amz-Security-Token")
  valid_614638 = validateParameter(valid_614638, JString, required = false,
                                 default = nil)
  if valid_614638 != nil:
    section.add "X-Amz-Security-Token", valid_614638
  var valid_614639 = header.getOrDefault("X-Amz-Algorithm")
  valid_614639 = validateParameter(valid_614639, JString, required = false,
                                 default = nil)
  if valid_614639 != nil:
    section.add "X-Amz-Algorithm", valid_614639
  var valid_614640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614640 = validateParameter(valid_614640, JString, required = false,
                                 default = nil)
  if valid_614640 != nil:
    section.add "X-Amz-SignedHeaders", valid_614640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614642: Call_RebootRelationalDatabase_614630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614642.validator(path, query, header, formData, body)
  let scheme = call_614642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614642.url(scheme.get, call_614642.host, call_614642.base,
                         call_614642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614642, url, valid)

proc call*(call_614643: Call_RebootRelationalDatabase_614630; body: JsonNode): Recallable =
  ## rebootRelationalDatabase
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614644 = newJObject()
  if body != nil:
    body_614644 = body
  result = call_614643.call(nil, nil, nil, nil, body_614644)

var rebootRelationalDatabase* = Call_RebootRelationalDatabase_614630(
    name: "rebootRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.RebootRelationalDatabase",
    validator: validate_RebootRelationalDatabase_614631, base: "/",
    url: url_RebootRelationalDatabase_614632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReleaseStaticIp_614645 = ref object of OpenApiRestCall_612658
proc url_ReleaseStaticIp_614647(protocol: Scheme; host: string; base: string;
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

proc validate_ReleaseStaticIp_614646(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a specific static IP from your account.
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
  var valid_614648 = header.getOrDefault("X-Amz-Target")
  valid_614648 = validateParameter(valid_614648, JString, required = true, default = newJString(
      "Lightsail_20161128.ReleaseStaticIp"))
  if valid_614648 != nil:
    section.add "X-Amz-Target", valid_614648
  var valid_614649 = header.getOrDefault("X-Amz-Signature")
  valid_614649 = validateParameter(valid_614649, JString, required = false,
                                 default = nil)
  if valid_614649 != nil:
    section.add "X-Amz-Signature", valid_614649
  var valid_614650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614650 = validateParameter(valid_614650, JString, required = false,
                                 default = nil)
  if valid_614650 != nil:
    section.add "X-Amz-Content-Sha256", valid_614650
  var valid_614651 = header.getOrDefault("X-Amz-Date")
  valid_614651 = validateParameter(valid_614651, JString, required = false,
                                 default = nil)
  if valid_614651 != nil:
    section.add "X-Amz-Date", valid_614651
  var valid_614652 = header.getOrDefault("X-Amz-Credential")
  valid_614652 = validateParameter(valid_614652, JString, required = false,
                                 default = nil)
  if valid_614652 != nil:
    section.add "X-Amz-Credential", valid_614652
  var valid_614653 = header.getOrDefault("X-Amz-Security-Token")
  valid_614653 = validateParameter(valid_614653, JString, required = false,
                                 default = nil)
  if valid_614653 != nil:
    section.add "X-Amz-Security-Token", valid_614653
  var valid_614654 = header.getOrDefault("X-Amz-Algorithm")
  valid_614654 = validateParameter(valid_614654, JString, required = false,
                                 default = nil)
  if valid_614654 != nil:
    section.add "X-Amz-Algorithm", valid_614654
  var valid_614655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614655 = validateParameter(valid_614655, JString, required = false,
                                 default = nil)
  if valid_614655 != nil:
    section.add "X-Amz-SignedHeaders", valid_614655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614657: Call_ReleaseStaticIp_614645; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specific static IP from your account.
  ## 
  let valid = call_614657.validator(path, query, header, formData, body)
  let scheme = call_614657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614657.url(scheme.get, call_614657.host, call_614657.base,
                         call_614657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614657, url, valid)

proc call*(call_614658: Call_ReleaseStaticIp_614645; body: JsonNode): Recallable =
  ## releaseStaticIp
  ## Deletes a specific static IP from your account.
  ##   body: JObject (required)
  var body_614659 = newJObject()
  if body != nil:
    body_614659 = body
  result = call_614658.call(nil, nil, nil, nil, body_614659)

var releaseStaticIp* = Call_ReleaseStaticIp_614645(name: "releaseStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ReleaseStaticIp",
    validator: validate_ReleaseStaticIp_614646, base: "/", url: url_ReleaseStaticIp_614647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartInstance_614660 = ref object of OpenApiRestCall_612658
proc url_StartInstance_614662(protocol: Scheme; host: string; base: string;
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

proc validate_StartInstance_614661(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614663 = header.getOrDefault("X-Amz-Target")
  valid_614663 = validateParameter(valid_614663, JString, required = true, default = newJString(
      "Lightsail_20161128.StartInstance"))
  if valid_614663 != nil:
    section.add "X-Amz-Target", valid_614663
  var valid_614664 = header.getOrDefault("X-Amz-Signature")
  valid_614664 = validateParameter(valid_614664, JString, required = false,
                                 default = nil)
  if valid_614664 != nil:
    section.add "X-Amz-Signature", valid_614664
  var valid_614665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614665 = validateParameter(valid_614665, JString, required = false,
                                 default = nil)
  if valid_614665 != nil:
    section.add "X-Amz-Content-Sha256", valid_614665
  var valid_614666 = header.getOrDefault("X-Amz-Date")
  valid_614666 = validateParameter(valid_614666, JString, required = false,
                                 default = nil)
  if valid_614666 != nil:
    section.add "X-Amz-Date", valid_614666
  var valid_614667 = header.getOrDefault("X-Amz-Credential")
  valid_614667 = validateParameter(valid_614667, JString, required = false,
                                 default = nil)
  if valid_614667 != nil:
    section.add "X-Amz-Credential", valid_614667
  var valid_614668 = header.getOrDefault("X-Amz-Security-Token")
  valid_614668 = validateParameter(valid_614668, JString, required = false,
                                 default = nil)
  if valid_614668 != nil:
    section.add "X-Amz-Security-Token", valid_614668
  var valid_614669 = header.getOrDefault("X-Amz-Algorithm")
  valid_614669 = validateParameter(valid_614669, JString, required = false,
                                 default = nil)
  if valid_614669 != nil:
    section.add "X-Amz-Algorithm", valid_614669
  var valid_614670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614670 = validateParameter(valid_614670, JString, required = false,
                                 default = nil)
  if valid_614670 != nil:
    section.add "X-Amz-SignedHeaders", valid_614670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614672: Call_StartInstance_614660; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614672.validator(path, query, header, formData, body)
  let scheme = call_614672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614672.url(scheme.get, call_614672.host, call_614672.base,
                         call_614672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614672, url, valid)

proc call*(call_614673: Call_StartInstance_614660; body: JsonNode): Recallable =
  ## startInstance
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614674 = newJObject()
  if body != nil:
    body_614674 = body
  result = call_614673.call(nil, nil, nil, nil, body_614674)

var startInstance* = Call_StartInstance_614660(name: "startInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StartInstance",
    validator: validate_StartInstance_614661, base: "/", url: url_StartInstance_614662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRelationalDatabase_614675 = ref object of OpenApiRestCall_612658
proc url_StartRelationalDatabase_614677(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_StartRelationalDatabase_614676(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the <code>reboot relational database</code> operation.</p> <p>The <code>start relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614678 = header.getOrDefault("X-Amz-Target")
  valid_614678 = validateParameter(valid_614678, JString, required = true, default = newJString(
      "Lightsail_20161128.StartRelationalDatabase"))
  if valid_614678 != nil:
    section.add "X-Amz-Target", valid_614678
  var valid_614679 = header.getOrDefault("X-Amz-Signature")
  valid_614679 = validateParameter(valid_614679, JString, required = false,
                                 default = nil)
  if valid_614679 != nil:
    section.add "X-Amz-Signature", valid_614679
  var valid_614680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614680 = validateParameter(valid_614680, JString, required = false,
                                 default = nil)
  if valid_614680 != nil:
    section.add "X-Amz-Content-Sha256", valid_614680
  var valid_614681 = header.getOrDefault("X-Amz-Date")
  valid_614681 = validateParameter(valid_614681, JString, required = false,
                                 default = nil)
  if valid_614681 != nil:
    section.add "X-Amz-Date", valid_614681
  var valid_614682 = header.getOrDefault("X-Amz-Credential")
  valid_614682 = validateParameter(valid_614682, JString, required = false,
                                 default = nil)
  if valid_614682 != nil:
    section.add "X-Amz-Credential", valid_614682
  var valid_614683 = header.getOrDefault("X-Amz-Security-Token")
  valid_614683 = validateParameter(valid_614683, JString, required = false,
                                 default = nil)
  if valid_614683 != nil:
    section.add "X-Amz-Security-Token", valid_614683
  var valid_614684 = header.getOrDefault("X-Amz-Algorithm")
  valid_614684 = validateParameter(valid_614684, JString, required = false,
                                 default = nil)
  if valid_614684 != nil:
    section.add "X-Amz-Algorithm", valid_614684
  var valid_614685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614685 = validateParameter(valid_614685, JString, required = false,
                                 default = nil)
  if valid_614685 != nil:
    section.add "X-Amz-SignedHeaders", valid_614685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614687: Call_StartRelationalDatabase_614675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the <code>reboot relational database</code> operation.</p> <p>The <code>start relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614687.validator(path, query, header, formData, body)
  let scheme = call_614687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614687.url(scheme.get, call_614687.host, call_614687.base,
                         call_614687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614687, url, valid)

proc call*(call_614688: Call_StartRelationalDatabase_614675; body: JsonNode): Recallable =
  ## startRelationalDatabase
  ## <p>Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the <code>reboot relational database</code> operation.</p> <p>The <code>start relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614689 = newJObject()
  if body != nil:
    body_614689 = body
  result = call_614688.call(nil, nil, nil, nil, body_614689)

var startRelationalDatabase* = Call_StartRelationalDatabase_614675(
    name: "startRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StartRelationalDatabase",
    validator: validate_StartRelationalDatabase_614676, base: "/",
    url: url_StartRelationalDatabase_614677, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopInstance_614690 = ref object of OpenApiRestCall_612658
proc url_StopInstance_614692(protocol: Scheme; host: string; base: string;
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

proc validate_StopInstance_614691(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614693 = header.getOrDefault("X-Amz-Target")
  valid_614693 = validateParameter(valid_614693, JString, required = true, default = newJString(
      "Lightsail_20161128.StopInstance"))
  if valid_614693 != nil:
    section.add "X-Amz-Target", valid_614693
  var valid_614694 = header.getOrDefault("X-Amz-Signature")
  valid_614694 = validateParameter(valid_614694, JString, required = false,
                                 default = nil)
  if valid_614694 != nil:
    section.add "X-Amz-Signature", valid_614694
  var valid_614695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614695 = validateParameter(valid_614695, JString, required = false,
                                 default = nil)
  if valid_614695 != nil:
    section.add "X-Amz-Content-Sha256", valid_614695
  var valid_614696 = header.getOrDefault("X-Amz-Date")
  valid_614696 = validateParameter(valid_614696, JString, required = false,
                                 default = nil)
  if valid_614696 != nil:
    section.add "X-Amz-Date", valid_614696
  var valid_614697 = header.getOrDefault("X-Amz-Credential")
  valid_614697 = validateParameter(valid_614697, JString, required = false,
                                 default = nil)
  if valid_614697 != nil:
    section.add "X-Amz-Credential", valid_614697
  var valid_614698 = header.getOrDefault("X-Amz-Security-Token")
  valid_614698 = validateParameter(valid_614698, JString, required = false,
                                 default = nil)
  if valid_614698 != nil:
    section.add "X-Amz-Security-Token", valid_614698
  var valid_614699 = header.getOrDefault("X-Amz-Algorithm")
  valid_614699 = validateParameter(valid_614699, JString, required = false,
                                 default = nil)
  if valid_614699 != nil:
    section.add "X-Amz-Algorithm", valid_614699
  var valid_614700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614700 = validateParameter(valid_614700, JString, required = false,
                                 default = nil)
  if valid_614700 != nil:
    section.add "X-Amz-SignedHeaders", valid_614700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614702: Call_StopInstance_614690; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614702.validator(path, query, header, formData, body)
  let scheme = call_614702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614702.url(scheme.get, call_614702.host, call_614702.base,
                         call_614702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614702, url, valid)

proc call*(call_614703: Call_StopInstance_614690; body: JsonNode): Recallable =
  ## stopInstance
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614704 = newJObject()
  if body != nil:
    body_614704 = body
  result = call_614703.call(nil, nil, nil, nil, body_614704)

var stopInstance* = Call_StopInstance_614690(name: "stopInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StopInstance",
    validator: validate_StopInstance_614691, base: "/", url: url_StopInstance_614692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRelationalDatabase_614705 = ref object of OpenApiRestCall_612658
proc url_StopRelationalDatabase_614707(protocol: Scheme; host: string; base: string;
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

proc validate_StopRelationalDatabase_614706(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops a specific database that is currently running in Amazon Lightsail.</p> <p>The <code>stop relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614708 = header.getOrDefault("X-Amz-Target")
  valid_614708 = validateParameter(valid_614708, JString, required = true, default = newJString(
      "Lightsail_20161128.StopRelationalDatabase"))
  if valid_614708 != nil:
    section.add "X-Amz-Target", valid_614708
  var valid_614709 = header.getOrDefault("X-Amz-Signature")
  valid_614709 = validateParameter(valid_614709, JString, required = false,
                                 default = nil)
  if valid_614709 != nil:
    section.add "X-Amz-Signature", valid_614709
  var valid_614710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614710 = validateParameter(valid_614710, JString, required = false,
                                 default = nil)
  if valid_614710 != nil:
    section.add "X-Amz-Content-Sha256", valid_614710
  var valid_614711 = header.getOrDefault("X-Amz-Date")
  valid_614711 = validateParameter(valid_614711, JString, required = false,
                                 default = nil)
  if valid_614711 != nil:
    section.add "X-Amz-Date", valid_614711
  var valid_614712 = header.getOrDefault("X-Amz-Credential")
  valid_614712 = validateParameter(valid_614712, JString, required = false,
                                 default = nil)
  if valid_614712 != nil:
    section.add "X-Amz-Credential", valid_614712
  var valid_614713 = header.getOrDefault("X-Amz-Security-Token")
  valid_614713 = validateParameter(valid_614713, JString, required = false,
                                 default = nil)
  if valid_614713 != nil:
    section.add "X-Amz-Security-Token", valid_614713
  var valid_614714 = header.getOrDefault("X-Amz-Algorithm")
  valid_614714 = validateParameter(valid_614714, JString, required = false,
                                 default = nil)
  if valid_614714 != nil:
    section.add "X-Amz-Algorithm", valid_614714
  var valid_614715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614715 = validateParameter(valid_614715, JString, required = false,
                                 default = nil)
  if valid_614715 != nil:
    section.add "X-Amz-SignedHeaders", valid_614715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614717: Call_StopRelationalDatabase_614705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a specific database that is currently running in Amazon Lightsail.</p> <p>The <code>stop relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614717.validator(path, query, header, formData, body)
  let scheme = call_614717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614717.url(scheme.get, call_614717.host, call_614717.base,
                         call_614717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614717, url, valid)

proc call*(call_614718: Call_StopRelationalDatabase_614705; body: JsonNode): Recallable =
  ## stopRelationalDatabase
  ## <p>Stops a specific database that is currently running in Amazon Lightsail.</p> <p>The <code>stop relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614719 = newJObject()
  if body != nil:
    body_614719 = body
  result = call_614718.call(nil, nil, nil, nil, body_614719)

var stopRelationalDatabase* = Call_StopRelationalDatabase_614705(
    name: "stopRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StopRelationalDatabase",
    validator: validate_StopRelationalDatabase_614706, base: "/",
    url: url_StopRelationalDatabase_614707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_614720 = ref object of OpenApiRestCall_612658
proc url_TagResource_614722(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_614721(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-tags">Lightsail Dev Guide</a>.</p> <p>The <code>tag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614723 = header.getOrDefault("X-Amz-Target")
  valid_614723 = validateParameter(valid_614723, JString, required = true, default = newJString(
      "Lightsail_20161128.TagResource"))
  if valid_614723 != nil:
    section.add "X-Amz-Target", valid_614723
  var valid_614724 = header.getOrDefault("X-Amz-Signature")
  valid_614724 = validateParameter(valid_614724, JString, required = false,
                                 default = nil)
  if valid_614724 != nil:
    section.add "X-Amz-Signature", valid_614724
  var valid_614725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614725 = validateParameter(valid_614725, JString, required = false,
                                 default = nil)
  if valid_614725 != nil:
    section.add "X-Amz-Content-Sha256", valid_614725
  var valid_614726 = header.getOrDefault("X-Amz-Date")
  valid_614726 = validateParameter(valid_614726, JString, required = false,
                                 default = nil)
  if valid_614726 != nil:
    section.add "X-Amz-Date", valid_614726
  var valid_614727 = header.getOrDefault("X-Amz-Credential")
  valid_614727 = validateParameter(valid_614727, JString, required = false,
                                 default = nil)
  if valid_614727 != nil:
    section.add "X-Amz-Credential", valid_614727
  var valid_614728 = header.getOrDefault("X-Amz-Security-Token")
  valid_614728 = validateParameter(valid_614728, JString, required = false,
                                 default = nil)
  if valid_614728 != nil:
    section.add "X-Amz-Security-Token", valid_614728
  var valid_614729 = header.getOrDefault("X-Amz-Algorithm")
  valid_614729 = validateParameter(valid_614729, JString, required = false,
                                 default = nil)
  if valid_614729 != nil:
    section.add "X-Amz-Algorithm", valid_614729
  var valid_614730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614730 = validateParameter(valid_614730, JString, required = false,
                                 default = nil)
  if valid_614730 != nil:
    section.add "X-Amz-SignedHeaders", valid_614730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614732: Call_TagResource_614720; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-tags">Lightsail Dev Guide</a>.</p> <p>The <code>tag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614732.validator(path, query, header, formData, body)
  let scheme = call_614732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614732.url(scheme.get, call_614732.host, call_614732.base,
                         call_614732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614732, url, valid)

proc call*(call_614733: Call_TagResource_614720; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-tags">Lightsail Dev Guide</a>.</p> <p>The <code>tag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614734 = newJObject()
  if body != nil:
    body_614734 = body
  result = call_614733.call(nil, nil, nil, nil, body_614734)

var tagResource* = Call_TagResource_614720(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.TagResource",
                                        validator: validate_TagResource_614721,
                                        base: "/", url: url_TagResource_614722,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnpeerVpc_614735 = ref object of OpenApiRestCall_612658
proc url_UnpeerVpc_614737(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UnpeerVpc_614736(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to unpeer the Lightsail VPC from the user's default VPC.
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
  var valid_614738 = header.getOrDefault("X-Amz-Target")
  valid_614738 = validateParameter(valid_614738, JString, required = true, default = newJString(
      "Lightsail_20161128.UnpeerVpc"))
  if valid_614738 != nil:
    section.add "X-Amz-Target", valid_614738
  var valid_614739 = header.getOrDefault("X-Amz-Signature")
  valid_614739 = validateParameter(valid_614739, JString, required = false,
                                 default = nil)
  if valid_614739 != nil:
    section.add "X-Amz-Signature", valid_614739
  var valid_614740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614740 = validateParameter(valid_614740, JString, required = false,
                                 default = nil)
  if valid_614740 != nil:
    section.add "X-Amz-Content-Sha256", valid_614740
  var valid_614741 = header.getOrDefault("X-Amz-Date")
  valid_614741 = validateParameter(valid_614741, JString, required = false,
                                 default = nil)
  if valid_614741 != nil:
    section.add "X-Amz-Date", valid_614741
  var valid_614742 = header.getOrDefault("X-Amz-Credential")
  valid_614742 = validateParameter(valid_614742, JString, required = false,
                                 default = nil)
  if valid_614742 != nil:
    section.add "X-Amz-Credential", valid_614742
  var valid_614743 = header.getOrDefault("X-Amz-Security-Token")
  valid_614743 = validateParameter(valid_614743, JString, required = false,
                                 default = nil)
  if valid_614743 != nil:
    section.add "X-Amz-Security-Token", valid_614743
  var valid_614744 = header.getOrDefault("X-Amz-Algorithm")
  valid_614744 = validateParameter(valid_614744, JString, required = false,
                                 default = nil)
  if valid_614744 != nil:
    section.add "X-Amz-Algorithm", valid_614744
  var valid_614745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614745 = validateParameter(valid_614745, JString, required = false,
                                 default = nil)
  if valid_614745 != nil:
    section.add "X-Amz-SignedHeaders", valid_614745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614747: Call_UnpeerVpc_614735; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to unpeer the Lightsail VPC from the user's default VPC.
  ## 
  let valid = call_614747.validator(path, query, header, formData, body)
  let scheme = call_614747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614747.url(scheme.get, call_614747.host, call_614747.base,
                         call_614747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614747, url, valid)

proc call*(call_614748: Call_UnpeerVpc_614735; body: JsonNode): Recallable =
  ## unpeerVpc
  ## Attempts to unpeer the Lightsail VPC from the user's default VPC.
  ##   body: JObject (required)
  var body_614749 = newJObject()
  if body != nil:
    body_614749 = body
  result = call_614748.call(nil, nil, nil, nil, body_614749)

var unpeerVpc* = Call_UnpeerVpc_614735(name: "unpeerVpc", meth: HttpMethod.HttpPost,
                                    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.UnpeerVpc",
                                    validator: validate_UnpeerVpc_614736,
                                    base: "/", url: url_UnpeerVpc_614737,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_614750 = ref object of OpenApiRestCall_612658
proc url_UntagResource_614752(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_614751(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614753 = header.getOrDefault("X-Amz-Target")
  valid_614753 = validateParameter(valid_614753, JString, required = true, default = newJString(
      "Lightsail_20161128.UntagResource"))
  if valid_614753 != nil:
    section.add "X-Amz-Target", valid_614753
  var valid_614754 = header.getOrDefault("X-Amz-Signature")
  valid_614754 = validateParameter(valid_614754, JString, required = false,
                                 default = nil)
  if valid_614754 != nil:
    section.add "X-Amz-Signature", valid_614754
  var valid_614755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614755 = validateParameter(valid_614755, JString, required = false,
                                 default = nil)
  if valid_614755 != nil:
    section.add "X-Amz-Content-Sha256", valid_614755
  var valid_614756 = header.getOrDefault("X-Amz-Date")
  valid_614756 = validateParameter(valid_614756, JString, required = false,
                                 default = nil)
  if valid_614756 != nil:
    section.add "X-Amz-Date", valid_614756
  var valid_614757 = header.getOrDefault("X-Amz-Credential")
  valid_614757 = validateParameter(valid_614757, JString, required = false,
                                 default = nil)
  if valid_614757 != nil:
    section.add "X-Amz-Credential", valid_614757
  var valid_614758 = header.getOrDefault("X-Amz-Security-Token")
  valid_614758 = validateParameter(valid_614758, JString, required = false,
                                 default = nil)
  if valid_614758 != nil:
    section.add "X-Amz-Security-Token", valid_614758
  var valid_614759 = header.getOrDefault("X-Amz-Algorithm")
  valid_614759 = validateParameter(valid_614759, JString, required = false,
                                 default = nil)
  if valid_614759 != nil:
    section.add "X-Amz-Algorithm", valid_614759
  var valid_614760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614760 = validateParameter(valid_614760, JString, required = false,
                                 default = nil)
  if valid_614760 != nil:
    section.add "X-Amz-SignedHeaders", valid_614760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614762: Call_UntagResource_614750; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614762.validator(path, query, header, formData, body)
  let scheme = call_614762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614762.url(scheme.get, call_614762.host, call_614762.base,
                         call_614762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614762, url, valid)

proc call*(call_614763: Call_UntagResource_614750; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614764 = newJObject()
  if body != nil:
    body_614764 = body
  result = call_614763.call(nil, nil, nil, nil, body_614764)

var untagResource* = Call_UntagResource_614750(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UntagResource",
    validator: validate_UntagResource_614751, base: "/", url: url_UntagResource_614752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainEntry_614765 = ref object of OpenApiRestCall_612658
proc url_UpdateDomainEntry_614767(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainEntry_614766(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates a domain recordset after it is created.</p> <p>The <code>update domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614768 = header.getOrDefault("X-Amz-Target")
  valid_614768 = validateParameter(valid_614768, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateDomainEntry"))
  if valid_614768 != nil:
    section.add "X-Amz-Target", valid_614768
  var valid_614769 = header.getOrDefault("X-Amz-Signature")
  valid_614769 = validateParameter(valid_614769, JString, required = false,
                                 default = nil)
  if valid_614769 != nil:
    section.add "X-Amz-Signature", valid_614769
  var valid_614770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614770 = validateParameter(valid_614770, JString, required = false,
                                 default = nil)
  if valid_614770 != nil:
    section.add "X-Amz-Content-Sha256", valid_614770
  var valid_614771 = header.getOrDefault("X-Amz-Date")
  valid_614771 = validateParameter(valid_614771, JString, required = false,
                                 default = nil)
  if valid_614771 != nil:
    section.add "X-Amz-Date", valid_614771
  var valid_614772 = header.getOrDefault("X-Amz-Credential")
  valid_614772 = validateParameter(valid_614772, JString, required = false,
                                 default = nil)
  if valid_614772 != nil:
    section.add "X-Amz-Credential", valid_614772
  var valid_614773 = header.getOrDefault("X-Amz-Security-Token")
  valid_614773 = validateParameter(valid_614773, JString, required = false,
                                 default = nil)
  if valid_614773 != nil:
    section.add "X-Amz-Security-Token", valid_614773
  var valid_614774 = header.getOrDefault("X-Amz-Algorithm")
  valid_614774 = validateParameter(valid_614774, JString, required = false,
                                 default = nil)
  if valid_614774 != nil:
    section.add "X-Amz-Algorithm", valid_614774
  var valid_614775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614775 = validateParameter(valid_614775, JString, required = false,
                                 default = nil)
  if valid_614775 != nil:
    section.add "X-Amz-SignedHeaders", valid_614775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614777: Call_UpdateDomainEntry_614765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a domain recordset after it is created.</p> <p>The <code>update domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614777.validator(path, query, header, formData, body)
  let scheme = call_614777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614777.url(scheme.get, call_614777.host, call_614777.base,
                         call_614777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614777, url, valid)

proc call*(call_614778: Call_UpdateDomainEntry_614765; body: JsonNode): Recallable =
  ## updateDomainEntry
  ## <p>Updates a domain recordset after it is created.</p> <p>The <code>update domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614779 = newJObject()
  if body != nil:
    body_614779 = body
  result = call_614778.call(nil, nil, nil, nil, body_614779)

var updateDomainEntry* = Call_UpdateDomainEntry_614765(name: "updateDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateDomainEntry",
    validator: validate_UpdateDomainEntry_614766, base: "/",
    url: url_UpdateDomainEntry_614767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoadBalancerAttribute_614780 = ref object of OpenApiRestCall_612658
proc url_UpdateLoadBalancerAttribute_614782(protocol: Scheme; host: string;
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

proc validate_UpdateLoadBalancerAttribute_614781(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614783 = header.getOrDefault("X-Amz-Target")
  valid_614783 = validateParameter(valid_614783, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateLoadBalancerAttribute"))
  if valid_614783 != nil:
    section.add "X-Amz-Target", valid_614783
  var valid_614784 = header.getOrDefault("X-Amz-Signature")
  valid_614784 = validateParameter(valid_614784, JString, required = false,
                                 default = nil)
  if valid_614784 != nil:
    section.add "X-Amz-Signature", valid_614784
  var valid_614785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614785 = validateParameter(valid_614785, JString, required = false,
                                 default = nil)
  if valid_614785 != nil:
    section.add "X-Amz-Content-Sha256", valid_614785
  var valid_614786 = header.getOrDefault("X-Amz-Date")
  valid_614786 = validateParameter(valid_614786, JString, required = false,
                                 default = nil)
  if valid_614786 != nil:
    section.add "X-Amz-Date", valid_614786
  var valid_614787 = header.getOrDefault("X-Amz-Credential")
  valid_614787 = validateParameter(valid_614787, JString, required = false,
                                 default = nil)
  if valid_614787 != nil:
    section.add "X-Amz-Credential", valid_614787
  var valid_614788 = header.getOrDefault("X-Amz-Security-Token")
  valid_614788 = validateParameter(valid_614788, JString, required = false,
                                 default = nil)
  if valid_614788 != nil:
    section.add "X-Amz-Security-Token", valid_614788
  var valid_614789 = header.getOrDefault("X-Amz-Algorithm")
  valid_614789 = validateParameter(valid_614789, JString, required = false,
                                 default = nil)
  if valid_614789 != nil:
    section.add "X-Amz-Algorithm", valid_614789
  var valid_614790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614790 = validateParameter(valid_614790, JString, required = false,
                                 default = nil)
  if valid_614790 != nil:
    section.add "X-Amz-SignedHeaders", valid_614790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614792: Call_UpdateLoadBalancerAttribute_614780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614792.validator(path, query, header, formData, body)
  let scheme = call_614792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614792.url(scheme.get, call_614792.host, call_614792.base,
                         call_614792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614792, url, valid)

proc call*(call_614793: Call_UpdateLoadBalancerAttribute_614780; body: JsonNode): Recallable =
  ## updateLoadBalancerAttribute
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614794 = newJObject()
  if body != nil:
    body_614794 = body
  result = call_614793.call(nil, nil, nil, nil, body_614794)

var updateLoadBalancerAttribute* = Call_UpdateLoadBalancerAttribute_614780(
    name: "updateLoadBalancerAttribute", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateLoadBalancerAttribute",
    validator: validate_UpdateLoadBalancerAttribute_614781, base: "/",
    url: url_UpdateLoadBalancerAttribute_614782,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRelationalDatabase_614795 = ref object of OpenApiRestCall_612658
proc url_UpdateRelationalDatabase_614797(protocol: Scheme; host: string;
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

proc validate_UpdateRelationalDatabase_614796(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614798 = header.getOrDefault("X-Amz-Target")
  valid_614798 = validateParameter(valid_614798, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateRelationalDatabase"))
  if valid_614798 != nil:
    section.add "X-Amz-Target", valid_614798
  var valid_614799 = header.getOrDefault("X-Amz-Signature")
  valid_614799 = validateParameter(valid_614799, JString, required = false,
                                 default = nil)
  if valid_614799 != nil:
    section.add "X-Amz-Signature", valid_614799
  var valid_614800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614800 = validateParameter(valid_614800, JString, required = false,
                                 default = nil)
  if valid_614800 != nil:
    section.add "X-Amz-Content-Sha256", valid_614800
  var valid_614801 = header.getOrDefault("X-Amz-Date")
  valid_614801 = validateParameter(valid_614801, JString, required = false,
                                 default = nil)
  if valid_614801 != nil:
    section.add "X-Amz-Date", valid_614801
  var valid_614802 = header.getOrDefault("X-Amz-Credential")
  valid_614802 = validateParameter(valid_614802, JString, required = false,
                                 default = nil)
  if valid_614802 != nil:
    section.add "X-Amz-Credential", valid_614802
  var valid_614803 = header.getOrDefault("X-Amz-Security-Token")
  valid_614803 = validateParameter(valid_614803, JString, required = false,
                                 default = nil)
  if valid_614803 != nil:
    section.add "X-Amz-Security-Token", valid_614803
  var valid_614804 = header.getOrDefault("X-Amz-Algorithm")
  valid_614804 = validateParameter(valid_614804, JString, required = false,
                                 default = nil)
  if valid_614804 != nil:
    section.add "X-Amz-Algorithm", valid_614804
  var valid_614805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614805 = validateParameter(valid_614805, JString, required = false,
                                 default = nil)
  if valid_614805 != nil:
    section.add "X-Amz-SignedHeaders", valid_614805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614807: Call_UpdateRelationalDatabase_614795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614807.validator(path, query, header, formData, body)
  let scheme = call_614807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614807.url(scheme.get, call_614807.host, call_614807.base,
                         call_614807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614807, url, valid)

proc call*(call_614808: Call_UpdateRelationalDatabase_614795; body: JsonNode): Recallable =
  ## updateRelationalDatabase
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614809 = newJObject()
  if body != nil:
    body_614809 = body
  result = call_614808.call(nil, nil, nil, nil, body_614809)

var updateRelationalDatabase* = Call_UpdateRelationalDatabase_614795(
    name: "updateRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateRelationalDatabase",
    validator: validate_UpdateRelationalDatabase_614796, base: "/",
    url: url_UpdateRelationalDatabase_614797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRelationalDatabaseParameters_614810 = ref object of OpenApiRestCall_612658
proc url_UpdateRelationalDatabaseParameters_614812(protocol: Scheme; host: string;
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

proc validate_UpdateRelationalDatabaseParameters_614811(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which parameter updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_614813 = header.getOrDefault("X-Amz-Target")
  valid_614813 = validateParameter(valid_614813, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateRelationalDatabaseParameters"))
  if valid_614813 != nil:
    section.add "X-Amz-Target", valid_614813
  var valid_614814 = header.getOrDefault("X-Amz-Signature")
  valid_614814 = validateParameter(valid_614814, JString, required = false,
                                 default = nil)
  if valid_614814 != nil:
    section.add "X-Amz-Signature", valid_614814
  var valid_614815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614815 = validateParameter(valid_614815, JString, required = false,
                                 default = nil)
  if valid_614815 != nil:
    section.add "X-Amz-Content-Sha256", valid_614815
  var valid_614816 = header.getOrDefault("X-Amz-Date")
  valid_614816 = validateParameter(valid_614816, JString, required = false,
                                 default = nil)
  if valid_614816 != nil:
    section.add "X-Amz-Date", valid_614816
  var valid_614817 = header.getOrDefault("X-Amz-Credential")
  valid_614817 = validateParameter(valid_614817, JString, required = false,
                                 default = nil)
  if valid_614817 != nil:
    section.add "X-Amz-Credential", valid_614817
  var valid_614818 = header.getOrDefault("X-Amz-Security-Token")
  valid_614818 = validateParameter(valid_614818, JString, required = false,
                                 default = nil)
  if valid_614818 != nil:
    section.add "X-Amz-Security-Token", valid_614818
  var valid_614819 = header.getOrDefault("X-Amz-Algorithm")
  valid_614819 = validateParameter(valid_614819, JString, required = false,
                                 default = nil)
  if valid_614819 != nil:
    section.add "X-Amz-Algorithm", valid_614819
  var valid_614820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614820 = validateParameter(valid_614820, JString, required = false,
                                 default = nil)
  if valid_614820 != nil:
    section.add "X-Amz-SignedHeaders", valid_614820
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614822: Call_UpdateRelationalDatabaseParameters_614810;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which parameter updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_614822.validator(path, query, header, formData, body)
  let scheme = call_614822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614822.url(scheme.get, call_614822.host, call_614822.base,
                         call_614822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614822, url, valid)

proc call*(call_614823: Call_UpdateRelationalDatabaseParameters_614810;
          body: JsonNode): Recallable =
  ## updateRelationalDatabaseParameters
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which parameter updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_614824 = newJObject()
  if body != nil:
    body_614824 = body
  result = call_614823.call(nil, nil, nil, nil, body_614824)

var updateRelationalDatabaseParameters* = Call_UpdateRelationalDatabaseParameters_614810(
    name: "updateRelationalDatabaseParameters", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.UpdateRelationalDatabaseParameters",
    validator: validate_UpdateRelationalDatabaseParameters_614811, base: "/",
    url: url_UpdateRelationalDatabaseParameters_614812,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
