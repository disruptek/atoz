
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "lightsail.ap-northeast-1.amazonaws.com", "ap-southeast-1": "lightsail.ap-southeast-1.amazonaws.com", "us-west-2": "lightsail.us-west-2.amazonaws.com", "eu-west-2": "lightsail.eu-west-2.amazonaws.com", "ap-northeast-3": "lightsail.ap-northeast-3.amazonaws.com", "eu-central-1": "lightsail.eu-central-1.amazonaws.com", "us-east-2": "lightsail.us-east-2.amazonaws.com", "us-east-1": "lightsail.us-east-1.amazonaws.com", "cn-northwest-1": "lightsail.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "lightsail.ap-south-1.amazonaws.com", "eu-north-1": "lightsail.eu-north-1.amazonaws.com", "ap-northeast-2": "lightsail.ap-northeast-2.amazonaws.com", "us-west-1": "lightsail.us-west-1.amazonaws.com", "us-gov-east-1": "lightsail.us-gov-east-1.amazonaws.com", "eu-west-3": "lightsail.eu-west-3.amazonaws.com", "cn-north-1": "lightsail.cn-north-1.amazonaws.com.cn", "sa-east-1": "lightsail.sa-east-1.amazonaws.com", "eu-west-1": "lightsail.eu-west-1.amazonaws.com", "us-gov-west-1": "lightsail.us-gov-west-1.amazonaws.com", "ap-southeast-2": "lightsail.ap-southeast-2.amazonaws.com", "ca-central-1": "lightsail.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AllocateStaticIp_402656294 = ref object of OpenApiRestCall_402656044
proc url_AllocateStaticIp_402656296(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocateStaticIp_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "Lightsail_20161128.AllocateStaticIp"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656412: Call_AllocateStaticIp_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allocates a static IP address.
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_AllocateStaticIp_402656294; body: JsonNode): Recallable =
  ## allocateStaticIp
  ## Allocates a static IP address.
  ##   body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var allocateStaticIp* = Call_AllocateStaticIp_402656294(
    name: "allocateStaticIp", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AllocateStaticIp",
    validator: validate_AllocateStaticIp_402656295, base: "/",
    makeUrl: url_AllocateStaticIp_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachDisk_402656489 = ref object of OpenApiRestCall_402656044
proc url_AttachDisk_402656491(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachDisk_402656490(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachDisk"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656501: Call_AttachDisk_402656489; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name.</p> <p>The <code>attach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_AttachDisk_402656489; body: JsonNode): Recallable =
  ## attachDisk
  ## <p>Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name.</p> <p>The <code>attach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var attachDisk* = Call_AttachDisk_402656489(name: "attachDisk",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AttachDisk",
    validator: validate_AttachDisk_402656490, base: "/",
    makeUrl: url_AttachDisk_402656491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachInstancesToLoadBalancer_402656504 = ref object of OpenApiRestCall_402656044
proc url_AttachInstancesToLoadBalancer_402656506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachInstancesToLoadBalancer_402656505(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachInstancesToLoadBalancer"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_AttachInstancesToLoadBalancer_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches one or more Lightsail instances to a load balancer.</p> <p>After some time, the instances are attached to the load balancer and the health check status is available.</p> <p>The <code>attach instances to load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_AttachInstancesToLoadBalancer_402656504;
           body: JsonNode): Recallable =
  ## attachInstancesToLoadBalancer
  ## <p>Attaches one or more Lightsail instances to a load balancer.</p> <p>After some time, the instances are attached to the load balancer and the health check status is available.</p> <p>The <code>attach instances to load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var attachInstancesToLoadBalancer* = Call_AttachInstancesToLoadBalancer_402656504(
    name: "attachInstancesToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AttachInstancesToLoadBalancer",
    validator: validate_AttachInstancesToLoadBalancer_402656505, base: "/",
    makeUrl: url_AttachInstancesToLoadBalancer_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachLoadBalancerTlsCertificate_402656519 = ref object of OpenApiRestCall_402656044
proc url_AttachLoadBalancerTlsCertificate_402656521(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachLoadBalancerTlsCertificate_402656520(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>AttachLoadBalancerTlsCertificate</code> action with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>AttachLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachLoadBalancerTlsCertificate"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_AttachLoadBalancerTlsCertificate_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>AttachLoadBalancerTlsCertificate</code> action with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>AttachLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_AttachLoadBalancerTlsCertificate_402656519;
           body: JsonNode): Recallable =
  ## attachLoadBalancerTlsCertificate
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>AttachLoadBalancerTlsCertificate</code> action with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>AttachLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var attachLoadBalancerTlsCertificate* = Call_AttachLoadBalancerTlsCertificate_402656519(
    name: "attachLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.AttachLoadBalancerTlsCertificate",
    validator: validate_AttachLoadBalancerTlsCertificate_402656520, base: "/",
    makeUrl: url_AttachLoadBalancerTlsCertificate_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachStaticIp_402656534 = ref object of OpenApiRestCall_402656044
proc url_AttachStaticIp_402656536(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachStaticIp_402656535(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachStaticIp"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656546: Call_AttachStaticIp_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attaches a static IP address to a specific Amazon Lightsail instance.
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_AttachStaticIp_402656534; body: JsonNode): Recallable =
  ## attachStaticIp
  ## Attaches a static IP address to a specific Amazon Lightsail instance.
  ##   body: 
                                                                          ## JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var attachStaticIp* = Call_AttachStaticIp_402656534(name: "attachStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AttachStaticIp",
    validator: validate_AttachStaticIp_402656535, base: "/",
    makeUrl: url_AttachStaticIp_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CloseInstancePublicPorts_402656549 = ref object of OpenApiRestCall_402656044
proc url_CloseInstancePublicPorts_402656551(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CloseInstancePublicPorts_402656550(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "Lightsail_20161128.CloseInstancePublicPorts"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656561: Call_CloseInstancePublicPorts_402656549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_CloseInstancePublicPorts_402656549;
           body: JsonNode): Recallable =
  ## closeInstancePublicPorts
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var closeInstancePublicPorts* = Call_CloseInstancePublicPorts_402656549(
    name: "closeInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CloseInstancePublicPorts",
    validator: validate_CloseInstancePublicPorts_402656550, base: "/",
    makeUrl: url_CloseInstancePublicPorts_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopySnapshot_402656564 = ref object of OpenApiRestCall_402656044
proc url_CopySnapshot_402656566(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CopySnapshot_402656565(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "Lightsail_20161128.CopySnapshot"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656576: Call_CopySnapshot_402656564; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Copies a manual snapshot of an instance or disk as another manual snapshot, or copies an automatic snapshot of an instance or disk as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p>
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_CopySnapshot_402656564; body: JsonNode): Recallable =
  ## copySnapshot
  ## <p>Copies a manual snapshot of an instance or disk as another manual snapshot, or copies an automatic snapshot of an instance or disk as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var copySnapshot* = Call_CopySnapshot_402656564(name: "copySnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CopySnapshot",
    validator: validate_CopySnapshot_402656565, base: "/",
    makeUrl: url_CopySnapshot_402656566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationStack_402656579 = ref object of OpenApiRestCall_402656044
proc url_CreateCloudFormationStack_402656581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCloudFormationStack_402656580(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateCloudFormationStack"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_CreateCloudFormationStack_402656579;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_CreateCloudFormationStack_402656579;
           body: JsonNode): Recallable =
  ## createCloudFormationStack
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var createCloudFormationStack* = Call_CreateCloudFormationStack_402656579(
    name: "createCloudFormationStack", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateCloudFormationStack",
    validator: validate_CreateCloudFormationStack_402656580, base: "/",
    makeUrl: url_CreateCloudFormationStack_402656581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateContactMethod_402656594 = ref object of OpenApiRestCall_402656044
proc url_CreateContactMethod_402656596(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateContactMethod_402656595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an email or SMS text message contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateContactMethod"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656606: Call_CreateContactMethod_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an email or SMS text message contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_CreateContactMethod_402656594; body: JsonNode): Recallable =
  ## createContactMethod
  ## <p>Creates an email or SMS text message contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var createContactMethod* = Call_CreateContactMethod_402656594(
    name: "createContactMethod", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateContactMethod",
    validator: validate_CreateContactMethod_402656595, base: "/",
    makeUrl: url_CreateContactMethod_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDisk_402656609 = ref object of OpenApiRestCall_402656044
proc url_CreateDisk_402656611(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDisk_402656610(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDisk"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656621: Call_CreateDisk_402656609; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_CreateDisk_402656609; body: JsonNode): Recallable =
  ## createDisk
  ## <p>Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var createDisk* = Call_CreateDisk_402656609(name: "createDisk",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDisk",
    validator: validate_CreateDisk_402656610, base: "/",
    makeUrl: url_CreateDisk_402656611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDiskFromSnapshot_402656624 = ref object of OpenApiRestCall_402656044
proc url_CreateDiskFromSnapshot_402656626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDiskFromSnapshot_402656625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDiskFromSnapshot"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_CreateDiskFromSnapshot_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_CreateDiskFromSnapshot_402656624; body: JsonNode): Recallable =
  ## createDiskFromSnapshot
  ## <p>Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var createDiskFromSnapshot* = Call_CreateDiskFromSnapshot_402656624(
    name: "createDiskFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDiskFromSnapshot",
    validator: validate_CreateDiskFromSnapshot_402656625, base: "/",
    makeUrl: url_CreateDiskFromSnapshot_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDiskSnapshot_402656639 = ref object of OpenApiRestCall_402656044
proc url_CreateDiskSnapshot_402656641(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDiskSnapshot_402656640(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDiskSnapshot"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_CreateDiskSnapshot_402656639;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance.</p> <p>You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending.</p> <p>You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the <code>instance name</code> parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk.</p> <p>The <code>create disk snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_CreateDiskSnapshot_402656639; body: JsonNode): Recallable =
  ## createDiskSnapshot
  ## <p>Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance.</p> <p>You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending.</p> <p>You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the <code>instance name</code> parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk.</p> <p>The <code>create disk snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var createDiskSnapshot* = Call_CreateDiskSnapshot_402656639(
    name: "createDiskSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDiskSnapshot",
    validator: validate_CreateDiskSnapshot_402656640, base: "/",
    makeUrl: url_CreateDiskSnapshot_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_402656654 = ref object of OpenApiRestCall_402656044
proc url_CreateDomain_402656656(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomain_402656655(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDomain"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_CreateDomain_402656654; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_CreateDomain_402656654; body: JsonNode): Recallable =
  ## createDomain
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var createDomain* = Call_CreateDomain_402656654(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDomain",
    validator: validate_CreateDomain_402656655, base: "/",
    makeUrl: url_CreateDomain_402656656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainEntry_402656669 = ref object of OpenApiRestCall_402656044
proc url_CreateDomainEntry_402656671(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomainEntry_402656670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDomainEntry"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656681: Call_CreateDomainEntry_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates one of the following entry records associated with the domain: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT).</p> <p>The <code>create domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_CreateDomainEntry_402656669; body: JsonNode): Recallable =
  ## createDomainEntry
  ## <p>Creates one of the following entry records associated with the domain: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT).</p> <p>The <code>create domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var createDomainEntry* = Call_CreateDomainEntry_402656669(
    name: "createDomainEntry", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDomainEntry",
    validator: validate_CreateDomainEntry_402656670, base: "/",
    makeUrl: url_CreateDomainEntry_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceSnapshot_402656684 = ref object of OpenApiRestCall_402656044
proc url_CreateInstanceSnapshot_402656686(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInstanceSnapshot_402656685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstanceSnapshot"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656696: Call_CreateInstanceSnapshot_402656684;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a snapshot of a specific virtual private server, or <i>instance</i>. You can use a snapshot to create a new instance that is based on that snapshot.</p> <p>The <code>create instance snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_CreateInstanceSnapshot_402656684; body: JsonNode): Recallable =
  ## createInstanceSnapshot
  ## <p>Creates a snapshot of a specific virtual private server, or <i>instance</i>. You can use a snapshot to create a new instance that is based on that snapshot.</p> <p>The <code>create instance snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var createInstanceSnapshot* = Call_CreateInstanceSnapshot_402656684(
    name: "createInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstanceSnapshot",
    validator: validate_CreateInstanceSnapshot_402656685, base: "/",
    makeUrl: url_CreateInstanceSnapshot_402656686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstances_402656699 = ref object of OpenApiRestCall_402656044
proc url_CreateInstances_402656701(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInstances_402656700(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656702 = header.getOrDefault("X-Amz-Target")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstances"))
  if valid_402656702 != nil:
    section.add "X-Amz-Target", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656711: Call_CreateInstances_402656699; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates one or more Amazon Lightsail instances.</p> <p>The <code>create instances</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_CreateInstances_402656699; body: JsonNode): Recallable =
  ## createInstances
  ## <p>Creates one or more Amazon Lightsail instances.</p> <p>The <code>create instances</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var createInstances* = Call_CreateInstances_402656699(name: "createInstances",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstances",
    validator: validate_CreateInstances_402656700, base: "/",
    makeUrl: url_CreateInstances_402656701, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstancesFromSnapshot_402656714 = ref object of OpenApiRestCall_402656044
proc url_CreateInstancesFromSnapshot_402656716(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInstancesFromSnapshot_402656715(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656717 = header.getOrDefault("X-Amz-Target")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstancesFromSnapshot"))
  if valid_402656717 != nil:
    section.add "X-Amz-Target", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656726: Call_CreateInstancesFromSnapshot_402656714;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_CreateInstancesFromSnapshot_402656714;
           body: JsonNode): Recallable =
  ## createInstancesFromSnapshot
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656728 = newJObject()
  if body != nil:
    body_402656728 = body
  result = call_402656727.call(nil, nil, nil, nil, body_402656728)

var createInstancesFromSnapshot* = Call_CreateInstancesFromSnapshot_402656714(
    name: "createInstancesFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstancesFromSnapshot",
    validator: validate_CreateInstancesFromSnapshot_402656715, base: "/",
    makeUrl: url_CreateInstancesFromSnapshot_402656716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateKeyPair_402656729 = ref object of OpenApiRestCall_402656044
proc url_CreateKeyPair_402656731(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateKeyPair_402656730(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateKeyPair"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656741: Call_CreateKeyPair_402656729; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_CreateKeyPair_402656729; body: JsonNode): Recallable =
  ## createKeyPair
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var createKeyPair* = Call_CreateKeyPair_402656729(name: "createKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateKeyPair",
    validator: validate_CreateKeyPair_402656730, base: "/",
    makeUrl: url_CreateKeyPair_402656731, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoadBalancer_402656744 = ref object of OpenApiRestCall_402656044
proc url_CreateLoadBalancer_402656746(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLoadBalancer_402656745(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656747 = header.getOrDefault("X-Amz-Target")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateLoadBalancer"))
  if valid_402656747 != nil:
    section.add "X-Amz-Target", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656756: Call_CreateLoadBalancer_402656744;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see <a href="https://lightsail.aws.amazon.com/ls/docs/how-to/article/configure-lightsail-instances-for-load-balancing">Configure your Lightsail instances for load balancing</a>. You can create up to 5 load balancers per AWS Region in your account.</p> <p>When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the <code>UpdateLoadBalancerAttribute</code> operation.</p> <p>The <code>create load balancer</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_CreateLoadBalancer_402656744; body: JsonNode): Recallable =
  ## createLoadBalancer
  ## <p>Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see <a href="https://lightsail.aws.amazon.com/ls/docs/how-to/article/configure-lightsail-instances-for-load-balancing">Configure your Lightsail instances for load balancing</a>. You can create up to 5 load balancers per AWS Region in your account.</p> <p>When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the <code>UpdateLoadBalancerAttribute</code> operation.</p> <p>The <code>create load balancer</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656758 = newJObject()
  if body != nil:
    body_402656758 = body
  result = call_402656757.call(nil, nil, nil, nil, body_402656758)

var createLoadBalancer* = Call_CreateLoadBalancer_402656744(
    name: "createLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateLoadBalancer",
    validator: validate_CreateLoadBalancer_402656745, base: "/",
    makeUrl: url_CreateLoadBalancer_402656746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoadBalancerTlsCertificate_402656759 = ref object of OpenApiRestCall_402656044
proc url_CreateLoadBalancerTlsCertificate_402656761(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLoadBalancerTlsCertificate_402656760(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>CreateLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656762 = header.getOrDefault("X-Amz-Target")
  valid_402656762 = validateParameter(valid_402656762, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateLoadBalancerTlsCertificate"))
  if valid_402656762 != nil:
    section.add "X-Amz-Target", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Security-Token", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Signature")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Signature", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Algorithm", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Date")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Date", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Credential")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Credential", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656771: Call_CreateLoadBalancerTlsCertificate_402656759;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>CreateLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_CreateLoadBalancerTlsCertificate_402656759;
           body: JsonNode): Recallable =
  ## createLoadBalancerTlsCertificate
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>CreateLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656773 = newJObject()
  if body != nil:
    body_402656773 = body
  result = call_402656772.call(nil, nil, nil, nil, body_402656773)

var createLoadBalancerTlsCertificate* = Call_CreateLoadBalancerTlsCertificate_402656759(
    name: "createLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateLoadBalancerTlsCertificate",
    validator: validate_CreateLoadBalancerTlsCertificate_402656760, base: "/",
    makeUrl: url_CreateLoadBalancerTlsCertificate_402656761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabase_402656774 = ref object of OpenApiRestCall_402656044
proc url_CreateRelationalDatabase_402656776(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRelationalDatabase_402656775(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656777 = header.getOrDefault("X-Amz-Target")
  valid_402656777 = validateParameter(valid_402656777, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabase"))
  if valid_402656777 != nil:
    section.add "X-Amz-Target", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Security-Token", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Signature")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Signature", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Algorithm", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Date")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Date", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Credential")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Credential", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656786: Call_CreateRelationalDatabase_402656774;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656786.validator(path, query, header, formData, body, _)
  let scheme = call_402656786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656786.makeUrl(scheme.get, call_402656786.host, call_402656786.base,
                                   call_402656786.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656786, uri, valid, _)

proc call*(call_402656787: Call_CreateRelationalDatabase_402656774;
           body: JsonNode): Recallable =
  ## createRelationalDatabase
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656788 = newJObject()
  if body != nil:
    body_402656788 = body
  result = call_402656787.call(nil, nil, nil, nil, body_402656788)

var createRelationalDatabase* = Call_CreateRelationalDatabase_402656774(
    name: "createRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabase",
    validator: validate_CreateRelationalDatabase_402656775, base: "/",
    makeUrl: url_CreateRelationalDatabase_402656776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabaseFromSnapshot_402656789 = ref object of OpenApiRestCall_402656044
proc url_CreateRelationalDatabaseFromSnapshot_402656791(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRelationalDatabaseFromSnapshot_402656790(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656792 = header.getOrDefault("X-Amz-Target")
  valid_402656792 = validateParameter(valid_402656792, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabaseFromSnapshot"))
  if valid_402656792 != nil:
    section.add "X-Amz-Target", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Security-Token", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Signature")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Signature", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Algorithm", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Date")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Date", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Credential")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Credential", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656801: Call_CreateRelationalDatabaseFromSnapshot_402656789;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new database from an existing database snapshot in Amazon Lightsail.</p> <p>You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan.</p> <p>The <code>create relational database from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656801.validator(path, query, header, formData, body, _)
  let scheme = call_402656801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656801.makeUrl(scheme.get, call_402656801.host, call_402656801.base,
                                   call_402656801.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656801, uri, valid, _)

proc call*(call_402656802: Call_CreateRelationalDatabaseFromSnapshot_402656789;
           body: JsonNode): Recallable =
  ## createRelationalDatabaseFromSnapshot
  ## <p>Creates a new database from an existing database snapshot in Amazon Lightsail.</p> <p>You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan.</p> <p>The <code>create relational database from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656803 = newJObject()
  if body != nil:
    body_402656803 = body
  result = call_402656802.call(nil, nil, nil, nil, body_402656803)

var createRelationalDatabaseFromSnapshot* = Call_CreateRelationalDatabaseFromSnapshot_402656789(
    name: "createRelationalDatabaseFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabaseFromSnapshot",
    validator: validate_CreateRelationalDatabaseFromSnapshot_402656790,
    base: "/", makeUrl: url_CreateRelationalDatabaseFromSnapshot_402656791,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabaseSnapshot_402656804 = ref object of OpenApiRestCall_402656044
proc url_CreateRelationalDatabaseSnapshot_402656806(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRelationalDatabaseSnapshot_402656805(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656807 = header.getOrDefault("X-Amz-Target")
  valid_402656807 = validateParameter(valid_402656807, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabaseSnapshot"))
  if valid_402656807 != nil:
    section.add "X-Amz-Target", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Security-Token", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Signature")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Signature", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Algorithm", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Date")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Date", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Credential")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Credential", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656816: Call_CreateRelationalDatabaseSnapshot_402656804;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database.</p> <p>The <code>create relational database snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656816.validator(path, query, header, formData, body, _)
  let scheme = call_402656816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656816.makeUrl(scheme.get, call_402656816.host, call_402656816.base,
                                   call_402656816.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656816, uri, valid, _)

proc call*(call_402656817: Call_CreateRelationalDatabaseSnapshot_402656804;
           body: JsonNode): Recallable =
  ## createRelationalDatabaseSnapshot
  ## <p>Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database.</p> <p>The <code>create relational database snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656818 = newJObject()
  if body != nil:
    body_402656818 = body
  result = call_402656817.call(nil, nil, nil, nil, body_402656818)

var createRelationalDatabaseSnapshot* = Call_CreateRelationalDatabaseSnapshot_402656804(
    name: "createRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabaseSnapshot",
    validator: validate_CreateRelationalDatabaseSnapshot_402656805, base: "/",
    makeUrl: url_CreateRelationalDatabaseSnapshot_402656806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlarm_402656819 = ref object of OpenApiRestCall_402656044
proc url_DeleteAlarm_402656821(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAlarm_402656820(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes an alarm.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656822 = header.getOrDefault("X-Amz-Target")
  valid_402656822 = validateParameter(valid_402656822, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteAlarm"))
  if valid_402656822 != nil:
    section.add "X-Amz-Target", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Security-Token", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Signature")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Signature", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Algorithm", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Date")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Date", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Credential")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Credential", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656831: Call_DeleteAlarm_402656819; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an alarm.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
                                                                                         ## 
  let valid = call_402656831.validator(path, query, header, formData, body, _)
  let scheme = call_402656831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656831.makeUrl(scheme.get, call_402656831.host, call_402656831.base,
                                   call_402656831.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656831, uri, valid, _)

proc call*(call_402656832: Call_DeleteAlarm_402656819; body: JsonNode): Recallable =
  ## deleteAlarm
  ## <p>Deletes an alarm.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656833 = newJObject()
  if body != nil:
    body_402656833 = body
  result = call_402656832.call(nil, nil, nil, nil, body_402656833)

var deleteAlarm* = Call_DeleteAlarm_402656819(name: "deleteAlarm",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteAlarm",
    validator: validate_DeleteAlarm_402656820, base: "/",
    makeUrl: url_DeleteAlarm_402656821, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAutoSnapshot_402656834 = ref object of OpenApiRestCall_402656044
proc url_DeleteAutoSnapshot_402656836(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAutoSnapshot_402656835(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656837 = header.getOrDefault("X-Amz-Target")
  valid_402656837 = validateParameter(valid_402656837, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteAutoSnapshot"))
  if valid_402656837 != nil:
    section.add "X-Amz-Target", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Security-Token", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Signature")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Signature", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Algorithm", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Date")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Date", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Credential")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Credential", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656846: Call_DeleteAutoSnapshot_402656834;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an automatic snapshot of an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
                                                                                         ## 
  let valid = call_402656846.validator(path, query, header, formData, body, _)
  let scheme = call_402656846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656846.makeUrl(scheme.get, call_402656846.host, call_402656846.base,
                                   call_402656846.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656846, uri, valid, _)

proc call*(call_402656847: Call_DeleteAutoSnapshot_402656834; body: JsonNode): Recallable =
  ## deleteAutoSnapshot
  ## Deletes an automatic snapshot of an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   
                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656848 = newJObject()
  if body != nil:
    body_402656848 = body
  result = call_402656847.call(nil, nil, nil, nil, body_402656848)

var deleteAutoSnapshot* = Call_DeleteAutoSnapshot_402656834(
    name: "deleteAutoSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteAutoSnapshot",
    validator: validate_DeleteAutoSnapshot_402656835, base: "/",
    makeUrl: url_DeleteAutoSnapshot_402656836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteContactMethod_402656849 = ref object of OpenApiRestCall_402656044
proc url_DeleteContactMethod_402656851(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteContactMethod_402656850(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656852 = header.getOrDefault("X-Amz-Target")
  valid_402656852 = validateParameter(valid_402656852, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteContactMethod"))
  if valid_402656852 != nil:
    section.add "X-Amz-Target", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Security-Token", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Signature")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Signature", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Algorithm", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Date")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Date", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Credential")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Credential", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656861: Call_DeleteContactMethod_402656849;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
                                                                                         ## 
  let valid = call_402656861.validator(path, query, header, formData, body, _)
  let scheme = call_402656861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656861.makeUrl(scheme.get, call_402656861.host, call_402656861.base,
                                   call_402656861.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656861, uri, valid, _)

proc call*(call_402656862: Call_DeleteContactMethod_402656849; body: JsonNode): Recallable =
  ## deleteContactMethod
  ## <p>Deletes a contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656863 = newJObject()
  if body != nil:
    body_402656863 = body
  result = call_402656862.call(nil, nil, nil, nil, body_402656863)

var deleteContactMethod* = Call_DeleteContactMethod_402656849(
    name: "deleteContactMethod", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteContactMethod",
    validator: validate_DeleteContactMethod_402656850, base: "/",
    makeUrl: url_DeleteContactMethod_402656851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDisk_402656864 = ref object of OpenApiRestCall_402656044
proc url_DeleteDisk_402656866(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDisk_402656865(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656867 = header.getOrDefault("X-Amz-Target")
  valid_402656867 = validateParameter(valid_402656867, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDisk"))
  if valid_402656867 != nil:
    section.add "X-Amz-Target", valid_402656867
  var valid_402656868 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656868 = validateParameter(valid_402656868, JString,
                                      required = false, default = nil)
  if valid_402656868 != nil:
    section.add "X-Amz-Security-Token", valid_402656868
  var valid_402656869 = header.getOrDefault("X-Amz-Signature")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-Signature", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Algorithm", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Date")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Date", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Credential")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Credential", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656876: Call_DeleteDisk_402656864; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified block storage disk. The disk must be in the <code>available</code> state (not attached to a Lightsail instance).</p> <note> <p>The disk may remain in the <code>deleting</code> state for several minutes.</p> </note> <p>The <code>delete disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656876.validator(path, query, header, formData, body, _)
  let scheme = call_402656876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656876.makeUrl(scheme.get, call_402656876.host, call_402656876.base,
                                   call_402656876.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656876, uri, valid, _)

proc call*(call_402656877: Call_DeleteDisk_402656864; body: JsonNode): Recallable =
  ## deleteDisk
  ## <p>Deletes the specified block storage disk. The disk must be in the <code>available</code> state (not attached to a Lightsail instance).</p> <note> <p>The disk may remain in the <code>deleting</code> state for several minutes.</p> </note> <p>The <code>delete disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656878 = newJObject()
  if body != nil:
    body_402656878 = body
  result = call_402656877.call(nil, nil, nil, nil, body_402656878)

var deleteDisk* = Call_DeleteDisk_402656864(name: "deleteDisk",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDisk",
    validator: validate_DeleteDisk_402656865, base: "/",
    makeUrl: url_DeleteDisk_402656866, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiskSnapshot_402656879 = ref object of OpenApiRestCall_402656044
proc url_DeleteDiskSnapshot_402656881(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDiskSnapshot_402656880(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656882 = header.getOrDefault("X-Amz-Target")
  valid_402656882 = validateParameter(valid_402656882, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDiskSnapshot"))
  if valid_402656882 != nil:
    section.add "X-Amz-Target", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Security-Token", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-Signature")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Signature", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Algorithm", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Date")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Date", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Credential")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Credential", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656891: Call_DeleteDiskSnapshot_402656879;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified disk snapshot.</p> <p>When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk.</p> <p>The <code>delete disk snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656891.validator(path, query, header, formData, body, _)
  let scheme = call_402656891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656891.makeUrl(scheme.get, call_402656891.host, call_402656891.base,
                                   call_402656891.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656891, uri, valid, _)

proc call*(call_402656892: Call_DeleteDiskSnapshot_402656879; body: JsonNode): Recallable =
  ## deleteDiskSnapshot
  ## <p>Deletes the specified disk snapshot.</p> <p>When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk.</p> <p>The <code>delete disk snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656893 = newJObject()
  if body != nil:
    body_402656893 = body
  result = call_402656892.call(nil, nil, nil, nil, body_402656893)

var deleteDiskSnapshot* = Call_DeleteDiskSnapshot_402656879(
    name: "deleteDiskSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDiskSnapshot",
    validator: validate_DeleteDiskSnapshot_402656880, base: "/",
    makeUrl: url_DeleteDiskSnapshot_402656881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_402656894 = ref object of OpenApiRestCall_402656044
proc url_DeleteDomain_402656896(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDomain_402656895(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656897 = header.getOrDefault("X-Amz-Target")
  valid_402656897 = validateParameter(valid_402656897, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDomain"))
  if valid_402656897 != nil:
    section.add "X-Amz-Target", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Security-Token", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Signature")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Signature", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Algorithm", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Date")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Date", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Credential")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Credential", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656906: Call_DeleteDomain_402656894; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656906.validator(path, query, header, formData, body, _)
  let scheme = call_402656906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656906.makeUrl(scheme.get, call_402656906.host, call_402656906.base,
                                   call_402656906.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656906, uri, valid, _)

proc call*(call_402656907: Call_DeleteDomain_402656894; body: JsonNode): Recallable =
  ## deleteDomain
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656908 = newJObject()
  if body != nil:
    body_402656908 = body
  result = call_402656907.call(nil, nil, nil, nil, body_402656908)

var deleteDomain* = Call_DeleteDomain_402656894(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDomain",
    validator: validate_DeleteDomain_402656895, base: "/",
    makeUrl: url_DeleteDomain_402656896, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainEntry_402656909 = ref object of OpenApiRestCall_402656044
proc url_DeleteDomainEntry_402656911(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDomainEntry_402656910(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656912 = header.getOrDefault("X-Amz-Target")
  valid_402656912 = validateParameter(valid_402656912, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDomainEntry"))
  if valid_402656912 != nil:
    section.add "X-Amz-Target", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Security-Token", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Signature")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Signature", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Algorithm", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Date")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Date", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Credential")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Credential", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656921: Call_DeleteDomainEntry_402656909;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a specific domain entry.</p> <p>The <code>delete domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656921.validator(path, query, header, formData, body, _)
  let scheme = call_402656921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656921.makeUrl(scheme.get, call_402656921.host, call_402656921.base,
                                   call_402656921.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656921, uri, valid, _)

proc call*(call_402656922: Call_DeleteDomainEntry_402656909; body: JsonNode): Recallable =
  ## deleteDomainEntry
  ## <p>Deletes a specific domain entry.</p> <p>The <code>delete domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656923 = newJObject()
  if body != nil:
    body_402656923 = body
  result = call_402656922.call(nil, nil, nil, nil, body_402656923)

var deleteDomainEntry* = Call_DeleteDomainEntry_402656909(
    name: "deleteDomainEntry", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDomainEntry",
    validator: validate_DeleteDomainEntry_402656910, base: "/",
    makeUrl: url_DeleteDomainEntry_402656911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstance_402656924 = ref object of OpenApiRestCall_402656044
proc url_DeleteInstance_402656926(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInstance_402656925(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656927 = header.getOrDefault("X-Amz-Target")
  valid_402656927 = validateParameter(valid_402656927, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteInstance"))
  if valid_402656927 != nil:
    section.add "X-Amz-Target", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Security-Token", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Signature")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Signature", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Algorithm", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-Date")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Date", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Credential")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Credential", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656936: Call_DeleteInstance_402656924; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an Amazon Lightsail instance.</p> <p>The <code>delete instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656936.validator(path, query, header, formData, body, _)
  let scheme = call_402656936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656936.makeUrl(scheme.get, call_402656936.host, call_402656936.base,
                                   call_402656936.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656936, uri, valid, _)

proc call*(call_402656937: Call_DeleteInstance_402656924; body: JsonNode): Recallable =
  ## deleteInstance
  ## <p>Deletes an Amazon Lightsail instance.</p> <p>The <code>delete instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656938 = newJObject()
  if body != nil:
    body_402656938 = body
  result = call_402656937.call(nil, nil, nil, nil, body_402656938)

var deleteInstance* = Call_DeleteInstance_402656924(name: "deleteInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteInstance",
    validator: validate_DeleteInstance_402656925, base: "/",
    makeUrl: url_DeleteInstance_402656926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceSnapshot_402656939 = ref object of OpenApiRestCall_402656044
proc url_DeleteInstanceSnapshot_402656941(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInstanceSnapshot_402656940(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656942 = header.getOrDefault("X-Amz-Target")
  valid_402656942 = validateParameter(valid_402656942, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteInstanceSnapshot"))
  if valid_402656942 != nil:
    section.add "X-Amz-Target", valid_402656942
  var valid_402656943 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656943 = validateParameter(valid_402656943, JString,
                                      required = false, default = nil)
  if valid_402656943 != nil:
    section.add "X-Amz-Security-Token", valid_402656943
  var valid_402656944 = header.getOrDefault("X-Amz-Signature")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-Signature", valid_402656944
  var valid_402656945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Algorithm", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Date")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Date", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-Credential")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Credential", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656951: Call_DeleteInstanceSnapshot_402656939;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a specific snapshot of a virtual private server (or <i>instance</i>).</p> <p>The <code>delete instance snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656951.validator(path, query, header, formData, body, _)
  let scheme = call_402656951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656951.makeUrl(scheme.get, call_402656951.host, call_402656951.base,
                                   call_402656951.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656951, uri, valid, _)

proc call*(call_402656952: Call_DeleteInstanceSnapshot_402656939; body: JsonNode): Recallable =
  ## deleteInstanceSnapshot
  ## <p>Deletes a specific snapshot of a virtual private server (or <i>instance</i>).</p> <p>The <code>delete instance snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656953 = newJObject()
  if body != nil:
    body_402656953 = body
  result = call_402656952.call(nil, nil, nil, nil, body_402656953)

var deleteInstanceSnapshot* = Call_DeleteInstanceSnapshot_402656939(
    name: "deleteInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteInstanceSnapshot",
    validator: validate_DeleteInstanceSnapshot_402656940, base: "/",
    makeUrl: url_DeleteInstanceSnapshot_402656941,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteKeyPair_402656954 = ref object of OpenApiRestCall_402656044
proc url_DeleteKeyPair_402656956(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteKeyPair_402656955(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656957 = header.getOrDefault("X-Amz-Target")
  valid_402656957 = validateParameter(valid_402656957, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteKeyPair"))
  if valid_402656957 != nil:
    section.add "X-Amz-Target", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Security-Token", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Signature")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Signature", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Algorithm", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Date")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Date", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-Credential")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Credential", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656966: Call_DeleteKeyPair_402656954; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656966.validator(path, query, header, formData, body, _)
  let scheme = call_402656966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656966.makeUrl(scheme.get, call_402656966.host, call_402656966.base,
                                   call_402656966.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656966, uri, valid, _)

proc call*(call_402656967: Call_DeleteKeyPair_402656954; body: JsonNode): Recallable =
  ## deleteKeyPair
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656968 = newJObject()
  if body != nil:
    body_402656968 = body
  result = call_402656967.call(nil, nil, nil, nil, body_402656968)

var deleteKeyPair* = Call_DeleteKeyPair_402656954(name: "deleteKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteKeyPair",
    validator: validate_DeleteKeyPair_402656955, base: "/",
    makeUrl: url_DeleteKeyPair_402656956, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteKnownHostKeys_402656969 = ref object of OpenApiRestCall_402656044
proc url_DeleteKnownHostKeys_402656971(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteKnownHostKeys_402656970(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656972 = header.getOrDefault("X-Amz-Target")
  valid_402656972 = validateParameter(valid_402656972, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteKnownHostKeys"))
  if valid_402656972 != nil:
    section.add "X-Amz-Target", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Security-Token", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Signature")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Signature", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Algorithm", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Date")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Date", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Credential")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Credential", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656981: Call_DeleteKnownHostKeys_402656969;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch.</p> <important> <p>Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection">Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client</a>.</p> </important>
                                                                                         ## 
  let valid = call_402656981.validator(path, query, header, formData, body, _)
  let scheme = call_402656981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656981.makeUrl(scheme.get, call_402656981.host, call_402656981.base,
                                   call_402656981.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656981, uri, valid, _)

proc call*(call_402656982: Call_DeleteKnownHostKeys_402656969; body: JsonNode): Recallable =
  ## deleteKnownHostKeys
  ## <p>Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch.</p> <important> <p>Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection">Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client</a>.</p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656983 = newJObject()
  if body != nil:
    body_402656983 = body
  result = call_402656982.call(nil, nil, nil, nil, body_402656983)

var deleteKnownHostKeys* = Call_DeleteKnownHostKeys_402656969(
    name: "deleteKnownHostKeys", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteKnownHostKeys",
    validator: validate_DeleteKnownHostKeys_402656970, base: "/",
    makeUrl: url_DeleteKnownHostKeys_402656971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoadBalancer_402656984 = ref object of OpenApiRestCall_402656044
proc url_DeleteLoadBalancer_402656986(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLoadBalancer_402656985(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656987 = header.getOrDefault("X-Amz-Target")
  valid_402656987 = validateParameter(valid_402656987, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteLoadBalancer"))
  if valid_402656987 != nil:
    section.add "X-Amz-Target", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Security-Token", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-Signature")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-Signature", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Algorithm", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Date")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Date", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-Credential")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Credential", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656996: Call_DeleteLoadBalancer_402656984;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again.</p> <p>The <code>delete load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402656996.validator(path, query, header, formData, body, _)
  let scheme = call_402656996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656996.makeUrl(scheme.get, call_402656996.host, call_402656996.base,
                                   call_402656996.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656996, uri, valid, _)

proc call*(call_402656997: Call_DeleteLoadBalancer_402656984; body: JsonNode): Recallable =
  ## deleteLoadBalancer
  ## <p>Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again.</p> <p>The <code>delete load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656998 = newJObject()
  if body != nil:
    body_402656998 = body
  result = call_402656997.call(nil, nil, nil, nil, body_402656998)

var deleteLoadBalancer* = Call_DeleteLoadBalancer_402656984(
    name: "deleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteLoadBalancer",
    validator: validate_DeleteLoadBalancer_402656985, base: "/",
    makeUrl: url_DeleteLoadBalancer_402656986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoadBalancerTlsCertificate_402656999 = ref object of OpenApiRestCall_402656044
proc url_DeleteLoadBalancerTlsCertificate_402657001(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLoadBalancerTlsCertificate_402657000(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>DeleteLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657002 = header.getOrDefault("X-Amz-Target")
  valid_402657002 = validateParameter(valid_402657002, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteLoadBalancerTlsCertificate"))
  if valid_402657002 != nil:
    section.add "X-Amz-Target", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Security-Token", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-Signature")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-Signature", valid_402657004
  var valid_402657005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657005 = validateParameter(valid_402657005, JString,
                                      required = false, default = nil)
  if valid_402657005 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657005
  var valid_402657006 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657006 = validateParameter(valid_402657006, JString,
                                      required = false, default = nil)
  if valid_402657006 != nil:
    section.add "X-Amz-Algorithm", valid_402657006
  var valid_402657007 = header.getOrDefault("X-Amz-Date")
  valid_402657007 = validateParameter(valid_402657007, JString,
                                      required = false, default = nil)
  if valid_402657007 != nil:
    section.add "X-Amz-Date", valid_402657007
  var valid_402657008 = header.getOrDefault("X-Amz-Credential")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "X-Amz-Credential", valid_402657008
  var valid_402657009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657011: Call_DeleteLoadBalancerTlsCertificate_402656999;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>DeleteLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402657011.validator(path, query, header, formData, body, _)
  let scheme = call_402657011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657011.makeUrl(scheme.get, call_402657011.host, call_402657011.base,
                                   call_402657011.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657011, uri, valid, _)

proc call*(call_402657012: Call_DeleteLoadBalancerTlsCertificate_402656999;
           body: JsonNode): Recallable =
  ## deleteLoadBalancerTlsCertificate
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>DeleteLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657013 = newJObject()
  if body != nil:
    body_402657013 = body
  result = call_402657012.call(nil, nil, nil, nil, body_402657013)

var deleteLoadBalancerTlsCertificate* = Call_DeleteLoadBalancerTlsCertificate_402656999(
    name: "deleteLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteLoadBalancerTlsCertificate",
    validator: validate_DeleteLoadBalancerTlsCertificate_402657000, base: "/",
    makeUrl: url_DeleteLoadBalancerTlsCertificate_402657001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRelationalDatabase_402657014 = ref object of OpenApiRestCall_402656044
proc url_DeleteRelationalDatabase_402657016(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRelationalDatabase_402657015(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657017 = header.getOrDefault("X-Amz-Target")
  valid_402657017 = validateParameter(valid_402657017, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteRelationalDatabase"))
  if valid_402657017 != nil:
    section.add "X-Amz-Target", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-Security-Token", valid_402657018
  var valid_402657019 = header.getOrDefault("X-Amz-Signature")
  valid_402657019 = validateParameter(valid_402657019, JString,
                                      required = false, default = nil)
  if valid_402657019 != nil:
    section.add "X-Amz-Signature", valid_402657019
  var valid_402657020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657020
  var valid_402657021 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "X-Amz-Algorithm", valid_402657021
  var valid_402657022 = header.getOrDefault("X-Amz-Date")
  valid_402657022 = validateParameter(valid_402657022, JString,
                                      required = false, default = nil)
  if valid_402657022 != nil:
    section.add "X-Amz-Date", valid_402657022
  var valid_402657023 = header.getOrDefault("X-Amz-Credential")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-Credential", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657026: Call_DeleteRelationalDatabase_402657014;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402657026.validator(path, query, header, formData, body, _)
  let scheme = call_402657026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657026.makeUrl(scheme.get, call_402657026.host, call_402657026.base,
                                   call_402657026.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657026, uri, valid, _)

proc call*(call_402657027: Call_DeleteRelationalDatabase_402657014;
           body: JsonNode): Recallable =
  ## deleteRelationalDatabase
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657028 = newJObject()
  if body != nil:
    body_402657028 = body
  result = call_402657027.call(nil, nil, nil, nil, body_402657028)

var deleteRelationalDatabase* = Call_DeleteRelationalDatabase_402657014(
    name: "deleteRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteRelationalDatabase",
    validator: validate_DeleteRelationalDatabase_402657015, base: "/",
    makeUrl: url_DeleteRelationalDatabase_402657016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRelationalDatabaseSnapshot_402657029 = ref object of OpenApiRestCall_402656044
proc url_DeleteRelationalDatabaseSnapshot_402657031(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRelationalDatabaseSnapshot_402657030(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657032 = header.getOrDefault("X-Amz-Target")
  valid_402657032 = validateParameter(valid_402657032, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteRelationalDatabaseSnapshot"))
  if valid_402657032 != nil:
    section.add "X-Amz-Target", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Security-Token", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-Signature")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Signature", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-Algorithm", valid_402657036
  var valid_402657037 = header.getOrDefault("X-Amz-Date")
  valid_402657037 = validateParameter(valid_402657037, JString,
                                      required = false, default = nil)
  if valid_402657037 != nil:
    section.add "X-Amz-Date", valid_402657037
  var valid_402657038 = header.getOrDefault("X-Amz-Credential")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "X-Amz-Credential", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657041: Call_DeleteRelationalDatabaseSnapshot_402657029;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a database snapshot in Amazon Lightsail.</p> <p>The <code>delete relational database snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402657041.validator(path, query, header, formData, body, _)
  let scheme = call_402657041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657041.makeUrl(scheme.get, call_402657041.host, call_402657041.base,
                                   call_402657041.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657041, uri, valid, _)

proc call*(call_402657042: Call_DeleteRelationalDatabaseSnapshot_402657029;
           body: JsonNode): Recallable =
  ## deleteRelationalDatabaseSnapshot
  ## <p>Deletes a database snapshot in Amazon Lightsail.</p> <p>The <code>delete relational database snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402657043 = newJObject()
  if body != nil:
    body_402657043 = body
  result = call_402657042.call(nil, nil, nil, nil, body_402657043)

var deleteRelationalDatabaseSnapshot* = Call_DeleteRelationalDatabaseSnapshot_402657029(
    name: "deleteRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteRelationalDatabaseSnapshot",
    validator: validate_DeleteRelationalDatabaseSnapshot_402657030, base: "/",
    makeUrl: url_DeleteRelationalDatabaseSnapshot_402657031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachDisk_402657044 = ref object of OpenApiRestCall_402656044
proc url_DetachDisk_402657046(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachDisk_402657045(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657047 = header.getOrDefault("X-Amz-Target")
  valid_402657047 = validateParameter(valid_402657047, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachDisk"))
  if valid_402657047 != nil:
    section.add "X-Amz-Target", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Security-Token", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-Signature")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Signature", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-Algorithm", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-Date")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Date", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-Credential")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Credential", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657056: Call_DetachDisk_402657044; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk.</p> <p>The <code>detach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402657056.validator(path, query, header, formData, body, _)
  let scheme = call_402657056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657056.makeUrl(scheme.get, call_402657056.host, call_402657056.base,
                                   call_402657056.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657056, uri, valid, _)

proc call*(call_402657057: Call_DetachDisk_402657044; body: JsonNode): Recallable =
  ## detachDisk
  ## <p>Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk.</p> <p>The <code>detach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657058 = newJObject()
  if body != nil:
    body_402657058 = body
  result = call_402657057.call(nil, nil, nil, nil, body_402657058)

var detachDisk* = Call_DetachDisk_402657044(name: "detachDisk",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DetachDisk",
    validator: validate_DetachDisk_402657045, base: "/",
    makeUrl: url_DetachDisk_402657046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachInstancesFromLoadBalancer_402657059 = ref object of OpenApiRestCall_402656044
proc url_DetachInstancesFromLoadBalancer_402657061(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachInstancesFromLoadBalancer_402657060(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657062 = header.getOrDefault("X-Amz-Target")
  valid_402657062 = validateParameter(valid_402657062, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachInstancesFromLoadBalancer"))
  if valid_402657062 != nil:
    section.add "X-Amz-Target", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Security-Token", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-Signature")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Signature", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-Algorithm", valid_402657066
  var valid_402657067 = header.getOrDefault("X-Amz-Date")
  valid_402657067 = validateParameter(valid_402657067, JString,
                                      required = false, default = nil)
  if valid_402657067 != nil:
    section.add "X-Amz-Date", valid_402657067
  var valid_402657068 = header.getOrDefault("X-Amz-Credential")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "X-Amz-Credential", valid_402657068
  var valid_402657069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657071: Call_DetachInstancesFromLoadBalancer_402657059;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Detaches the specified instances from a Lightsail load balancer.</p> <p>This operation waits until the instances are no longer needed before they are detached from the load balancer.</p> <p>The <code>detach instances from load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402657071.validator(path, query, header, formData, body, _)
  let scheme = call_402657071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657071.makeUrl(scheme.get, call_402657071.host, call_402657071.base,
                                   call_402657071.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657071, uri, valid, _)

proc call*(call_402657072: Call_DetachInstancesFromLoadBalancer_402657059;
           body: JsonNode): Recallable =
  ## detachInstancesFromLoadBalancer
  ## <p>Detaches the specified instances from a Lightsail load balancer.</p> <p>This operation waits until the instances are no longer needed before they are detached from the load balancer.</p> <p>The <code>detach instances from load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657073 = newJObject()
  if body != nil:
    body_402657073 = body
  result = call_402657072.call(nil, nil, nil, nil, body_402657073)

var detachInstancesFromLoadBalancer* = Call_DetachInstancesFromLoadBalancer_402657059(
    name: "detachInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DetachInstancesFromLoadBalancer",
    validator: validate_DetachInstancesFromLoadBalancer_402657060, base: "/",
    makeUrl: url_DetachInstancesFromLoadBalancer_402657061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachStaticIp_402657074 = ref object of OpenApiRestCall_402656044
proc url_DetachStaticIp_402657076(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachStaticIp_402657075(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657077 = header.getOrDefault("X-Amz-Target")
  valid_402657077 = validateParameter(valid_402657077, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachStaticIp"))
  if valid_402657077 != nil:
    section.add "X-Amz-Target", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Security-Token", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Signature")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Signature", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-Algorithm", valid_402657081
  var valid_402657082 = header.getOrDefault("X-Amz-Date")
  valid_402657082 = validateParameter(valid_402657082, JString,
                                      required = false, default = nil)
  if valid_402657082 != nil:
    section.add "X-Amz-Date", valid_402657082
  var valid_402657083 = header.getOrDefault("X-Amz-Credential")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "X-Amz-Credential", valid_402657083
  var valid_402657084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657086: Call_DetachStaticIp_402657074; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Detaches a static IP from the Amazon Lightsail instance to which it is attached.
                                                                                         ## 
  let valid = call_402657086.validator(path, query, header, formData, body, _)
  let scheme = call_402657086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657086.makeUrl(scheme.get, call_402657086.host, call_402657086.base,
                                   call_402657086.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657086, uri, valid, _)

proc call*(call_402657087: Call_DetachStaticIp_402657074; body: JsonNode): Recallable =
  ## detachStaticIp
  ## Detaches a static IP from the Amazon Lightsail instance to which it is attached.
  ##   
                                                                                     ## body: JObject (required)
  var body_402657088 = newJObject()
  if body != nil:
    body_402657088 = body
  result = call_402657087.call(nil, nil, nil, nil, body_402657088)

var detachStaticIp* = Call_DetachStaticIp_402657074(name: "detachStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DetachStaticIp",
    validator: validate_DetachStaticIp_402657075, base: "/",
    makeUrl: url_DetachStaticIp_402657076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAddOn_402657089 = ref object of OpenApiRestCall_402656044
proc url_DisableAddOn_402657091(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableAddOn_402657090(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657092 = header.getOrDefault("X-Amz-Target")
  valid_402657092 = validateParameter(valid_402657092, JString, required = true, default = newJString(
      "Lightsail_20161128.DisableAddOn"))
  if valid_402657092 != nil:
    section.add "X-Amz-Target", valid_402657092
  var valid_402657093 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-Security-Token", valid_402657093
  var valid_402657094 = header.getOrDefault("X-Amz-Signature")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Signature", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Algorithm", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Date")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Date", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Credential")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Credential", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657101: Call_DisableAddOn_402657089; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
                                                                                         ## 
  let valid = call_402657101.validator(path, query, header, formData, body, _)
  let scheme = call_402657101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657101.makeUrl(scheme.get, call_402657101.host, call_402657101.base,
                                   call_402657101.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657101, uri, valid, _)

proc call*(call_402657102: Call_DisableAddOn_402657089; body: JsonNode): Recallable =
  ## disableAddOn
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   
                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657103 = newJObject()
  if body != nil:
    body_402657103 = body
  result = call_402657102.call(nil, nil, nil, nil, body_402657103)

var disableAddOn* = Call_DisableAddOn_402657089(name: "disableAddOn",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DisableAddOn",
    validator: validate_DisableAddOn_402657090, base: "/",
    makeUrl: url_DisableAddOn_402657091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DownloadDefaultKeyPair_402657104 = ref object of OpenApiRestCall_402656044
proc url_DownloadDefaultKeyPair_402657106(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DownloadDefaultKeyPair_402657105(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657107 = header.getOrDefault("X-Amz-Target")
  valid_402657107 = validateParameter(valid_402657107, JString, required = true, default = newJString(
      "Lightsail_20161128.DownloadDefaultKeyPair"))
  if valid_402657107 != nil:
    section.add "X-Amz-Target", valid_402657107
  var valid_402657108 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657108 = validateParameter(valid_402657108, JString,
                                      required = false, default = nil)
  if valid_402657108 != nil:
    section.add "X-Amz-Security-Token", valid_402657108
  var valid_402657109 = header.getOrDefault("X-Amz-Signature")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "X-Amz-Signature", valid_402657109
  var valid_402657110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657110
  var valid_402657111 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "X-Amz-Algorithm", valid_402657111
  var valid_402657112 = header.getOrDefault("X-Amz-Date")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Date", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Credential")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Credential", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657116: Call_DownloadDefaultKeyPair_402657104;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Downloads the default SSH key pair from the user's account.
                                                                                         ## 
  let valid = call_402657116.validator(path, query, header, formData, body, _)
  let scheme = call_402657116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657116.makeUrl(scheme.get, call_402657116.host, call_402657116.base,
                                   call_402657116.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657116, uri, valid, _)

proc call*(call_402657117: Call_DownloadDefaultKeyPair_402657104; body: JsonNode): Recallable =
  ## downloadDefaultKeyPair
  ## Downloads the default SSH key pair from the user's account.
  ##   body: JObject (required)
  var body_402657118 = newJObject()
  if body != nil:
    body_402657118 = body
  result = call_402657117.call(nil, nil, nil, nil, body_402657118)

var downloadDefaultKeyPair* = Call_DownloadDefaultKeyPair_402657104(
    name: "downloadDefaultKeyPair", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DownloadDefaultKeyPair",
    validator: validate_DownloadDefaultKeyPair_402657105, base: "/",
    makeUrl: url_DownloadDefaultKeyPair_402657106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAddOn_402657119 = ref object of OpenApiRestCall_402656044
proc url_EnableAddOn_402657121(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableAddOn_402657120(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657122 = header.getOrDefault("X-Amz-Target")
  valid_402657122 = validateParameter(valid_402657122, JString, required = true, default = newJString(
      "Lightsail_20161128.EnableAddOn"))
  if valid_402657122 != nil:
    section.add "X-Amz-Target", valid_402657122
  var valid_402657123 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657123 = validateParameter(valid_402657123, JString,
                                      required = false, default = nil)
  if valid_402657123 != nil:
    section.add "X-Amz-Security-Token", valid_402657123
  var valid_402657124 = header.getOrDefault("X-Amz-Signature")
  valid_402657124 = validateParameter(valid_402657124, JString,
                                      required = false, default = nil)
  if valid_402657124 != nil:
    section.add "X-Amz-Signature", valid_402657124
  var valid_402657125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657125 = validateParameter(valid_402657125, JString,
                                      required = false, default = nil)
  if valid_402657125 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657125
  var valid_402657126 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657126 = validateParameter(valid_402657126, JString,
                                      required = false, default = nil)
  if valid_402657126 != nil:
    section.add "X-Amz-Algorithm", valid_402657126
  var valid_402657127 = header.getOrDefault("X-Amz-Date")
  valid_402657127 = validateParameter(valid_402657127, JString,
                                      required = false, default = nil)
  if valid_402657127 != nil:
    section.add "X-Amz-Date", valid_402657127
  var valid_402657128 = header.getOrDefault("X-Amz-Credential")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "X-Amz-Credential", valid_402657128
  var valid_402657129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657131: Call_EnableAddOn_402657119; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
                                                                                         ## 
  let valid = call_402657131.validator(path, query, header, formData, body, _)
  let scheme = call_402657131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657131.makeUrl(scheme.get, call_402657131.host, call_402657131.base,
                                   call_402657131.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657131, uri, valid, _)

proc call*(call_402657132: Call_EnableAddOn_402657119; body: JsonNode): Recallable =
  ## enableAddOn
  ## Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   
                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402657133 = newJObject()
  if body != nil:
    body_402657133 = body
  result = call_402657132.call(nil, nil, nil, nil, body_402657133)

var enableAddOn* = Call_EnableAddOn_402657119(name: "enableAddOn",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.EnableAddOn",
    validator: validate_EnableAddOn_402657120, base: "/",
    makeUrl: url_EnableAddOn_402657121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportSnapshot_402657134 = ref object of OpenApiRestCall_402656044
proc url_ExportSnapshot_402657136(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExportSnapshot_402657135(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657137 = header.getOrDefault("X-Amz-Target")
  valid_402657137 = validateParameter(valid_402657137, JString, required = true, default = newJString(
      "Lightsail_20161128.ExportSnapshot"))
  if valid_402657137 != nil:
    section.add "X-Amz-Target", valid_402657137
  var valid_402657138 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657138 = validateParameter(valid_402657138, JString,
                                      required = false, default = nil)
  if valid_402657138 != nil:
    section.add "X-Amz-Security-Token", valid_402657138
  var valid_402657139 = header.getOrDefault("X-Amz-Signature")
  valid_402657139 = validateParameter(valid_402657139, JString,
                                      required = false, default = nil)
  if valid_402657139 != nil:
    section.add "X-Amz-Signature", valid_402657139
  var valid_402657140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657140 = validateParameter(valid_402657140, JString,
                                      required = false, default = nil)
  if valid_402657140 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657140
  var valid_402657141 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657141 = validateParameter(valid_402657141, JString,
                                      required = false, default = nil)
  if valid_402657141 != nil:
    section.add "X-Amz-Algorithm", valid_402657141
  var valid_402657142 = header.getOrDefault("X-Amz-Date")
  valid_402657142 = validateParameter(valid_402657142, JString,
                                      required = false, default = nil)
  if valid_402657142 != nil:
    section.add "X-Amz-Date", valid_402657142
  var valid_402657143 = header.getOrDefault("X-Amz-Credential")
  valid_402657143 = validateParameter(valid_402657143, JString,
                                      required = false, default = nil)
  if valid_402657143 != nil:
    section.add "X-Amz-Credential", valid_402657143
  var valid_402657144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657144 = validateParameter(valid_402657144, JString,
                                      required = false, default = nil)
  if valid_402657144 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657146: Call_ExportSnapshot_402657134; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the <code>create cloud formation stack</code> operation to create new Amazon EC2 instances.</p> <p>Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot.</p> <p/> <p>The <code>export snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>source snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p> <note> <p>Use the <code>get instance snapshots</code> or <code>get disk snapshots</code> operations to get a list of snapshots that you can export to Amazon EC2.</p> </note>
                                                                                         ## 
  let valid = call_402657146.validator(path, query, header, formData, body, _)
  let scheme = call_402657146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657146.makeUrl(scheme.get, call_402657146.host, call_402657146.base,
                                   call_402657146.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657146, uri, valid, _)

proc call*(call_402657147: Call_ExportSnapshot_402657134; body: JsonNode): Recallable =
  ## exportSnapshot
  ## <p>Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the <code>create cloud formation stack</code> operation to create new Amazon EC2 instances.</p> <p>Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot.</p> <p/> <p>The <code>export snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>source snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p> <note> <p>Use the <code>get instance snapshots</code> or <code>get disk snapshots</code> operations to get a list of snapshots that you can export to Amazon EC2.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402657148 = newJObject()
  if body != nil:
    body_402657148 = body
  result = call_402657147.call(nil, nil, nil, nil, body_402657148)

var exportSnapshot* = Call_ExportSnapshot_402657134(name: "exportSnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ExportSnapshot",
    validator: validate_ExportSnapshot_402657135, base: "/",
    makeUrl: url_ExportSnapshot_402657136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetActiveNames_402657149 = ref object of OpenApiRestCall_402656044
proc url_GetActiveNames_402657151(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetActiveNames_402657150(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657152 = header.getOrDefault("X-Amz-Target")
  valid_402657152 = validateParameter(valid_402657152, JString, required = true, default = newJString(
      "Lightsail_20161128.GetActiveNames"))
  if valid_402657152 != nil:
    section.add "X-Amz-Target", valid_402657152
  var valid_402657153 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657153 = validateParameter(valid_402657153, JString,
                                      required = false, default = nil)
  if valid_402657153 != nil:
    section.add "X-Amz-Security-Token", valid_402657153
  var valid_402657154 = header.getOrDefault("X-Amz-Signature")
  valid_402657154 = validateParameter(valid_402657154, JString,
                                      required = false, default = nil)
  if valid_402657154 != nil:
    section.add "X-Amz-Signature", valid_402657154
  var valid_402657155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657155 = validateParameter(valid_402657155, JString,
                                      required = false, default = nil)
  if valid_402657155 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657155
  var valid_402657156 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657156 = validateParameter(valid_402657156, JString,
                                      required = false, default = nil)
  if valid_402657156 != nil:
    section.add "X-Amz-Algorithm", valid_402657156
  var valid_402657157 = header.getOrDefault("X-Amz-Date")
  valid_402657157 = validateParameter(valid_402657157, JString,
                                      required = false, default = nil)
  if valid_402657157 != nil:
    section.add "X-Amz-Date", valid_402657157
  var valid_402657158 = header.getOrDefault("X-Amz-Credential")
  valid_402657158 = validateParameter(valid_402657158, JString,
                                      required = false, default = nil)
  if valid_402657158 != nil:
    section.add "X-Amz-Credential", valid_402657158
  var valid_402657159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657159 = validateParameter(valid_402657159, JString,
                                      required = false, default = nil)
  if valid_402657159 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657161: Call_GetActiveNames_402657149; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the names of all active (not deleted) resources.
                                                                                         ## 
  let valid = call_402657161.validator(path, query, header, formData, body, _)
  let scheme = call_402657161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657161.makeUrl(scheme.get, call_402657161.host, call_402657161.base,
                                   call_402657161.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657161, uri, valid, _)

proc call*(call_402657162: Call_GetActiveNames_402657149; body: JsonNode): Recallable =
  ## getActiveNames
  ## Returns the names of all active (not deleted) resources.
  ##   body: JObject (required)
  var body_402657163 = newJObject()
  if body != nil:
    body_402657163 = body
  result = call_402657162.call(nil, nil, nil, nil, body_402657163)

var getActiveNames* = Call_GetActiveNames_402657149(name: "getActiveNames",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetActiveNames",
    validator: validate_GetActiveNames_402657150, base: "/",
    makeUrl: url_GetActiveNames_402657151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAlarms_402657164 = ref object of OpenApiRestCall_402656044
proc url_GetAlarms_402657166(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAlarms_402657165(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns information about the configured alarms. Specify an alarm name in your request to return information about a specific alarm, or specify a monitored resource name to return information about all alarms for a specific resource.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657167 = header.getOrDefault("X-Amz-Target")
  valid_402657167 = validateParameter(valid_402657167, JString, required = true, default = newJString(
      "Lightsail_20161128.GetAlarms"))
  if valid_402657167 != nil:
    section.add "X-Amz-Target", valid_402657167
  var valid_402657168 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657168 = validateParameter(valid_402657168, JString,
                                      required = false, default = nil)
  if valid_402657168 != nil:
    section.add "X-Amz-Security-Token", valid_402657168
  var valid_402657169 = header.getOrDefault("X-Amz-Signature")
  valid_402657169 = validateParameter(valid_402657169, JString,
                                      required = false, default = nil)
  if valid_402657169 != nil:
    section.add "X-Amz-Signature", valid_402657169
  var valid_402657170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657170
  var valid_402657171 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657171 = validateParameter(valid_402657171, JString,
                                      required = false, default = nil)
  if valid_402657171 != nil:
    section.add "X-Amz-Algorithm", valid_402657171
  var valid_402657172 = header.getOrDefault("X-Amz-Date")
  valid_402657172 = validateParameter(valid_402657172, JString,
                                      required = false, default = nil)
  if valid_402657172 != nil:
    section.add "X-Amz-Date", valid_402657172
  var valid_402657173 = header.getOrDefault("X-Amz-Credential")
  valid_402657173 = validateParameter(valid_402657173, JString,
                                      required = false, default = nil)
  if valid_402657173 != nil:
    section.add "X-Amz-Credential", valid_402657173
  var valid_402657174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657174 = validateParameter(valid_402657174, JString,
                                      required = false, default = nil)
  if valid_402657174 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657176: Call_GetAlarms_402657164; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the configured alarms. Specify an alarm name in your request to return information about a specific alarm, or specify a monitored resource name to return information about all alarms for a specific resource.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
                                                                                         ## 
  let valid = call_402657176.validator(path, query, header, formData, body, _)
  let scheme = call_402657176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657176.makeUrl(scheme.get, call_402657176.host, call_402657176.base,
                                   call_402657176.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657176, uri, valid, _)

proc call*(call_402657177: Call_GetAlarms_402657164; body: JsonNode): Recallable =
  ## getAlarms
  ## <p>Returns information about the configured alarms. Specify an alarm name in your request to return information about a specific alarm, or specify a monitored resource name to return information about all alarms for a specific resource.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402657178 = newJObject()
  if body != nil:
    body_402657178 = body
  result = call_402657177.call(nil, nil, nil, nil, body_402657178)

var getAlarms* = Call_GetAlarms_402657164(name: "getAlarms",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetAlarms",
    validator: validate_GetAlarms_402657165, base: "/", makeUrl: url_GetAlarms_402657166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutoSnapshots_402657179 = ref object of OpenApiRestCall_402656044
proc url_GetAutoSnapshots_402657181(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAutoSnapshots_402657180(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657182 = header.getOrDefault("X-Amz-Target")
  valid_402657182 = validateParameter(valid_402657182, JString, required = true, default = newJString(
      "Lightsail_20161128.GetAutoSnapshots"))
  if valid_402657182 != nil:
    section.add "X-Amz-Target", valid_402657182
  var valid_402657183 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657183 = validateParameter(valid_402657183, JString,
                                      required = false, default = nil)
  if valid_402657183 != nil:
    section.add "X-Amz-Security-Token", valid_402657183
  var valid_402657184 = header.getOrDefault("X-Amz-Signature")
  valid_402657184 = validateParameter(valid_402657184, JString,
                                      required = false, default = nil)
  if valid_402657184 != nil:
    section.add "X-Amz-Signature", valid_402657184
  var valid_402657185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657185 = validateParameter(valid_402657185, JString,
                                      required = false, default = nil)
  if valid_402657185 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657185
  var valid_402657186 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657186 = validateParameter(valid_402657186, JString,
                                      required = false, default = nil)
  if valid_402657186 != nil:
    section.add "X-Amz-Algorithm", valid_402657186
  var valid_402657187 = header.getOrDefault("X-Amz-Date")
  valid_402657187 = validateParameter(valid_402657187, JString,
                                      required = false, default = nil)
  if valid_402657187 != nil:
    section.add "X-Amz-Date", valid_402657187
  var valid_402657188 = header.getOrDefault("X-Amz-Credential")
  valid_402657188 = validateParameter(valid_402657188, JString,
                                      required = false, default = nil)
  if valid_402657188 != nil:
    section.add "X-Amz-Credential", valid_402657188
  var valid_402657189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657189 = validateParameter(valid_402657189, JString,
                                      required = false, default = nil)
  if valid_402657189 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657191: Call_GetAutoSnapshots_402657179;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the available automatic snapshots for an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
                                                                                         ## 
  let valid = call_402657191.validator(path, query, header, formData, body, _)
  let scheme = call_402657191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657191.makeUrl(scheme.get, call_402657191.host, call_402657191.base,
                                   call_402657191.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657191, uri, valid, _)

proc call*(call_402657192: Call_GetAutoSnapshots_402657179; body: JsonNode): Recallable =
  ## getAutoSnapshots
  ## Returns the available automatic snapshots for an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   
                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402657193 = newJObject()
  if body != nil:
    body_402657193 = body
  result = call_402657192.call(nil, nil, nil, nil, body_402657193)

var getAutoSnapshots* = Call_GetAutoSnapshots_402657179(
    name: "getAutoSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetAutoSnapshots",
    validator: validate_GetAutoSnapshots_402657180, base: "/",
    makeUrl: url_GetAutoSnapshots_402657181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlueprints_402657194 = ref object of OpenApiRestCall_402656044
proc url_GetBlueprints_402657196(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBlueprints_402657195(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657197 = header.getOrDefault("X-Amz-Target")
  valid_402657197 = validateParameter(valid_402657197, JString, required = true, default = newJString(
      "Lightsail_20161128.GetBlueprints"))
  if valid_402657197 != nil:
    section.add "X-Amz-Target", valid_402657197
  var valid_402657198 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657198 = validateParameter(valid_402657198, JString,
                                      required = false, default = nil)
  if valid_402657198 != nil:
    section.add "X-Amz-Security-Token", valid_402657198
  var valid_402657199 = header.getOrDefault("X-Amz-Signature")
  valid_402657199 = validateParameter(valid_402657199, JString,
                                      required = false, default = nil)
  if valid_402657199 != nil:
    section.add "X-Amz-Signature", valid_402657199
  var valid_402657200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657200 = validateParameter(valid_402657200, JString,
                                      required = false, default = nil)
  if valid_402657200 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657200
  var valid_402657201 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657201 = validateParameter(valid_402657201, JString,
                                      required = false, default = nil)
  if valid_402657201 != nil:
    section.add "X-Amz-Algorithm", valid_402657201
  var valid_402657202 = header.getOrDefault("X-Amz-Date")
  valid_402657202 = validateParameter(valid_402657202, JString,
                                      required = false, default = nil)
  if valid_402657202 != nil:
    section.add "X-Amz-Date", valid_402657202
  var valid_402657203 = header.getOrDefault("X-Amz-Credential")
  valid_402657203 = validateParameter(valid_402657203, JString,
                                      required = false, default = nil)
  if valid_402657203 != nil:
    section.add "X-Amz-Credential", valid_402657203
  var valid_402657204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657204 = validateParameter(valid_402657204, JString,
                                      required = false, default = nil)
  if valid_402657204 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657206: Call_GetBlueprints_402657194; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
                                                                                         ## 
  let valid = call_402657206.validator(path, query, header, formData, body, _)
  let scheme = call_402657206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657206.makeUrl(scheme.get, call_402657206.host, call_402657206.base,
                                   call_402657206.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657206, uri, valid, _)

proc call*(call_402657207: Call_GetBlueprints_402657194; body: JsonNode): Recallable =
  ## getBlueprints
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402657208 = newJObject()
  if body != nil:
    body_402657208 = body
  result = call_402657207.call(nil, nil, nil, nil, body_402657208)

var getBlueprints* = Call_GetBlueprints_402657194(name: "getBlueprints",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetBlueprints",
    validator: validate_GetBlueprints_402657195, base: "/",
    makeUrl: url_GetBlueprints_402657196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBundles_402657209 = ref object of OpenApiRestCall_402656044
proc url_GetBundles_402657211(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBundles_402657210(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657212 = header.getOrDefault("X-Amz-Target")
  valid_402657212 = validateParameter(valid_402657212, JString, required = true, default = newJString(
      "Lightsail_20161128.GetBundles"))
  if valid_402657212 != nil:
    section.add "X-Amz-Target", valid_402657212
  var valid_402657213 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657213 = validateParameter(valid_402657213, JString,
                                      required = false, default = nil)
  if valid_402657213 != nil:
    section.add "X-Amz-Security-Token", valid_402657213
  var valid_402657214 = header.getOrDefault("X-Amz-Signature")
  valid_402657214 = validateParameter(valid_402657214, JString,
                                      required = false, default = nil)
  if valid_402657214 != nil:
    section.add "X-Amz-Signature", valid_402657214
  var valid_402657215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657215 = validateParameter(valid_402657215, JString,
                                      required = false, default = nil)
  if valid_402657215 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657215
  var valid_402657216 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657216 = validateParameter(valid_402657216, JString,
                                      required = false, default = nil)
  if valid_402657216 != nil:
    section.add "X-Amz-Algorithm", valid_402657216
  var valid_402657217 = header.getOrDefault("X-Amz-Date")
  valid_402657217 = validateParameter(valid_402657217, JString,
                                      required = false, default = nil)
  if valid_402657217 != nil:
    section.add "X-Amz-Date", valid_402657217
  var valid_402657218 = header.getOrDefault("X-Amz-Credential")
  valid_402657218 = validateParameter(valid_402657218, JString,
                                      required = false, default = nil)
  if valid_402657218 != nil:
    section.add "X-Amz-Credential", valid_402657218
  var valid_402657219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657219 = validateParameter(valid_402657219, JString,
                                      required = false, default = nil)
  if valid_402657219 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657221: Call_GetBundles_402657209; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the list of bundles that are available for purchase. A bundle describes the specs for your virtual private server (or <i>instance</i>).
                                                                                         ## 
  let valid = call_402657221.validator(path, query, header, formData, body, _)
  let scheme = call_402657221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657221.makeUrl(scheme.get, call_402657221.host, call_402657221.base,
                                   call_402657221.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657221, uri, valid, _)

proc call*(call_402657222: Call_GetBundles_402657209; body: JsonNode): Recallable =
  ## getBundles
  ## Returns the list of bundles that are available for purchase. A bundle describes the specs for your virtual private server (or <i>instance</i>).
  ##   
                                                                                                                                                    ## body: JObject (required)
  var body_402657223 = newJObject()
  if body != nil:
    body_402657223 = body
  result = call_402657222.call(nil, nil, nil, nil, body_402657223)

var getBundles* = Call_GetBundles_402657209(name: "getBundles",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetBundles",
    validator: validate_GetBundles_402657210, base: "/",
    makeUrl: url_GetBundles_402657211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFormationStackRecords_402657224 = ref object of OpenApiRestCall_402656044
proc url_GetCloudFormationStackRecords_402657226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCloudFormationStackRecords_402657225(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657227 = header.getOrDefault("X-Amz-Target")
  valid_402657227 = validateParameter(valid_402657227, JString, required = true, default = newJString(
      "Lightsail_20161128.GetCloudFormationStackRecords"))
  if valid_402657227 != nil:
    section.add "X-Amz-Target", valid_402657227
  var valid_402657228 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657228 = validateParameter(valid_402657228, JString,
                                      required = false, default = nil)
  if valid_402657228 != nil:
    section.add "X-Amz-Security-Token", valid_402657228
  var valid_402657229 = header.getOrDefault("X-Amz-Signature")
  valid_402657229 = validateParameter(valid_402657229, JString,
                                      required = false, default = nil)
  if valid_402657229 != nil:
    section.add "X-Amz-Signature", valid_402657229
  var valid_402657230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657230
  var valid_402657231 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657231 = validateParameter(valid_402657231, JString,
                                      required = false, default = nil)
  if valid_402657231 != nil:
    section.add "X-Amz-Algorithm", valid_402657231
  var valid_402657232 = header.getOrDefault("X-Amz-Date")
  valid_402657232 = validateParameter(valid_402657232, JString,
                                      required = false, default = nil)
  if valid_402657232 != nil:
    section.add "X-Amz-Date", valid_402657232
  var valid_402657233 = header.getOrDefault("X-Amz-Credential")
  valid_402657233 = validateParameter(valid_402657233, JString,
                                      required = false, default = nil)
  if valid_402657233 != nil:
    section.add "X-Amz-Credential", valid_402657233
  var valid_402657234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657234 = validateParameter(valid_402657234, JString,
                                      required = false, default = nil)
  if valid_402657234 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657236: Call_GetCloudFormationStackRecords_402657224;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the CloudFormation stack record created as a result of the <code>create cloud formation stack</code> operation.</p> <p>An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.</p>
                                                                                         ## 
  let valid = call_402657236.validator(path, query, header, formData, body, _)
  let scheme = call_402657236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657236.makeUrl(scheme.get, call_402657236.host, call_402657236.base,
                                   call_402657236.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657236, uri, valid, _)

proc call*(call_402657237: Call_GetCloudFormationStackRecords_402657224;
           body: JsonNode): Recallable =
  ## getCloudFormationStackRecords
  ## <p>Returns the CloudFormation stack record created as a result of the <code>create cloud formation stack</code> operation.</p> <p>An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.</p>
  ##   
                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657238 = newJObject()
  if body != nil:
    body_402657238 = body
  result = call_402657237.call(nil, nil, nil, nil, body_402657238)

var getCloudFormationStackRecords* = Call_GetCloudFormationStackRecords_402657224(
    name: "getCloudFormationStackRecords", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetCloudFormationStackRecords",
    validator: validate_GetCloudFormationStackRecords_402657225, base: "/",
    makeUrl: url_GetCloudFormationStackRecords_402657226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactMethods_402657239 = ref object of OpenApiRestCall_402656044
proc url_GetContactMethods_402657241(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetContactMethods_402657240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns information about the configured contact methods. Specify a protocol in your request to return information about a specific contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657242 = header.getOrDefault("X-Amz-Target")
  valid_402657242 = validateParameter(valid_402657242, JString, required = true, default = newJString(
      "Lightsail_20161128.GetContactMethods"))
  if valid_402657242 != nil:
    section.add "X-Amz-Target", valid_402657242
  var valid_402657243 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657243 = validateParameter(valid_402657243, JString,
                                      required = false, default = nil)
  if valid_402657243 != nil:
    section.add "X-Amz-Security-Token", valid_402657243
  var valid_402657244 = header.getOrDefault("X-Amz-Signature")
  valid_402657244 = validateParameter(valid_402657244, JString,
                                      required = false, default = nil)
  if valid_402657244 != nil:
    section.add "X-Amz-Signature", valid_402657244
  var valid_402657245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657245 = validateParameter(valid_402657245, JString,
                                      required = false, default = nil)
  if valid_402657245 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657245
  var valid_402657246 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657246 = validateParameter(valid_402657246, JString,
                                      required = false, default = nil)
  if valid_402657246 != nil:
    section.add "X-Amz-Algorithm", valid_402657246
  var valid_402657247 = header.getOrDefault("X-Amz-Date")
  valid_402657247 = validateParameter(valid_402657247, JString,
                                      required = false, default = nil)
  if valid_402657247 != nil:
    section.add "X-Amz-Date", valid_402657247
  var valid_402657248 = header.getOrDefault("X-Amz-Credential")
  valid_402657248 = validateParameter(valid_402657248, JString,
                                      required = false, default = nil)
  if valid_402657248 != nil:
    section.add "X-Amz-Credential", valid_402657248
  var valid_402657249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657249 = validateParameter(valid_402657249, JString,
                                      required = false, default = nil)
  if valid_402657249 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657251: Call_GetContactMethods_402657239;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the configured contact methods. Specify a protocol in your request to return information about a specific contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
                                                                                         ## 
  let valid = call_402657251.validator(path, query, header, formData, body, _)
  let scheme = call_402657251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657251.makeUrl(scheme.get, call_402657251.host, call_402657251.base,
                                   call_402657251.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657251, uri, valid, _)

proc call*(call_402657252: Call_GetContactMethods_402657239; body: JsonNode): Recallable =
  ## getContactMethods
  ## <p>Returns information about the configured contact methods. Specify a protocol in your request to return information about a specific contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402657253 = newJObject()
  if body != nil:
    body_402657253 = body
  result = call_402657252.call(nil, nil, nil, nil, body_402657253)

var getContactMethods* = Call_GetContactMethods_402657239(
    name: "getContactMethods", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetContactMethods",
    validator: validate_GetContactMethods_402657240, base: "/",
    makeUrl: url_GetContactMethods_402657241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisk_402657254 = ref object of OpenApiRestCall_402656044
proc url_GetDisk_402657256(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDisk_402657255(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657257 = header.getOrDefault("X-Amz-Target")
  valid_402657257 = validateParameter(valid_402657257, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDisk"))
  if valid_402657257 != nil:
    section.add "X-Amz-Target", valid_402657257
  var valid_402657258 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657258 = validateParameter(valid_402657258, JString,
                                      required = false, default = nil)
  if valid_402657258 != nil:
    section.add "X-Amz-Security-Token", valid_402657258
  var valid_402657259 = header.getOrDefault("X-Amz-Signature")
  valid_402657259 = validateParameter(valid_402657259, JString,
                                      required = false, default = nil)
  if valid_402657259 != nil:
    section.add "X-Amz-Signature", valid_402657259
  var valid_402657260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657260 = validateParameter(valid_402657260, JString,
                                      required = false, default = nil)
  if valid_402657260 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657260
  var valid_402657261 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657261 = validateParameter(valid_402657261, JString,
                                      required = false, default = nil)
  if valid_402657261 != nil:
    section.add "X-Amz-Algorithm", valid_402657261
  var valid_402657262 = header.getOrDefault("X-Amz-Date")
  valid_402657262 = validateParameter(valid_402657262, JString,
                                      required = false, default = nil)
  if valid_402657262 != nil:
    section.add "X-Amz-Date", valid_402657262
  var valid_402657263 = header.getOrDefault("X-Amz-Credential")
  valid_402657263 = validateParameter(valid_402657263, JString,
                                      required = false, default = nil)
  if valid_402657263 != nil:
    section.add "X-Amz-Credential", valid_402657263
  var valid_402657264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657264 = validateParameter(valid_402657264, JString,
                                      required = false, default = nil)
  if valid_402657264 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657266: Call_GetDisk_402657254; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific block storage disk.
                                                                                         ## 
  let valid = call_402657266.validator(path, query, header, formData, body, _)
  let scheme = call_402657266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657266.makeUrl(scheme.get, call_402657266.host, call_402657266.base,
                                   call_402657266.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657266, uri, valid, _)

proc call*(call_402657267: Call_GetDisk_402657254; body: JsonNode): Recallable =
  ## getDisk
  ## Returns information about a specific block storage disk.
  ##   body: JObject (required)
  var body_402657268 = newJObject()
  if body != nil:
    body_402657268 = body
  result = call_402657267.call(nil, nil, nil, nil, body_402657268)

var getDisk* = Call_GetDisk_402657254(name: "getDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDisk",
                                      validator: validate_GetDisk_402657255,
                                      base: "/", makeUrl: url_GetDisk_402657256,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiskSnapshot_402657269 = ref object of OpenApiRestCall_402656044
proc url_GetDiskSnapshot_402657271(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiskSnapshot_402657270(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657272 = header.getOrDefault("X-Amz-Target")
  valid_402657272 = validateParameter(valid_402657272, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDiskSnapshot"))
  if valid_402657272 != nil:
    section.add "X-Amz-Target", valid_402657272
  var valid_402657273 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657273 = validateParameter(valid_402657273, JString,
                                      required = false, default = nil)
  if valid_402657273 != nil:
    section.add "X-Amz-Security-Token", valid_402657273
  var valid_402657274 = header.getOrDefault("X-Amz-Signature")
  valid_402657274 = validateParameter(valid_402657274, JString,
                                      required = false, default = nil)
  if valid_402657274 != nil:
    section.add "X-Amz-Signature", valid_402657274
  var valid_402657275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657275 = validateParameter(valid_402657275, JString,
                                      required = false, default = nil)
  if valid_402657275 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657275
  var valid_402657276 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657276 = validateParameter(valid_402657276, JString,
                                      required = false, default = nil)
  if valid_402657276 != nil:
    section.add "X-Amz-Algorithm", valid_402657276
  var valid_402657277 = header.getOrDefault("X-Amz-Date")
  valid_402657277 = validateParameter(valid_402657277, JString,
                                      required = false, default = nil)
  if valid_402657277 != nil:
    section.add "X-Amz-Date", valid_402657277
  var valid_402657278 = header.getOrDefault("X-Amz-Credential")
  valid_402657278 = validateParameter(valid_402657278, JString,
                                      required = false, default = nil)
  if valid_402657278 != nil:
    section.add "X-Amz-Credential", valid_402657278
  var valid_402657279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657279 = validateParameter(valid_402657279, JString,
                                      required = false, default = nil)
  if valid_402657279 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657281: Call_GetDiskSnapshot_402657269; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific block storage disk snapshot.
                                                                                         ## 
  let valid = call_402657281.validator(path, query, header, formData, body, _)
  let scheme = call_402657281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657281.makeUrl(scheme.get, call_402657281.host, call_402657281.base,
                                   call_402657281.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657281, uri, valid, _)

proc call*(call_402657282: Call_GetDiskSnapshot_402657269; body: JsonNode): Recallable =
  ## getDiskSnapshot
  ## Returns information about a specific block storage disk snapshot.
  ##   body: JObject (required)
  var body_402657283 = newJObject()
  if body != nil:
    body_402657283 = body
  result = call_402657282.call(nil, nil, nil, nil, body_402657283)

var getDiskSnapshot* = Call_GetDiskSnapshot_402657269(name: "getDiskSnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDiskSnapshot",
    validator: validate_GetDiskSnapshot_402657270, base: "/",
    makeUrl: url_GetDiskSnapshot_402657271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiskSnapshots_402657284 = ref object of OpenApiRestCall_402656044
proc url_GetDiskSnapshots_402657286(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiskSnapshots_402657285(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about all block storage disk snapshots in your AWS account and region.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657287 = header.getOrDefault("X-Amz-Target")
  valid_402657287 = validateParameter(valid_402657287, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDiskSnapshots"))
  if valid_402657287 != nil:
    section.add "X-Amz-Target", valid_402657287
  var valid_402657288 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657288 = validateParameter(valid_402657288, JString,
                                      required = false, default = nil)
  if valid_402657288 != nil:
    section.add "X-Amz-Security-Token", valid_402657288
  var valid_402657289 = header.getOrDefault("X-Amz-Signature")
  valid_402657289 = validateParameter(valid_402657289, JString,
                                      required = false, default = nil)
  if valid_402657289 != nil:
    section.add "X-Amz-Signature", valid_402657289
  var valid_402657290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657290 = validateParameter(valid_402657290, JString,
                                      required = false, default = nil)
  if valid_402657290 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657290
  var valid_402657291 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657291 = validateParameter(valid_402657291, JString,
                                      required = false, default = nil)
  if valid_402657291 != nil:
    section.add "X-Amz-Algorithm", valid_402657291
  var valid_402657292 = header.getOrDefault("X-Amz-Date")
  valid_402657292 = validateParameter(valid_402657292, JString,
                                      required = false, default = nil)
  if valid_402657292 != nil:
    section.add "X-Amz-Date", valid_402657292
  var valid_402657293 = header.getOrDefault("X-Amz-Credential")
  valid_402657293 = validateParameter(valid_402657293, JString,
                                      required = false, default = nil)
  if valid_402657293 != nil:
    section.add "X-Amz-Credential", valid_402657293
  var valid_402657294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657294 = validateParameter(valid_402657294, JString,
                                      required = false, default = nil)
  if valid_402657294 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657296: Call_GetDiskSnapshots_402657284;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all block storage disk snapshots in your AWS account and region.
                                                                                         ## 
  let valid = call_402657296.validator(path, query, header, formData, body, _)
  let scheme = call_402657296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657296.makeUrl(scheme.get, call_402657296.host, call_402657296.base,
                                   call_402657296.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657296, uri, valid, _)

proc call*(call_402657297: Call_GetDiskSnapshots_402657284; body: JsonNode): Recallable =
  ## getDiskSnapshots
  ## Returns information about all block storage disk snapshots in your AWS account and region.
  ##   
                                                                                               ## body: JObject (required)
  var body_402657298 = newJObject()
  if body != nil:
    body_402657298 = body
  result = call_402657297.call(nil, nil, nil, nil, body_402657298)

var getDiskSnapshots* = Call_GetDiskSnapshots_402657284(
    name: "getDiskSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDiskSnapshots",
    validator: validate_GetDiskSnapshots_402657285, base: "/",
    makeUrl: url_GetDiskSnapshots_402657286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisks_402657299 = ref object of OpenApiRestCall_402656044
proc url_GetDisks_402657301(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDisks_402657300(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about all block storage disks in your AWS account and region.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657302 = header.getOrDefault("X-Amz-Target")
  valid_402657302 = validateParameter(valid_402657302, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDisks"))
  if valid_402657302 != nil:
    section.add "X-Amz-Target", valid_402657302
  var valid_402657303 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657303 = validateParameter(valid_402657303, JString,
                                      required = false, default = nil)
  if valid_402657303 != nil:
    section.add "X-Amz-Security-Token", valid_402657303
  var valid_402657304 = header.getOrDefault("X-Amz-Signature")
  valid_402657304 = validateParameter(valid_402657304, JString,
                                      required = false, default = nil)
  if valid_402657304 != nil:
    section.add "X-Amz-Signature", valid_402657304
  var valid_402657305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657305 = validateParameter(valid_402657305, JString,
                                      required = false, default = nil)
  if valid_402657305 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657305
  var valid_402657306 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657306 = validateParameter(valid_402657306, JString,
                                      required = false, default = nil)
  if valid_402657306 != nil:
    section.add "X-Amz-Algorithm", valid_402657306
  var valid_402657307 = header.getOrDefault("X-Amz-Date")
  valid_402657307 = validateParameter(valid_402657307, JString,
                                      required = false, default = nil)
  if valid_402657307 != nil:
    section.add "X-Amz-Date", valid_402657307
  var valid_402657308 = header.getOrDefault("X-Amz-Credential")
  valid_402657308 = validateParameter(valid_402657308, JString,
                                      required = false, default = nil)
  if valid_402657308 != nil:
    section.add "X-Amz-Credential", valid_402657308
  var valid_402657309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657309 = validateParameter(valid_402657309, JString,
                                      required = false, default = nil)
  if valid_402657309 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657311: Call_GetDisks_402657299; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all block storage disks in your AWS account and region.
                                                                                         ## 
  let valid = call_402657311.validator(path, query, header, formData, body, _)
  let scheme = call_402657311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657311.makeUrl(scheme.get, call_402657311.host, call_402657311.base,
                                   call_402657311.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657311, uri, valid, _)

proc call*(call_402657312: Call_GetDisks_402657299; body: JsonNode): Recallable =
  ## getDisks
  ## Returns information about all block storage disks in your AWS account and region.
  ##   
                                                                                      ## body: JObject (required)
  var body_402657313 = newJObject()
  if body != nil:
    body_402657313 = body
  result = call_402657312.call(nil, nil, nil, nil, body_402657313)

var getDisks* = Call_GetDisks_402657299(name: "getDisks",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDisks",
                                        validator: validate_GetDisks_402657300,
                                        base: "/", makeUrl: url_GetDisks_402657301,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomain_402657314 = ref object of OpenApiRestCall_402656044
proc url_GetDomain_402657316(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomain_402657315(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657317 = header.getOrDefault("X-Amz-Target")
  valid_402657317 = validateParameter(valid_402657317, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDomain"))
  if valid_402657317 != nil:
    section.add "X-Amz-Target", valid_402657317
  var valid_402657318 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657318 = validateParameter(valid_402657318, JString,
                                      required = false, default = nil)
  if valid_402657318 != nil:
    section.add "X-Amz-Security-Token", valid_402657318
  var valid_402657319 = header.getOrDefault("X-Amz-Signature")
  valid_402657319 = validateParameter(valid_402657319, JString,
                                      required = false, default = nil)
  if valid_402657319 != nil:
    section.add "X-Amz-Signature", valid_402657319
  var valid_402657320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657320 = validateParameter(valid_402657320, JString,
                                      required = false, default = nil)
  if valid_402657320 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657320
  var valid_402657321 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657321 = validateParameter(valid_402657321, JString,
                                      required = false, default = nil)
  if valid_402657321 != nil:
    section.add "X-Amz-Algorithm", valid_402657321
  var valid_402657322 = header.getOrDefault("X-Amz-Date")
  valid_402657322 = validateParameter(valid_402657322, JString,
                                      required = false, default = nil)
  if valid_402657322 != nil:
    section.add "X-Amz-Date", valid_402657322
  var valid_402657323 = header.getOrDefault("X-Amz-Credential")
  valid_402657323 = validateParameter(valid_402657323, JString,
                                      required = false, default = nil)
  if valid_402657323 != nil:
    section.add "X-Amz-Credential", valid_402657323
  var valid_402657324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657324 = validateParameter(valid_402657324, JString,
                                      required = false, default = nil)
  if valid_402657324 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657326: Call_GetDomain_402657314; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific domain recordset.
                                                                                         ## 
  let valid = call_402657326.validator(path, query, header, formData, body, _)
  let scheme = call_402657326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657326.makeUrl(scheme.get, call_402657326.host, call_402657326.base,
                                   call_402657326.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657326, uri, valid, _)

proc call*(call_402657327: Call_GetDomain_402657314; body: JsonNode): Recallable =
  ## getDomain
  ## Returns information about a specific domain recordset.
  ##   body: JObject (required)
  var body_402657328 = newJObject()
  if body != nil:
    body_402657328 = body
  result = call_402657327.call(nil, nil, nil, nil, body_402657328)

var getDomain* = Call_GetDomain_402657314(name: "getDomain",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDomain",
    validator: validate_GetDomain_402657315, base: "/", makeUrl: url_GetDomain_402657316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomains_402657329 = ref object of OpenApiRestCall_402656044
proc url_GetDomains_402657331(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomains_402657330(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657332 = header.getOrDefault("X-Amz-Target")
  valid_402657332 = validateParameter(valid_402657332, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDomains"))
  if valid_402657332 != nil:
    section.add "X-Amz-Target", valid_402657332
  var valid_402657333 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657333 = validateParameter(valid_402657333, JString,
                                      required = false, default = nil)
  if valid_402657333 != nil:
    section.add "X-Amz-Security-Token", valid_402657333
  var valid_402657334 = header.getOrDefault("X-Amz-Signature")
  valid_402657334 = validateParameter(valid_402657334, JString,
                                      required = false, default = nil)
  if valid_402657334 != nil:
    section.add "X-Amz-Signature", valid_402657334
  var valid_402657335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657335 = validateParameter(valid_402657335, JString,
                                      required = false, default = nil)
  if valid_402657335 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657335
  var valid_402657336 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657336 = validateParameter(valid_402657336, JString,
                                      required = false, default = nil)
  if valid_402657336 != nil:
    section.add "X-Amz-Algorithm", valid_402657336
  var valid_402657337 = header.getOrDefault("X-Amz-Date")
  valid_402657337 = validateParameter(valid_402657337, JString,
                                      required = false, default = nil)
  if valid_402657337 != nil:
    section.add "X-Amz-Date", valid_402657337
  var valid_402657338 = header.getOrDefault("X-Amz-Credential")
  valid_402657338 = validateParameter(valid_402657338, JString,
                                      required = false, default = nil)
  if valid_402657338 != nil:
    section.add "X-Amz-Credential", valid_402657338
  var valid_402657339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657339 = validateParameter(valid_402657339, JString,
                                      required = false, default = nil)
  if valid_402657339 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657341: Call_GetDomains_402657329; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all domains in the user's account.
                                                                                         ## 
  let valid = call_402657341.validator(path, query, header, formData, body, _)
  let scheme = call_402657341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657341.makeUrl(scheme.get, call_402657341.host, call_402657341.base,
                                   call_402657341.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657341, uri, valid, _)

proc call*(call_402657342: Call_GetDomains_402657329; body: JsonNode): Recallable =
  ## getDomains
  ## Returns a list of all domains in the user's account.
  ##   body: JObject (required)
  var body_402657343 = newJObject()
  if body != nil:
    body_402657343 = body
  result = call_402657342.call(nil, nil, nil, nil, body_402657343)

var getDomains* = Call_GetDomains_402657329(name: "getDomains",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDomains",
    validator: validate_GetDomains_402657330, base: "/",
    makeUrl: url_GetDomains_402657331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportSnapshotRecords_402657344 = ref object of OpenApiRestCall_402656044
proc url_GetExportSnapshotRecords_402657346(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetExportSnapshotRecords_402657345(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657347 = header.getOrDefault("X-Amz-Target")
  valid_402657347 = validateParameter(valid_402657347, JString, required = true, default = newJString(
      "Lightsail_20161128.GetExportSnapshotRecords"))
  if valid_402657347 != nil:
    section.add "X-Amz-Target", valid_402657347
  var valid_402657348 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657348 = validateParameter(valid_402657348, JString,
                                      required = false, default = nil)
  if valid_402657348 != nil:
    section.add "X-Amz-Security-Token", valid_402657348
  var valid_402657349 = header.getOrDefault("X-Amz-Signature")
  valid_402657349 = validateParameter(valid_402657349, JString,
                                      required = false, default = nil)
  if valid_402657349 != nil:
    section.add "X-Amz-Signature", valid_402657349
  var valid_402657350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657350 = validateParameter(valid_402657350, JString,
                                      required = false, default = nil)
  if valid_402657350 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657350
  var valid_402657351 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657351 = validateParameter(valid_402657351, JString,
                                      required = false, default = nil)
  if valid_402657351 != nil:
    section.add "X-Amz-Algorithm", valid_402657351
  var valid_402657352 = header.getOrDefault("X-Amz-Date")
  valid_402657352 = validateParameter(valid_402657352, JString,
                                      required = false, default = nil)
  if valid_402657352 != nil:
    section.add "X-Amz-Date", valid_402657352
  var valid_402657353 = header.getOrDefault("X-Amz-Credential")
  valid_402657353 = validateParameter(valid_402657353, JString,
                                      required = false, default = nil)
  if valid_402657353 != nil:
    section.add "X-Amz-Credential", valid_402657353
  var valid_402657354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657354 = validateParameter(valid_402657354, JString,
                                      required = false, default = nil)
  if valid_402657354 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657356: Call_GetExportSnapshotRecords_402657344;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
                                                                                         ## 
  let valid = call_402657356.validator(path, query, header, formData, body, _)
  let scheme = call_402657356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657356.makeUrl(scheme.get, call_402657356.host, call_402657356.base,
                                   call_402657356.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657356, uri, valid, _)

proc call*(call_402657357: Call_GetExportSnapshotRecords_402657344;
           body: JsonNode): Recallable =
  ## getExportSnapshotRecords
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
  ##   
                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657358 = newJObject()
  if body != nil:
    body_402657358 = body
  result = call_402657357.call(nil, nil, nil, nil, body_402657358)

var getExportSnapshotRecords* = Call_GetExportSnapshotRecords_402657344(
    name: "getExportSnapshotRecords", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetExportSnapshotRecords",
    validator: validate_GetExportSnapshotRecords_402657345, base: "/",
    makeUrl: url_GetExportSnapshotRecords_402657346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstance_402657359 = ref object of OpenApiRestCall_402656044
proc url_GetInstance_402657361(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstance_402657360(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657362 = header.getOrDefault("X-Amz-Target")
  valid_402657362 = validateParameter(valid_402657362, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstance"))
  if valid_402657362 != nil:
    section.add "X-Amz-Target", valid_402657362
  var valid_402657363 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657363 = validateParameter(valid_402657363, JString,
                                      required = false, default = nil)
  if valid_402657363 != nil:
    section.add "X-Amz-Security-Token", valid_402657363
  var valid_402657364 = header.getOrDefault("X-Amz-Signature")
  valid_402657364 = validateParameter(valid_402657364, JString,
                                      required = false, default = nil)
  if valid_402657364 != nil:
    section.add "X-Amz-Signature", valid_402657364
  var valid_402657365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657365 = validateParameter(valid_402657365, JString,
                                      required = false, default = nil)
  if valid_402657365 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657365
  var valid_402657366 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657366 = validateParameter(valid_402657366, JString,
                                      required = false, default = nil)
  if valid_402657366 != nil:
    section.add "X-Amz-Algorithm", valid_402657366
  var valid_402657367 = header.getOrDefault("X-Amz-Date")
  valid_402657367 = validateParameter(valid_402657367, JString,
                                      required = false, default = nil)
  if valid_402657367 != nil:
    section.add "X-Amz-Date", valid_402657367
  var valid_402657368 = header.getOrDefault("X-Amz-Credential")
  valid_402657368 = validateParameter(valid_402657368, JString,
                                      required = false, default = nil)
  if valid_402657368 != nil:
    section.add "X-Amz-Credential", valid_402657368
  var valid_402657369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657369 = validateParameter(valid_402657369, JString,
                                      required = false, default = nil)
  if valid_402657369 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657371: Call_GetInstance_402657359; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
                                                                                         ## 
  let valid = call_402657371.validator(path, query, header, formData, body, _)
  let scheme = call_402657371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657371.makeUrl(scheme.get, call_402657371.host, call_402657371.base,
                                   call_402657371.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657371, uri, valid, _)

proc call*(call_402657372: Call_GetInstance_402657359; body: JsonNode): Recallable =
  ## getInstance
  ## Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
  ##   
                                                                                                       ## body: JObject (required)
  var body_402657373 = newJObject()
  if body != nil:
    body_402657373 = body
  result = call_402657372.call(nil, nil, nil, nil, body_402657373)

var getInstance* = Call_GetInstance_402657359(name: "getInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstance",
    validator: validate_GetInstance_402657360, base: "/",
    makeUrl: url_GetInstance_402657361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceAccessDetails_402657374 = ref object of OpenApiRestCall_402656044
proc url_GetInstanceAccessDetails_402657376(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceAccessDetails_402657375(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657377 = header.getOrDefault("X-Amz-Target")
  valid_402657377 = validateParameter(valid_402657377, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceAccessDetails"))
  if valid_402657377 != nil:
    section.add "X-Amz-Target", valid_402657377
  var valid_402657378 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657378 = validateParameter(valid_402657378, JString,
                                      required = false, default = nil)
  if valid_402657378 != nil:
    section.add "X-Amz-Security-Token", valid_402657378
  var valid_402657379 = header.getOrDefault("X-Amz-Signature")
  valid_402657379 = validateParameter(valid_402657379, JString,
                                      required = false, default = nil)
  if valid_402657379 != nil:
    section.add "X-Amz-Signature", valid_402657379
  var valid_402657380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657380 = validateParameter(valid_402657380, JString,
                                      required = false, default = nil)
  if valid_402657380 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657380
  var valid_402657381 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657381 = validateParameter(valid_402657381, JString,
                                      required = false, default = nil)
  if valid_402657381 != nil:
    section.add "X-Amz-Algorithm", valid_402657381
  var valid_402657382 = header.getOrDefault("X-Amz-Date")
  valid_402657382 = validateParameter(valid_402657382, JString,
                                      required = false, default = nil)
  if valid_402657382 != nil:
    section.add "X-Amz-Date", valid_402657382
  var valid_402657383 = header.getOrDefault("X-Amz-Credential")
  valid_402657383 = validateParameter(valid_402657383, JString,
                                      required = false, default = nil)
  if valid_402657383 != nil:
    section.add "X-Amz-Credential", valid_402657383
  var valid_402657384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657384 = validateParameter(valid_402657384, JString,
                                      required = false, default = nil)
  if valid_402657384 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657386: Call_GetInstanceAccessDetails_402657374;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402657386.validator(path, query, header, formData, body, _)
  let scheme = call_402657386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657386.makeUrl(scheme.get, call_402657386.host, call_402657386.base,
                                   call_402657386.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657386, uri, valid, _)

proc call*(call_402657387: Call_GetInstanceAccessDetails_402657374;
           body: JsonNode): Recallable =
  ## getInstanceAccessDetails
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402657388 = newJObject()
  if body != nil:
    body_402657388 = body
  result = call_402657387.call(nil, nil, nil, nil, body_402657388)

var getInstanceAccessDetails* = Call_GetInstanceAccessDetails_402657374(
    name: "getInstanceAccessDetails", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceAccessDetails",
    validator: validate_GetInstanceAccessDetails_402657375, base: "/",
    makeUrl: url_GetInstanceAccessDetails_402657376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceMetricData_402657389 = ref object of OpenApiRestCall_402656044
proc url_GetInstanceMetricData_402657391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceMetricData_402657390(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657392 = header.getOrDefault("X-Amz-Target")
  valid_402657392 = validateParameter(valid_402657392, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceMetricData"))
  if valid_402657392 != nil:
    section.add "X-Amz-Target", valid_402657392
  var valid_402657393 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657393 = validateParameter(valid_402657393, JString,
                                      required = false, default = nil)
  if valid_402657393 != nil:
    section.add "X-Amz-Security-Token", valid_402657393
  var valid_402657394 = header.getOrDefault("X-Amz-Signature")
  valid_402657394 = validateParameter(valid_402657394, JString,
                                      required = false, default = nil)
  if valid_402657394 != nil:
    section.add "X-Amz-Signature", valid_402657394
  var valid_402657395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657395 = validateParameter(valid_402657395, JString,
                                      required = false, default = nil)
  if valid_402657395 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657395
  var valid_402657396 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657396 = validateParameter(valid_402657396, JString,
                                      required = false, default = nil)
  if valid_402657396 != nil:
    section.add "X-Amz-Algorithm", valid_402657396
  var valid_402657397 = header.getOrDefault("X-Amz-Date")
  valid_402657397 = validateParameter(valid_402657397, JString,
                                      required = false, default = nil)
  if valid_402657397 != nil:
    section.add "X-Amz-Date", valid_402657397
  var valid_402657398 = header.getOrDefault("X-Amz-Credential")
  valid_402657398 = validateParameter(valid_402657398, JString,
                                      required = false, default = nil)
  if valid_402657398 != nil:
    section.add "X-Amz-Credential", valid_402657398
  var valid_402657399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657399 = validateParameter(valid_402657399, JString,
                                      required = false, default = nil)
  if valid_402657399 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657401: Call_GetInstanceMetricData_402657389;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the data points for the specified Amazon Lightsail instance metric, given an instance name.
                                                                                         ## 
  let valid = call_402657401.validator(path, query, header, formData, body, _)
  let scheme = call_402657401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657401.makeUrl(scheme.get, call_402657401.host, call_402657401.base,
                                   call_402657401.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657401, uri, valid, _)

proc call*(call_402657402: Call_GetInstanceMetricData_402657389; body: JsonNode): Recallable =
  ## getInstanceMetricData
  ## Returns the data points for the specified Amazon Lightsail instance metric, given an instance name.
  ##   
                                                                                                        ## body: JObject (required)
  var body_402657403 = newJObject()
  if body != nil:
    body_402657403 = body
  result = call_402657402.call(nil, nil, nil, nil, body_402657403)

var getInstanceMetricData* = Call_GetInstanceMetricData_402657389(
    name: "getInstanceMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceMetricData",
    validator: validate_GetInstanceMetricData_402657390, base: "/",
    makeUrl: url_GetInstanceMetricData_402657391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstancePortStates_402657404 = ref object of OpenApiRestCall_402656044
proc url_GetInstancePortStates_402657406(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstancePortStates_402657405(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657407 = header.getOrDefault("X-Amz-Target")
  valid_402657407 = validateParameter(valid_402657407, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstancePortStates"))
  if valid_402657407 != nil:
    section.add "X-Amz-Target", valid_402657407
  var valid_402657408 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657408 = validateParameter(valid_402657408, JString,
                                      required = false, default = nil)
  if valid_402657408 != nil:
    section.add "X-Amz-Security-Token", valid_402657408
  var valid_402657409 = header.getOrDefault("X-Amz-Signature")
  valid_402657409 = validateParameter(valid_402657409, JString,
                                      required = false, default = nil)
  if valid_402657409 != nil:
    section.add "X-Amz-Signature", valid_402657409
  var valid_402657410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657410 = validateParameter(valid_402657410, JString,
                                      required = false, default = nil)
  if valid_402657410 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657410
  var valid_402657411 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657411 = validateParameter(valid_402657411, JString,
                                      required = false, default = nil)
  if valid_402657411 != nil:
    section.add "X-Amz-Algorithm", valid_402657411
  var valid_402657412 = header.getOrDefault("X-Amz-Date")
  valid_402657412 = validateParameter(valid_402657412, JString,
                                      required = false, default = nil)
  if valid_402657412 != nil:
    section.add "X-Amz-Date", valid_402657412
  var valid_402657413 = header.getOrDefault("X-Amz-Credential")
  valid_402657413 = validateParameter(valid_402657413, JString,
                                      required = false, default = nil)
  if valid_402657413 != nil:
    section.add "X-Amz-Credential", valid_402657413
  var valid_402657414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657414 = validateParameter(valid_402657414, JString,
                                      required = false, default = nil)
  if valid_402657414 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657416: Call_GetInstancePortStates_402657404;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the port states for a specific virtual private server, or <i>instance</i>.
                                                                                         ## 
  let valid = call_402657416.validator(path, query, header, formData, body, _)
  let scheme = call_402657416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657416.makeUrl(scheme.get, call_402657416.host, call_402657416.base,
                                   call_402657416.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657416, uri, valid, _)

proc call*(call_402657417: Call_GetInstancePortStates_402657404; body: JsonNode): Recallable =
  ## getInstancePortStates
  ## Returns the port states for a specific virtual private server, or <i>instance</i>.
  ##   
                                                                                       ## body: JObject (required)
  var body_402657418 = newJObject()
  if body != nil:
    body_402657418 = body
  result = call_402657417.call(nil, nil, nil, nil, body_402657418)

var getInstancePortStates* = Call_GetInstancePortStates_402657404(
    name: "getInstancePortStates", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstancePortStates",
    validator: validate_GetInstancePortStates_402657405, base: "/",
    makeUrl: url_GetInstancePortStates_402657406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceSnapshot_402657419 = ref object of OpenApiRestCall_402656044
proc url_GetInstanceSnapshot_402657421(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceSnapshot_402657420(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657422 = header.getOrDefault("X-Amz-Target")
  valid_402657422 = validateParameter(valid_402657422, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceSnapshot"))
  if valid_402657422 != nil:
    section.add "X-Amz-Target", valid_402657422
  var valid_402657423 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657423 = validateParameter(valid_402657423, JString,
                                      required = false, default = nil)
  if valid_402657423 != nil:
    section.add "X-Amz-Security-Token", valid_402657423
  var valid_402657424 = header.getOrDefault("X-Amz-Signature")
  valid_402657424 = validateParameter(valid_402657424, JString,
                                      required = false, default = nil)
  if valid_402657424 != nil:
    section.add "X-Amz-Signature", valid_402657424
  var valid_402657425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657425 = validateParameter(valid_402657425, JString,
                                      required = false, default = nil)
  if valid_402657425 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657425
  var valid_402657426 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657426 = validateParameter(valid_402657426, JString,
                                      required = false, default = nil)
  if valid_402657426 != nil:
    section.add "X-Amz-Algorithm", valid_402657426
  var valid_402657427 = header.getOrDefault("X-Amz-Date")
  valid_402657427 = validateParameter(valid_402657427, JString,
                                      required = false, default = nil)
  if valid_402657427 != nil:
    section.add "X-Amz-Date", valid_402657427
  var valid_402657428 = header.getOrDefault("X-Amz-Credential")
  valid_402657428 = validateParameter(valid_402657428, JString,
                                      required = false, default = nil)
  if valid_402657428 != nil:
    section.add "X-Amz-Credential", valid_402657428
  var valid_402657429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657429 = validateParameter(valid_402657429, JString,
                                      required = false, default = nil)
  if valid_402657429 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657431: Call_GetInstanceSnapshot_402657419;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific instance snapshot.
                                                                                         ## 
  let valid = call_402657431.validator(path, query, header, formData, body, _)
  let scheme = call_402657431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657431.makeUrl(scheme.get, call_402657431.host, call_402657431.base,
                                   call_402657431.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657431, uri, valid, _)

proc call*(call_402657432: Call_GetInstanceSnapshot_402657419; body: JsonNode): Recallable =
  ## getInstanceSnapshot
  ## Returns information about a specific instance snapshot.
  ##   body: JObject (required)
  var body_402657433 = newJObject()
  if body != nil:
    body_402657433 = body
  result = call_402657432.call(nil, nil, nil, nil, body_402657433)

var getInstanceSnapshot* = Call_GetInstanceSnapshot_402657419(
    name: "getInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceSnapshot",
    validator: validate_GetInstanceSnapshot_402657420, base: "/",
    makeUrl: url_GetInstanceSnapshot_402657421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceSnapshots_402657434 = ref object of OpenApiRestCall_402656044
proc url_GetInstanceSnapshots_402657436(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceSnapshots_402657435(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657437 = header.getOrDefault("X-Amz-Target")
  valid_402657437 = validateParameter(valid_402657437, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceSnapshots"))
  if valid_402657437 != nil:
    section.add "X-Amz-Target", valid_402657437
  var valid_402657438 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657438 = validateParameter(valid_402657438, JString,
                                      required = false, default = nil)
  if valid_402657438 != nil:
    section.add "X-Amz-Security-Token", valid_402657438
  var valid_402657439 = header.getOrDefault("X-Amz-Signature")
  valid_402657439 = validateParameter(valid_402657439, JString,
                                      required = false, default = nil)
  if valid_402657439 != nil:
    section.add "X-Amz-Signature", valid_402657439
  var valid_402657440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657440 = validateParameter(valid_402657440, JString,
                                      required = false, default = nil)
  if valid_402657440 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657440
  var valid_402657441 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657441 = validateParameter(valid_402657441, JString,
                                      required = false, default = nil)
  if valid_402657441 != nil:
    section.add "X-Amz-Algorithm", valid_402657441
  var valid_402657442 = header.getOrDefault("X-Amz-Date")
  valid_402657442 = validateParameter(valid_402657442, JString,
                                      required = false, default = nil)
  if valid_402657442 != nil:
    section.add "X-Amz-Date", valid_402657442
  var valid_402657443 = header.getOrDefault("X-Amz-Credential")
  valid_402657443 = validateParameter(valid_402657443, JString,
                                      required = false, default = nil)
  if valid_402657443 != nil:
    section.add "X-Amz-Credential", valid_402657443
  var valid_402657444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657444 = validateParameter(valid_402657444, JString,
                                      required = false, default = nil)
  if valid_402657444 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657446: Call_GetInstanceSnapshots_402657434;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all instance snapshots for the user's account.
                                                                                         ## 
  let valid = call_402657446.validator(path, query, header, formData, body, _)
  let scheme = call_402657446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657446.makeUrl(scheme.get, call_402657446.host, call_402657446.base,
                                   call_402657446.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657446, uri, valid, _)

proc call*(call_402657447: Call_GetInstanceSnapshots_402657434; body: JsonNode): Recallable =
  ## getInstanceSnapshots
  ## Returns all instance snapshots for the user's account.
  ##   body: JObject (required)
  var body_402657448 = newJObject()
  if body != nil:
    body_402657448 = body
  result = call_402657447.call(nil, nil, nil, nil, body_402657448)

var getInstanceSnapshots* = Call_GetInstanceSnapshots_402657434(
    name: "getInstanceSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceSnapshots",
    validator: validate_GetInstanceSnapshots_402657435, base: "/",
    makeUrl: url_GetInstanceSnapshots_402657436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceState_402657449 = ref object of OpenApiRestCall_402656044
proc url_GetInstanceState_402657451(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceState_402657450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657452 = header.getOrDefault("X-Amz-Target")
  valid_402657452 = validateParameter(valid_402657452, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceState"))
  if valid_402657452 != nil:
    section.add "X-Amz-Target", valid_402657452
  var valid_402657453 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657453 = validateParameter(valid_402657453, JString,
                                      required = false, default = nil)
  if valid_402657453 != nil:
    section.add "X-Amz-Security-Token", valid_402657453
  var valid_402657454 = header.getOrDefault("X-Amz-Signature")
  valid_402657454 = validateParameter(valid_402657454, JString,
                                      required = false, default = nil)
  if valid_402657454 != nil:
    section.add "X-Amz-Signature", valid_402657454
  var valid_402657455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657455 = validateParameter(valid_402657455, JString,
                                      required = false, default = nil)
  if valid_402657455 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657455
  var valid_402657456 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657456 = validateParameter(valid_402657456, JString,
                                      required = false, default = nil)
  if valid_402657456 != nil:
    section.add "X-Amz-Algorithm", valid_402657456
  var valid_402657457 = header.getOrDefault("X-Amz-Date")
  valid_402657457 = validateParameter(valid_402657457, JString,
                                      required = false, default = nil)
  if valid_402657457 != nil:
    section.add "X-Amz-Date", valid_402657457
  var valid_402657458 = header.getOrDefault("X-Amz-Credential")
  valid_402657458 = validateParameter(valid_402657458, JString,
                                      required = false, default = nil)
  if valid_402657458 != nil:
    section.add "X-Amz-Credential", valid_402657458
  var valid_402657459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657459 = validateParameter(valid_402657459, JString,
                                      required = false, default = nil)
  if valid_402657459 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657461: Call_GetInstanceState_402657449;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the state of a specific instance. Works on one instance at a time.
                                                                                         ## 
  let valid = call_402657461.validator(path, query, header, formData, body, _)
  let scheme = call_402657461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657461.makeUrl(scheme.get, call_402657461.host, call_402657461.base,
                                   call_402657461.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657461, uri, valid, _)

proc call*(call_402657462: Call_GetInstanceState_402657449; body: JsonNode): Recallable =
  ## getInstanceState
  ## Returns the state of a specific instance. Works on one instance at a time.
  ##   
                                                                               ## body: JObject (required)
  var body_402657463 = newJObject()
  if body != nil:
    body_402657463 = body
  result = call_402657462.call(nil, nil, nil, nil, body_402657463)

var getInstanceState* = Call_GetInstanceState_402657449(
    name: "getInstanceState", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceState",
    validator: validate_GetInstanceState_402657450, base: "/",
    makeUrl: url_GetInstanceState_402657451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstances_402657464 = ref object of OpenApiRestCall_402656044
proc url_GetInstances_402657466(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstances_402657465(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657467 = header.getOrDefault("X-Amz-Target")
  valid_402657467 = validateParameter(valid_402657467, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstances"))
  if valid_402657467 != nil:
    section.add "X-Amz-Target", valid_402657467
  var valid_402657468 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657468 = validateParameter(valid_402657468, JString,
                                      required = false, default = nil)
  if valid_402657468 != nil:
    section.add "X-Amz-Security-Token", valid_402657468
  var valid_402657469 = header.getOrDefault("X-Amz-Signature")
  valid_402657469 = validateParameter(valid_402657469, JString,
                                      required = false, default = nil)
  if valid_402657469 != nil:
    section.add "X-Amz-Signature", valid_402657469
  var valid_402657470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657470 = validateParameter(valid_402657470, JString,
                                      required = false, default = nil)
  if valid_402657470 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657470
  var valid_402657471 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657471 = validateParameter(valid_402657471, JString,
                                      required = false, default = nil)
  if valid_402657471 != nil:
    section.add "X-Amz-Algorithm", valid_402657471
  var valid_402657472 = header.getOrDefault("X-Amz-Date")
  valid_402657472 = validateParameter(valid_402657472, JString,
                                      required = false, default = nil)
  if valid_402657472 != nil:
    section.add "X-Amz-Date", valid_402657472
  var valid_402657473 = header.getOrDefault("X-Amz-Credential")
  valid_402657473 = validateParameter(valid_402657473, JString,
                                      required = false, default = nil)
  if valid_402657473 != nil:
    section.add "X-Amz-Credential", valid_402657473
  var valid_402657474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657474 = validateParameter(valid_402657474, JString,
                                      required = false, default = nil)
  if valid_402657474 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657476: Call_GetInstances_402657464; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
                                                                                         ## 
  let valid = call_402657476.validator(path, query, header, formData, body, _)
  let scheme = call_402657476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657476.makeUrl(scheme.get, call_402657476.host, call_402657476.base,
                                   call_402657476.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657476, uri, valid, _)

proc call*(call_402657477: Call_GetInstances_402657464; body: JsonNode): Recallable =
  ## getInstances
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
  ##   
                                                                                                 ## body: JObject (required)
  var body_402657478 = newJObject()
  if body != nil:
    body_402657478 = body
  result = call_402657477.call(nil, nil, nil, nil, body_402657478)

var getInstances* = Call_GetInstances_402657464(name: "getInstances",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstances",
    validator: validate_GetInstances_402657465, base: "/",
    makeUrl: url_GetInstances_402657466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPair_402657479 = ref object of OpenApiRestCall_402656044
proc url_GetKeyPair_402657481(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetKeyPair_402657480(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657482 = header.getOrDefault("X-Amz-Target")
  valid_402657482 = validateParameter(valid_402657482, JString, required = true, default = newJString(
      "Lightsail_20161128.GetKeyPair"))
  if valid_402657482 != nil:
    section.add "X-Amz-Target", valid_402657482
  var valid_402657483 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657483 = validateParameter(valid_402657483, JString,
                                      required = false, default = nil)
  if valid_402657483 != nil:
    section.add "X-Amz-Security-Token", valid_402657483
  var valid_402657484 = header.getOrDefault("X-Amz-Signature")
  valid_402657484 = validateParameter(valid_402657484, JString,
                                      required = false, default = nil)
  if valid_402657484 != nil:
    section.add "X-Amz-Signature", valid_402657484
  var valid_402657485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657485 = validateParameter(valid_402657485, JString,
                                      required = false, default = nil)
  if valid_402657485 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657485
  var valid_402657486 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657486 = validateParameter(valid_402657486, JString,
                                      required = false, default = nil)
  if valid_402657486 != nil:
    section.add "X-Amz-Algorithm", valid_402657486
  var valid_402657487 = header.getOrDefault("X-Amz-Date")
  valid_402657487 = validateParameter(valid_402657487, JString,
                                      required = false, default = nil)
  if valid_402657487 != nil:
    section.add "X-Amz-Date", valid_402657487
  var valid_402657488 = header.getOrDefault("X-Amz-Credential")
  valid_402657488 = validateParameter(valid_402657488, JString,
                                      required = false, default = nil)
  if valid_402657488 != nil:
    section.add "X-Amz-Credential", valid_402657488
  var valid_402657489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657489 = validateParameter(valid_402657489, JString,
                                      required = false, default = nil)
  if valid_402657489 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657491: Call_GetKeyPair_402657479; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific key pair.
                                                                                         ## 
  let valid = call_402657491.validator(path, query, header, formData, body, _)
  let scheme = call_402657491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657491.makeUrl(scheme.get, call_402657491.host, call_402657491.base,
                                   call_402657491.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657491, uri, valid, _)

proc call*(call_402657492: Call_GetKeyPair_402657479; body: JsonNode): Recallable =
  ## getKeyPair
  ## Returns information about a specific key pair.
  ##   body: JObject (required)
  var body_402657493 = newJObject()
  if body != nil:
    body_402657493 = body
  result = call_402657492.call(nil, nil, nil, nil, body_402657493)

var getKeyPair* = Call_GetKeyPair_402657479(name: "getKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetKeyPair",
    validator: validate_GetKeyPair_402657480, base: "/",
    makeUrl: url_GetKeyPair_402657481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPairs_402657494 = ref object of OpenApiRestCall_402656044
proc url_GetKeyPairs_402657496(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetKeyPairs_402657495(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657497 = header.getOrDefault("X-Amz-Target")
  valid_402657497 = validateParameter(valid_402657497, JString, required = true, default = newJString(
      "Lightsail_20161128.GetKeyPairs"))
  if valid_402657497 != nil:
    section.add "X-Amz-Target", valid_402657497
  var valid_402657498 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657498 = validateParameter(valid_402657498, JString,
                                      required = false, default = nil)
  if valid_402657498 != nil:
    section.add "X-Amz-Security-Token", valid_402657498
  var valid_402657499 = header.getOrDefault("X-Amz-Signature")
  valid_402657499 = validateParameter(valid_402657499, JString,
                                      required = false, default = nil)
  if valid_402657499 != nil:
    section.add "X-Amz-Signature", valid_402657499
  var valid_402657500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657500 = validateParameter(valid_402657500, JString,
                                      required = false, default = nil)
  if valid_402657500 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657500
  var valid_402657501 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657501 = validateParameter(valid_402657501, JString,
                                      required = false, default = nil)
  if valid_402657501 != nil:
    section.add "X-Amz-Algorithm", valid_402657501
  var valid_402657502 = header.getOrDefault("X-Amz-Date")
  valid_402657502 = validateParameter(valid_402657502, JString,
                                      required = false, default = nil)
  if valid_402657502 != nil:
    section.add "X-Amz-Date", valid_402657502
  var valid_402657503 = header.getOrDefault("X-Amz-Credential")
  valid_402657503 = validateParameter(valid_402657503, JString,
                                      required = false, default = nil)
  if valid_402657503 != nil:
    section.add "X-Amz-Credential", valid_402657503
  var valid_402657504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657504 = validateParameter(valid_402657504, JString,
                                      required = false, default = nil)
  if valid_402657504 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657506: Call_GetKeyPairs_402657494; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all key pairs in the user's account.
                                                                                         ## 
  let valid = call_402657506.validator(path, query, header, formData, body, _)
  let scheme = call_402657506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657506.makeUrl(scheme.get, call_402657506.host, call_402657506.base,
                                   call_402657506.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657506, uri, valid, _)

proc call*(call_402657507: Call_GetKeyPairs_402657494; body: JsonNode): Recallable =
  ## getKeyPairs
  ## Returns information about all key pairs in the user's account.
  ##   body: JObject (required)
  var body_402657508 = newJObject()
  if body != nil:
    body_402657508 = body
  result = call_402657507.call(nil, nil, nil, nil, body_402657508)

var getKeyPairs* = Call_GetKeyPairs_402657494(name: "getKeyPairs",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetKeyPairs",
    validator: validate_GetKeyPairs_402657495, base: "/",
    makeUrl: url_GetKeyPairs_402657496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancer_402657509 = ref object of OpenApiRestCall_402656044
proc url_GetLoadBalancer_402657511(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLoadBalancer_402657510(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657512 = header.getOrDefault("X-Amz-Target")
  valid_402657512 = validateParameter(valid_402657512, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancer"))
  if valid_402657512 != nil:
    section.add "X-Amz-Target", valid_402657512
  var valid_402657513 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657513 = validateParameter(valid_402657513, JString,
                                      required = false, default = nil)
  if valid_402657513 != nil:
    section.add "X-Amz-Security-Token", valid_402657513
  var valid_402657514 = header.getOrDefault("X-Amz-Signature")
  valid_402657514 = validateParameter(valid_402657514, JString,
                                      required = false, default = nil)
  if valid_402657514 != nil:
    section.add "X-Amz-Signature", valid_402657514
  var valid_402657515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657515 = validateParameter(valid_402657515, JString,
                                      required = false, default = nil)
  if valid_402657515 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657515
  var valid_402657516 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657516 = validateParameter(valid_402657516, JString,
                                      required = false, default = nil)
  if valid_402657516 != nil:
    section.add "X-Amz-Algorithm", valid_402657516
  var valid_402657517 = header.getOrDefault("X-Amz-Date")
  valid_402657517 = validateParameter(valid_402657517, JString,
                                      required = false, default = nil)
  if valid_402657517 != nil:
    section.add "X-Amz-Date", valid_402657517
  var valid_402657518 = header.getOrDefault("X-Amz-Credential")
  valid_402657518 = validateParameter(valid_402657518, JString,
                                      required = false, default = nil)
  if valid_402657518 != nil:
    section.add "X-Amz-Credential", valid_402657518
  var valid_402657519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657519 = validateParameter(valid_402657519, JString,
                                      required = false, default = nil)
  if valid_402657519 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657521: Call_GetLoadBalancer_402657509; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified Lightsail load balancer.
                                                                                         ## 
  let valid = call_402657521.validator(path, query, header, formData, body, _)
  let scheme = call_402657521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657521.makeUrl(scheme.get, call_402657521.host, call_402657521.base,
                                   call_402657521.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657521, uri, valid, _)

proc call*(call_402657522: Call_GetLoadBalancer_402657509; body: JsonNode): Recallable =
  ## getLoadBalancer
  ## Returns information about the specified Lightsail load balancer.
  ##   body: JObject (required)
  var body_402657523 = newJObject()
  if body != nil:
    body_402657523 = body
  result = call_402657522.call(nil, nil, nil, nil, body_402657523)

var getLoadBalancer* = Call_GetLoadBalancer_402657509(name: "getLoadBalancer",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancer",
    validator: validate_GetLoadBalancer_402657510, base: "/",
    makeUrl: url_GetLoadBalancer_402657511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancerMetricData_402657524 = ref object of OpenApiRestCall_402656044
proc url_GetLoadBalancerMetricData_402657526(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLoadBalancerMetricData_402657525(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657527 = header.getOrDefault("X-Amz-Target")
  valid_402657527 = validateParameter(valid_402657527, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancerMetricData"))
  if valid_402657527 != nil:
    section.add "X-Amz-Target", valid_402657527
  var valid_402657528 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657528 = validateParameter(valid_402657528, JString,
                                      required = false, default = nil)
  if valid_402657528 != nil:
    section.add "X-Amz-Security-Token", valid_402657528
  var valid_402657529 = header.getOrDefault("X-Amz-Signature")
  valid_402657529 = validateParameter(valid_402657529, JString,
                                      required = false, default = nil)
  if valid_402657529 != nil:
    section.add "X-Amz-Signature", valid_402657529
  var valid_402657530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657530 = validateParameter(valid_402657530, JString,
                                      required = false, default = nil)
  if valid_402657530 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657530
  var valid_402657531 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657531 = validateParameter(valid_402657531, JString,
                                      required = false, default = nil)
  if valid_402657531 != nil:
    section.add "X-Amz-Algorithm", valid_402657531
  var valid_402657532 = header.getOrDefault("X-Amz-Date")
  valid_402657532 = validateParameter(valid_402657532, JString,
                                      required = false, default = nil)
  if valid_402657532 != nil:
    section.add "X-Amz-Date", valid_402657532
  var valid_402657533 = header.getOrDefault("X-Amz-Credential")
  valid_402657533 = validateParameter(valid_402657533, JString,
                                      required = false, default = nil)
  if valid_402657533 != nil:
    section.add "X-Amz-Credential", valid_402657533
  var valid_402657534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657534 = validateParameter(valid_402657534, JString,
                                      required = false, default = nil)
  if valid_402657534 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657536: Call_GetLoadBalancerMetricData_402657524;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about health metrics for your Lightsail load balancer.
                                                                                         ## 
  let valid = call_402657536.validator(path, query, header, formData, body, _)
  let scheme = call_402657536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657536.makeUrl(scheme.get, call_402657536.host, call_402657536.base,
                                   call_402657536.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657536, uri, valid, _)

proc call*(call_402657537: Call_GetLoadBalancerMetricData_402657524;
           body: JsonNode): Recallable =
  ## getLoadBalancerMetricData
  ## Returns information about health metrics for your Lightsail load balancer.
  ##   
                                                                               ## body: JObject (required)
  var body_402657538 = newJObject()
  if body != nil:
    body_402657538 = body
  result = call_402657537.call(nil, nil, nil, nil, body_402657538)

var getLoadBalancerMetricData* = Call_GetLoadBalancerMetricData_402657524(
    name: "getLoadBalancerMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancerMetricData",
    validator: validate_GetLoadBalancerMetricData_402657525, base: "/",
    makeUrl: url_GetLoadBalancerMetricData_402657526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancerTlsCertificates_402657539 = ref object of OpenApiRestCall_402656044
proc url_GetLoadBalancerTlsCertificates_402657541(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLoadBalancerTlsCertificates_402657540(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657542 = header.getOrDefault("X-Amz-Target")
  valid_402657542 = validateParameter(valid_402657542, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancerTlsCertificates"))
  if valid_402657542 != nil:
    section.add "X-Amz-Target", valid_402657542
  var valid_402657543 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657543 = validateParameter(valid_402657543, JString,
                                      required = false, default = nil)
  if valid_402657543 != nil:
    section.add "X-Amz-Security-Token", valid_402657543
  var valid_402657544 = header.getOrDefault("X-Amz-Signature")
  valid_402657544 = validateParameter(valid_402657544, JString,
                                      required = false, default = nil)
  if valid_402657544 != nil:
    section.add "X-Amz-Signature", valid_402657544
  var valid_402657545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657545 = validateParameter(valid_402657545, JString,
                                      required = false, default = nil)
  if valid_402657545 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657545
  var valid_402657546 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657546 = validateParameter(valid_402657546, JString,
                                      required = false, default = nil)
  if valid_402657546 != nil:
    section.add "X-Amz-Algorithm", valid_402657546
  var valid_402657547 = header.getOrDefault("X-Amz-Date")
  valid_402657547 = validateParameter(valid_402657547, JString,
                                      required = false, default = nil)
  if valid_402657547 != nil:
    section.add "X-Amz-Date", valid_402657547
  var valid_402657548 = header.getOrDefault("X-Amz-Credential")
  valid_402657548 = validateParameter(valid_402657548, JString,
                                      required = false, default = nil)
  if valid_402657548 != nil:
    section.add "X-Amz-Credential", valid_402657548
  var valid_402657549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657549 = validateParameter(valid_402657549, JString,
                                      required = false, default = nil)
  if valid_402657549 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657551: Call_GetLoadBalancerTlsCertificates_402657539;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the TLS certificates that are associated with the specified Lightsail load balancer.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.</p>
                                                                                         ## 
  let valid = call_402657551.validator(path, query, header, formData, body, _)
  let scheme = call_402657551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657551.makeUrl(scheme.get, call_402657551.host, call_402657551.base,
                                   call_402657551.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657551, uri, valid, _)

proc call*(call_402657552: Call_GetLoadBalancerTlsCertificates_402657539;
           body: JsonNode): Recallable =
  ## getLoadBalancerTlsCertificates
  ## <p>Returns information about the TLS certificates that are associated with the specified Lightsail load balancer.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402657553 = newJObject()
  if body != nil:
    body_402657553 = body
  result = call_402657552.call(nil, nil, nil, nil, body_402657553)

var getLoadBalancerTlsCertificates* = Call_GetLoadBalancerTlsCertificates_402657539(
    name: "getLoadBalancerTlsCertificates", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancerTlsCertificates",
    validator: validate_GetLoadBalancerTlsCertificates_402657540, base: "/",
    makeUrl: url_GetLoadBalancerTlsCertificates_402657541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancers_402657554 = ref object of OpenApiRestCall_402656044
proc url_GetLoadBalancers_402657556(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLoadBalancers_402657555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about all load balancers in an account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657557 = header.getOrDefault("X-Amz-Target")
  valid_402657557 = validateParameter(valid_402657557, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancers"))
  if valid_402657557 != nil:
    section.add "X-Amz-Target", valid_402657557
  var valid_402657558 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657558 = validateParameter(valid_402657558, JString,
                                      required = false, default = nil)
  if valid_402657558 != nil:
    section.add "X-Amz-Security-Token", valid_402657558
  var valid_402657559 = header.getOrDefault("X-Amz-Signature")
  valid_402657559 = validateParameter(valid_402657559, JString,
                                      required = false, default = nil)
  if valid_402657559 != nil:
    section.add "X-Amz-Signature", valid_402657559
  var valid_402657560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657560 = validateParameter(valid_402657560, JString,
                                      required = false, default = nil)
  if valid_402657560 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657560
  var valid_402657561 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657561 = validateParameter(valid_402657561, JString,
                                      required = false, default = nil)
  if valid_402657561 != nil:
    section.add "X-Amz-Algorithm", valid_402657561
  var valid_402657562 = header.getOrDefault("X-Amz-Date")
  valid_402657562 = validateParameter(valid_402657562, JString,
                                      required = false, default = nil)
  if valid_402657562 != nil:
    section.add "X-Amz-Date", valid_402657562
  var valid_402657563 = header.getOrDefault("X-Amz-Credential")
  valid_402657563 = validateParameter(valid_402657563, JString,
                                      required = false, default = nil)
  if valid_402657563 != nil:
    section.add "X-Amz-Credential", valid_402657563
  var valid_402657564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657564 = validateParameter(valid_402657564, JString,
                                      required = false, default = nil)
  if valid_402657564 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657566: Call_GetLoadBalancers_402657554;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all load balancers in an account.
                                                                                         ## 
  let valid = call_402657566.validator(path, query, header, formData, body, _)
  let scheme = call_402657566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657566.makeUrl(scheme.get, call_402657566.host, call_402657566.base,
                                   call_402657566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657566, uri, valid, _)

proc call*(call_402657567: Call_GetLoadBalancers_402657554; body: JsonNode): Recallable =
  ## getLoadBalancers
  ## Returns information about all load balancers in an account.
  ##   body: JObject (required)
  var body_402657568 = newJObject()
  if body != nil:
    body_402657568 = body
  result = call_402657567.call(nil, nil, nil, nil, body_402657568)

var getLoadBalancers* = Call_GetLoadBalancers_402657554(
    name: "getLoadBalancers", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancers",
    validator: validate_GetLoadBalancers_402657555, base: "/",
    makeUrl: url_GetLoadBalancers_402657556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperation_402657569 = ref object of OpenApiRestCall_402656044
proc url_GetOperation_402657571(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOperation_402657570(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657572 = header.getOrDefault("X-Amz-Target")
  valid_402657572 = validateParameter(valid_402657572, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperation"))
  if valid_402657572 != nil:
    section.add "X-Amz-Target", valid_402657572
  var valid_402657573 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657573 = validateParameter(valid_402657573, JString,
                                      required = false, default = nil)
  if valid_402657573 != nil:
    section.add "X-Amz-Security-Token", valid_402657573
  var valid_402657574 = header.getOrDefault("X-Amz-Signature")
  valid_402657574 = validateParameter(valid_402657574, JString,
                                      required = false, default = nil)
  if valid_402657574 != nil:
    section.add "X-Amz-Signature", valid_402657574
  var valid_402657575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657575 = validateParameter(valid_402657575, JString,
                                      required = false, default = nil)
  if valid_402657575 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657575
  var valid_402657576 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657576 = validateParameter(valid_402657576, JString,
                                      required = false, default = nil)
  if valid_402657576 != nil:
    section.add "X-Amz-Algorithm", valid_402657576
  var valid_402657577 = header.getOrDefault("X-Amz-Date")
  valid_402657577 = validateParameter(valid_402657577, JString,
                                      required = false, default = nil)
  if valid_402657577 != nil:
    section.add "X-Amz-Date", valid_402657577
  var valid_402657578 = header.getOrDefault("X-Amz-Credential")
  valid_402657578 = validateParameter(valid_402657578, JString,
                                      required = false, default = nil)
  if valid_402657578 != nil:
    section.add "X-Amz-Credential", valid_402657578
  var valid_402657579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657579 = validateParameter(valid_402657579, JString,
                                      required = false, default = nil)
  if valid_402657579 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657581: Call_GetOperation_402657569; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
                                                                                         ## 
  let valid = call_402657581.validator(path, query, header, formData, body, _)
  let scheme = call_402657581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657581.makeUrl(scheme.get, call_402657581.host, call_402657581.base,
                                   call_402657581.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657581, uri, valid, _)

proc call*(call_402657582: Call_GetOperation_402657569; body: JsonNode): Recallable =
  ## getOperation
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
  ##   
                                                                                                                                                                        ## body: JObject (required)
  var body_402657583 = newJObject()
  if body != nil:
    body_402657583 = body
  result = call_402657582.call(nil, nil, nil, nil, body_402657583)

var getOperation* = Call_GetOperation_402657569(name: "getOperation",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperation",
    validator: validate_GetOperation_402657570, base: "/",
    makeUrl: url_GetOperation_402657571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperations_402657584 = ref object of OpenApiRestCall_402656044
proc url_GetOperations_402657586(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOperations_402657585(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657587 = header.getOrDefault("X-Amz-Target")
  valid_402657587 = validateParameter(valid_402657587, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperations"))
  if valid_402657587 != nil:
    section.add "X-Amz-Target", valid_402657587
  var valid_402657588 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657588 = validateParameter(valid_402657588, JString,
                                      required = false, default = nil)
  if valid_402657588 != nil:
    section.add "X-Amz-Security-Token", valid_402657588
  var valid_402657589 = header.getOrDefault("X-Amz-Signature")
  valid_402657589 = validateParameter(valid_402657589, JString,
                                      required = false, default = nil)
  if valid_402657589 != nil:
    section.add "X-Amz-Signature", valid_402657589
  var valid_402657590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657590 = validateParameter(valid_402657590, JString,
                                      required = false, default = nil)
  if valid_402657590 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657590
  var valid_402657591 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657591 = validateParameter(valid_402657591, JString,
                                      required = false, default = nil)
  if valid_402657591 != nil:
    section.add "X-Amz-Algorithm", valid_402657591
  var valid_402657592 = header.getOrDefault("X-Amz-Date")
  valid_402657592 = validateParameter(valid_402657592, JString,
                                      required = false, default = nil)
  if valid_402657592 != nil:
    section.add "X-Amz-Date", valid_402657592
  var valid_402657593 = header.getOrDefault("X-Amz-Credential")
  valid_402657593 = validateParameter(valid_402657593, JString,
                                      required = false, default = nil)
  if valid_402657593 != nil:
    section.add "X-Amz-Credential", valid_402657593
  var valid_402657594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657594 = validateParameter(valid_402657594, JString,
                                      required = false, default = nil)
  if valid_402657594 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657596: Call_GetOperations_402657584; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
                                                                                         ## 
  let valid = call_402657596.validator(path, query, header, formData, body, _)
  let scheme = call_402657596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657596.makeUrl(scheme.get, call_402657596.host, call_402657596.base,
                                   call_402657596.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657596, uri, valid, _)

proc call*(call_402657597: Call_GetOperations_402657584; body: JsonNode): Recallable =
  ## getOperations
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
  ##   
                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657598 = newJObject()
  if body != nil:
    body_402657598 = body
  result = call_402657597.call(nil, nil, nil, nil, body_402657598)

var getOperations* = Call_GetOperations_402657584(name: "getOperations",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperations",
    validator: validate_GetOperations_402657585, base: "/",
    makeUrl: url_GetOperations_402657586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperationsForResource_402657599 = ref object of OpenApiRestCall_402656044
proc url_GetOperationsForResource_402657601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOperationsForResource_402657600(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657602 = header.getOrDefault("X-Amz-Target")
  valid_402657602 = validateParameter(valid_402657602, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperationsForResource"))
  if valid_402657602 != nil:
    section.add "X-Amz-Target", valid_402657602
  var valid_402657603 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657603 = validateParameter(valid_402657603, JString,
                                      required = false, default = nil)
  if valid_402657603 != nil:
    section.add "X-Amz-Security-Token", valid_402657603
  var valid_402657604 = header.getOrDefault("X-Amz-Signature")
  valid_402657604 = validateParameter(valid_402657604, JString,
                                      required = false, default = nil)
  if valid_402657604 != nil:
    section.add "X-Amz-Signature", valid_402657604
  var valid_402657605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657605 = validateParameter(valid_402657605, JString,
                                      required = false, default = nil)
  if valid_402657605 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657605
  var valid_402657606 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657606 = validateParameter(valid_402657606, JString,
                                      required = false, default = nil)
  if valid_402657606 != nil:
    section.add "X-Amz-Algorithm", valid_402657606
  var valid_402657607 = header.getOrDefault("X-Amz-Date")
  valid_402657607 = validateParameter(valid_402657607, JString,
                                      required = false, default = nil)
  if valid_402657607 != nil:
    section.add "X-Amz-Date", valid_402657607
  var valid_402657608 = header.getOrDefault("X-Amz-Credential")
  valid_402657608 = validateParameter(valid_402657608, JString,
                                      required = false, default = nil)
  if valid_402657608 != nil:
    section.add "X-Amz-Credential", valid_402657608
  var valid_402657609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657609 = validateParameter(valid_402657609, JString,
                                      required = false, default = nil)
  if valid_402657609 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657611: Call_GetOperationsForResource_402657599;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
                                                                                         ## 
  let valid = call_402657611.validator(path, query, header, formData, body, _)
  let scheme = call_402657611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657611.makeUrl(scheme.get, call_402657611.host, call_402657611.base,
                                   call_402657611.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657611, uri, valid, _)

proc call*(call_402657612: Call_GetOperationsForResource_402657599;
           body: JsonNode): Recallable =
  ## getOperationsForResource
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
  ##   
                                                                                ## body: JObject (required)
  var body_402657613 = newJObject()
  if body != nil:
    body_402657613 = body
  result = call_402657612.call(nil, nil, nil, nil, body_402657613)

var getOperationsForResource* = Call_GetOperationsForResource_402657599(
    name: "getOperationsForResource", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperationsForResource",
    validator: validate_GetOperationsForResource_402657600, base: "/",
    makeUrl: url_GetOperationsForResource_402657601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegions_402657614 = ref object of OpenApiRestCall_402656044
proc url_GetRegions_402657616(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRegions_402657615(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657617 = header.getOrDefault("X-Amz-Target")
  valid_402657617 = validateParameter(valid_402657617, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRegions"))
  if valid_402657617 != nil:
    section.add "X-Amz-Target", valid_402657617
  var valid_402657618 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657618 = validateParameter(valid_402657618, JString,
                                      required = false, default = nil)
  if valid_402657618 != nil:
    section.add "X-Amz-Security-Token", valid_402657618
  var valid_402657619 = header.getOrDefault("X-Amz-Signature")
  valid_402657619 = validateParameter(valid_402657619, JString,
                                      required = false, default = nil)
  if valid_402657619 != nil:
    section.add "X-Amz-Signature", valid_402657619
  var valid_402657620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657620 = validateParameter(valid_402657620, JString,
                                      required = false, default = nil)
  if valid_402657620 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657620
  var valid_402657621 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657621 = validateParameter(valid_402657621, JString,
                                      required = false, default = nil)
  if valid_402657621 != nil:
    section.add "X-Amz-Algorithm", valid_402657621
  var valid_402657622 = header.getOrDefault("X-Amz-Date")
  valid_402657622 = validateParameter(valid_402657622, JString,
                                      required = false, default = nil)
  if valid_402657622 != nil:
    section.add "X-Amz-Date", valid_402657622
  var valid_402657623 = header.getOrDefault("X-Amz-Credential")
  valid_402657623 = validateParameter(valid_402657623, JString,
                                      required = false, default = nil)
  if valid_402657623 != nil:
    section.add "X-Amz-Credential", valid_402657623
  var valid_402657624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657624 = validateParameter(valid_402657624, JString,
                                      required = false, default = nil)
  if valid_402657624 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657626: Call_GetRegions_402657614; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all valid regions for Amazon Lightsail. Use the <code>include availability zones</code> parameter to also return the Availability Zones in a region.
                                                                                         ## 
  let valid = call_402657626.validator(path, query, header, formData, body, _)
  let scheme = call_402657626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657626.makeUrl(scheme.get, call_402657626.host, call_402657626.base,
                                   call_402657626.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657626, uri, valid, _)

proc call*(call_402657627: Call_GetRegions_402657614; body: JsonNode): Recallable =
  ## getRegions
  ## Returns a list of all valid regions for Amazon Lightsail. Use the <code>include availability zones</code> parameter to also return the Availability Zones in a region.
  ##   
                                                                                                                                                                           ## body: JObject (required)
  var body_402657628 = newJObject()
  if body != nil:
    body_402657628 = body
  result = call_402657627.call(nil, nil, nil, nil, body_402657628)

var getRegions* = Call_GetRegions_402657614(name: "getRegions",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRegions",
    validator: validate_GetRegions_402657615, base: "/",
    makeUrl: url_GetRegions_402657616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabase_402657629 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabase_402657631(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabase_402657630(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657632 = header.getOrDefault("X-Amz-Target")
  valid_402657632 = validateParameter(valid_402657632, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabase"))
  if valid_402657632 != nil:
    section.add "X-Amz-Target", valid_402657632
  var valid_402657633 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657633 = validateParameter(valid_402657633, JString,
                                      required = false, default = nil)
  if valid_402657633 != nil:
    section.add "X-Amz-Security-Token", valid_402657633
  var valid_402657634 = header.getOrDefault("X-Amz-Signature")
  valid_402657634 = validateParameter(valid_402657634, JString,
                                      required = false, default = nil)
  if valid_402657634 != nil:
    section.add "X-Amz-Signature", valid_402657634
  var valid_402657635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657635 = validateParameter(valid_402657635, JString,
                                      required = false, default = nil)
  if valid_402657635 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657635
  var valid_402657636 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657636 = validateParameter(valid_402657636, JString,
                                      required = false, default = nil)
  if valid_402657636 != nil:
    section.add "X-Amz-Algorithm", valid_402657636
  var valid_402657637 = header.getOrDefault("X-Amz-Date")
  valid_402657637 = validateParameter(valid_402657637, JString,
                                      required = false, default = nil)
  if valid_402657637 != nil:
    section.add "X-Amz-Date", valid_402657637
  var valid_402657638 = header.getOrDefault("X-Amz-Credential")
  valid_402657638 = validateParameter(valid_402657638, JString,
                                      required = false, default = nil)
  if valid_402657638 != nil:
    section.add "X-Amz-Credential", valid_402657638
  var valid_402657639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657639 = validateParameter(valid_402657639, JString,
                                      required = false, default = nil)
  if valid_402657639 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657641: Call_GetRelationalDatabase_402657629;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific database in Amazon Lightsail.
                                                                                         ## 
  let valid = call_402657641.validator(path, query, header, formData, body, _)
  let scheme = call_402657641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657641.makeUrl(scheme.get, call_402657641.host, call_402657641.base,
                                   call_402657641.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657641, uri, valid, _)

proc call*(call_402657642: Call_GetRelationalDatabase_402657629; body: JsonNode): Recallable =
  ## getRelationalDatabase
  ## Returns information about a specific database in Amazon Lightsail.
  ##   body: JObject 
                                                                       ## (required)
  var body_402657643 = newJObject()
  if body != nil:
    body_402657643 = body
  result = call_402657642.call(nil, nil, nil, nil, body_402657643)

var getRelationalDatabase* = Call_GetRelationalDatabase_402657629(
    name: "getRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabase",
    validator: validate_GetRelationalDatabase_402657630, base: "/",
    makeUrl: url_GetRelationalDatabase_402657631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseBlueprints_402657644 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabaseBlueprints_402657646(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseBlueprints_402657645(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657647 = header.getOrDefault("X-Amz-Target")
  valid_402657647 = validateParameter(valid_402657647, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseBlueprints"))
  if valid_402657647 != nil:
    section.add "X-Amz-Target", valid_402657647
  var valid_402657648 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657648 = validateParameter(valid_402657648, JString,
                                      required = false, default = nil)
  if valid_402657648 != nil:
    section.add "X-Amz-Security-Token", valid_402657648
  var valid_402657649 = header.getOrDefault("X-Amz-Signature")
  valid_402657649 = validateParameter(valid_402657649, JString,
                                      required = false, default = nil)
  if valid_402657649 != nil:
    section.add "X-Amz-Signature", valid_402657649
  var valid_402657650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657650 = validateParameter(valid_402657650, JString,
                                      required = false, default = nil)
  if valid_402657650 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657650
  var valid_402657651 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657651 = validateParameter(valid_402657651, JString,
                                      required = false, default = nil)
  if valid_402657651 != nil:
    section.add "X-Amz-Algorithm", valid_402657651
  var valid_402657652 = header.getOrDefault("X-Amz-Date")
  valid_402657652 = validateParameter(valid_402657652, JString,
                                      required = false, default = nil)
  if valid_402657652 != nil:
    section.add "X-Amz-Date", valid_402657652
  var valid_402657653 = header.getOrDefault("X-Amz-Credential")
  valid_402657653 = validateParameter(valid_402657653, JString,
                                      required = false, default = nil)
  if valid_402657653 != nil:
    section.add "X-Amz-Credential", valid_402657653
  var valid_402657654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657654 = validateParameter(valid_402657654, JString,
                                      required = false, default = nil)
  if valid_402657654 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657656: Call_GetRelationalDatabaseBlueprints_402657644;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database.</p> <p>You can use a blueprint ID to create a new database that runs a specific database engine.</p>
                                                                                         ## 
  let valid = call_402657656.validator(path, query, header, formData, body, _)
  let scheme = call_402657656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657656.makeUrl(scheme.get, call_402657656.host, call_402657656.base,
                                   call_402657656.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657656, uri, valid, _)

proc call*(call_402657657: Call_GetRelationalDatabaseBlueprints_402657644;
           body: JsonNode): Recallable =
  ## getRelationalDatabaseBlueprints
  ## <p>Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database.</p> <p>You can use a blueprint ID to create a new database that runs a specific database engine.</p>
  ##   
                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402657658 = newJObject()
  if body != nil:
    body_402657658 = body
  result = call_402657657.call(nil, nil, nil, nil, body_402657658)

var getRelationalDatabaseBlueprints* = Call_GetRelationalDatabaseBlueprints_402657644(
    name: "getRelationalDatabaseBlueprints", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseBlueprints",
    validator: validate_GetRelationalDatabaseBlueprints_402657645, base: "/",
    makeUrl: url_GetRelationalDatabaseBlueprints_402657646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseBundles_402657659 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabaseBundles_402657661(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseBundles_402657660(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657662 = header.getOrDefault("X-Amz-Target")
  valid_402657662 = validateParameter(valid_402657662, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseBundles"))
  if valid_402657662 != nil:
    section.add "X-Amz-Target", valid_402657662
  var valid_402657663 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657663 = validateParameter(valid_402657663, JString,
                                      required = false, default = nil)
  if valid_402657663 != nil:
    section.add "X-Amz-Security-Token", valid_402657663
  var valid_402657664 = header.getOrDefault("X-Amz-Signature")
  valid_402657664 = validateParameter(valid_402657664, JString,
                                      required = false, default = nil)
  if valid_402657664 != nil:
    section.add "X-Amz-Signature", valid_402657664
  var valid_402657665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657665 = validateParameter(valid_402657665, JString,
                                      required = false, default = nil)
  if valid_402657665 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657665
  var valid_402657666 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657666 = validateParameter(valid_402657666, JString,
                                      required = false, default = nil)
  if valid_402657666 != nil:
    section.add "X-Amz-Algorithm", valid_402657666
  var valid_402657667 = header.getOrDefault("X-Amz-Date")
  valid_402657667 = validateParameter(valid_402657667, JString,
                                      required = false, default = nil)
  if valid_402657667 != nil:
    section.add "X-Amz-Date", valid_402657667
  var valid_402657668 = header.getOrDefault("X-Amz-Credential")
  valid_402657668 = validateParameter(valid_402657668, JString,
                                      required = false, default = nil)
  if valid_402657668 != nil:
    section.add "X-Amz-Credential", valid_402657668
  var valid_402657669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657669 = validateParameter(valid_402657669, JString,
                                      required = false, default = nil)
  if valid_402657669 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657671: Call_GetRelationalDatabaseBundles_402657659;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database.</p> <p>You can use a bundle ID to create a new database with explicit performance specifications.</p>
                                                                                         ## 
  let valid = call_402657671.validator(path, query, header, formData, body, _)
  let scheme = call_402657671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657671.makeUrl(scheme.get, call_402657671.host, call_402657671.base,
                                   call_402657671.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657671, uri, valid, _)

proc call*(call_402657672: Call_GetRelationalDatabaseBundles_402657659;
           body: JsonNode): Recallable =
  ## getRelationalDatabaseBundles
  ## <p>Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database.</p> <p>You can use a bundle ID to create a new database with explicit performance specifications.</p>
  ##   
                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657673 = newJObject()
  if body != nil:
    body_402657673 = body
  result = call_402657672.call(nil, nil, nil, nil, body_402657673)

var getRelationalDatabaseBundles* = Call_GetRelationalDatabaseBundles_402657659(
    name: "getRelationalDatabaseBundles", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseBundles",
    validator: validate_GetRelationalDatabaseBundles_402657660, base: "/",
    makeUrl: url_GetRelationalDatabaseBundles_402657661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseEvents_402657674 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabaseEvents_402657676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseEvents_402657675(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657677 = header.getOrDefault("X-Amz-Target")
  valid_402657677 = validateParameter(valid_402657677, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseEvents"))
  if valid_402657677 != nil:
    section.add "X-Amz-Target", valid_402657677
  var valid_402657678 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657678 = validateParameter(valid_402657678, JString,
                                      required = false, default = nil)
  if valid_402657678 != nil:
    section.add "X-Amz-Security-Token", valid_402657678
  var valid_402657679 = header.getOrDefault("X-Amz-Signature")
  valid_402657679 = validateParameter(valid_402657679, JString,
                                      required = false, default = nil)
  if valid_402657679 != nil:
    section.add "X-Amz-Signature", valid_402657679
  var valid_402657680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657680 = validateParameter(valid_402657680, JString,
                                      required = false, default = nil)
  if valid_402657680 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657680
  var valid_402657681 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657681 = validateParameter(valid_402657681, JString,
                                      required = false, default = nil)
  if valid_402657681 != nil:
    section.add "X-Amz-Algorithm", valid_402657681
  var valid_402657682 = header.getOrDefault("X-Amz-Date")
  valid_402657682 = validateParameter(valid_402657682, JString,
                                      required = false, default = nil)
  if valid_402657682 != nil:
    section.add "X-Amz-Date", valid_402657682
  var valid_402657683 = header.getOrDefault("X-Amz-Credential")
  valid_402657683 = validateParameter(valid_402657683, JString,
                                      required = false, default = nil)
  if valid_402657683 != nil:
    section.add "X-Amz-Credential", valid_402657683
  var valid_402657684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657684 = validateParameter(valid_402657684, JString,
                                      required = false, default = nil)
  if valid_402657684 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657686: Call_GetRelationalDatabaseEvents_402657674;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of events for a specific database in Amazon Lightsail.
                                                                                         ## 
  let valid = call_402657686.validator(path, query, header, formData, body, _)
  let scheme = call_402657686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657686.makeUrl(scheme.get, call_402657686.host, call_402657686.base,
                                   call_402657686.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657686, uri, valid, _)

proc call*(call_402657687: Call_GetRelationalDatabaseEvents_402657674;
           body: JsonNode): Recallable =
  ## getRelationalDatabaseEvents
  ## Returns a list of events for a specific database in Amazon Lightsail.
  ##   body: 
                                                                          ## JObject (required)
  var body_402657688 = newJObject()
  if body != nil:
    body_402657688 = body
  result = call_402657687.call(nil, nil, nil, nil, body_402657688)

var getRelationalDatabaseEvents* = Call_GetRelationalDatabaseEvents_402657674(
    name: "getRelationalDatabaseEvents", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseEvents",
    validator: validate_GetRelationalDatabaseEvents_402657675, base: "/",
    makeUrl: url_GetRelationalDatabaseEvents_402657676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseLogEvents_402657689 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabaseLogEvents_402657691(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseLogEvents_402657690(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657692 = header.getOrDefault("X-Amz-Target")
  valid_402657692 = validateParameter(valid_402657692, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseLogEvents"))
  if valid_402657692 != nil:
    section.add "X-Amz-Target", valid_402657692
  var valid_402657693 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657693 = validateParameter(valid_402657693, JString,
                                      required = false, default = nil)
  if valid_402657693 != nil:
    section.add "X-Amz-Security-Token", valid_402657693
  var valid_402657694 = header.getOrDefault("X-Amz-Signature")
  valid_402657694 = validateParameter(valid_402657694, JString,
                                      required = false, default = nil)
  if valid_402657694 != nil:
    section.add "X-Amz-Signature", valid_402657694
  var valid_402657695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657695 = validateParameter(valid_402657695, JString,
                                      required = false, default = nil)
  if valid_402657695 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657695
  var valid_402657696 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657696 = validateParameter(valid_402657696, JString,
                                      required = false, default = nil)
  if valid_402657696 != nil:
    section.add "X-Amz-Algorithm", valid_402657696
  var valid_402657697 = header.getOrDefault("X-Amz-Date")
  valid_402657697 = validateParameter(valid_402657697, JString,
                                      required = false, default = nil)
  if valid_402657697 != nil:
    section.add "X-Amz-Date", valid_402657697
  var valid_402657698 = header.getOrDefault("X-Amz-Credential")
  valid_402657698 = validateParameter(valid_402657698, JString,
                                      required = false, default = nil)
  if valid_402657698 != nil:
    section.add "X-Amz-Credential", valid_402657698
  var valid_402657699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657699 = validateParameter(valid_402657699, JString,
                                      required = false, default = nil)
  if valid_402657699 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657701: Call_GetRelationalDatabaseLogEvents_402657689;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of log events for a database in Amazon Lightsail.
                                                                                         ## 
  let valid = call_402657701.validator(path, query, header, formData, body, _)
  let scheme = call_402657701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657701.makeUrl(scheme.get, call_402657701.host, call_402657701.base,
                                   call_402657701.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657701, uri, valid, _)

proc call*(call_402657702: Call_GetRelationalDatabaseLogEvents_402657689;
           body: JsonNode): Recallable =
  ## getRelationalDatabaseLogEvents
  ## Returns a list of log events for a database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_402657703 = newJObject()
  if body != nil:
    body_402657703 = body
  result = call_402657702.call(nil, nil, nil, nil, body_402657703)

var getRelationalDatabaseLogEvents* = Call_GetRelationalDatabaseLogEvents_402657689(
    name: "getRelationalDatabaseLogEvents", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseLogEvents",
    validator: validate_GetRelationalDatabaseLogEvents_402657690, base: "/",
    makeUrl: url_GetRelationalDatabaseLogEvents_402657691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseLogStreams_402657704 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabaseLogStreams_402657706(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseLogStreams_402657705(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657707 = header.getOrDefault("X-Amz-Target")
  valid_402657707 = validateParameter(valid_402657707, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseLogStreams"))
  if valid_402657707 != nil:
    section.add "X-Amz-Target", valid_402657707
  var valid_402657708 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657708 = validateParameter(valid_402657708, JString,
                                      required = false, default = nil)
  if valid_402657708 != nil:
    section.add "X-Amz-Security-Token", valid_402657708
  var valid_402657709 = header.getOrDefault("X-Amz-Signature")
  valid_402657709 = validateParameter(valid_402657709, JString,
                                      required = false, default = nil)
  if valid_402657709 != nil:
    section.add "X-Amz-Signature", valid_402657709
  var valid_402657710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657710 = validateParameter(valid_402657710, JString,
                                      required = false, default = nil)
  if valid_402657710 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657710
  var valid_402657711 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657711 = validateParameter(valid_402657711, JString,
                                      required = false, default = nil)
  if valid_402657711 != nil:
    section.add "X-Amz-Algorithm", valid_402657711
  var valid_402657712 = header.getOrDefault("X-Amz-Date")
  valid_402657712 = validateParameter(valid_402657712, JString,
                                      required = false, default = nil)
  if valid_402657712 != nil:
    section.add "X-Amz-Date", valid_402657712
  var valid_402657713 = header.getOrDefault("X-Amz-Credential")
  valid_402657713 = validateParameter(valid_402657713, JString,
                                      required = false, default = nil)
  if valid_402657713 != nil:
    section.add "X-Amz-Credential", valid_402657713
  var valid_402657714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657714 = validateParameter(valid_402657714, JString,
                                      required = false, default = nil)
  if valid_402657714 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657716: Call_GetRelationalDatabaseLogStreams_402657704;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of available log streams for a specific database in Amazon Lightsail.
                                                                                         ## 
  let valid = call_402657716.validator(path, query, header, formData, body, _)
  let scheme = call_402657716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657716.makeUrl(scheme.get, call_402657716.host, call_402657716.base,
                                   call_402657716.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657716, uri, valid, _)

proc call*(call_402657717: Call_GetRelationalDatabaseLogStreams_402657704;
           body: JsonNode): Recallable =
  ## getRelationalDatabaseLogStreams
  ## Returns a list of available log streams for a specific database in Amazon Lightsail.
  ##   
                                                                                         ## body: JObject (required)
  var body_402657718 = newJObject()
  if body != nil:
    body_402657718 = body
  result = call_402657717.call(nil, nil, nil, nil, body_402657718)

var getRelationalDatabaseLogStreams* = Call_GetRelationalDatabaseLogStreams_402657704(
    name: "getRelationalDatabaseLogStreams", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseLogStreams",
    validator: validate_GetRelationalDatabaseLogStreams_402657705, base: "/",
    makeUrl: url_GetRelationalDatabaseLogStreams_402657706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseMasterUserPassword_402657719 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabaseMasterUserPassword_402657721(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseMasterUserPassword_402657720(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657722 = header.getOrDefault("X-Amz-Target")
  valid_402657722 = validateParameter(valid_402657722, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseMasterUserPassword"))
  if valid_402657722 != nil:
    section.add "X-Amz-Target", valid_402657722
  var valid_402657723 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657723 = validateParameter(valid_402657723, JString,
                                      required = false, default = nil)
  if valid_402657723 != nil:
    section.add "X-Amz-Security-Token", valid_402657723
  var valid_402657724 = header.getOrDefault("X-Amz-Signature")
  valid_402657724 = validateParameter(valid_402657724, JString,
                                      required = false, default = nil)
  if valid_402657724 != nil:
    section.add "X-Amz-Signature", valid_402657724
  var valid_402657725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657725 = validateParameter(valid_402657725, JString,
                                      required = false, default = nil)
  if valid_402657725 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657725
  var valid_402657726 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657726 = validateParameter(valid_402657726, JString,
                                      required = false, default = nil)
  if valid_402657726 != nil:
    section.add "X-Amz-Algorithm", valid_402657726
  var valid_402657727 = header.getOrDefault("X-Amz-Date")
  valid_402657727 = validateParameter(valid_402657727, JString,
                                      required = false, default = nil)
  if valid_402657727 != nil:
    section.add "X-Amz-Date", valid_402657727
  var valid_402657728 = header.getOrDefault("X-Amz-Credential")
  valid_402657728 = validateParameter(valid_402657728, JString,
                                      required = false, default = nil)
  if valid_402657728 != nil:
    section.add "X-Amz-Credential", valid_402657728
  var valid_402657729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657729 = validateParameter(valid_402657729, JString,
                                      required = false, default = nil)
  if valid_402657729 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657731: Call_GetRelationalDatabaseMasterUserPassword_402657719;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the current, previous, or pending versions of the master user password for a Lightsail database.</p> <p>The <code>GetRelationalDatabaseMasterUserPassword</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.</p>
                                                                                         ## 
  let valid = call_402657731.validator(path, query, header, formData, body, _)
  let scheme = call_402657731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657731.makeUrl(scheme.get, call_402657731.host, call_402657731.base,
                                   call_402657731.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657731, uri, valid, _)

proc call*(call_402657732: Call_GetRelationalDatabaseMasterUserPassword_402657719;
           body: JsonNode): Recallable =
  ## getRelationalDatabaseMasterUserPassword
  ## <p>Returns the current, previous, or pending versions of the master user password for a Lightsail database.</p> <p>The <code>GetRelationalDatabaseMasterUserPassword</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.</p>
  ##   
                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402657733 = newJObject()
  if body != nil:
    body_402657733 = body
  result = call_402657732.call(nil, nil, nil, nil, body_402657733)

var getRelationalDatabaseMasterUserPassword* = Call_GetRelationalDatabaseMasterUserPassword_402657719(
    name: "getRelationalDatabaseMasterUserPassword", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseMasterUserPassword",
    validator: validate_GetRelationalDatabaseMasterUserPassword_402657720,
    base: "/", makeUrl: url_GetRelationalDatabaseMasterUserPassword_402657721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseMetricData_402657734 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabaseMetricData_402657736(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseMetricData_402657735(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657737 = header.getOrDefault("X-Amz-Target")
  valid_402657737 = validateParameter(valid_402657737, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseMetricData"))
  if valid_402657737 != nil:
    section.add "X-Amz-Target", valid_402657737
  var valid_402657738 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657738 = validateParameter(valid_402657738, JString,
                                      required = false, default = nil)
  if valid_402657738 != nil:
    section.add "X-Amz-Security-Token", valid_402657738
  var valid_402657739 = header.getOrDefault("X-Amz-Signature")
  valid_402657739 = validateParameter(valid_402657739, JString,
                                      required = false, default = nil)
  if valid_402657739 != nil:
    section.add "X-Amz-Signature", valid_402657739
  var valid_402657740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657740 = validateParameter(valid_402657740, JString,
                                      required = false, default = nil)
  if valid_402657740 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657740
  var valid_402657741 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657741 = validateParameter(valid_402657741, JString,
                                      required = false, default = nil)
  if valid_402657741 != nil:
    section.add "X-Amz-Algorithm", valid_402657741
  var valid_402657742 = header.getOrDefault("X-Amz-Date")
  valid_402657742 = validateParameter(valid_402657742, JString,
                                      required = false, default = nil)
  if valid_402657742 != nil:
    section.add "X-Amz-Date", valid_402657742
  var valid_402657743 = header.getOrDefault("X-Amz-Credential")
  valid_402657743 = validateParameter(valid_402657743, JString,
                                      required = false, default = nil)
  if valid_402657743 != nil:
    section.add "X-Amz-Credential", valid_402657743
  var valid_402657744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657744 = validateParameter(valid_402657744, JString,
                                      required = false, default = nil)
  if valid_402657744 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657746: Call_GetRelationalDatabaseMetricData_402657734;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the data points of the specified metric for a database in Amazon Lightsail.
                                                                                         ## 
  let valid = call_402657746.validator(path, query, header, formData, body, _)
  let scheme = call_402657746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657746.makeUrl(scheme.get, call_402657746.host, call_402657746.base,
                                   call_402657746.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657746, uri, valid, _)

proc call*(call_402657747: Call_GetRelationalDatabaseMetricData_402657734;
           body: JsonNode): Recallable =
  ## getRelationalDatabaseMetricData
  ## Returns the data points of the specified metric for a database in Amazon Lightsail.
  ##   
                                                                                        ## body: JObject (required)
  var body_402657748 = newJObject()
  if body != nil:
    body_402657748 = body
  result = call_402657747.call(nil, nil, nil, nil, body_402657748)

var getRelationalDatabaseMetricData* = Call_GetRelationalDatabaseMetricData_402657734(
    name: "getRelationalDatabaseMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseMetricData",
    validator: validate_GetRelationalDatabaseMetricData_402657735, base: "/",
    makeUrl: url_GetRelationalDatabaseMetricData_402657736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseParameters_402657749 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabaseParameters_402657751(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseParameters_402657750(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657752 = header.getOrDefault("X-Amz-Target")
  valid_402657752 = validateParameter(valid_402657752, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseParameters"))
  if valid_402657752 != nil:
    section.add "X-Amz-Target", valid_402657752
  var valid_402657753 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657753 = validateParameter(valid_402657753, JString,
                                      required = false, default = nil)
  if valid_402657753 != nil:
    section.add "X-Amz-Security-Token", valid_402657753
  var valid_402657754 = header.getOrDefault("X-Amz-Signature")
  valid_402657754 = validateParameter(valid_402657754, JString,
                                      required = false, default = nil)
  if valid_402657754 != nil:
    section.add "X-Amz-Signature", valid_402657754
  var valid_402657755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657755 = validateParameter(valid_402657755, JString,
                                      required = false, default = nil)
  if valid_402657755 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657755
  var valid_402657756 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657756 = validateParameter(valid_402657756, JString,
                                      required = false, default = nil)
  if valid_402657756 != nil:
    section.add "X-Amz-Algorithm", valid_402657756
  var valid_402657757 = header.getOrDefault("X-Amz-Date")
  valid_402657757 = validateParameter(valid_402657757, JString,
                                      required = false, default = nil)
  if valid_402657757 != nil:
    section.add "X-Amz-Date", valid_402657757
  var valid_402657758 = header.getOrDefault("X-Amz-Credential")
  valid_402657758 = validateParameter(valid_402657758, JString,
                                      required = false, default = nil)
  if valid_402657758 != nil:
    section.add "X-Amz-Credential", valid_402657758
  var valid_402657759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657759 = validateParameter(valid_402657759, JString,
                                      required = false, default = nil)
  if valid_402657759 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657761: Call_GetRelationalDatabaseParameters_402657749;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail.</p> <p>In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.</p>
                                                                                         ## 
  let valid = call_402657761.validator(path, query, header, formData, body, _)
  let scheme = call_402657761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657761.makeUrl(scheme.get, call_402657761.host, call_402657761.base,
                                   call_402657761.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657761, uri, valid, _)

proc call*(call_402657762: Call_GetRelationalDatabaseParameters_402657749;
           body: JsonNode): Recallable =
  ## getRelationalDatabaseParameters
  ## <p>Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail.</p> <p>In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402657763 = newJObject()
  if body != nil:
    body_402657763 = body
  result = call_402657762.call(nil, nil, nil, nil, body_402657763)

var getRelationalDatabaseParameters* = Call_GetRelationalDatabaseParameters_402657749(
    name: "getRelationalDatabaseParameters", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseParameters",
    validator: validate_GetRelationalDatabaseParameters_402657750, base: "/",
    makeUrl: url_GetRelationalDatabaseParameters_402657751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseSnapshot_402657764 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabaseSnapshot_402657766(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseSnapshot_402657765(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657767 = header.getOrDefault("X-Amz-Target")
  valid_402657767 = validateParameter(valid_402657767, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseSnapshot"))
  if valid_402657767 != nil:
    section.add "X-Amz-Target", valid_402657767
  var valid_402657768 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657768 = validateParameter(valid_402657768, JString,
                                      required = false, default = nil)
  if valid_402657768 != nil:
    section.add "X-Amz-Security-Token", valid_402657768
  var valid_402657769 = header.getOrDefault("X-Amz-Signature")
  valid_402657769 = validateParameter(valid_402657769, JString,
                                      required = false, default = nil)
  if valid_402657769 != nil:
    section.add "X-Amz-Signature", valid_402657769
  var valid_402657770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657770 = validateParameter(valid_402657770, JString,
                                      required = false, default = nil)
  if valid_402657770 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657770
  var valid_402657771 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657771 = validateParameter(valid_402657771, JString,
                                      required = false, default = nil)
  if valid_402657771 != nil:
    section.add "X-Amz-Algorithm", valid_402657771
  var valid_402657772 = header.getOrDefault("X-Amz-Date")
  valid_402657772 = validateParameter(valid_402657772, JString,
                                      required = false, default = nil)
  if valid_402657772 != nil:
    section.add "X-Amz-Date", valid_402657772
  var valid_402657773 = header.getOrDefault("X-Amz-Credential")
  valid_402657773 = validateParameter(valid_402657773, JString,
                                      required = false, default = nil)
  if valid_402657773 != nil:
    section.add "X-Amz-Credential", valid_402657773
  var valid_402657774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657774 = validateParameter(valid_402657774, JString,
                                      required = false, default = nil)
  if valid_402657774 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657776: Call_GetRelationalDatabaseSnapshot_402657764;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific database snapshot in Amazon Lightsail.
                                                                                         ## 
  let valid = call_402657776.validator(path, query, header, formData, body, _)
  let scheme = call_402657776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657776.makeUrl(scheme.get, call_402657776.host, call_402657776.base,
                                   call_402657776.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657776, uri, valid, _)

proc call*(call_402657777: Call_GetRelationalDatabaseSnapshot_402657764;
           body: JsonNode): Recallable =
  ## getRelationalDatabaseSnapshot
  ## Returns information about a specific database snapshot in Amazon Lightsail.
  ##   
                                                                                ## body: JObject (required)
  var body_402657778 = newJObject()
  if body != nil:
    body_402657778 = body
  result = call_402657777.call(nil, nil, nil, nil, body_402657778)

var getRelationalDatabaseSnapshot* = Call_GetRelationalDatabaseSnapshot_402657764(
    name: "getRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseSnapshot",
    validator: validate_GetRelationalDatabaseSnapshot_402657765, base: "/",
    makeUrl: url_GetRelationalDatabaseSnapshot_402657766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseSnapshots_402657779 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabaseSnapshots_402657781(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseSnapshots_402657780(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657782 = header.getOrDefault("X-Amz-Target")
  valid_402657782 = validateParameter(valid_402657782, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseSnapshots"))
  if valid_402657782 != nil:
    section.add "X-Amz-Target", valid_402657782
  var valid_402657783 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657783 = validateParameter(valid_402657783, JString,
                                      required = false, default = nil)
  if valid_402657783 != nil:
    section.add "X-Amz-Security-Token", valid_402657783
  var valid_402657784 = header.getOrDefault("X-Amz-Signature")
  valid_402657784 = validateParameter(valid_402657784, JString,
                                      required = false, default = nil)
  if valid_402657784 != nil:
    section.add "X-Amz-Signature", valid_402657784
  var valid_402657785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657785 = validateParameter(valid_402657785, JString,
                                      required = false, default = nil)
  if valid_402657785 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657785
  var valid_402657786 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657786 = validateParameter(valid_402657786, JString,
                                      required = false, default = nil)
  if valid_402657786 != nil:
    section.add "X-Amz-Algorithm", valid_402657786
  var valid_402657787 = header.getOrDefault("X-Amz-Date")
  valid_402657787 = validateParameter(valid_402657787, JString,
                                      required = false, default = nil)
  if valid_402657787 != nil:
    section.add "X-Amz-Date", valid_402657787
  var valid_402657788 = header.getOrDefault("X-Amz-Credential")
  valid_402657788 = validateParameter(valid_402657788, JString,
                                      required = false, default = nil)
  if valid_402657788 != nil:
    section.add "X-Amz-Credential", valid_402657788
  var valid_402657789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657789 = validateParameter(valid_402657789, JString,
                                      required = false, default = nil)
  if valid_402657789 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657791: Call_GetRelationalDatabaseSnapshots_402657779;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all of your database snapshots in Amazon Lightsail.
                                                                                         ## 
  let valid = call_402657791.validator(path, query, header, formData, body, _)
  let scheme = call_402657791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657791.makeUrl(scheme.get, call_402657791.host, call_402657791.base,
                                   call_402657791.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657791, uri, valid, _)

proc call*(call_402657792: Call_GetRelationalDatabaseSnapshots_402657779;
           body: JsonNode): Recallable =
  ## getRelationalDatabaseSnapshots
  ## Returns information about all of your database snapshots in Amazon Lightsail.
  ##   
                                                                                  ## body: JObject (required)
  var body_402657793 = newJObject()
  if body != nil:
    body_402657793 = body
  result = call_402657792.call(nil, nil, nil, nil, body_402657793)

var getRelationalDatabaseSnapshots* = Call_GetRelationalDatabaseSnapshots_402657779(
    name: "getRelationalDatabaseSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseSnapshots",
    validator: validate_GetRelationalDatabaseSnapshots_402657780, base: "/",
    makeUrl: url_GetRelationalDatabaseSnapshots_402657781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabases_402657794 = ref object of OpenApiRestCall_402656044
proc url_GetRelationalDatabases_402657796(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabases_402657795(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657797 = header.getOrDefault("X-Amz-Target")
  valid_402657797 = validateParameter(valid_402657797, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabases"))
  if valid_402657797 != nil:
    section.add "X-Amz-Target", valid_402657797
  var valid_402657798 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657798 = validateParameter(valid_402657798, JString,
                                      required = false, default = nil)
  if valid_402657798 != nil:
    section.add "X-Amz-Security-Token", valid_402657798
  var valid_402657799 = header.getOrDefault("X-Amz-Signature")
  valid_402657799 = validateParameter(valid_402657799, JString,
                                      required = false, default = nil)
  if valid_402657799 != nil:
    section.add "X-Amz-Signature", valid_402657799
  var valid_402657800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657800 = validateParameter(valid_402657800, JString,
                                      required = false, default = nil)
  if valid_402657800 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657800
  var valid_402657801 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657801 = validateParameter(valid_402657801, JString,
                                      required = false, default = nil)
  if valid_402657801 != nil:
    section.add "X-Amz-Algorithm", valid_402657801
  var valid_402657802 = header.getOrDefault("X-Amz-Date")
  valid_402657802 = validateParameter(valid_402657802, JString,
                                      required = false, default = nil)
  if valid_402657802 != nil:
    section.add "X-Amz-Date", valid_402657802
  var valid_402657803 = header.getOrDefault("X-Amz-Credential")
  valid_402657803 = validateParameter(valid_402657803, JString,
                                      required = false, default = nil)
  if valid_402657803 != nil:
    section.add "X-Amz-Credential", valid_402657803
  var valid_402657804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657804 = validateParameter(valid_402657804, JString,
                                      required = false, default = nil)
  if valid_402657804 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657806: Call_GetRelationalDatabases_402657794;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all of your databases in Amazon Lightsail.
                                                                                         ## 
  let valid = call_402657806.validator(path, query, header, formData, body, _)
  let scheme = call_402657806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657806.makeUrl(scheme.get, call_402657806.host, call_402657806.base,
                                   call_402657806.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657806, uri, valid, _)

proc call*(call_402657807: Call_GetRelationalDatabases_402657794; body: JsonNode): Recallable =
  ## getRelationalDatabases
  ## Returns information about all of your databases in Amazon Lightsail.
  ##   body: JObject 
                                                                         ## (required)
  var body_402657808 = newJObject()
  if body != nil:
    body_402657808 = body
  result = call_402657807.call(nil, nil, nil, nil, body_402657808)

var getRelationalDatabases* = Call_GetRelationalDatabases_402657794(
    name: "getRelationalDatabases", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabases",
    validator: validate_GetRelationalDatabases_402657795, base: "/",
    makeUrl: url_GetRelationalDatabases_402657796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStaticIp_402657809 = ref object of OpenApiRestCall_402656044
proc url_GetStaticIp_402657811(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStaticIp_402657810(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657812 = header.getOrDefault("X-Amz-Target")
  valid_402657812 = validateParameter(valid_402657812, JString, required = true, default = newJString(
      "Lightsail_20161128.GetStaticIp"))
  if valid_402657812 != nil:
    section.add "X-Amz-Target", valid_402657812
  var valid_402657813 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657813 = validateParameter(valid_402657813, JString,
                                      required = false, default = nil)
  if valid_402657813 != nil:
    section.add "X-Amz-Security-Token", valid_402657813
  var valid_402657814 = header.getOrDefault("X-Amz-Signature")
  valid_402657814 = validateParameter(valid_402657814, JString,
                                      required = false, default = nil)
  if valid_402657814 != nil:
    section.add "X-Amz-Signature", valid_402657814
  var valid_402657815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657815 = validateParameter(valid_402657815, JString,
                                      required = false, default = nil)
  if valid_402657815 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657815
  var valid_402657816 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657816 = validateParameter(valid_402657816, JString,
                                      required = false, default = nil)
  if valid_402657816 != nil:
    section.add "X-Amz-Algorithm", valid_402657816
  var valid_402657817 = header.getOrDefault("X-Amz-Date")
  valid_402657817 = validateParameter(valid_402657817, JString,
                                      required = false, default = nil)
  if valid_402657817 != nil:
    section.add "X-Amz-Date", valid_402657817
  var valid_402657818 = header.getOrDefault("X-Amz-Credential")
  valid_402657818 = validateParameter(valid_402657818, JString,
                                      required = false, default = nil)
  if valid_402657818 != nil:
    section.add "X-Amz-Credential", valid_402657818
  var valid_402657819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657819 = validateParameter(valid_402657819, JString,
                                      required = false, default = nil)
  if valid_402657819 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657821: Call_GetStaticIp_402657809; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific static IP.
                                                                                         ## 
  let valid = call_402657821.validator(path, query, header, formData, body, _)
  let scheme = call_402657821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657821.makeUrl(scheme.get, call_402657821.host, call_402657821.base,
                                   call_402657821.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657821, uri, valid, _)

proc call*(call_402657822: Call_GetStaticIp_402657809; body: JsonNode): Recallable =
  ## getStaticIp
  ## Returns information about a specific static IP.
  ##   body: JObject (required)
  var body_402657823 = newJObject()
  if body != nil:
    body_402657823 = body
  result = call_402657822.call(nil, nil, nil, nil, body_402657823)

var getStaticIp* = Call_GetStaticIp_402657809(name: "getStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetStaticIp",
    validator: validate_GetStaticIp_402657810, base: "/",
    makeUrl: url_GetStaticIp_402657811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStaticIps_402657824 = ref object of OpenApiRestCall_402656044
proc url_GetStaticIps_402657826(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStaticIps_402657825(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657827 = header.getOrDefault("X-Amz-Target")
  valid_402657827 = validateParameter(valid_402657827, JString, required = true, default = newJString(
      "Lightsail_20161128.GetStaticIps"))
  if valid_402657827 != nil:
    section.add "X-Amz-Target", valid_402657827
  var valid_402657828 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657828 = validateParameter(valid_402657828, JString,
                                      required = false, default = nil)
  if valid_402657828 != nil:
    section.add "X-Amz-Security-Token", valid_402657828
  var valid_402657829 = header.getOrDefault("X-Amz-Signature")
  valid_402657829 = validateParameter(valid_402657829, JString,
                                      required = false, default = nil)
  if valid_402657829 != nil:
    section.add "X-Amz-Signature", valid_402657829
  var valid_402657830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657830 = validateParameter(valid_402657830, JString,
                                      required = false, default = nil)
  if valid_402657830 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657830
  var valid_402657831 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657831 = validateParameter(valid_402657831, JString,
                                      required = false, default = nil)
  if valid_402657831 != nil:
    section.add "X-Amz-Algorithm", valid_402657831
  var valid_402657832 = header.getOrDefault("X-Amz-Date")
  valid_402657832 = validateParameter(valid_402657832, JString,
                                      required = false, default = nil)
  if valid_402657832 != nil:
    section.add "X-Amz-Date", valid_402657832
  var valid_402657833 = header.getOrDefault("X-Amz-Credential")
  valid_402657833 = validateParameter(valid_402657833, JString,
                                      required = false, default = nil)
  if valid_402657833 != nil:
    section.add "X-Amz-Credential", valid_402657833
  var valid_402657834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657834 = validateParameter(valid_402657834, JString,
                                      required = false, default = nil)
  if valid_402657834 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657836: Call_GetStaticIps_402657824; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all static IPs in the user's account.
                                                                                         ## 
  let valid = call_402657836.validator(path, query, header, formData, body, _)
  let scheme = call_402657836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657836.makeUrl(scheme.get, call_402657836.host, call_402657836.base,
                                   call_402657836.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657836, uri, valid, _)

proc call*(call_402657837: Call_GetStaticIps_402657824; body: JsonNode): Recallable =
  ## getStaticIps
  ## Returns information about all static IPs in the user's account.
  ##   body: JObject (required)
  var body_402657838 = newJObject()
  if body != nil:
    body_402657838 = body
  result = call_402657837.call(nil, nil, nil, nil, body_402657838)

var getStaticIps* = Call_GetStaticIps_402657824(name: "getStaticIps",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetStaticIps",
    validator: validate_GetStaticIps_402657825, base: "/",
    makeUrl: url_GetStaticIps_402657826, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportKeyPair_402657839 = ref object of OpenApiRestCall_402656044
proc url_ImportKeyPair_402657841(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportKeyPair_402657840(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657842 = header.getOrDefault("X-Amz-Target")
  valid_402657842 = validateParameter(valid_402657842, JString, required = true, default = newJString(
      "Lightsail_20161128.ImportKeyPair"))
  if valid_402657842 != nil:
    section.add "X-Amz-Target", valid_402657842
  var valid_402657843 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657843 = validateParameter(valid_402657843, JString,
                                      required = false, default = nil)
  if valid_402657843 != nil:
    section.add "X-Amz-Security-Token", valid_402657843
  var valid_402657844 = header.getOrDefault("X-Amz-Signature")
  valid_402657844 = validateParameter(valid_402657844, JString,
                                      required = false, default = nil)
  if valid_402657844 != nil:
    section.add "X-Amz-Signature", valid_402657844
  var valid_402657845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657845 = validateParameter(valid_402657845, JString,
                                      required = false, default = nil)
  if valid_402657845 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657845
  var valid_402657846 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657846 = validateParameter(valid_402657846, JString,
                                      required = false, default = nil)
  if valid_402657846 != nil:
    section.add "X-Amz-Algorithm", valid_402657846
  var valid_402657847 = header.getOrDefault("X-Amz-Date")
  valid_402657847 = validateParameter(valid_402657847, JString,
                                      required = false, default = nil)
  if valid_402657847 != nil:
    section.add "X-Amz-Date", valid_402657847
  var valid_402657848 = header.getOrDefault("X-Amz-Credential")
  valid_402657848 = validateParameter(valid_402657848, JString,
                                      required = false, default = nil)
  if valid_402657848 != nil:
    section.add "X-Amz-Credential", valid_402657848
  var valid_402657849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657849 = validateParameter(valid_402657849, JString,
                                      required = false, default = nil)
  if valid_402657849 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657851: Call_ImportKeyPair_402657839; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Imports a public SSH key from a specific key pair.
                                                                                         ## 
  let valid = call_402657851.validator(path, query, header, formData, body, _)
  let scheme = call_402657851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657851.makeUrl(scheme.get, call_402657851.host, call_402657851.base,
                                   call_402657851.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657851, uri, valid, _)

proc call*(call_402657852: Call_ImportKeyPair_402657839; body: JsonNode): Recallable =
  ## importKeyPair
  ## Imports a public SSH key from a specific key pair.
  ##   body: JObject (required)
  var body_402657853 = newJObject()
  if body != nil:
    body_402657853 = body
  result = call_402657852.call(nil, nil, nil, nil, body_402657853)

var importKeyPair* = Call_ImportKeyPair_402657839(name: "importKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ImportKeyPair",
    validator: validate_ImportKeyPair_402657840, base: "/",
    makeUrl: url_ImportKeyPair_402657841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_IsVpcPeered_402657854 = ref object of OpenApiRestCall_402656044
proc url_IsVpcPeered_402657856(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_IsVpcPeered_402657855(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657857 = header.getOrDefault("X-Amz-Target")
  valid_402657857 = validateParameter(valid_402657857, JString, required = true, default = newJString(
      "Lightsail_20161128.IsVpcPeered"))
  if valid_402657857 != nil:
    section.add "X-Amz-Target", valid_402657857
  var valid_402657858 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657858 = validateParameter(valid_402657858, JString,
                                      required = false, default = nil)
  if valid_402657858 != nil:
    section.add "X-Amz-Security-Token", valid_402657858
  var valid_402657859 = header.getOrDefault("X-Amz-Signature")
  valid_402657859 = validateParameter(valid_402657859, JString,
                                      required = false, default = nil)
  if valid_402657859 != nil:
    section.add "X-Amz-Signature", valid_402657859
  var valid_402657860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657860 = validateParameter(valid_402657860, JString,
                                      required = false, default = nil)
  if valid_402657860 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657860
  var valid_402657861 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657861 = validateParameter(valid_402657861, JString,
                                      required = false, default = nil)
  if valid_402657861 != nil:
    section.add "X-Amz-Algorithm", valid_402657861
  var valid_402657862 = header.getOrDefault("X-Amz-Date")
  valid_402657862 = validateParameter(valid_402657862, JString,
                                      required = false, default = nil)
  if valid_402657862 != nil:
    section.add "X-Amz-Date", valid_402657862
  var valid_402657863 = header.getOrDefault("X-Amz-Credential")
  valid_402657863 = validateParameter(valid_402657863, JString,
                                      required = false, default = nil)
  if valid_402657863 != nil:
    section.add "X-Amz-Credential", valid_402657863
  var valid_402657864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657864 = validateParameter(valid_402657864, JString,
                                      required = false, default = nil)
  if valid_402657864 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657866: Call_IsVpcPeered_402657854; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a Boolean value indicating whether your Lightsail VPC is peered.
                                                                                         ## 
  let valid = call_402657866.validator(path, query, header, formData, body, _)
  let scheme = call_402657866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657866.makeUrl(scheme.get, call_402657866.host, call_402657866.base,
                                   call_402657866.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657866, uri, valid, _)

proc call*(call_402657867: Call_IsVpcPeered_402657854; body: JsonNode): Recallable =
  ## isVpcPeered
  ## Returns a Boolean value indicating whether your Lightsail VPC is peered.
  ##   
                                                                             ## body: JObject (required)
  var body_402657868 = newJObject()
  if body != nil:
    body_402657868 = body
  result = call_402657867.call(nil, nil, nil, nil, body_402657868)

var isVpcPeered* = Call_IsVpcPeered_402657854(name: "isVpcPeered",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.IsVpcPeered",
    validator: validate_IsVpcPeered_402657855, base: "/",
    makeUrl: url_IsVpcPeered_402657856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_OpenInstancePublicPorts_402657869 = ref object of OpenApiRestCall_402656044
proc url_OpenInstancePublicPorts_402657871(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_OpenInstancePublicPorts_402657870(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657872 = header.getOrDefault("X-Amz-Target")
  valid_402657872 = validateParameter(valid_402657872, JString, required = true, default = newJString(
      "Lightsail_20161128.OpenInstancePublicPorts"))
  if valid_402657872 != nil:
    section.add "X-Amz-Target", valid_402657872
  var valid_402657873 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657873 = validateParameter(valid_402657873, JString,
                                      required = false, default = nil)
  if valid_402657873 != nil:
    section.add "X-Amz-Security-Token", valid_402657873
  var valid_402657874 = header.getOrDefault("X-Amz-Signature")
  valid_402657874 = validateParameter(valid_402657874, JString,
                                      required = false, default = nil)
  if valid_402657874 != nil:
    section.add "X-Amz-Signature", valid_402657874
  var valid_402657875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657875 = validateParameter(valid_402657875, JString,
                                      required = false, default = nil)
  if valid_402657875 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657875
  var valid_402657876 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657876 = validateParameter(valid_402657876, JString,
                                      required = false, default = nil)
  if valid_402657876 != nil:
    section.add "X-Amz-Algorithm", valid_402657876
  var valid_402657877 = header.getOrDefault("X-Amz-Date")
  valid_402657877 = validateParameter(valid_402657877, JString,
                                      required = false, default = nil)
  if valid_402657877 != nil:
    section.add "X-Amz-Date", valid_402657877
  var valid_402657878 = header.getOrDefault("X-Amz-Credential")
  valid_402657878 = validateParameter(valid_402657878, JString,
                                      required = false, default = nil)
  if valid_402657878 != nil:
    section.add "X-Amz-Credential", valid_402657878
  var valid_402657879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657879 = validateParameter(valid_402657879, JString,
                                      required = false, default = nil)
  if valid_402657879 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657881: Call_OpenInstancePublicPorts_402657869;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds public ports to an Amazon Lightsail instance.</p> <p>The <code>open instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402657881.validator(path, query, header, formData, body, _)
  let scheme = call_402657881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657881.makeUrl(scheme.get, call_402657881.host, call_402657881.base,
                                   call_402657881.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657881, uri, valid, _)

proc call*(call_402657882: Call_OpenInstancePublicPorts_402657869;
           body: JsonNode): Recallable =
  ## openInstancePublicPorts
  ## <p>Adds public ports to an Amazon Lightsail instance.</p> <p>The <code>open instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657883 = newJObject()
  if body != nil:
    body_402657883 = body
  result = call_402657882.call(nil, nil, nil, nil, body_402657883)

var openInstancePublicPorts* = Call_OpenInstancePublicPorts_402657869(
    name: "openInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.OpenInstancePublicPorts",
    validator: validate_OpenInstancePublicPorts_402657870, base: "/",
    makeUrl: url_OpenInstancePublicPorts_402657871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PeerVpc_402657884 = ref object of OpenApiRestCall_402656044
proc url_PeerVpc_402657886(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PeerVpc_402657885(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657887 = header.getOrDefault("X-Amz-Target")
  valid_402657887 = validateParameter(valid_402657887, JString, required = true, default = newJString(
      "Lightsail_20161128.PeerVpc"))
  if valid_402657887 != nil:
    section.add "X-Amz-Target", valid_402657887
  var valid_402657888 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657888 = validateParameter(valid_402657888, JString,
                                      required = false, default = nil)
  if valid_402657888 != nil:
    section.add "X-Amz-Security-Token", valid_402657888
  var valid_402657889 = header.getOrDefault("X-Amz-Signature")
  valid_402657889 = validateParameter(valid_402657889, JString,
                                      required = false, default = nil)
  if valid_402657889 != nil:
    section.add "X-Amz-Signature", valid_402657889
  var valid_402657890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657890 = validateParameter(valid_402657890, JString,
                                      required = false, default = nil)
  if valid_402657890 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657890
  var valid_402657891 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657891 = validateParameter(valid_402657891, JString,
                                      required = false, default = nil)
  if valid_402657891 != nil:
    section.add "X-Amz-Algorithm", valid_402657891
  var valid_402657892 = header.getOrDefault("X-Amz-Date")
  valid_402657892 = validateParameter(valid_402657892, JString,
                                      required = false, default = nil)
  if valid_402657892 != nil:
    section.add "X-Amz-Date", valid_402657892
  var valid_402657893 = header.getOrDefault("X-Amz-Credential")
  valid_402657893 = validateParameter(valid_402657893, JString,
                                      required = false, default = nil)
  if valid_402657893 != nil:
    section.add "X-Amz-Credential", valid_402657893
  var valid_402657894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657894 = validateParameter(valid_402657894, JString,
                                      required = false, default = nil)
  if valid_402657894 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657896: Call_PeerVpc_402657884; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Tries to peer the Lightsail VPC with the user's default VPC.
                                                                                         ## 
  let valid = call_402657896.validator(path, query, header, formData, body, _)
  let scheme = call_402657896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657896.makeUrl(scheme.get, call_402657896.host, call_402657896.base,
                                   call_402657896.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657896, uri, valid, _)

proc call*(call_402657897: Call_PeerVpc_402657884; body: JsonNode): Recallable =
  ## peerVpc
  ## Tries to peer the Lightsail VPC with the user's default VPC.
  ##   body: JObject (required)
  var body_402657898 = newJObject()
  if body != nil:
    body_402657898 = body
  result = call_402657897.call(nil, nil, nil, nil, body_402657898)

var peerVpc* = Call_PeerVpc_402657884(name: "peerVpc",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.PeerVpc",
                                      validator: validate_PeerVpc_402657885,
                                      base: "/", makeUrl: url_PeerVpc_402657886,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAlarm_402657899 = ref object of OpenApiRestCall_402656044
proc url_PutAlarm_402657901(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAlarm_402657900(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates or updates an alarm, and associates it with the specified metric.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p> <p>When this action creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm. The alarm is then evaluated with the updated configuration.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657902 = header.getOrDefault("X-Amz-Target")
  valid_402657902 = validateParameter(valid_402657902, JString, required = true, default = newJString(
      "Lightsail_20161128.PutAlarm"))
  if valid_402657902 != nil:
    section.add "X-Amz-Target", valid_402657902
  var valid_402657903 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657903 = validateParameter(valid_402657903, JString,
                                      required = false, default = nil)
  if valid_402657903 != nil:
    section.add "X-Amz-Security-Token", valid_402657903
  var valid_402657904 = header.getOrDefault("X-Amz-Signature")
  valid_402657904 = validateParameter(valid_402657904, JString,
                                      required = false, default = nil)
  if valid_402657904 != nil:
    section.add "X-Amz-Signature", valid_402657904
  var valid_402657905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657905 = validateParameter(valid_402657905, JString,
                                      required = false, default = nil)
  if valid_402657905 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657905
  var valid_402657906 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657906 = validateParameter(valid_402657906, JString,
                                      required = false, default = nil)
  if valid_402657906 != nil:
    section.add "X-Amz-Algorithm", valid_402657906
  var valid_402657907 = header.getOrDefault("X-Amz-Date")
  valid_402657907 = validateParameter(valid_402657907, JString,
                                      required = false, default = nil)
  if valid_402657907 != nil:
    section.add "X-Amz-Date", valid_402657907
  var valid_402657908 = header.getOrDefault("X-Amz-Credential")
  valid_402657908 = validateParameter(valid_402657908, JString,
                                      required = false, default = nil)
  if valid_402657908 != nil:
    section.add "X-Amz-Credential", valid_402657908
  var valid_402657909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657909 = validateParameter(valid_402657909, JString,
                                      required = false, default = nil)
  if valid_402657909 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657911: Call_PutAlarm_402657899; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates or updates an alarm, and associates it with the specified metric.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p> <p>When this action creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm. The alarm is then evaluated with the updated configuration.</p>
                                                                                         ## 
  let valid = call_402657911.validator(path, query, header, formData, body, _)
  let scheme = call_402657911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657911.makeUrl(scheme.get, call_402657911.host, call_402657911.base,
                                   call_402657911.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657911, uri, valid, _)

proc call*(call_402657912: Call_PutAlarm_402657899; body: JsonNode): Recallable =
  ## putAlarm
  ## <p>Creates or updates an alarm, and associates it with the specified metric.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p> <p>When this action creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm. The alarm is then evaluated with the updated configuration.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402657913 = newJObject()
  if body != nil:
    body_402657913 = body
  result = call_402657912.call(nil, nil, nil, nil, body_402657913)

var putAlarm* = Call_PutAlarm_402657899(name: "putAlarm",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.PutAlarm",
                                        validator: validate_PutAlarm_402657900,
                                        base: "/", makeUrl: url_PutAlarm_402657901,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInstancePublicPorts_402657914 = ref object of OpenApiRestCall_402656044
proc url_PutInstancePublicPorts_402657916(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutInstancePublicPorts_402657915(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657917 = header.getOrDefault("X-Amz-Target")
  valid_402657917 = validateParameter(valid_402657917, JString, required = true, default = newJString(
      "Lightsail_20161128.PutInstancePublicPorts"))
  if valid_402657917 != nil:
    section.add "X-Amz-Target", valid_402657917
  var valid_402657918 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657918 = validateParameter(valid_402657918, JString,
                                      required = false, default = nil)
  if valid_402657918 != nil:
    section.add "X-Amz-Security-Token", valid_402657918
  var valid_402657919 = header.getOrDefault("X-Amz-Signature")
  valid_402657919 = validateParameter(valid_402657919, JString,
                                      required = false, default = nil)
  if valid_402657919 != nil:
    section.add "X-Amz-Signature", valid_402657919
  var valid_402657920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657920 = validateParameter(valid_402657920, JString,
                                      required = false, default = nil)
  if valid_402657920 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657920
  var valid_402657921 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657921 = validateParameter(valid_402657921, JString,
                                      required = false, default = nil)
  if valid_402657921 != nil:
    section.add "X-Amz-Algorithm", valid_402657921
  var valid_402657922 = header.getOrDefault("X-Amz-Date")
  valid_402657922 = validateParameter(valid_402657922, JString,
                                      required = false, default = nil)
  if valid_402657922 != nil:
    section.add "X-Amz-Date", valid_402657922
  var valid_402657923 = header.getOrDefault("X-Amz-Credential")
  valid_402657923 = validateParameter(valid_402657923, JString,
                                      required = false, default = nil)
  if valid_402657923 != nil:
    section.add "X-Amz-Credential", valid_402657923
  var valid_402657924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657924 = validateParameter(valid_402657924, JString,
                                      required = false, default = nil)
  if valid_402657924 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657926: Call_PutInstancePublicPorts_402657914;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the specified open ports for an Amazon Lightsail instance, and closes all ports for every protocol not included in the current request.</p> <p>The <code>put instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402657926.validator(path, query, header, formData, body, _)
  let scheme = call_402657926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657926.makeUrl(scheme.get, call_402657926.host, call_402657926.base,
                                   call_402657926.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657926, uri, valid, _)

proc call*(call_402657927: Call_PutInstancePublicPorts_402657914; body: JsonNode): Recallable =
  ## putInstancePublicPorts
  ## <p>Sets the specified open ports for an Amazon Lightsail instance, and closes all ports for every protocol not included in the current request.</p> <p>The <code>put instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402657928 = newJObject()
  if body != nil:
    body_402657928 = body
  result = call_402657927.call(nil, nil, nil, nil, body_402657928)

var putInstancePublicPorts* = Call_PutInstancePublicPorts_402657914(
    name: "putInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.PutInstancePublicPorts",
    validator: validate_PutInstancePublicPorts_402657915, base: "/",
    makeUrl: url_PutInstancePublicPorts_402657916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootInstance_402657929 = ref object of OpenApiRestCall_402656044
proc url_RebootInstance_402657931(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RebootInstance_402657930(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657932 = header.getOrDefault("X-Amz-Target")
  valid_402657932 = validateParameter(valid_402657932, JString, required = true, default = newJString(
      "Lightsail_20161128.RebootInstance"))
  if valid_402657932 != nil:
    section.add "X-Amz-Target", valid_402657932
  var valid_402657933 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657933 = validateParameter(valid_402657933, JString,
                                      required = false, default = nil)
  if valid_402657933 != nil:
    section.add "X-Amz-Security-Token", valid_402657933
  var valid_402657934 = header.getOrDefault("X-Amz-Signature")
  valid_402657934 = validateParameter(valid_402657934, JString,
                                      required = false, default = nil)
  if valid_402657934 != nil:
    section.add "X-Amz-Signature", valid_402657934
  var valid_402657935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657935 = validateParameter(valid_402657935, JString,
                                      required = false, default = nil)
  if valid_402657935 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657935
  var valid_402657936 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657936 = validateParameter(valid_402657936, JString,
                                      required = false, default = nil)
  if valid_402657936 != nil:
    section.add "X-Amz-Algorithm", valid_402657936
  var valid_402657937 = header.getOrDefault("X-Amz-Date")
  valid_402657937 = validateParameter(valid_402657937, JString,
                                      required = false, default = nil)
  if valid_402657937 != nil:
    section.add "X-Amz-Date", valid_402657937
  var valid_402657938 = header.getOrDefault("X-Amz-Credential")
  valid_402657938 = validateParameter(valid_402657938, JString,
                                      required = false, default = nil)
  if valid_402657938 != nil:
    section.add "X-Amz-Credential", valid_402657938
  var valid_402657939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657939 = validateParameter(valid_402657939, JString,
                                      required = false, default = nil)
  if valid_402657939 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657941: Call_RebootInstance_402657929; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Restarts a specific instance.</p> <p>The <code>reboot instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402657941.validator(path, query, header, formData, body, _)
  let scheme = call_402657941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657941.makeUrl(scheme.get, call_402657941.host, call_402657941.base,
                                   call_402657941.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657941, uri, valid, _)

proc call*(call_402657942: Call_RebootInstance_402657929; body: JsonNode): Recallable =
  ## rebootInstance
  ## <p>Restarts a specific instance.</p> <p>The <code>reboot instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657943 = newJObject()
  if body != nil:
    body_402657943 = body
  result = call_402657942.call(nil, nil, nil, nil, body_402657943)

var rebootInstance* = Call_RebootInstance_402657929(name: "rebootInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.RebootInstance",
    validator: validate_RebootInstance_402657930, base: "/",
    makeUrl: url_RebootInstance_402657931, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootRelationalDatabase_402657944 = ref object of OpenApiRestCall_402656044
proc url_RebootRelationalDatabase_402657946(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RebootRelationalDatabase_402657945(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657947 = header.getOrDefault("X-Amz-Target")
  valid_402657947 = validateParameter(valid_402657947, JString, required = true, default = newJString(
      "Lightsail_20161128.RebootRelationalDatabase"))
  if valid_402657947 != nil:
    section.add "X-Amz-Target", valid_402657947
  var valid_402657948 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657948 = validateParameter(valid_402657948, JString,
                                      required = false, default = nil)
  if valid_402657948 != nil:
    section.add "X-Amz-Security-Token", valid_402657948
  var valid_402657949 = header.getOrDefault("X-Amz-Signature")
  valid_402657949 = validateParameter(valid_402657949, JString,
                                      required = false, default = nil)
  if valid_402657949 != nil:
    section.add "X-Amz-Signature", valid_402657949
  var valid_402657950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657950 = validateParameter(valid_402657950, JString,
                                      required = false, default = nil)
  if valid_402657950 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657950
  var valid_402657951 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657951 = validateParameter(valid_402657951, JString,
                                      required = false, default = nil)
  if valid_402657951 != nil:
    section.add "X-Amz-Algorithm", valid_402657951
  var valid_402657952 = header.getOrDefault("X-Amz-Date")
  valid_402657952 = validateParameter(valid_402657952, JString,
                                      required = false, default = nil)
  if valid_402657952 != nil:
    section.add "X-Amz-Date", valid_402657952
  var valid_402657953 = header.getOrDefault("X-Amz-Credential")
  valid_402657953 = validateParameter(valid_402657953, JString,
                                      required = false, default = nil)
  if valid_402657953 != nil:
    section.add "X-Amz-Credential", valid_402657953
  var valid_402657954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657954 = validateParameter(valid_402657954, JString,
                                      required = false, default = nil)
  if valid_402657954 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657954
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657956: Call_RebootRelationalDatabase_402657944;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402657956.validator(path, query, header, formData, body, _)
  let scheme = call_402657956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657956.makeUrl(scheme.get, call_402657956.host, call_402657956.base,
                                   call_402657956.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657956, uri, valid, _)

proc call*(call_402657957: Call_RebootRelationalDatabase_402657944;
           body: JsonNode): Recallable =
  ## rebootRelationalDatabase
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402657958 = newJObject()
  if body != nil:
    body_402657958 = body
  result = call_402657957.call(nil, nil, nil, nil, body_402657958)

var rebootRelationalDatabase* = Call_RebootRelationalDatabase_402657944(
    name: "rebootRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.RebootRelationalDatabase",
    validator: validate_RebootRelationalDatabase_402657945, base: "/",
    makeUrl: url_RebootRelationalDatabase_402657946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReleaseStaticIp_402657959 = ref object of OpenApiRestCall_402656044
proc url_ReleaseStaticIp_402657961(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ReleaseStaticIp_402657960(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657962 = header.getOrDefault("X-Amz-Target")
  valid_402657962 = validateParameter(valid_402657962, JString, required = true, default = newJString(
      "Lightsail_20161128.ReleaseStaticIp"))
  if valid_402657962 != nil:
    section.add "X-Amz-Target", valid_402657962
  var valid_402657963 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657963 = validateParameter(valid_402657963, JString,
                                      required = false, default = nil)
  if valid_402657963 != nil:
    section.add "X-Amz-Security-Token", valid_402657963
  var valid_402657964 = header.getOrDefault("X-Amz-Signature")
  valid_402657964 = validateParameter(valid_402657964, JString,
                                      required = false, default = nil)
  if valid_402657964 != nil:
    section.add "X-Amz-Signature", valid_402657964
  var valid_402657965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657965 = validateParameter(valid_402657965, JString,
                                      required = false, default = nil)
  if valid_402657965 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657965
  var valid_402657966 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657966 = validateParameter(valid_402657966, JString,
                                      required = false, default = nil)
  if valid_402657966 != nil:
    section.add "X-Amz-Algorithm", valid_402657966
  var valid_402657967 = header.getOrDefault("X-Amz-Date")
  valid_402657967 = validateParameter(valid_402657967, JString,
                                      required = false, default = nil)
  if valid_402657967 != nil:
    section.add "X-Amz-Date", valid_402657967
  var valid_402657968 = header.getOrDefault("X-Amz-Credential")
  valid_402657968 = validateParameter(valid_402657968, JString,
                                      required = false, default = nil)
  if valid_402657968 != nil:
    section.add "X-Amz-Credential", valid_402657968
  var valid_402657969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657969 = validateParameter(valid_402657969, JString,
                                      required = false, default = nil)
  if valid_402657969 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657971: Call_ReleaseStaticIp_402657959; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specific static IP from your account.
                                                                                         ## 
  let valid = call_402657971.validator(path, query, header, formData, body, _)
  let scheme = call_402657971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657971.makeUrl(scheme.get, call_402657971.host, call_402657971.base,
                                   call_402657971.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657971, uri, valid, _)

proc call*(call_402657972: Call_ReleaseStaticIp_402657959; body: JsonNode): Recallable =
  ## releaseStaticIp
  ## Deletes a specific static IP from your account.
  ##   body: JObject (required)
  var body_402657973 = newJObject()
  if body != nil:
    body_402657973 = body
  result = call_402657972.call(nil, nil, nil, nil, body_402657973)

var releaseStaticIp* = Call_ReleaseStaticIp_402657959(name: "releaseStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ReleaseStaticIp",
    validator: validate_ReleaseStaticIp_402657960, base: "/",
    makeUrl: url_ReleaseStaticIp_402657961, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendContactMethodVerification_402657974 = ref object of OpenApiRestCall_402656044
proc url_SendContactMethodVerification_402657976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendContactMethodVerification_402657975(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Sends a verification request to an email contact method to ensure it’s owned by the requester. SMS contact methods don’t need to be verified.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p> <p>A verification request is sent to the contact method when you initially create it. Use this action to send another verification request if a previous verification request was deleted, or has expired.</p> <important> <p>Notifications are not sent to an email contact method until after it is verified, and confirmed as valid.</p> </important>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657977 = header.getOrDefault("X-Amz-Target")
  valid_402657977 = validateParameter(valid_402657977, JString, required = true, default = newJString(
      "Lightsail_20161128.SendContactMethodVerification"))
  if valid_402657977 != nil:
    section.add "X-Amz-Target", valid_402657977
  var valid_402657978 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657978 = validateParameter(valid_402657978, JString,
                                      required = false, default = nil)
  if valid_402657978 != nil:
    section.add "X-Amz-Security-Token", valid_402657978
  var valid_402657979 = header.getOrDefault("X-Amz-Signature")
  valid_402657979 = validateParameter(valid_402657979, JString,
                                      required = false, default = nil)
  if valid_402657979 != nil:
    section.add "X-Amz-Signature", valid_402657979
  var valid_402657980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657980 = validateParameter(valid_402657980, JString,
                                      required = false, default = nil)
  if valid_402657980 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657980
  var valid_402657981 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657981 = validateParameter(valid_402657981, JString,
                                      required = false, default = nil)
  if valid_402657981 != nil:
    section.add "X-Amz-Algorithm", valid_402657981
  var valid_402657982 = header.getOrDefault("X-Amz-Date")
  valid_402657982 = validateParameter(valid_402657982, JString,
                                      required = false, default = nil)
  if valid_402657982 != nil:
    section.add "X-Amz-Date", valid_402657982
  var valid_402657983 = header.getOrDefault("X-Amz-Credential")
  valid_402657983 = validateParameter(valid_402657983, JString,
                                      required = false, default = nil)
  if valid_402657983 != nil:
    section.add "X-Amz-Credential", valid_402657983
  var valid_402657984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657984 = validateParameter(valid_402657984, JString,
                                      required = false, default = nil)
  if valid_402657984 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657986: Call_SendContactMethodVerification_402657974;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sends a verification request to an email contact method to ensure it’s owned by the requester. SMS contact methods don’t need to be verified.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p> <p>A verification request is sent to the contact method when you initially create it. Use this action to send another verification request if a previous verification request was deleted, or has expired.</p> <important> <p>Notifications are not sent to an email contact method until after it is verified, and confirmed as valid.</p> </important>
                                                                                         ## 
  let valid = call_402657986.validator(path, query, header, formData, body, _)
  let scheme = call_402657986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657986.makeUrl(scheme.get, call_402657986.host, call_402657986.base,
                                   call_402657986.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657986, uri, valid, _)

proc call*(call_402657987: Call_SendContactMethodVerification_402657974;
           body: JsonNode): Recallable =
  ## sendContactMethodVerification
  ## <p>Sends a verification request to an email contact method to ensure it’s owned by the requester. SMS contact methods don’t need to be verified.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p> <p>A verification request is sent to the contact method when you initially create it. Use this action to send another verification request if a previous verification request was deleted, or has expired.</p> <important> <p>Notifications are not sent to an email contact method until after it is verified, and confirmed as valid.</p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657988 = newJObject()
  if body != nil:
    body_402657988 = body
  result = call_402657987.call(nil, nil, nil, nil, body_402657988)

var sendContactMethodVerification* = Call_SendContactMethodVerification_402657974(
    name: "sendContactMethodVerification", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.SendContactMethodVerification",
    validator: validate_SendContactMethodVerification_402657975, base: "/",
    makeUrl: url_SendContactMethodVerification_402657976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartInstance_402657989 = ref object of OpenApiRestCall_402656044
proc url_StartInstance_402657991(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartInstance_402657990(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657992 = header.getOrDefault("X-Amz-Target")
  valid_402657992 = validateParameter(valid_402657992, JString, required = true, default = newJString(
      "Lightsail_20161128.StartInstance"))
  if valid_402657992 != nil:
    section.add "X-Amz-Target", valid_402657992
  var valid_402657993 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657993 = validateParameter(valid_402657993, JString,
                                      required = false, default = nil)
  if valid_402657993 != nil:
    section.add "X-Amz-Security-Token", valid_402657993
  var valid_402657994 = header.getOrDefault("X-Amz-Signature")
  valid_402657994 = validateParameter(valid_402657994, JString,
                                      required = false, default = nil)
  if valid_402657994 != nil:
    section.add "X-Amz-Signature", valid_402657994
  var valid_402657995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657995 = validateParameter(valid_402657995, JString,
                                      required = false, default = nil)
  if valid_402657995 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657995
  var valid_402657996 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657996 = validateParameter(valid_402657996, JString,
                                      required = false, default = nil)
  if valid_402657996 != nil:
    section.add "X-Amz-Algorithm", valid_402657996
  var valid_402657997 = header.getOrDefault("X-Amz-Date")
  valid_402657997 = validateParameter(valid_402657997, JString,
                                      required = false, default = nil)
  if valid_402657997 != nil:
    section.add "X-Amz-Date", valid_402657997
  var valid_402657998 = header.getOrDefault("X-Amz-Credential")
  valid_402657998 = validateParameter(valid_402657998, JString,
                                      required = false, default = nil)
  if valid_402657998 != nil:
    section.add "X-Amz-Credential", valid_402657998
  var valid_402657999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657999 = validateParameter(valid_402657999, JString,
                                      required = false, default = nil)
  if valid_402657999 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658001: Call_StartInstance_402657989; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402658001.validator(path, query, header, formData, body, _)
  let scheme = call_402658001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658001.makeUrl(scheme.get, call_402658001.host, call_402658001.base,
                                   call_402658001.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658001, uri, valid, _)

proc call*(call_402658002: Call_StartInstance_402657989; body: JsonNode): Recallable =
  ## startInstance
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402658003 = newJObject()
  if body != nil:
    body_402658003 = body
  result = call_402658002.call(nil, nil, nil, nil, body_402658003)

var startInstance* = Call_StartInstance_402657989(name: "startInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StartInstance",
    validator: validate_StartInstance_402657990, base: "/",
    makeUrl: url_StartInstance_402657991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRelationalDatabase_402658004 = ref object of OpenApiRestCall_402656044
proc url_StartRelationalDatabase_402658006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartRelationalDatabase_402658005(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658007 = header.getOrDefault("X-Amz-Target")
  valid_402658007 = validateParameter(valid_402658007, JString, required = true, default = newJString(
      "Lightsail_20161128.StartRelationalDatabase"))
  if valid_402658007 != nil:
    section.add "X-Amz-Target", valid_402658007
  var valid_402658008 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658008 = validateParameter(valid_402658008, JString,
                                      required = false, default = nil)
  if valid_402658008 != nil:
    section.add "X-Amz-Security-Token", valid_402658008
  var valid_402658009 = header.getOrDefault("X-Amz-Signature")
  valid_402658009 = validateParameter(valid_402658009, JString,
                                      required = false, default = nil)
  if valid_402658009 != nil:
    section.add "X-Amz-Signature", valid_402658009
  var valid_402658010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658010 = validateParameter(valid_402658010, JString,
                                      required = false, default = nil)
  if valid_402658010 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658010
  var valid_402658011 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658011 = validateParameter(valid_402658011, JString,
                                      required = false, default = nil)
  if valid_402658011 != nil:
    section.add "X-Amz-Algorithm", valid_402658011
  var valid_402658012 = header.getOrDefault("X-Amz-Date")
  valid_402658012 = validateParameter(valid_402658012, JString,
                                      required = false, default = nil)
  if valid_402658012 != nil:
    section.add "X-Amz-Date", valid_402658012
  var valid_402658013 = header.getOrDefault("X-Amz-Credential")
  valid_402658013 = validateParameter(valid_402658013, JString,
                                      required = false, default = nil)
  if valid_402658013 != nil:
    section.add "X-Amz-Credential", valid_402658013
  var valid_402658014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658014 = validateParameter(valid_402658014, JString,
                                      required = false, default = nil)
  if valid_402658014 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658016: Call_StartRelationalDatabase_402658004;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the <code>reboot relational database</code> operation.</p> <p>The <code>start relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402658016.validator(path, query, header, formData, body, _)
  let scheme = call_402658016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658016.makeUrl(scheme.get, call_402658016.host, call_402658016.base,
                                   call_402658016.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658016, uri, valid, _)

proc call*(call_402658017: Call_StartRelationalDatabase_402658004;
           body: JsonNode): Recallable =
  ## startRelationalDatabase
  ## <p>Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the <code>reboot relational database</code> operation.</p> <p>The <code>start relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402658018 = newJObject()
  if body != nil:
    body_402658018 = body
  result = call_402658017.call(nil, nil, nil, nil, body_402658018)

var startRelationalDatabase* = Call_StartRelationalDatabase_402658004(
    name: "startRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StartRelationalDatabase",
    validator: validate_StartRelationalDatabase_402658005, base: "/",
    makeUrl: url_StartRelationalDatabase_402658006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopInstance_402658019 = ref object of OpenApiRestCall_402656044
proc url_StopInstance_402658021(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopInstance_402658020(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658022 = header.getOrDefault("X-Amz-Target")
  valid_402658022 = validateParameter(valid_402658022, JString, required = true, default = newJString(
      "Lightsail_20161128.StopInstance"))
  if valid_402658022 != nil:
    section.add "X-Amz-Target", valid_402658022
  var valid_402658023 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658023 = validateParameter(valid_402658023, JString,
                                      required = false, default = nil)
  if valid_402658023 != nil:
    section.add "X-Amz-Security-Token", valid_402658023
  var valid_402658024 = header.getOrDefault("X-Amz-Signature")
  valid_402658024 = validateParameter(valid_402658024, JString,
                                      required = false, default = nil)
  if valid_402658024 != nil:
    section.add "X-Amz-Signature", valid_402658024
  var valid_402658025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658025 = validateParameter(valid_402658025, JString,
                                      required = false, default = nil)
  if valid_402658025 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658025
  var valid_402658026 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658026 = validateParameter(valid_402658026, JString,
                                      required = false, default = nil)
  if valid_402658026 != nil:
    section.add "X-Amz-Algorithm", valid_402658026
  var valid_402658027 = header.getOrDefault("X-Amz-Date")
  valid_402658027 = validateParameter(valid_402658027, JString,
                                      required = false, default = nil)
  if valid_402658027 != nil:
    section.add "X-Amz-Date", valid_402658027
  var valid_402658028 = header.getOrDefault("X-Amz-Credential")
  valid_402658028 = validateParameter(valid_402658028, JString,
                                      required = false, default = nil)
  if valid_402658028 != nil:
    section.add "X-Amz-Credential", valid_402658028
  var valid_402658029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658029 = validateParameter(valid_402658029, JString,
                                      required = false, default = nil)
  if valid_402658029 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658031: Call_StopInstance_402658019; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402658031.validator(path, query, header, formData, body, _)
  let scheme = call_402658031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658031.makeUrl(scheme.get, call_402658031.host, call_402658031.base,
                                   call_402658031.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658031, uri, valid, _)

proc call*(call_402658032: Call_StopInstance_402658019; body: JsonNode): Recallable =
  ## stopInstance
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402658033 = newJObject()
  if body != nil:
    body_402658033 = body
  result = call_402658032.call(nil, nil, nil, nil, body_402658033)

var stopInstance* = Call_StopInstance_402658019(name: "stopInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StopInstance",
    validator: validate_StopInstance_402658020, base: "/",
    makeUrl: url_StopInstance_402658021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRelationalDatabase_402658034 = ref object of OpenApiRestCall_402656044
proc url_StopRelationalDatabase_402658036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRelationalDatabase_402658035(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658037 = header.getOrDefault("X-Amz-Target")
  valid_402658037 = validateParameter(valid_402658037, JString, required = true, default = newJString(
      "Lightsail_20161128.StopRelationalDatabase"))
  if valid_402658037 != nil:
    section.add "X-Amz-Target", valid_402658037
  var valid_402658038 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658038 = validateParameter(valid_402658038, JString,
                                      required = false, default = nil)
  if valid_402658038 != nil:
    section.add "X-Amz-Security-Token", valid_402658038
  var valid_402658039 = header.getOrDefault("X-Amz-Signature")
  valid_402658039 = validateParameter(valid_402658039, JString,
                                      required = false, default = nil)
  if valid_402658039 != nil:
    section.add "X-Amz-Signature", valid_402658039
  var valid_402658040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658040 = validateParameter(valid_402658040, JString,
                                      required = false, default = nil)
  if valid_402658040 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658040
  var valid_402658041 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658041 = validateParameter(valid_402658041, JString,
                                      required = false, default = nil)
  if valid_402658041 != nil:
    section.add "X-Amz-Algorithm", valid_402658041
  var valid_402658042 = header.getOrDefault("X-Amz-Date")
  valid_402658042 = validateParameter(valid_402658042, JString,
                                      required = false, default = nil)
  if valid_402658042 != nil:
    section.add "X-Amz-Date", valid_402658042
  var valid_402658043 = header.getOrDefault("X-Amz-Credential")
  valid_402658043 = validateParameter(valid_402658043, JString,
                                      required = false, default = nil)
  if valid_402658043 != nil:
    section.add "X-Amz-Credential", valid_402658043
  var valid_402658044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658044 = validateParameter(valid_402658044, JString,
                                      required = false, default = nil)
  if valid_402658044 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658046: Call_StopRelationalDatabase_402658034;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a specific database that is currently running in Amazon Lightsail.</p> <p>The <code>stop relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402658046.validator(path, query, header, formData, body, _)
  let scheme = call_402658046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658046.makeUrl(scheme.get, call_402658046.host, call_402658046.base,
                                   call_402658046.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658046, uri, valid, _)

proc call*(call_402658047: Call_StopRelationalDatabase_402658034; body: JsonNode): Recallable =
  ## stopRelationalDatabase
  ## <p>Stops a specific database that is currently running in Amazon Lightsail.</p> <p>The <code>stop relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402658048 = newJObject()
  if body != nil:
    body_402658048 = body
  result = call_402658047.call(nil, nil, nil, nil, body_402658048)

var stopRelationalDatabase* = Call_StopRelationalDatabase_402658034(
    name: "stopRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StopRelationalDatabase",
    validator: validate_StopRelationalDatabase_402658035, base: "/",
    makeUrl: url_StopRelationalDatabase_402658036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402658049 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402658051(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402658050(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658052 = header.getOrDefault("X-Amz-Target")
  valid_402658052 = validateParameter(valid_402658052, JString, required = true, default = newJString(
      "Lightsail_20161128.TagResource"))
  if valid_402658052 != nil:
    section.add "X-Amz-Target", valid_402658052
  var valid_402658053 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658053 = validateParameter(valid_402658053, JString,
                                      required = false, default = nil)
  if valid_402658053 != nil:
    section.add "X-Amz-Security-Token", valid_402658053
  var valid_402658054 = header.getOrDefault("X-Amz-Signature")
  valid_402658054 = validateParameter(valid_402658054, JString,
                                      required = false, default = nil)
  if valid_402658054 != nil:
    section.add "X-Amz-Signature", valid_402658054
  var valid_402658055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658055 = validateParameter(valid_402658055, JString,
                                      required = false, default = nil)
  if valid_402658055 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658055
  var valid_402658056 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658056 = validateParameter(valid_402658056, JString,
                                      required = false, default = nil)
  if valid_402658056 != nil:
    section.add "X-Amz-Algorithm", valid_402658056
  var valid_402658057 = header.getOrDefault("X-Amz-Date")
  valid_402658057 = validateParameter(valid_402658057, JString,
                                      required = false, default = nil)
  if valid_402658057 != nil:
    section.add "X-Amz-Date", valid_402658057
  var valid_402658058 = header.getOrDefault("X-Amz-Credential")
  valid_402658058 = validateParameter(valid_402658058, JString,
                                      required = false, default = nil)
  if valid_402658058 != nil:
    section.add "X-Amz-Credential", valid_402658058
  var valid_402658059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658059 = validateParameter(valid_402658059, JString,
                                      required = false, default = nil)
  if valid_402658059 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658061: Call_TagResource_402658049; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-tags">Lightsail Dev Guide</a>.</p> <p>The <code>tag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402658061.validator(path, query, header, formData, body, _)
  let scheme = call_402658061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658061.makeUrl(scheme.get, call_402658061.host, call_402658061.base,
                                   call_402658061.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658061, uri, valid, _)

proc call*(call_402658062: Call_TagResource_402658049; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-tags">Lightsail Dev Guide</a>.</p> <p>The <code>tag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402658063 = newJObject()
  if body != nil:
    body_402658063 = body
  result = call_402658062.call(nil, nil, nil, nil, body_402658063)

var tagResource* = Call_TagResource_402658049(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.TagResource",
    validator: validate_TagResource_402658050, base: "/",
    makeUrl: url_TagResource_402658051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestAlarm_402658064 = ref object of OpenApiRestCall_402656044
proc url_TestAlarm_402658066(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestAlarm_402658065(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Tests an alarm by displaying a banner on the Amazon Lightsail console. If a notification trigger is configured for the specified alarm, the test also sends a notification to the notification protocol (<code>Email</code> and/or <code>SMS</code>) configured for the alarm.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658067 = header.getOrDefault("X-Amz-Target")
  valid_402658067 = validateParameter(valid_402658067, JString, required = true, default = newJString(
      "Lightsail_20161128.TestAlarm"))
  if valid_402658067 != nil:
    section.add "X-Amz-Target", valid_402658067
  var valid_402658068 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658068 = validateParameter(valid_402658068, JString,
                                      required = false, default = nil)
  if valid_402658068 != nil:
    section.add "X-Amz-Security-Token", valid_402658068
  var valid_402658069 = header.getOrDefault("X-Amz-Signature")
  valid_402658069 = validateParameter(valid_402658069, JString,
                                      required = false, default = nil)
  if valid_402658069 != nil:
    section.add "X-Amz-Signature", valid_402658069
  var valid_402658070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658070 = validateParameter(valid_402658070, JString,
                                      required = false, default = nil)
  if valid_402658070 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658070
  var valid_402658071 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658071 = validateParameter(valid_402658071, JString,
                                      required = false, default = nil)
  if valid_402658071 != nil:
    section.add "X-Amz-Algorithm", valid_402658071
  var valid_402658072 = header.getOrDefault("X-Amz-Date")
  valid_402658072 = validateParameter(valid_402658072, JString,
                                      required = false, default = nil)
  if valid_402658072 != nil:
    section.add "X-Amz-Date", valid_402658072
  var valid_402658073 = header.getOrDefault("X-Amz-Credential")
  valid_402658073 = validateParameter(valid_402658073, JString,
                                      required = false, default = nil)
  if valid_402658073 != nil:
    section.add "X-Amz-Credential", valid_402658073
  var valid_402658074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658074 = validateParameter(valid_402658074, JString,
                                      required = false, default = nil)
  if valid_402658074 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658076: Call_TestAlarm_402658064; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Tests an alarm by displaying a banner on the Amazon Lightsail console. If a notification trigger is configured for the specified alarm, the test also sends a notification to the notification protocol (<code>Email</code> and/or <code>SMS</code>) configured for the alarm.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
                                                                                         ## 
  let valid = call_402658076.validator(path, query, header, formData, body, _)
  let scheme = call_402658076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658076.makeUrl(scheme.get, call_402658076.host, call_402658076.base,
                                   call_402658076.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658076, uri, valid, _)

proc call*(call_402658077: Call_TestAlarm_402658064; body: JsonNode): Recallable =
  ## testAlarm
  ## <p>Tests an alarm by displaying a banner on the Amazon Lightsail console. If a notification trigger is configured for the specified alarm, the test also sends a notification to the notification protocol (<code>Email</code> and/or <code>SMS</code>) configured for the alarm.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402658078 = newJObject()
  if body != nil:
    body_402658078 = body
  result = call_402658077.call(nil, nil, nil, nil, body_402658078)

var testAlarm* = Call_TestAlarm_402658064(name: "testAlarm",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.TestAlarm",
    validator: validate_TestAlarm_402658065, base: "/", makeUrl: url_TestAlarm_402658066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnpeerVpc_402658079 = ref object of OpenApiRestCall_402656044
proc url_UnpeerVpc_402658081(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UnpeerVpc_402658080(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658082 = header.getOrDefault("X-Amz-Target")
  valid_402658082 = validateParameter(valid_402658082, JString, required = true, default = newJString(
      "Lightsail_20161128.UnpeerVpc"))
  if valid_402658082 != nil:
    section.add "X-Amz-Target", valid_402658082
  var valid_402658083 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658083 = validateParameter(valid_402658083, JString,
                                      required = false, default = nil)
  if valid_402658083 != nil:
    section.add "X-Amz-Security-Token", valid_402658083
  var valid_402658084 = header.getOrDefault("X-Amz-Signature")
  valid_402658084 = validateParameter(valid_402658084, JString,
                                      required = false, default = nil)
  if valid_402658084 != nil:
    section.add "X-Amz-Signature", valid_402658084
  var valid_402658085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658085 = validateParameter(valid_402658085, JString,
                                      required = false, default = nil)
  if valid_402658085 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658085
  var valid_402658086 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658086 = validateParameter(valid_402658086, JString,
                                      required = false, default = nil)
  if valid_402658086 != nil:
    section.add "X-Amz-Algorithm", valid_402658086
  var valid_402658087 = header.getOrDefault("X-Amz-Date")
  valid_402658087 = validateParameter(valid_402658087, JString,
                                      required = false, default = nil)
  if valid_402658087 != nil:
    section.add "X-Amz-Date", valid_402658087
  var valid_402658088 = header.getOrDefault("X-Amz-Credential")
  valid_402658088 = validateParameter(valid_402658088, JString,
                                      required = false, default = nil)
  if valid_402658088 != nil:
    section.add "X-Amz-Credential", valid_402658088
  var valid_402658089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658089 = validateParameter(valid_402658089, JString,
                                      required = false, default = nil)
  if valid_402658089 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658091: Call_UnpeerVpc_402658079; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to unpeer the Lightsail VPC from the user's default VPC.
                                                                                         ## 
  let valid = call_402658091.validator(path, query, header, formData, body, _)
  let scheme = call_402658091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658091.makeUrl(scheme.get, call_402658091.host, call_402658091.base,
                                   call_402658091.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658091, uri, valid, _)

proc call*(call_402658092: Call_UnpeerVpc_402658079; body: JsonNode): Recallable =
  ## unpeerVpc
  ## Attempts to unpeer the Lightsail VPC from the user's default VPC.
  ##   body: JObject (required)
  var body_402658093 = newJObject()
  if body != nil:
    body_402658093 = body
  result = call_402658092.call(nil, nil, nil, nil, body_402658093)

var unpeerVpc* = Call_UnpeerVpc_402658079(name: "unpeerVpc",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UnpeerVpc",
    validator: validate_UnpeerVpc_402658080, base: "/", makeUrl: url_UnpeerVpc_402658081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402658094 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402658096(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402658095(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658097 = header.getOrDefault("X-Amz-Target")
  valid_402658097 = validateParameter(valid_402658097, JString, required = true, default = newJString(
      "Lightsail_20161128.UntagResource"))
  if valid_402658097 != nil:
    section.add "X-Amz-Target", valid_402658097
  var valid_402658098 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658098 = validateParameter(valid_402658098, JString,
                                      required = false, default = nil)
  if valid_402658098 != nil:
    section.add "X-Amz-Security-Token", valid_402658098
  var valid_402658099 = header.getOrDefault("X-Amz-Signature")
  valid_402658099 = validateParameter(valid_402658099, JString,
                                      required = false, default = nil)
  if valid_402658099 != nil:
    section.add "X-Amz-Signature", valid_402658099
  var valid_402658100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658100 = validateParameter(valid_402658100, JString,
                                      required = false, default = nil)
  if valid_402658100 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658100
  var valid_402658101 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658101 = validateParameter(valid_402658101, JString,
                                      required = false, default = nil)
  if valid_402658101 != nil:
    section.add "X-Amz-Algorithm", valid_402658101
  var valid_402658102 = header.getOrDefault("X-Amz-Date")
  valid_402658102 = validateParameter(valid_402658102, JString,
                                      required = false, default = nil)
  if valid_402658102 != nil:
    section.add "X-Amz-Date", valid_402658102
  var valid_402658103 = header.getOrDefault("X-Amz-Credential")
  valid_402658103 = validateParameter(valid_402658103, JString,
                                      required = false, default = nil)
  if valid_402658103 != nil:
    section.add "X-Amz-Credential", valid_402658103
  var valid_402658104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658104 = validateParameter(valid_402658104, JString,
                                      required = false, default = nil)
  if valid_402658104 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658106: Call_UntagResource_402658094; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402658106.validator(path, query, header, formData, body, _)
  let scheme = call_402658106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658106.makeUrl(scheme.get, call_402658106.host, call_402658106.base,
                                   call_402658106.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658106, uri, valid, _)

proc call*(call_402658107: Call_UntagResource_402658094; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402658108 = newJObject()
  if body != nil:
    body_402658108 = body
  result = call_402658107.call(nil, nil, nil, nil, body_402658108)

var untagResource* = Call_UntagResource_402658094(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UntagResource",
    validator: validate_UntagResource_402658095, base: "/",
    makeUrl: url_UntagResource_402658096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainEntry_402658109 = ref object of OpenApiRestCall_402656044
proc url_UpdateDomainEntry_402658111(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDomainEntry_402658110(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658112 = header.getOrDefault("X-Amz-Target")
  valid_402658112 = validateParameter(valid_402658112, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateDomainEntry"))
  if valid_402658112 != nil:
    section.add "X-Amz-Target", valid_402658112
  var valid_402658113 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658113 = validateParameter(valid_402658113, JString,
                                      required = false, default = nil)
  if valid_402658113 != nil:
    section.add "X-Amz-Security-Token", valid_402658113
  var valid_402658114 = header.getOrDefault("X-Amz-Signature")
  valid_402658114 = validateParameter(valid_402658114, JString,
                                      required = false, default = nil)
  if valid_402658114 != nil:
    section.add "X-Amz-Signature", valid_402658114
  var valid_402658115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658115 = validateParameter(valid_402658115, JString,
                                      required = false, default = nil)
  if valid_402658115 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658115
  var valid_402658116 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658116 = validateParameter(valid_402658116, JString,
                                      required = false, default = nil)
  if valid_402658116 != nil:
    section.add "X-Amz-Algorithm", valid_402658116
  var valid_402658117 = header.getOrDefault("X-Amz-Date")
  valid_402658117 = validateParameter(valid_402658117, JString,
                                      required = false, default = nil)
  if valid_402658117 != nil:
    section.add "X-Amz-Date", valid_402658117
  var valid_402658118 = header.getOrDefault("X-Amz-Credential")
  valid_402658118 = validateParameter(valid_402658118, JString,
                                      required = false, default = nil)
  if valid_402658118 != nil:
    section.add "X-Amz-Credential", valid_402658118
  var valid_402658119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658119 = validateParameter(valid_402658119, JString,
                                      required = false, default = nil)
  if valid_402658119 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658121: Call_UpdateDomainEntry_402658109;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates a domain recordset after it is created.</p> <p>The <code>update domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402658121.validator(path, query, header, formData, body, _)
  let scheme = call_402658121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658121.makeUrl(scheme.get, call_402658121.host, call_402658121.base,
                                   call_402658121.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658121, uri, valid, _)

proc call*(call_402658122: Call_UpdateDomainEntry_402658109; body: JsonNode): Recallable =
  ## updateDomainEntry
  ## <p>Updates a domain recordset after it is created.</p> <p>The <code>update domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402658123 = newJObject()
  if body != nil:
    body_402658123 = body
  result = call_402658122.call(nil, nil, nil, nil, body_402658123)

var updateDomainEntry* = Call_UpdateDomainEntry_402658109(
    name: "updateDomainEntry", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateDomainEntry",
    validator: validate_UpdateDomainEntry_402658110, base: "/",
    makeUrl: url_UpdateDomainEntry_402658111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoadBalancerAttribute_402658124 = ref object of OpenApiRestCall_402656044
proc url_UpdateLoadBalancerAttribute_402658126(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLoadBalancerAttribute_402658125(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658127 = header.getOrDefault("X-Amz-Target")
  valid_402658127 = validateParameter(valid_402658127, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateLoadBalancerAttribute"))
  if valid_402658127 != nil:
    section.add "X-Amz-Target", valid_402658127
  var valid_402658128 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658128 = validateParameter(valid_402658128, JString,
                                      required = false, default = nil)
  if valid_402658128 != nil:
    section.add "X-Amz-Security-Token", valid_402658128
  var valid_402658129 = header.getOrDefault("X-Amz-Signature")
  valid_402658129 = validateParameter(valid_402658129, JString,
                                      required = false, default = nil)
  if valid_402658129 != nil:
    section.add "X-Amz-Signature", valid_402658129
  var valid_402658130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658130 = validateParameter(valid_402658130, JString,
                                      required = false, default = nil)
  if valid_402658130 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658130
  var valid_402658131 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658131 = validateParameter(valid_402658131, JString,
                                      required = false, default = nil)
  if valid_402658131 != nil:
    section.add "X-Amz-Algorithm", valid_402658131
  var valid_402658132 = header.getOrDefault("X-Amz-Date")
  valid_402658132 = validateParameter(valid_402658132, JString,
                                      required = false, default = nil)
  if valid_402658132 != nil:
    section.add "X-Amz-Date", valid_402658132
  var valid_402658133 = header.getOrDefault("X-Amz-Credential")
  valid_402658133 = validateParameter(valid_402658133, JString,
                                      required = false, default = nil)
  if valid_402658133 != nil:
    section.add "X-Amz-Credential", valid_402658133
  var valid_402658134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658134 = validateParameter(valid_402658134, JString,
                                      required = false, default = nil)
  if valid_402658134 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658136: Call_UpdateLoadBalancerAttribute_402658124;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402658136.validator(path, query, header, formData, body, _)
  let scheme = call_402658136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658136.makeUrl(scheme.get, call_402658136.host, call_402658136.base,
                                   call_402658136.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658136, uri, valid, _)

proc call*(call_402658137: Call_UpdateLoadBalancerAttribute_402658124;
           body: JsonNode): Recallable =
  ## updateLoadBalancerAttribute
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402658138 = newJObject()
  if body != nil:
    body_402658138 = body
  result = call_402658137.call(nil, nil, nil, nil, body_402658138)

var updateLoadBalancerAttribute* = Call_UpdateLoadBalancerAttribute_402658124(
    name: "updateLoadBalancerAttribute", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateLoadBalancerAttribute",
    validator: validate_UpdateLoadBalancerAttribute_402658125, base: "/",
    makeUrl: url_UpdateLoadBalancerAttribute_402658126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRelationalDatabase_402658139 = ref object of OpenApiRestCall_402656044
proc url_UpdateRelationalDatabase_402658141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRelationalDatabase_402658140(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658142 = header.getOrDefault("X-Amz-Target")
  valid_402658142 = validateParameter(valid_402658142, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateRelationalDatabase"))
  if valid_402658142 != nil:
    section.add "X-Amz-Target", valid_402658142
  var valid_402658143 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658143 = validateParameter(valid_402658143, JString,
                                      required = false, default = nil)
  if valid_402658143 != nil:
    section.add "X-Amz-Security-Token", valid_402658143
  var valid_402658144 = header.getOrDefault("X-Amz-Signature")
  valid_402658144 = validateParameter(valid_402658144, JString,
                                      required = false, default = nil)
  if valid_402658144 != nil:
    section.add "X-Amz-Signature", valid_402658144
  var valid_402658145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658145 = validateParameter(valid_402658145, JString,
                                      required = false, default = nil)
  if valid_402658145 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658145
  var valid_402658146 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658146 = validateParameter(valid_402658146, JString,
                                      required = false, default = nil)
  if valid_402658146 != nil:
    section.add "X-Amz-Algorithm", valid_402658146
  var valid_402658147 = header.getOrDefault("X-Amz-Date")
  valid_402658147 = validateParameter(valid_402658147, JString,
                                      required = false, default = nil)
  if valid_402658147 != nil:
    section.add "X-Amz-Date", valid_402658147
  var valid_402658148 = header.getOrDefault("X-Amz-Credential")
  valid_402658148 = validateParameter(valid_402658148, JString,
                                      required = false, default = nil)
  if valid_402658148 != nil:
    section.add "X-Amz-Credential", valid_402658148
  var valid_402658149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658149 = validateParameter(valid_402658149, JString,
                                      required = false, default = nil)
  if valid_402658149 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658151: Call_UpdateRelationalDatabase_402658139;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402658151.validator(path, query, header, formData, body, _)
  let scheme = call_402658151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658151.makeUrl(scheme.get, call_402658151.host, call_402658151.base,
                                   call_402658151.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658151, uri, valid, _)

proc call*(call_402658152: Call_UpdateRelationalDatabase_402658139;
           body: JsonNode): Recallable =
  ## updateRelationalDatabase
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402658153 = newJObject()
  if body != nil:
    body_402658153 = body
  result = call_402658152.call(nil, nil, nil, nil, body_402658153)

var updateRelationalDatabase* = Call_UpdateRelationalDatabase_402658139(
    name: "updateRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateRelationalDatabase",
    validator: validate_UpdateRelationalDatabase_402658140, base: "/",
    makeUrl: url_UpdateRelationalDatabase_402658141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRelationalDatabaseParameters_402658154 = ref object of OpenApiRestCall_402656044
proc url_UpdateRelationalDatabaseParameters_402658156(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRelationalDatabaseParameters_402658155(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658157 = header.getOrDefault("X-Amz-Target")
  valid_402658157 = validateParameter(valid_402658157, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateRelationalDatabaseParameters"))
  if valid_402658157 != nil:
    section.add "X-Amz-Target", valid_402658157
  var valid_402658158 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658158 = validateParameter(valid_402658158, JString,
                                      required = false, default = nil)
  if valid_402658158 != nil:
    section.add "X-Amz-Security-Token", valid_402658158
  var valid_402658159 = header.getOrDefault("X-Amz-Signature")
  valid_402658159 = validateParameter(valid_402658159, JString,
                                      required = false, default = nil)
  if valid_402658159 != nil:
    section.add "X-Amz-Signature", valid_402658159
  var valid_402658160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658160 = validateParameter(valid_402658160, JString,
                                      required = false, default = nil)
  if valid_402658160 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658160
  var valid_402658161 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658161 = validateParameter(valid_402658161, JString,
                                      required = false, default = nil)
  if valid_402658161 != nil:
    section.add "X-Amz-Algorithm", valid_402658161
  var valid_402658162 = header.getOrDefault("X-Amz-Date")
  valid_402658162 = validateParameter(valid_402658162, JString,
                                      required = false, default = nil)
  if valid_402658162 != nil:
    section.add "X-Amz-Date", valid_402658162
  var valid_402658163 = header.getOrDefault("X-Amz-Credential")
  valid_402658163 = validateParameter(valid_402658163, JString,
                                      required = false, default = nil)
  if valid_402658163 != nil:
    section.add "X-Amz-Credential", valid_402658163
  var valid_402658164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658164 = validateParameter(valid_402658164, JString,
                                      required = false, default = nil)
  if valid_402658164 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658166: Call_UpdateRelationalDatabaseParameters_402658154;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which parameter updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
                                                                                         ## 
  let valid = call_402658166.validator(path, query, header, formData, body, _)
  let scheme = call_402658166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658166.makeUrl(scheme.get, call_402658166.host, call_402658166.base,
                                   call_402658166.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658166, uri, valid, _)

proc call*(call_402658167: Call_UpdateRelationalDatabaseParameters_402658154;
           body: JsonNode): Recallable =
  ## updateRelationalDatabaseParameters
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which parameter updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402658168 = newJObject()
  if body != nil:
    body_402658168 = body
  result = call_402658167.call(nil, nil, nil, nil, body_402658168)

var updateRelationalDatabaseParameters* = Call_UpdateRelationalDatabaseParameters_402658154(
    name: "updateRelationalDatabaseParameters", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.UpdateRelationalDatabaseParameters",
    validator: validate_UpdateRelationalDatabaseParameters_402658155, base: "/",
    makeUrl: url_UpdateRelationalDatabaseParameters_402658156,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}