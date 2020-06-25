
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AllocateStaticIp_21625779 = ref object of OpenApiRestCall_21625435
proc url_AllocateStaticIp_21625781(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocateStaticIp_21625780(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "Lightsail_20161128.AllocateStaticIp"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
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

proc call*(call_21625929: Call_AllocateStaticIp_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Allocates a static IP address.
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_AllocateStaticIp_21625779; body: JsonNode): Recallable =
  ## allocateStaticIp
  ## Allocates a static IP address.
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var allocateStaticIp* = Call_AllocateStaticIp_21625779(name: "allocateStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AllocateStaticIp",
    validator: validate_AllocateStaticIp_21625780, base: "/",
    makeUrl: url_AllocateStaticIp_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachDisk_21626029 = ref object of OpenApiRestCall_21625435
proc url_AttachDisk_21626031(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachDisk_21626030(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachDisk"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
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

proc call*(call_21626041: Call_AttachDisk_21626029; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name.</p> <p>The <code>attach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_AttachDisk_21626029; body: JsonNode): Recallable =
  ## attachDisk
  ## <p>Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name.</p> <p>The <code>attach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var attachDisk* = Call_AttachDisk_21626029(name: "attachDisk",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.AttachDisk",
                                        validator: validate_AttachDisk_21626030,
                                        base: "/", makeUrl: url_AttachDisk_21626031,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachInstancesToLoadBalancer_21626044 = ref object of OpenApiRestCall_21625435
proc url_AttachInstancesToLoadBalancer_21626046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachInstancesToLoadBalancer_21626045(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachInstancesToLoadBalancer"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
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

proc call*(call_21626056: Call_AttachInstancesToLoadBalancer_21626044;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches one or more Lightsail instances to a load balancer.</p> <p>After some time, the instances are attached to the load balancer and the health check status is available.</p> <p>The <code>attach instances to load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_AttachInstancesToLoadBalancer_21626044;
          body: JsonNode): Recallable =
  ## attachInstancesToLoadBalancer
  ## <p>Attaches one or more Lightsail instances to a load balancer.</p> <p>After some time, the instances are attached to the load balancer and the health check status is available.</p> <p>The <code>attach instances to load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var attachInstancesToLoadBalancer* = Call_AttachInstancesToLoadBalancer_21626044(
    name: "attachInstancesToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AttachInstancesToLoadBalancer",
    validator: validate_AttachInstancesToLoadBalancer_21626045, base: "/",
    makeUrl: url_AttachInstancesToLoadBalancer_21626046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachLoadBalancerTlsCertificate_21626059 = ref object of OpenApiRestCall_21625435
proc url_AttachLoadBalancerTlsCertificate_21626061(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachLoadBalancerTlsCertificate_21626060(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachLoadBalancerTlsCertificate"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
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

proc call*(call_21626071: Call_AttachLoadBalancerTlsCertificate_21626059;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>AttachLoadBalancerTlsCertificate</code> action with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>AttachLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_AttachLoadBalancerTlsCertificate_21626059;
          body: JsonNode): Recallable =
  ## attachLoadBalancerTlsCertificate
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>AttachLoadBalancerTlsCertificate</code> action with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>AttachLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var attachLoadBalancerTlsCertificate* = Call_AttachLoadBalancerTlsCertificate_21626059(
    name: "attachLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.AttachLoadBalancerTlsCertificate",
    validator: validate_AttachLoadBalancerTlsCertificate_21626060, base: "/",
    makeUrl: url_AttachLoadBalancerTlsCertificate_21626061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachStaticIp_21626074 = ref object of OpenApiRestCall_21625435
proc url_AttachStaticIp_21626076(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachStaticIp_21626075(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachStaticIp"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
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

proc call*(call_21626086: Call_AttachStaticIp_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Attaches a static IP address to a specific Amazon Lightsail instance.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_AttachStaticIp_21626074; body: JsonNode): Recallable =
  ## attachStaticIp
  ## Attaches a static IP address to a specific Amazon Lightsail instance.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var attachStaticIp* = Call_AttachStaticIp_21626074(name: "attachStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AttachStaticIp",
    validator: validate_AttachStaticIp_21626075, base: "/",
    makeUrl: url_AttachStaticIp_21626076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CloseInstancePublicPorts_21626089 = ref object of OpenApiRestCall_21625435
proc url_CloseInstancePublicPorts_21626091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CloseInstancePublicPorts_21626090(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "Lightsail_20161128.CloseInstancePublicPorts"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
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

proc call*(call_21626101: Call_CloseInstancePublicPorts_21626089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_CloseInstancePublicPorts_21626089; body: JsonNode): Recallable =
  ## closeInstancePublicPorts
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var closeInstancePublicPorts* = Call_CloseInstancePublicPorts_21626089(
    name: "closeInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CloseInstancePublicPorts",
    validator: validate_CloseInstancePublicPorts_21626090, base: "/",
    makeUrl: url_CloseInstancePublicPorts_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopySnapshot_21626104 = ref object of OpenApiRestCall_21625435
proc url_CopySnapshot_21626106(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CopySnapshot_21626105(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Copies a manual snapshot of an instance or disk as another manual snapshot, or copies an automatic snapshot of an instance or disk as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p>
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
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "Lightsail_20161128.CopySnapshot"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
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

proc call*(call_21626116: Call_CopySnapshot_21626104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Copies a manual snapshot of an instance or disk as another manual snapshot, or copies an automatic snapshot of an instance or disk as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p>
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_CopySnapshot_21626104; body: JsonNode): Recallable =
  ## copySnapshot
  ## <p>Copies a manual snapshot of an instance or disk as another manual snapshot, or copies an automatic snapshot of an instance or disk as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p>
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var copySnapshot* = Call_CopySnapshot_21626104(name: "copySnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CopySnapshot",
    validator: validate_CopySnapshot_21626105, base: "/", makeUrl: url_CopySnapshot_21626106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationStack_21626119 = ref object of OpenApiRestCall_21625435
proc url_CreateCloudFormationStack_21626121(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCloudFormationStack_21626120(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
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
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateCloudFormationStack"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
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

proc call*(call_21626131: Call_CreateCloudFormationStack_21626119;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_CreateCloudFormationStack_21626119; body: JsonNode): Recallable =
  ## createCloudFormationStack
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var createCloudFormationStack* = Call_CreateCloudFormationStack_21626119(
    name: "createCloudFormationStack", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateCloudFormationStack",
    validator: validate_CreateCloudFormationStack_21626120, base: "/",
    makeUrl: url_CreateCloudFormationStack_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateContactMethod_21626134 = ref object of OpenApiRestCall_21625435
proc url_CreateContactMethod_21626136(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateContactMethod_21626135(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Target")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateContactMethod"))
  if valid_21626139 != nil:
    section.add "X-Amz-Target", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Algorithm", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Signature")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Signature", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Credential")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Credential", valid_21626144
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

proc call*(call_21626146: Call_CreateContactMethod_21626134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an email or SMS text message contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_CreateContactMethod_21626134; body: JsonNode): Recallable =
  ## createContactMethod
  ## <p>Creates an email or SMS text message contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
  ##   body: JObject (required)
  var body_21626148 = newJObject()
  if body != nil:
    body_21626148 = body
  result = call_21626147.call(nil, nil, nil, nil, body_21626148)

var createContactMethod* = Call_CreateContactMethod_21626134(
    name: "createContactMethod", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateContactMethod",
    validator: validate_CreateContactMethod_21626135, base: "/",
    makeUrl: url_CreateContactMethod_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDisk_21626149 = ref object of OpenApiRestCall_21625435
proc url_CreateDisk_21626151(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDisk_21626150(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Target")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDisk"))
  if valid_21626154 != nil:
    section.add "X-Amz-Target", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
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

proc call*(call_21626161: Call_CreateDisk_21626149; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_CreateDisk_21626149; body: JsonNode): Recallable =
  ## createDisk
  ## <p>Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var createDisk* = Call_CreateDisk_21626149(name: "createDisk",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateDisk",
                                        validator: validate_CreateDisk_21626150,
                                        base: "/", makeUrl: url_CreateDisk_21626151,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDiskFromSnapshot_21626164 = ref object of OpenApiRestCall_21625435
proc url_CreateDiskFromSnapshot_21626166(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDiskFromSnapshot_21626165(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Target")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDiskFromSnapshot"))
  if valid_21626169 != nil:
    section.add "X-Amz-Target", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
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

proc call*(call_21626176: Call_CreateDiskFromSnapshot_21626164;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_CreateDiskFromSnapshot_21626164; body: JsonNode): Recallable =
  ## createDiskFromSnapshot
  ## <p>Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var createDiskFromSnapshot* = Call_CreateDiskFromSnapshot_21626164(
    name: "createDiskFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDiskFromSnapshot",
    validator: validate_CreateDiskFromSnapshot_21626165, base: "/",
    makeUrl: url_CreateDiskFromSnapshot_21626166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDiskSnapshot_21626179 = ref object of OpenApiRestCall_21625435
proc url_CreateDiskSnapshot_21626181(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDiskSnapshot_21626180(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626182 = header.getOrDefault("X-Amz-Date")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Date", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Security-Token", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Target")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDiskSnapshot"))
  if valid_21626184 != nil:
    section.add "X-Amz-Target", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
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

proc call*(call_21626191: Call_CreateDiskSnapshot_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance.</p> <p>You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending.</p> <p>You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the <code>instance name</code> parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk.</p> <p>The <code>create disk snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_CreateDiskSnapshot_21626179; body: JsonNode): Recallable =
  ## createDiskSnapshot
  ## <p>Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance.</p> <p>You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending.</p> <p>You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the <code>instance name</code> parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk.</p> <p>The <code>create disk snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626193 = newJObject()
  if body != nil:
    body_21626193 = body
  result = call_21626192.call(nil, nil, nil, nil, body_21626193)

var createDiskSnapshot* = Call_CreateDiskSnapshot_21626179(
    name: "createDiskSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDiskSnapshot",
    validator: validate_CreateDiskSnapshot_21626180, base: "/",
    makeUrl: url_CreateDiskSnapshot_21626181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_21626194 = ref object of OpenApiRestCall_21625435
proc url_CreateDomain_21626196(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomain_21626195(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDomain"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
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

proc call*(call_21626206: Call_CreateDomain_21626194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_CreateDomain_21626194; body: JsonNode): Recallable =
  ## createDomain
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var createDomain* = Call_CreateDomain_21626194(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDomain",
    validator: validate_CreateDomain_21626195, base: "/", makeUrl: url_CreateDomain_21626196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainEntry_21626209 = ref object of OpenApiRestCall_21625435
proc url_CreateDomainEntry_21626211(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomainEntry_21626210(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Target")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDomainEntry"))
  if valid_21626214 != nil:
    section.add "X-Amz-Target", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
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

proc call*(call_21626221: Call_CreateDomainEntry_21626209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates one of the following entry records associated with the domain: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT).</p> <p>The <code>create domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_CreateDomainEntry_21626209; body: JsonNode): Recallable =
  ## createDomainEntry
  ## <p>Creates one of the following entry records associated with the domain: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT).</p> <p>The <code>create domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var createDomainEntry* = Call_CreateDomainEntry_21626209(name: "createDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDomainEntry",
    validator: validate_CreateDomainEntry_21626210, base: "/",
    makeUrl: url_CreateDomainEntry_21626211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceSnapshot_21626224 = ref object of OpenApiRestCall_21625435
proc url_CreateInstanceSnapshot_21626226(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInstanceSnapshot_21626225(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Target")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstanceSnapshot"))
  if valid_21626229 != nil:
    section.add "X-Amz-Target", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
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

proc call*(call_21626236: Call_CreateInstanceSnapshot_21626224;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a snapshot of a specific virtual private server, or <i>instance</i>. You can use a snapshot to create a new instance that is based on that snapshot.</p> <p>The <code>create instance snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_CreateInstanceSnapshot_21626224; body: JsonNode): Recallable =
  ## createInstanceSnapshot
  ## <p>Creates a snapshot of a specific virtual private server, or <i>instance</i>. You can use a snapshot to create a new instance that is based on that snapshot.</p> <p>The <code>create instance snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626238 = newJObject()
  if body != nil:
    body_21626238 = body
  result = call_21626237.call(nil, nil, nil, nil, body_21626238)

var createInstanceSnapshot* = Call_CreateInstanceSnapshot_21626224(
    name: "createInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstanceSnapshot",
    validator: validate_CreateInstanceSnapshot_21626225, base: "/",
    makeUrl: url_CreateInstanceSnapshot_21626226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstances_21626239 = ref object of OpenApiRestCall_21625435
proc url_CreateInstances_21626241(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInstances_21626240(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626242 = header.getOrDefault("X-Amz-Date")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Date", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Security-Token", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Target")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstances"))
  if valid_21626244 != nil:
    section.add "X-Amz-Target", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
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

proc call*(call_21626251: Call_CreateInstances_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates one or more Amazon Lightsail instances.</p> <p>The <code>create instances</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_CreateInstances_21626239; body: JsonNode): Recallable =
  ## createInstances
  ## <p>Creates one or more Amazon Lightsail instances.</p> <p>The <code>create instances</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626253 = newJObject()
  if body != nil:
    body_21626253 = body
  result = call_21626252.call(nil, nil, nil, nil, body_21626253)

var createInstances* = Call_CreateInstances_21626239(name: "createInstances",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstances",
    validator: validate_CreateInstances_21626240, base: "/",
    makeUrl: url_CreateInstances_21626241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstancesFromSnapshot_21626254 = ref object of OpenApiRestCall_21625435
proc url_CreateInstancesFromSnapshot_21626256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInstancesFromSnapshot_21626255(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21626257 = header.getOrDefault("X-Amz-Date")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Date", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Security-Token", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Target")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstancesFromSnapshot"))
  if valid_21626259 != nil:
    section.add "X-Amz-Target", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Algorithm", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Signature", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Credential")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Credential", valid_21626264
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

proc call*(call_21626266: Call_CreateInstancesFromSnapshot_21626254;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_CreateInstancesFromSnapshot_21626254; body: JsonNode): Recallable =
  ## createInstancesFromSnapshot
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626268 = newJObject()
  if body != nil:
    body_21626268 = body
  result = call_21626267.call(nil, nil, nil, nil, body_21626268)

var createInstancesFromSnapshot* = Call_CreateInstancesFromSnapshot_21626254(
    name: "createInstancesFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstancesFromSnapshot",
    validator: validate_CreateInstancesFromSnapshot_21626255, base: "/",
    makeUrl: url_CreateInstancesFromSnapshot_21626256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateKeyPair_21626269 = ref object of OpenApiRestCall_21625435
proc url_CreateKeyPair_21626271(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateKeyPair_21626270(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21626272 = header.getOrDefault("X-Amz-Date")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Date", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Security-Token", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Target")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateKeyPair"))
  if valid_21626274 != nil:
    section.add "X-Amz-Target", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Algorithm", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Signature")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Signature", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Credential")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Credential", valid_21626279
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

proc call*(call_21626281: Call_CreateKeyPair_21626269; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_CreateKeyPair_21626269; body: JsonNode): Recallable =
  ## createKeyPair
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626283 = newJObject()
  if body != nil:
    body_21626283 = body
  result = call_21626282.call(nil, nil, nil, nil, body_21626283)

var createKeyPair* = Call_CreateKeyPair_21626269(name: "createKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateKeyPair",
    validator: validate_CreateKeyPair_21626270, base: "/",
    makeUrl: url_CreateKeyPair_21626271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoadBalancer_21626284 = ref object of OpenApiRestCall_21625435
proc url_CreateLoadBalancer_21626286(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLoadBalancer_21626285(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626287 = header.getOrDefault("X-Amz-Date")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Date", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Security-Token", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Target")
  valid_21626289 = validateParameter(valid_21626289, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateLoadBalancer"))
  if valid_21626289 != nil:
    section.add "X-Amz-Target", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
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

proc call*(call_21626296: Call_CreateLoadBalancer_21626284; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see <a href="https://lightsail.aws.amazon.com/ls/docs/how-to/article/configure-lightsail-instances-for-load-balancing">Configure your Lightsail instances for load balancing</a>. You can create up to 5 load balancers per AWS Region in your account.</p> <p>When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the <code>UpdateLoadBalancerAttribute</code> operation.</p> <p>The <code>create load balancer</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_CreateLoadBalancer_21626284; body: JsonNode): Recallable =
  ## createLoadBalancer
  ## <p>Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see <a href="https://lightsail.aws.amazon.com/ls/docs/how-to/article/configure-lightsail-instances-for-load-balancing">Configure your Lightsail instances for load balancing</a>. You can create up to 5 load balancers per AWS Region in your account.</p> <p>When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the <code>UpdateLoadBalancerAttribute</code> operation.</p> <p>The <code>create load balancer</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626298 = newJObject()
  if body != nil:
    body_21626298 = body
  result = call_21626297.call(nil, nil, nil, nil, body_21626298)

var createLoadBalancer* = Call_CreateLoadBalancer_21626284(
    name: "createLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateLoadBalancer",
    validator: validate_CreateLoadBalancer_21626285, base: "/",
    makeUrl: url_CreateLoadBalancer_21626286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoadBalancerTlsCertificate_21626299 = ref object of OpenApiRestCall_21625435
proc url_CreateLoadBalancerTlsCertificate_21626301(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLoadBalancerTlsCertificate_21626300(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626302 = header.getOrDefault("X-Amz-Date")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Date", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Security-Token", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Target")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateLoadBalancerTlsCertificate"))
  if valid_21626304 != nil:
    section.add "X-Amz-Target", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
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

proc call*(call_21626311: Call_CreateLoadBalancerTlsCertificate_21626299;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>CreateLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_CreateLoadBalancerTlsCertificate_21626299;
          body: JsonNode): Recallable =
  ## createLoadBalancerTlsCertificate
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>CreateLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626313 = newJObject()
  if body != nil:
    body_21626313 = body
  result = call_21626312.call(nil, nil, nil, nil, body_21626313)

var createLoadBalancerTlsCertificate* = Call_CreateLoadBalancerTlsCertificate_21626299(
    name: "createLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateLoadBalancerTlsCertificate",
    validator: validate_CreateLoadBalancerTlsCertificate_21626300, base: "/",
    makeUrl: url_CreateLoadBalancerTlsCertificate_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabase_21626314 = ref object of OpenApiRestCall_21625435
proc url_CreateRelationalDatabase_21626316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRelationalDatabase_21626315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21626317 = header.getOrDefault("X-Amz-Date")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Date", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Security-Token", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Target")
  valid_21626319 = validateParameter(valid_21626319, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabase"))
  if valid_21626319 != nil:
    section.add "X-Amz-Target", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Algorithm", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Signature")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Signature", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Credential")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Credential", valid_21626324
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

proc call*(call_21626326: Call_CreateRelationalDatabase_21626314;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626326.validator(path, query, header, formData, body, _)
  let scheme = call_21626326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626326.makeUrl(scheme.get, call_21626326.host, call_21626326.base,
                               call_21626326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626326, uri, valid, _)

proc call*(call_21626327: Call_CreateRelationalDatabase_21626314; body: JsonNode): Recallable =
  ## createRelationalDatabase
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626328 = newJObject()
  if body != nil:
    body_21626328 = body
  result = call_21626327.call(nil, nil, nil, nil, body_21626328)

var createRelationalDatabase* = Call_CreateRelationalDatabase_21626314(
    name: "createRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabase",
    validator: validate_CreateRelationalDatabase_21626315, base: "/",
    makeUrl: url_CreateRelationalDatabase_21626316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabaseFromSnapshot_21626329 = ref object of OpenApiRestCall_21625435
proc url_CreateRelationalDatabaseFromSnapshot_21626331(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRelationalDatabaseFromSnapshot_21626330(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Target")
  valid_21626334 = validateParameter(valid_21626334, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabaseFromSnapshot"))
  if valid_21626334 != nil:
    section.add "X-Amz-Target", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
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

proc call*(call_21626341: Call_CreateRelationalDatabaseFromSnapshot_21626329;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new database from an existing database snapshot in Amazon Lightsail.</p> <p>You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan.</p> <p>The <code>create relational database from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626341.validator(path, query, header, formData, body, _)
  let scheme = call_21626341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626341.makeUrl(scheme.get, call_21626341.host, call_21626341.base,
                               call_21626341.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626341, uri, valid, _)

proc call*(call_21626342: Call_CreateRelationalDatabaseFromSnapshot_21626329;
          body: JsonNode): Recallable =
  ## createRelationalDatabaseFromSnapshot
  ## <p>Creates a new database from an existing database snapshot in Amazon Lightsail.</p> <p>You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan.</p> <p>The <code>create relational database from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626343 = newJObject()
  if body != nil:
    body_21626343 = body
  result = call_21626342.call(nil, nil, nil, nil, body_21626343)

var createRelationalDatabaseFromSnapshot* = Call_CreateRelationalDatabaseFromSnapshot_21626329(
    name: "createRelationalDatabaseFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabaseFromSnapshot",
    validator: validate_CreateRelationalDatabaseFromSnapshot_21626330, base: "/",
    makeUrl: url_CreateRelationalDatabaseFromSnapshot_21626331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabaseSnapshot_21626344 = ref object of OpenApiRestCall_21625435
proc url_CreateRelationalDatabaseSnapshot_21626346(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRelationalDatabaseSnapshot_21626345(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Target")
  valid_21626349 = validateParameter(valid_21626349, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabaseSnapshot"))
  if valid_21626349 != nil:
    section.add "X-Amz-Target", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
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

proc call*(call_21626356: Call_CreateRelationalDatabaseSnapshot_21626344;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database.</p> <p>The <code>create relational database snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_CreateRelationalDatabaseSnapshot_21626344;
          body: JsonNode): Recallable =
  ## createRelationalDatabaseSnapshot
  ## <p>Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database.</p> <p>The <code>create relational database snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626358 = newJObject()
  if body != nil:
    body_21626358 = body
  result = call_21626357.call(nil, nil, nil, nil, body_21626358)

var createRelationalDatabaseSnapshot* = Call_CreateRelationalDatabaseSnapshot_21626344(
    name: "createRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabaseSnapshot",
    validator: validate_CreateRelationalDatabaseSnapshot_21626345, base: "/",
    makeUrl: url_CreateRelationalDatabaseSnapshot_21626346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlarm_21626359 = ref object of OpenApiRestCall_21625435
proc url_DeleteAlarm_21626361(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAlarm_21626360(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626362 = header.getOrDefault("X-Amz-Date")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Date", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Security-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Target")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteAlarm"))
  if valid_21626364 != nil:
    section.add "X-Amz-Target", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Algorithm", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Signature")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Signature", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Credential")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Credential", valid_21626369
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

proc call*(call_21626371: Call_DeleteAlarm_21626359; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an alarm.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
  ## 
  let valid = call_21626371.validator(path, query, header, formData, body, _)
  let scheme = call_21626371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626371.makeUrl(scheme.get, call_21626371.host, call_21626371.base,
                               call_21626371.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626371, uri, valid, _)

proc call*(call_21626372: Call_DeleteAlarm_21626359; body: JsonNode): Recallable =
  ## deleteAlarm
  ## <p>Deletes an alarm.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
  ##   body: JObject (required)
  var body_21626373 = newJObject()
  if body != nil:
    body_21626373 = body
  result = call_21626372.call(nil, nil, nil, nil, body_21626373)

var deleteAlarm* = Call_DeleteAlarm_21626359(name: "deleteAlarm",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteAlarm",
    validator: validate_DeleteAlarm_21626360, base: "/", makeUrl: url_DeleteAlarm_21626361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAutoSnapshot_21626374 = ref object of OpenApiRestCall_21625435
proc url_DeleteAutoSnapshot_21626376(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAutoSnapshot_21626375(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626377 = header.getOrDefault("X-Amz-Date")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Date", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Security-Token", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Target")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteAutoSnapshot"))
  if valid_21626379 != nil:
    section.add "X-Amz-Target", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Algorithm", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Signature")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Signature", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Credential")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Credential", valid_21626384
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

proc call*(call_21626386: Call_DeleteAutoSnapshot_21626374; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an automatic snapshot of an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_21626386.validator(path, query, header, formData, body, _)
  let scheme = call_21626386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626386.makeUrl(scheme.get, call_21626386.host, call_21626386.base,
                               call_21626386.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626386, uri, valid, _)

proc call*(call_21626387: Call_DeleteAutoSnapshot_21626374; body: JsonNode): Recallable =
  ## deleteAutoSnapshot
  ## Deletes an automatic snapshot of an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_21626388 = newJObject()
  if body != nil:
    body_21626388 = body
  result = call_21626387.call(nil, nil, nil, nil, body_21626388)

var deleteAutoSnapshot* = Call_DeleteAutoSnapshot_21626374(
    name: "deleteAutoSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteAutoSnapshot",
    validator: validate_DeleteAutoSnapshot_21626375, base: "/",
    makeUrl: url_DeleteAutoSnapshot_21626376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteContactMethod_21626389 = ref object of OpenApiRestCall_21625435
proc url_DeleteContactMethod_21626391(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteContactMethod_21626390(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626392 = header.getOrDefault("X-Amz-Date")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Date", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Security-Token", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Target")
  valid_21626394 = validateParameter(valid_21626394, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteContactMethod"))
  if valid_21626394 != nil:
    section.add "X-Amz-Target", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Algorithm", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Signature")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Signature", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Credential")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Credential", valid_21626399
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

proc call*(call_21626401: Call_DeleteContactMethod_21626389; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
  ## 
  let valid = call_21626401.validator(path, query, header, formData, body, _)
  let scheme = call_21626401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626401.makeUrl(scheme.get, call_21626401.host, call_21626401.base,
                               call_21626401.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626401, uri, valid, _)

proc call*(call_21626402: Call_DeleteContactMethod_21626389; body: JsonNode): Recallable =
  ## deleteContactMethod
  ## <p>Deletes a contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
  ##   body: JObject (required)
  var body_21626403 = newJObject()
  if body != nil:
    body_21626403 = body
  result = call_21626402.call(nil, nil, nil, nil, body_21626403)

var deleteContactMethod* = Call_DeleteContactMethod_21626389(
    name: "deleteContactMethod", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteContactMethod",
    validator: validate_DeleteContactMethod_21626390, base: "/",
    makeUrl: url_DeleteContactMethod_21626391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDisk_21626404 = ref object of OpenApiRestCall_21625435
proc url_DeleteDisk_21626406(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDisk_21626405(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626407 = header.getOrDefault("X-Amz-Date")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Date", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Security-Token", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Target")
  valid_21626409 = validateParameter(valid_21626409, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDisk"))
  if valid_21626409 != nil:
    section.add "X-Amz-Target", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Algorithm", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Signature")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Signature", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Credential")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Credential", valid_21626414
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

proc call*(call_21626416: Call_DeleteDisk_21626404; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified block storage disk. The disk must be in the <code>available</code> state (not attached to a Lightsail instance).</p> <note> <p>The disk may remain in the <code>deleting</code> state for several minutes.</p> </note> <p>The <code>delete disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626416.validator(path, query, header, formData, body, _)
  let scheme = call_21626416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626416.makeUrl(scheme.get, call_21626416.host, call_21626416.base,
                               call_21626416.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626416, uri, valid, _)

proc call*(call_21626417: Call_DeleteDisk_21626404; body: JsonNode): Recallable =
  ## deleteDisk
  ## <p>Deletes the specified block storage disk. The disk must be in the <code>available</code> state (not attached to a Lightsail instance).</p> <note> <p>The disk may remain in the <code>deleting</code> state for several minutes.</p> </note> <p>The <code>delete disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626418 = newJObject()
  if body != nil:
    body_21626418 = body
  result = call_21626417.call(nil, nil, nil, nil, body_21626418)

var deleteDisk* = Call_DeleteDisk_21626404(name: "deleteDisk",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteDisk",
                                        validator: validate_DeleteDisk_21626405,
                                        base: "/", makeUrl: url_DeleteDisk_21626406,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiskSnapshot_21626419 = ref object of OpenApiRestCall_21625435
proc url_DeleteDiskSnapshot_21626421(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDiskSnapshot_21626420(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626422 = header.getOrDefault("X-Amz-Date")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Date", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Security-Token", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Target")
  valid_21626424 = validateParameter(valid_21626424, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDiskSnapshot"))
  if valid_21626424 != nil:
    section.add "X-Amz-Target", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Algorithm", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Signature")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Signature", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Credential")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Credential", valid_21626429
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

proc call*(call_21626431: Call_DeleteDiskSnapshot_21626419; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified disk snapshot.</p> <p>When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk.</p> <p>The <code>delete disk snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626431.validator(path, query, header, formData, body, _)
  let scheme = call_21626431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626431.makeUrl(scheme.get, call_21626431.host, call_21626431.base,
                               call_21626431.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626431, uri, valid, _)

proc call*(call_21626432: Call_DeleteDiskSnapshot_21626419; body: JsonNode): Recallable =
  ## deleteDiskSnapshot
  ## <p>Deletes the specified disk snapshot.</p> <p>When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk.</p> <p>The <code>delete disk snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626433 = newJObject()
  if body != nil:
    body_21626433 = body
  result = call_21626432.call(nil, nil, nil, nil, body_21626433)

var deleteDiskSnapshot* = Call_DeleteDiskSnapshot_21626419(
    name: "deleteDiskSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDiskSnapshot",
    validator: validate_DeleteDiskSnapshot_21626420, base: "/",
    makeUrl: url_DeleteDiskSnapshot_21626421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_21626434 = ref object of OpenApiRestCall_21625435
proc url_DeleteDomain_21626436(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDomain_21626435(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21626437 = header.getOrDefault("X-Amz-Date")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Date", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Security-Token", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Target")
  valid_21626439 = validateParameter(valid_21626439, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDomain"))
  if valid_21626439 != nil:
    section.add "X-Amz-Target", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Algorithm", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Signature")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Signature", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Credential")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Credential", valid_21626444
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

proc call*(call_21626446: Call_DeleteDomain_21626434; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626446.validator(path, query, header, formData, body, _)
  let scheme = call_21626446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626446.makeUrl(scheme.get, call_21626446.host, call_21626446.base,
                               call_21626446.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626446, uri, valid, _)

proc call*(call_21626447: Call_DeleteDomain_21626434; body: JsonNode): Recallable =
  ## deleteDomain
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626448 = newJObject()
  if body != nil:
    body_21626448 = body
  result = call_21626447.call(nil, nil, nil, nil, body_21626448)

var deleteDomain* = Call_DeleteDomain_21626434(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDomain",
    validator: validate_DeleteDomain_21626435, base: "/", makeUrl: url_DeleteDomain_21626436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainEntry_21626449 = ref object of OpenApiRestCall_21625435
proc url_DeleteDomainEntry_21626451(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDomainEntry_21626450(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626452 = header.getOrDefault("X-Amz-Date")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Date", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Security-Token", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Target")
  valid_21626454 = validateParameter(valid_21626454, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDomainEntry"))
  if valid_21626454 != nil:
    section.add "X-Amz-Target", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Algorithm", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Signature")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Signature", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Credential")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Credential", valid_21626459
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

proc call*(call_21626461: Call_DeleteDomainEntry_21626449; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a specific domain entry.</p> <p>The <code>delete domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626461.validator(path, query, header, formData, body, _)
  let scheme = call_21626461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626461.makeUrl(scheme.get, call_21626461.host, call_21626461.base,
                               call_21626461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626461, uri, valid, _)

proc call*(call_21626462: Call_DeleteDomainEntry_21626449; body: JsonNode): Recallable =
  ## deleteDomainEntry
  ## <p>Deletes a specific domain entry.</p> <p>The <code>delete domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626463 = newJObject()
  if body != nil:
    body_21626463 = body
  result = call_21626462.call(nil, nil, nil, nil, body_21626463)

var deleteDomainEntry* = Call_DeleteDomainEntry_21626449(name: "deleteDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDomainEntry",
    validator: validate_DeleteDomainEntry_21626450, base: "/",
    makeUrl: url_DeleteDomainEntry_21626451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstance_21626464 = ref object of OpenApiRestCall_21625435
proc url_DeleteInstance_21626466(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInstance_21626465(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626467 = header.getOrDefault("X-Amz-Date")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Date", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Security-Token", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Target")
  valid_21626469 = validateParameter(valid_21626469, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteInstance"))
  if valid_21626469 != nil:
    section.add "X-Amz-Target", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Algorithm", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Signature")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Signature", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Credential")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Credential", valid_21626474
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

proc call*(call_21626476: Call_DeleteInstance_21626464; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an Amazon Lightsail instance.</p> <p>The <code>delete instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626476.validator(path, query, header, formData, body, _)
  let scheme = call_21626476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626476.makeUrl(scheme.get, call_21626476.host, call_21626476.base,
                               call_21626476.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626476, uri, valid, _)

proc call*(call_21626477: Call_DeleteInstance_21626464; body: JsonNode): Recallable =
  ## deleteInstance
  ## <p>Deletes an Amazon Lightsail instance.</p> <p>The <code>delete instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626478 = newJObject()
  if body != nil:
    body_21626478 = body
  result = call_21626477.call(nil, nil, nil, nil, body_21626478)

var deleteInstance* = Call_DeleteInstance_21626464(name: "deleteInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteInstance",
    validator: validate_DeleteInstance_21626465, base: "/",
    makeUrl: url_DeleteInstance_21626466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceSnapshot_21626479 = ref object of OpenApiRestCall_21625435
proc url_DeleteInstanceSnapshot_21626481(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInstanceSnapshot_21626480(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626482 = header.getOrDefault("X-Amz-Date")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Date", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Security-Token", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Target")
  valid_21626484 = validateParameter(valid_21626484, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteInstanceSnapshot"))
  if valid_21626484 != nil:
    section.add "X-Amz-Target", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Algorithm", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Signature")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Signature", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Credential")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Credential", valid_21626489
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

proc call*(call_21626491: Call_DeleteInstanceSnapshot_21626479;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a specific snapshot of a virtual private server (or <i>instance</i>).</p> <p>The <code>delete instance snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626491.validator(path, query, header, formData, body, _)
  let scheme = call_21626491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626491.makeUrl(scheme.get, call_21626491.host, call_21626491.base,
                               call_21626491.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626491, uri, valid, _)

proc call*(call_21626492: Call_DeleteInstanceSnapshot_21626479; body: JsonNode): Recallable =
  ## deleteInstanceSnapshot
  ## <p>Deletes a specific snapshot of a virtual private server (or <i>instance</i>).</p> <p>The <code>delete instance snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626493 = newJObject()
  if body != nil:
    body_21626493 = body
  result = call_21626492.call(nil, nil, nil, nil, body_21626493)

var deleteInstanceSnapshot* = Call_DeleteInstanceSnapshot_21626479(
    name: "deleteInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteInstanceSnapshot",
    validator: validate_DeleteInstanceSnapshot_21626480, base: "/",
    makeUrl: url_DeleteInstanceSnapshot_21626481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteKeyPair_21626494 = ref object of OpenApiRestCall_21625435
proc url_DeleteKeyPair_21626496(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteKeyPair_21626495(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21626497 = header.getOrDefault("X-Amz-Date")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Date", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Security-Token", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Target")
  valid_21626499 = validateParameter(valid_21626499, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteKeyPair"))
  if valid_21626499 != nil:
    section.add "X-Amz-Target", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Algorithm", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Signature")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Signature", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Credential")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Credential", valid_21626504
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

proc call*(call_21626506: Call_DeleteKeyPair_21626494; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626506.validator(path, query, header, formData, body, _)
  let scheme = call_21626506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626506.makeUrl(scheme.get, call_21626506.host, call_21626506.base,
                               call_21626506.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626506, uri, valid, _)

proc call*(call_21626507: Call_DeleteKeyPair_21626494; body: JsonNode): Recallable =
  ## deleteKeyPair
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626508 = newJObject()
  if body != nil:
    body_21626508 = body
  result = call_21626507.call(nil, nil, nil, nil, body_21626508)

var deleteKeyPair* = Call_DeleteKeyPair_21626494(name: "deleteKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteKeyPair",
    validator: validate_DeleteKeyPair_21626495, base: "/",
    makeUrl: url_DeleteKeyPair_21626496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteKnownHostKeys_21626509 = ref object of OpenApiRestCall_21625435
proc url_DeleteKnownHostKeys_21626511(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteKnownHostKeys_21626510(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626512 = header.getOrDefault("X-Amz-Date")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Date", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Security-Token", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Target")
  valid_21626514 = validateParameter(valid_21626514, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteKnownHostKeys"))
  if valid_21626514 != nil:
    section.add "X-Amz-Target", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Algorithm", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Signature")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Signature", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Credential")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Credential", valid_21626519
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

proc call*(call_21626521: Call_DeleteKnownHostKeys_21626509; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch.</p> <important> <p>Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection">Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client</a>.</p> </important>
  ## 
  let valid = call_21626521.validator(path, query, header, formData, body, _)
  let scheme = call_21626521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626521.makeUrl(scheme.get, call_21626521.host, call_21626521.base,
                               call_21626521.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626521, uri, valid, _)

proc call*(call_21626522: Call_DeleteKnownHostKeys_21626509; body: JsonNode): Recallable =
  ## deleteKnownHostKeys
  ## <p>Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch.</p> <important> <p>Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection">Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client</a>.</p> </important>
  ##   body: JObject (required)
  var body_21626523 = newJObject()
  if body != nil:
    body_21626523 = body
  result = call_21626522.call(nil, nil, nil, nil, body_21626523)

var deleteKnownHostKeys* = Call_DeleteKnownHostKeys_21626509(
    name: "deleteKnownHostKeys", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteKnownHostKeys",
    validator: validate_DeleteKnownHostKeys_21626510, base: "/",
    makeUrl: url_DeleteKnownHostKeys_21626511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoadBalancer_21626524 = ref object of OpenApiRestCall_21625435
proc url_DeleteLoadBalancer_21626526(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLoadBalancer_21626525(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626527 = header.getOrDefault("X-Amz-Date")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Date", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Security-Token", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Target")
  valid_21626529 = validateParameter(valid_21626529, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteLoadBalancer"))
  if valid_21626529 != nil:
    section.add "X-Amz-Target", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Algorithm", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Signature")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Signature", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Credential")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Credential", valid_21626534
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

proc call*(call_21626536: Call_DeleteLoadBalancer_21626524; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again.</p> <p>The <code>delete load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626536.validator(path, query, header, formData, body, _)
  let scheme = call_21626536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626536.makeUrl(scheme.get, call_21626536.host, call_21626536.base,
                               call_21626536.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626536, uri, valid, _)

proc call*(call_21626537: Call_DeleteLoadBalancer_21626524; body: JsonNode): Recallable =
  ## deleteLoadBalancer
  ## <p>Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again.</p> <p>The <code>delete load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626538 = newJObject()
  if body != nil:
    body_21626538 = body
  result = call_21626537.call(nil, nil, nil, nil, body_21626538)

var deleteLoadBalancer* = Call_DeleteLoadBalancer_21626524(
    name: "deleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteLoadBalancer",
    validator: validate_DeleteLoadBalancer_21626525, base: "/",
    makeUrl: url_DeleteLoadBalancer_21626526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoadBalancerTlsCertificate_21626539 = ref object of OpenApiRestCall_21625435
proc url_DeleteLoadBalancerTlsCertificate_21626541(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLoadBalancerTlsCertificate_21626540(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626542 = header.getOrDefault("X-Amz-Date")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Date", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Security-Token", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Target")
  valid_21626544 = validateParameter(valid_21626544, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteLoadBalancerTlsCertificate"))
  if valid_21626544 != nil:
    section.add "X-Amz-Target", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Algorithm", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Signature")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Signature", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Credential")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Credential", valid_21626549
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

proc call*(call_21626551: Call_DeleteLoadBalancerTlsCertificate_21626539;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>DeleteLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626551.validator(path, query, header, formData, body, _)
  let scheme = call_21626551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626551.makeUrl(scheme.get, call_21626551.host, call_21626551.base,
                               call_21626551.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626551, uri, valid, _)

proc call*(call_21626552: Call_DeleteLoadBalancerTlsCertificate_21626539;
          body: JsonNode): Recallable =
  ## deleteLoadBalancerTlsCertificate
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>DeleteLoadBalancerTlsCertificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626553 = newJObject()
  if body != nil:
    body_21626553 = body
  result = call_21626552.call(nil, nil, nil, nil, body_21626553)

var deleteLoadBalancerTlsCertificate* = Call_DeleteLoadBalancerTlsCertificate_21626539(
    name: "deleteLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteLoadBalancerTlsCertificate",
    validator: validate_DeleteLoadBalancerTlsCertificate_21626540, base: "/",
    makeUrl: url_DeleteLoadBalancerTlsCertificate_21626541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRelationalDatabase_21626554 = ref object of OpenApiRestCall_21625435
proc url_DeleteRelationalDatabase_21626556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRelationalDatabase_21626555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21626557 = header.getOrDefault("X-Amz-Date")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Date", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Security-Token", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Target")
  valid_21626559 = validateParameter(valid_21626559, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteRelationalDatabase"))
  if valid_21626559 != nil:
    section.add "X-Amz-Target", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Algorithm", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Signature")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Signature", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Credential")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Credential", valid_21626564
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

proc call*(call_21626566: Call_DeleteRelationalDatabase_21626554;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626566.validator(path, query, header, formData, body, _)
  let scheme = call_21626566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626566.makeUrl(scheme.get, call_21626566.host, call_21626566.base,
                               call_21626566.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626566, uri, valid, _)

proc call*(call_21626567: Call_DeleteRelationalDatabase_21626554; body: JsonNode): Recallable =
  ## deleteRelationalDatabase
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626568 = newJObject()
  if body != nil:
    body_21626568 = body
  result = call_21626567.call(nil, nil, nil, nil, body_21626568)

var deleteRelationalDatabase* = Call_DeleteRelationalDatabase_21626554(
    name: "deleteRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteRelationalDatabase",
    validator: validate_DeleteRelationalDatabase_21626555, base: "/",
    makeUrl: url_DeleteRelationalDatabase_21626556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRelationalDatabaseSnapshot_21626569 = ref object of OpenApiRestCall_21625435
proc url_DeleteRelationalDatabaseSnapshot_21626571(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRelationalDatabaseSnapshot_21626570(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626572 = header.getOrDefault("X-Amz-Date")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Date", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Security-Token", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Target")
  valid_21626574 = validateParameter(valid_21626574, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteRelationalDatabaseSnapshot"))
  if valid_21626574 != nil:
    section.add "X-Amz-Target", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Algorithm", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Signature")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Signature", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Credential")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Credential", valid_21626579
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

proc call*(call_21626581: Call_DeleteRelationalDatabaseSnapshot_21626569;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a database snapshot in Amazon Lightsail.</p> <p>The <code>delete relational database snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626581.validator(path, query, header, formData, body, _)
  let scheme = call_21626581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626581.makeUrl(scheme.get, call_21626581.host, call_21626581.base,
                               call_21626581.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626581, uri, valid, _)

proc call*(call_21626582: Call_DeleteRelationalDatabaseSnapshot_21626569;
          body: JsonNode): Recallable =
  ## deleteRelationalDatabaseSnapshot
  ## <p>Deletes a database snapshot in Amazon Lightsail.</p> <p>The <code>delete relational database snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626583 = newJObject()
  if body != nil:
    body_21626583 = body
  result = call_21626582.call(nil, nil, nil, nil, body_21626583)

var deleteRelationalDatabaseSnapshot* = Call_DeleteRelationalDatabaseSnapshot_21626569(
    name: "deleteRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteRelationalDatabaseSnapshot",
    validator: validate_DeleteRelationalDatabaseSnapshot_21626570, base: "/",
    makeUrl: url_DeleteRelationalDatabaseSnapshot_21626571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachDisk_21626584 = ref object of OpenApiRestCall_21625435
proc url_DetachDisk_21626586(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachDisk_21626585(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626587 = header.getOrDefault("X-Amz-Date")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Date", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Security-Token", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Target")
  valid_21626589 = validateParameter(valid_21626589, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachDisk"))
  if valid_21626589 != nil:
    section.add "X-Amz-Target", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-Algorithm", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-Signature")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Signature", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Credential")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Credential", valid_21626594
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

proc call*(call_21626596: Call_DetachDisk_21626584; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk.</p> <p>The <code>detach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626596.validator(path, query, header, formData, body, _)
  let scheme = call_21626596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626596.makeUrl(scheme.get, call_21626596.host, call_21626596.base,
                               call_21626596.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626596, uri, valid, _)

proc call*(call_21626597: Call_DetachDisk_21626584; body: JsonNode): Recallable =
  ## detachDisk
  ## <p>Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk.</p> <p>The <code>detach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626598 = newJObject()
  if body != nil:
    body_21626598 = body
  result = call_21626597.call(nil, nil, nil, nil, body_21626598)

var detachDisk* = Call_DetachDisk_21626584(name: "detachDisk",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DetachDisk",
                                        validator: validate_DetachDisk_21626585,
                                        base: "/", makeUrl: url_DetachDisk_21626586,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachInstancesFromLoadBalancer_21626599 = ref object of OpenApiRestCall_21625435
proc url_DetachInstancesFromLoadBalancer_21626601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachInstancesFromLoadBalancer_21626600(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626602 = header.getOrDefault("X-Amz-Date")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Date", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Security-Token", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Target")
  valid_21626604 = validateParameter(valid_21626604, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachInstancesFromLoadBalancer"))
  if valid_21626604 != nil:
    section.add "X-Amz-Target", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626605
  var valid_21626606 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "X-Amz-Algorithm", valid_21626606
  var valid_21626607 = header.getOrDefault("X-Amz-Signature")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-Signature", valid_21626607
  var valid_21626608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626608
  var valid_21626609 = header.getOrDefault("X-Amz-Credential")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Credential", valid_21626609
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

proc call*(call_21626611: Call_DetachInstancesFromLoadBalancer_21626599;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Detaches the specified instances from a Lightsail load balancer.</p> <p>This operation waits until the instances are no longer needed before they are detached from the load balancer.</p> <p>The <code>detach instances from load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626611.validator(path, query, header, formData, body, _)
  let scheme = call_21626611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626611.makeUrl(scheme.get, call_21626611.host, call_21626611.base,
                               call_21626611.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626611, uri, valid, _)

proc call*(call_21626612: Call_DetachInstancesFromLoadBalancer_21626599;
          body: JsonNode): Recallable =
  ## detachInstancesFromLoadBalancer
  ## <p>Detaches the specified instances from a Lightsail load balancer.</p> <p>This operation waits until the instances are no longer needed before they are detached from the load balancer.</p> <p>The <code>detach instances from load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626613 = newJObject()
  if body != nil:
    body_21626613 = body
  result = call_21626612.call(nil, nil, nil, nil, body_21626613)

var detachInstancesFromLoadBalancer* = Call_DetachInstancesFromLoadBalancer_21626599(
    name: "detachInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DetachInstancesFromLoadBalancer",
    validator: validate_DetachInstancesFromLoadBalancer_21626600, base: "/",
    makeUrl: url_DetachInstancesFromLoadBalancer_21626601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachStaticIp_21626614 = ref object of OpenApiRestCall_21625435
proc url_DetachStaticIp_21626616(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachStaticIp_21626615(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626617 = header.getOrDefault("X-Amz-Date")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Date", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Security-Token", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Target")
  valid_21626619 = validateParameter(valid_21626619, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachStaticIp"))
  if valid_21626619 != nil:
    section.add "X-Amz-Target", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Algorithm", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Signature")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Signature", valid_21626622
  var valid_21626623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626623
  var valid_21626624 = header.getOrDefault("X-Amz-Credential")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-Credential", valid_21626624
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

proc call*(call_21626626: Call_DetachStaticIp_21626614; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Detaches a static IP from the Amazon Lightsail instance to which it is attached.
  ## 
  let valid = call_21626626.validator(path, query, header, formData, body, _)
  let scheme = call_21626626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626626.makeUrl(scheme.get, call_21626626.host, call_21626626.base,
                               call_21626626.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626626, uri, valid, _)

proc call*(call_21626627: Call_DetachStaticIp_21626614; body: JsonNode): Recallable =
  ## detachStaticIp
  ## Detaches a static IP from the Amazon Lightsail instance to which it is attached.
  ##   body: JObject (required)
  var body_21626628 = newJObject()
  if body != nil:
    body_21626628 = body
  result = call_21626627.call(nil, nil, nil, nil, body_21626628)

var detachStaticIp* = Call_DetachStaticIp_21626614(name: "detachStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DetachStaticIp",
    validator: validate_DetachStaticIp_21626615, base: "/",
    makeUrl: url_DetachStaticIp_21626616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAddOn_21626629 = ref object of OpenApiRestCall_21625435
proc url_DisableAddOn_21626631(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableAddOn_21626630(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
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
  var valid_21626632 = header.getOrDefault("X-Amz-Date")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Date", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Security-Token", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Target")
  valid_21626634 = validateParameter(valid_21626634, JString, required = true, default = newJString(
      "Lightsail_20161128.DisableAddOn"))
  if valid_21626634 != nil:
    section.add "X-Amz-Target", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-Algorithm", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Signature")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Signature", valid_21626637
  var valid_21626638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626638
  var valid_21626639 = header.getOrDefault("X-Amz-Credential")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-Credential", valid_21626639
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

proc call*(call_21626641: Call_DisableAddOn_21626629; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_21626641.validator(path, query, header, formData, body, _)
  let scheme = call_21626641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626641.makeUrl(scheme.get, call_21626641.host, call_21626641.base,
                               call_21626641.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626641, uri, valid, _)

proc call*(call_21626642: Call_DisableAddOn_21626629; body: JsonNode): Recallable =
  ## disableAddOn
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_21626643 = newJObject()
  if body != nil:
    body_21626643 = body
  result = call_21626642.call(nil, nil, nil, nil, body_21626643)

var disableAddOn* = Call_DisableAddOn_21626629(name: "disableAddOn",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DisableAddOn",
    validator: validate_DisableAddOn_21626630, base: "/", makeUrl: url_DisableAddOn_21626631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DownloadDefaultKeyPair_21626644 = ref object of OpenApiRestCall_21625435
proc url_DownloadDefaultKeyPair_21626646(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DownloadDefaultKeyPair_21626645(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626647 = header.getOrDefault("X-Amz-Date")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Date", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Security-Token", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Target")
  valid_21626649 = validateParameter(valid_21626649, JString, required = true, default = newJString(
      "Lightsail_20161128.DownloadDefaultKeyPair"))
  if valid_21626649 != nil:
    section.add "X-Amz-Target", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Algorithm", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Signature")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Signature", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Credential")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Credential", valid_21626654
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

proc call*(call_21626656: Call_DownloadDefaultKeyPair_21626644;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Downloads the default SSH key pair from the user's account.
  ## 
  let valid = call_21626656.validator(path, query, header, formData, body, _)
  let scheme = call_21626656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626656.makeUrl(scheme.get, call_21626656.host, call_21626656.base,
                               call_21626656.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626656, uri, valid, _)

proc call*(call_21626657: Call_DownloadDefaultKeyPair_21626644; body: JsonNode): Recallable =
  ## downloadDefaultKeyPair
  ## Downloads the default SSH key pair from the user's account.
  ##   body: JObject (required)
  var body_21626658 = newJObject()
  if body != nil:
    body_21626658 = body
  result = call_21626657.call(nil, nil, nil, nil, body_21626658)

var downloadDefaultKeyPair* = Call_DownloadDefaultKeyPair_21626644(
    name: "downloadDefaultKeyPair", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DownloadDefaultKeyPair",
    validator: validate_DownloadDefaultKeyPair_21626645, base: "/",
    makeUrl: url_DownloadDefaultKeyPair_21626646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAddOn_21626659 = ref object of OpenApiRestCall_21625435
proc url_EnableAddOn_21626661(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableAddOn_21626660(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626662 = header.getOrDefault("X-Amz-Date")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Date", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Security-Token", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Target")
  valid_21626664 = validateParameter(valid_21626664, JString, required = true, default = newJString(
      "Lightsail_20161128.EnableAddOn"))
  if valid_21626664 != nil:
    section.add "X-Amz-Target", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Algorithm", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Signature")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Signature", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Credential")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Credential", valid_21626669
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

proc call*(call_21626671: Call_EnableAddOn_21626659; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_21626671.validator(path, query, header, formData, body, _)
  let scheme = call_21626671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626671.makeUrl(scheme.get, call_21626671.host, call_21626671.base,
                               call_21626671.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626671, uri, valid, _)

proc call*(call_21626672: Call_EnableAddOn_21626659; body: JsonNode): Recallable =
  ## enableAddOn
  ## Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_21626673 = newJObject()
  if body != nil:
    body_21626673 = body
  result = call_21626672.call(nil, nil, nil, nil, body_21626673)

var enableAddOn* = Call_EnableAddOn_21626659(name: "enableAddOn",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.EnableAddOn",
    validator: validate_EnableAddOn_21626660, base: "/", makeUrl: url_EnableAddOn_21626661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportSnapshot_21626674 = ref object of OpenApiRestCall_21625435
proc url_ExportSnapshot_21626676(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExportSnapshot_21626675(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626677 = header.getOrDefault("X-Amz-Date")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Date", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Security-Token", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Target")
  valid_21626679 = validateParameter(valid_21626679, JString, required = true, default = newJString(
      "Lightsail_20161128.ExportSnapshot"))
  if valid_21626679 != nil:
    section.add "X-Amz-Target", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Algorithm", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Signature")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Signature", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Credential")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Credential", valid_21626684
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

proc call*(call_21626686: Call_ExportSnapshot_21626674; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the <code>create cloud formation stack</code> operation to create new Amazon EC2 instances.</p> <p>Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot.</p> <p/> <p>The <code>export snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>source snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p> <note> <p>Use the <code>get instance snapshots</code> or <code>get disk snapshots</code> operations to get a list of snapshots that you can export to Amazon EC2.</p> </note>
  ## 
  let valid = call_21626686.validator(path, query, header, formData, body, _)
  let scheme = call_21626686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626686.makeUrl(scheme.get, call_21626686.host, call_21626686.base,
                               call_21626686.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626686, uri, valid, _)

proc call*(call_21626687: Call_ExportSnapshot_21626674; body: JsonNode): Recallable =
  ## exportSnapshot
  ## <p>Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the <code>create cloud formation stack</code> operation to create new Amazon EC2 instances.</p> <p>Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot.</p> <p/> <p>The <code>export snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>source snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p> <note> <p>Use the <code>get instance snapshots</code> or <code>get disk snapshots</code> operations to get a list of snapshots that you can export to Amazon EC2.</p> </note>
  ##   body: JObject (required)
  var body_21626688 = newJObject()
  if body != nil:
    body_21626688 = body
  result = call_21626687.call(nil, nil, nil, nil, body_21626688)

var exportSnapshot* = Call_ExportSnapshot_21626674(name: "exportSnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ExportSnapshot",
    validator: validate_ExportSnapshot_21626675, base: "/",
    makeUrl: url_ExportSnapshot_21626676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetActiveNames_21626689 = ref object of OpenApiRestCall_21625435
proc url_GetActiveNames_21626691(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetActiveNames_21626690(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626692 = header.getOrDefault("X-Amz-Date")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Date", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Security-Token", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Target")
  valid_21626694 = validateParameter(valid_21626694, JString, required = true, default = newJString(
      "Lightsail_20161128.GetActiveNames"))
  if valid_21626694 != nil:
    section.add "X-Amz-Target", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Algorithm", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-Signature")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-Signature", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626698
  var valid_21626699 = header.getOrDefault("X-Amz-Credential")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Credential", valid_21626699
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

proc call*(call_21626701: Call_GetActiveNames_21626689; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the names of all active (not deleted) resources.
  ## 
  let valid = call_21626701.validator(path, query, header, formData, body, _)
  let scheme = call_21626701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626701.makeUrl(scheme.get, call_21626701.host, call_21626701.base,
                               call_21626701.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626701, uri, valid, _)

proc call*(call_21626702: Call_GetActiveNames_21626689; body: JsonNode): Recallable =
  ## getActiveNames
  ## Returns the names of all active (not deleted) resources.
  ##   body: JObject (required)
  var body_21626703 = newJObject()
  if body != nil:
    body_21626703 = body
  result = call_21626702.call(nil, nil, nil, nil, body_21626703)

var getActiveNames* = Call_GetActiveNames_21626689(name: "getActiveNames",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetActiveNames",
    validator: validate_GetActiveNames_21626690, base: "/",
    makeUrl: url_GetActiveNames_21626691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAlarms_21626704 = ref object of OpenApiRestCall_21625435
proc url_GetAlarms_21626706(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAlarms_21626705(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626707 = header.getOrDefault("X-Amz-Date")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Date", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Security-Token", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Target")
  valid_21626709 = validateParameter(valid_21626709, JString, required = true, default = newJString(
      "Lightsail_20161128.GetAlarms"))
  if valid_21626709 != nil:
    section.add "X-Amz-Target", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Algorithm", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Signature")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Signature", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Credential")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Credential", valid_21626714
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

proc call*(call_21626716: Call_GetAlarms_21626704; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the configured alarms. Specify an alarm name in your request to return information about a specific alarm, or specify a monitored resource name to return information about all alarms for a specific resource.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
  ## 
  let valid = call_21626716.validator(path, query, header, formData, body, _)
  let scheme = call_21626716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626716.makeUrl(scheme.get, call_21626716.host, call_21626716.base,
                               call_21626716.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626716, uri, valid, _)

proc call*(call_21626717: Call_GetAlarms_21626704; body: JsonNode): Recallable =
  ## getAlarms
  ## <p>Returns information about the configured alarms. Specify an alarm name in your request to return information about a specific alarm, or specify a monitored resource name to return information about all alarms for a specific resource.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
  ##   body: JObject (required)
  var body_21626718 = newJObject()
  if body != nil:
    body_21626718 = body
  result = call_21626717.call(nil, nil, nil, nil, body_21626718)

var getAlarms* = Call_GetAlarms_21626704(name: "getAlarms",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetAlarms",
                                      validator: validate_GetAlarms_21626705,
                                      base: "/", makeUrl: url_GetAlarms_21626706,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutoSnapshots_21626719 = ref object of OpenApiRestCall_21625435
proc url_GetAutoSnapshots_21626721(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAutoSnapshots_21626720(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626722 = header.getOrDefault("X-Amz-Date")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Date", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Security-Token", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Target")
  valid_21626724 = validateParameter(valid_21626724, JString, required = true, default = newJString(
      "Lightsail_20161128.GetAutoSnapshots"))
  if valid_21626724 != nil:
    section.add "X-Amz-Target", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Algorithm", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Signature")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Signature", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Credential")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Credential", valid_21626729
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

proc call*(call_21626731: Call_GetAutoSnapshots_21626719; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the available automatic snapshots for an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_21626731.validator(path, query, header, formData, body, _)
  let scheme = call_21626731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626731.makeUrl(scheme.get, call_21626731.host, call_21626731.base,
                               call_21626731.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626731, uri, valid, _)

proc call*(call_21626732: Call_GetAutoSnapshots_21626719; body: JsonNode): Recallable =
  ## getAutoSnapshots
  ## Returns the available automatic snapshots for an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_21626733 = newJObject()
  if body != nil:
    body_21626733 = body
  result = call_21626732.call(nil, nil, nil, nil, body_21626733)

var getAutoSnapshots* = Call_GetAutoSnapshots_21626719(name: "getAutoSnapshots",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetAutoSnapshots",
    validator: validate_GetAutoSnapshots_21626720, base: "/",
    makeUrl: url_GetAutoSnapshots_21626721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlueprints_21626734 = ref object of OpenApiRestCall_21625435
proc url_GetBlueprints_21626736(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBlueprints_21626735(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
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
  var valid_21626737 = header.getOrDefault("X-Amz-Date")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Date", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Security-Token", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Target")
  valid_21626739 = validateParameter(valid_21626739, JString, required = true, default = newJString(
      "Lightsail_20161128.GetBlueprints"))
  if valid_21626739 != nil:
    section.add "X-Amz-Target", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-Algorithm", valid_21626741
  var valid_21626742 = header.getOrDefault("X-Amz-Signature")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-Signature", valid_21626742
  var valid_21626743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626743
  var valid_21626744 = header.getOrDefault("X-Amz-Credential")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Credential", valid_21626744
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

proc call*(call_21626746: Call_GetBlueprints_21626734; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
  ## 
  let valid = call_21626746.validator(path, query, header, formData, body, _)
  let scheme = call_21626746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626746.makeUrl(scheme.get, call_21626746.host, call_21626746.base,
                               call_21626746.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626746, uri, valid, _)

proc call*(call_21626747: Call_GetBlueprints_21626734; body: JsonNode): Recallable =
  ## getBlueprints
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
  ##   body: JObject (required)
  var body_21626748 = newJObject()
  if body != nil:
    body_21626748 = body
  result = call_21626747.call(nil, nil, nil, nil, body_21626748)

var getBlueprints* = Call_GetBlueprints_21626734(name: "getBlueprints",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetBlueprints",
    validator: validate_GetBlueprints_21626735, base: "/",
    makeUrl: url_GetBlueprints_21626736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBundles_21626749 = ref object of OpenApiRestCall_21625435
proc url_GetBundles_21626751(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBundles_21626750(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626752 = header.getOrDefault("X-Amz-Date")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Date", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-Security-Token", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Target")
  valid_21626754 = validateParameter(valid_21626754, JString, required = true, default = newJString(
      "Lightsail_20161128.GetBundles"))
  if valid_21626754 != nil:
    section.add "X-Amz-Target", valid_21626754
  var valid_21626755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626755
  var valid_21626756 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-Algorithm", valid_21626756
  var valid_21626757 = header.getOrDefault("X-Amz-Signature")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Signature", valid_21626757
  var valid_21626758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Credential")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Credential", valid_21626759
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

proc call*(call_21626761: Call_GetBundles_21626749; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the list of bundles that are available for purchase. A bundle describes the specs for your virtual private server (or <i>instance</i>).
  ## 
  let valid = call_21626761.validator(path, query, header, formData, body, _)
  let scheme = call_21626761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626761.makeUrl(scheme.get, call_21626761.host, call_21626761.base,
                               call_21626761.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626761, uri, valid, _)

proc call*(call_21626762: Call_GetBundles_21626749; body: JsonNode): Recallable =
  ## getBundles
  ## Returns the list of bundles that are available for purchase. A bundle describes the specs for your virtual private server (or <i>instance</i>).
  ##   body: JObject (required)
  var body_21626763 = newJObject()
  if body != nil:
    body_21626763 = body
  result = call_21626762.call(nil, nil, nil, nil, body_21626763)

var getBundles* = Call_GetBundles_21626749(name: "getBundles",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetBundles",
                                        validator: validate_GetBundles_21626750,
                                        base: "/", makeUrl: url_GetBundles_21626751,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFormationStackRecords_21626764 = ref object of OpenApiRestCall_21625435
proc url_GetCloudFormationStackRecords_21626766(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCloudFormationStackRecords_21626765(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626767 = header.getOrDefault("X-Amz-Date")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Date", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-Security-Token", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-Target")
  valid_21626769 = validateParameter(valid_21626769, JString, required = true, default = newJString(
      "Lightsail_20161128.GetCloudFormationStackRecords"))
  if valid_21626769 != nil:
    section.add "X-Amz-Target", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626770
  var valid_21626771 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626771 = validateParameter(valid_21626771, JString, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "X-Amz-Algorithm", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Signature")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Signature", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-Credential")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Credential", valid_21626774
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

proc call*(call_21626776: Call_GetCloudFormationStackRecords_21626764;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the CloudFormation stack record created as a result of the <code>create cloud formation stack</code> operation.</p> <p>An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.</p>
  ## 
  let valid = call_21626776.validator(path, query, header, formData, body, _)
  let scheme = call_21626776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626776.makeUrl(scheme.get, call_21626776.host, call_21626776.base,
                               call_21626776.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626776, uri, valid, _)

proc call*(call_21626777: Call_GetCloudFormationStackRecords_21626764;
          body: JsonNode): Recallable =
  ## getCloudFormationStackRecords
  ## <p>Returns the CloudFormation stack record created as a result of the <code>create cloud formation stack</code> operation.</p> <p>An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.</p>
  ##   body: JObject (required)
  var body_21626778 = newJObject()
  if body != nil:
    body_21626778 = body
  result = call_21626777.call(nil, nil, nil, nil, body_21626778)

var getCloudFormationStackRecords* = Call_GetCloudFormationStackRecords_21626764(
    name: "getCloudFormationStackRecords", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetCloudFormationStackRecords",
    validator: validate_GetCloudFormationStackRecords_21626765, base: "/",
    makeUrl: url_GetCloudFormationStackRecords_21626766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactMethods_21626779 = ref object of OpenApiRestCall_21625435
proc url_GetContactMethods_21626781(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetContactMethods_21626780(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626782 = header.getOrDefault("X-Amz-Date")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Date", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Security-Token", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Target")
  valid_21626784 = validateParameter(valid_21626784, JString, required = true, default = newJString(
      "Lightsail_20161128.GetContactMethods"))
  if valid_21626784 != nil:
    section.add "X-Amz-Target", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626785
  var valid_21626786 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-Algorithm", valid_21626786
  var valid_21626787 = header.getOrDefault("X-Amz-Signature")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Signature", valid_21626787
  var valid_21626788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626788 = validateParameter(valid_21626788, JString, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626788
  var valid_21626789 = header.getOrDefault("X-Amz-Credential")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "X-Amz-Credential", valid_21626789
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

proc call*(call_21626791: Call_GetContactMethods_21626779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the configured contact methods. Specify a protocol in your request to return information about a specific contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
  ## 
  let valid = call_21626791.validator(path, query, header, formData, body, _)
  let scheme = call_21626791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626791.makeUrl(scheme.get, call_21626791.host, call_21626791.base,
                               call_21626791.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626791, uri, valid, _)

proc call*(call_21626792: Call_GetContactMethods_21626779; body: JsonNode): Recallable =
  ## getContactMethods
  ## <p>Returns information about the configured contact methods. Specify a protocol in your request to return information about a specific contact method.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p>
  ##   body: JObject (required)
  var body_21626793 = newJObject()
  if body != nil:
    body_21626793 = body
  result = call_21626792.call(nil, nil, nil, nil, body_21626793)

var getContactMethods* = Call_GetContactMethods_21626779(name: "getContactMethods",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetContactMethods",
    validator: validate_GetContactMethods_21626780, base: "/",
    makeUrl: url_GetContactMethods_21626781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisk_21626794 = ref object of OpenApiRestCall_21625435
proc url_GetDisk_21626796(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDisk_21626795(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626797 = header.getOrDefault("X-Amz-Date")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Date", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Security-Token", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Target")
  valid_21626799 = validateParameter(valid_21626799, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDisk"))
  if valid_21626799 != nil:
    section.add "X-Amz-Target", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-Algorithm", valid_21626801
  var valid_21626802 = header.getOrDefault("X-Amz-Signature")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-Signature", valid_21626802
  var valid_21626803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626803 = validateParameter(valid_21626803, JString, required = false,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626803
  var valid_21626804 = header.getOrDefault("X-Amz-Credential")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "X-Amz-Credential", valid_21626804
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

proc call*(call_21626806: Call_GetDisk_21626794; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific block storage disk.
  ## 
  let valid = call_21626806.validator(path, query, header, formData, body, _)
  let scheme = call_21626806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626806.makeUrl(scheme.get, call_21626806.host, call_21626806.base,
                               call_21626806.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626806, uri, valid, _)

proc call*(call_21626807: Call_GetDisk_21626794; body: JsonNode): Recallable =
  ## getDisk
  ## Returns information about a specific block storage disk.
  ##   body: JObject (required)
  var body_21626808 = newJObject()
  if body != nil:
    body_21626808 = body
  result = call_21626807.call(nil, nil, nil, nil, body_21626808)

var getDisk* = Call_GetDisk_21626794(name: "getDisk", meth: HttpMethod.HttpPost,
                                  host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDisk",
                                  validator: validate_GetDisk_21626795, base: "/",
                                  makeUrl: url_GetDisk_21626796,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiskSnapshot_21626809 = ref object of OpenApiRestCall_21625435
proc url_GetDiskSnapshot_21626811(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiskSnapshot_21626810(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626812 = header.getOrDefault("X-Amz-Date")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Date", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-Security-Token", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Target")
  valid_21626814 = validateParameter(valid_21626814, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDiskSnapshot"))
  if valid_21626814 != nil:
    section.add "X-Amz-Target", valid_21626814
  var valid_21626815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626815
  var valid_21626816 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-Algorithm", valid_21626816
  var valid_21626817 = header.getOrDefault("X-Amz-Signature")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "X-Amz-Signature", valid_21626817
  var valid_21626818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626818 = validateParameter(valid_21626818, JString, required = false,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626818
  var valid_21626819 = header.getOrDefault("X-Amz-Credential")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Credential", valid_21626819
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

proc call*(call_21626821: Call_GetDiskSnapshot_21626809; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific block storage disk snapshot.
  ## 
  let valid = call_21626821.validator(path, query, header, formData, body, _)
  let scheme = call_21626821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626821.makeUrl(scheme.get, call_21626821.host, call_21626821.base,
                               call_21626821.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626821, uri, valid, _)

proc call*(call_21626822: Call_GetDiskSnapshot_21626809; body: JsonNode): Recallable =
  ## getDiskSnapshot
  ## Returns information about a specific block storage disk snapshot.
  ##   body: JObject (required)
  var body_21626823 = newJObject()
  if body != nil:
    body_21626823 = body
  result = call_21626822.call(nil, nil, nil, nil, body_21626823)

var getDiskSnapshot* = Call_GetDiskSnapshot_21626809(name: "getDiskSnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDiskSnapshot",
    validator: validate_GetDiskSnapshot_21626810, base: "/",
    makeUrl: url_GetDiskSnapshot_21626811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiskSnapshots_21626824 = ref object of OpenApiRestCall_21625435
proc url_GetDiskSnapshots_21626826(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiskSnapshots_21626825(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626827 = header.getOrDefault("X-Amz-Date")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-Date", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-Security-Token", valid_21626828
  var valid_21626829 = header.getOrDefault("X-Amz-Target")
  valid_21626829 = validateParameter(valid_21626829, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDiskSnapshots"))
  if valid_21626829 != nil:
    section.add "X-Amz-Target", valid_21626829
  var valid_21626830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626830 = validateParameter(valid_21626830, JString, required = false,
                                   default = nil)
  if valid_21626830 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626830
  var valid_21626831 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-Algorithm", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Signature")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Signature", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-Credential")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Credential", valid_21626834
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

proc call*(call_21626836: Call_GetDiskSnapshots_21626824; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all block storage disk snapshots in your AWS account and region.
  ## 
  let valid = call_21626836.validator(path, query, header, formData, body, _)
  let scheme = call_21626836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626836.makeUrl(scheme.get, call_21626836.host, call_21626836.base,
                               call_21626836.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626836, uri, valid, _)

proc call*(call_21626837: Call_GetDiskSnapshots_21626824; body: JsonNode): Recallable =
  ## getDiskSnapshots
  ## Returns information about all block storage disk snapshots in your AWS account and region.
  ##   body: JObject (required)
  var body_21626838 = newJObject()
  if body != nil:
    body_21626838 = body
  result = call_21626837.call(nil, nil, nil, nil, body_21626838)

var getDiskSnapshots* = Call_GetDiskSnapshots_21626824(name: "getDiskSnapshots",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDiskSnapshots",
    validator: validate_GetDiskSnapshots_21626825, base: "/",
    makeUrl: url_GetDiskSnapshots_21626826, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisks_21626839 = ref object of OpenApiRestCall_21625435
proc url_GetDisks_21626841(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDisks_21626840(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626842 = header.getOrDefault("X-Amz-Date")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "X-Amz-Date", valid_21626842
  var valid_21626843 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "X-Amz-Security-Token", valid_21626843
  var valid_21626844 = header.getOrDefault("X-Amz-Target")
  valid_21626844 = validateParameter(valid_21626844, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDisks"))
  if valid_21626844 != nil:
    section.add "X-Amz-Target", valid_21626844
  var valid_21626845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626845
  var valid_21626846 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626846 = validateParameter(valid_21626846, JString, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "X-Amz-Algorithm", valid_21626846
  var valid_21626847 = header.getOrDefault("X-Amz-Signature")
  valid_21626847 = validateParameter(valid_21626847, JString, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "X-Amz-Signature", valid_21626847
  var valid_21626848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626848 = validateParameter(valid_21626848, JString, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626848
  var valid_21626849 = header.getOrDefault("X-Amz-Credential")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "X-Amz-Credential", valid_21626849
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

proc call*(call_21626851: Call_GetDisks_21626839; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all block storage disks in your AWS account and region.
  ## 
  let valid = call_21626851.validator(path, query, header, formData, body, _)
  let scheme = call_21626851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626851.makeUrl(scheme.get, call_21626851.host, call_21626851.base,
                               call_21626851.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626851, uri, valid, _)

proc call*(call_21626852: Call_GetDisks_21626839; body: JsonNode): Recallable =
  ## getDisks
  ## Returns information about all block storage disks in your AWS account and region.
  ##   body: JObject (required)
  var body_21626853 = newJObject()
  if body != nil:
    body_21626853 = body
  result = call_21626852.call(nil, nil, nil, nil, body_21626853)

var getDisks* = Call_GetDisks_21626839(name: "getDisks", meth: HttpMethod.HttpPost,
                                    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDisks",
                                    validator: validate_GetDisks_21626840,
                                    base: "/", makeUrl: url_GetDisks_21626841,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomain_21626854 = ref object of OpenApiRestCall_21625435
proc url_GetDomain_21626856(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomain_21626855(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626857 = header.getOrDefault("X-Amz-Date")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Date", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Security-Token", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Target")
  valid_21626859 = validateParameter(valid_21626859, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDomain"))
  if valid_21626859 != nil:
    section.add "X-Amz-Target", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-Algorithm", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-Signature")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "X-Amz-Signature", valid_21626862
  var valid_21626863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626863
  var valid_21626864 = header.getOrDefault("X-Amz-Credential")
  valid_21626864 = validateParameter(valid_21626864, JString, required = false,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "X-Amz-Credential", valid_21626864
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

proc call*(call_21626866: Call_GetDomain_21626854; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific domain recordset.
  ## 
  let valid = call_21626866.validator(path, query, header, formData, body, _)
  let scheme = call_21626866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626866.makeUrl(scheme.get, call_21626866.host, call_21626866.base,
                               call_21626866.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626866, uri, valid, _)

proc call*(call_21626867: Call_GetDomain_21626854; body: JsonNode): Recallable =
  ## getDomain
  ## Returns information about a specific domain recordset.
  ##   body: JObject (required)
  var body_21626868 = newJObject()
  if body != nil:
    body_21626868 = body
  result = call_21626867.call(nil, nil, nil, nil, body_21626868)

var getDomain* = Call_GetDomain_21626854(name: "getDomain",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDomain",
                                      validator: validate_GetDomain_21626855,
                                      base: "/", makeUrl: url_GetDomain_21626856,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomains_21626869 = ref object of OpenApiRestCall_21625435
proc url_GetDomains_21626871(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDomains_21626870(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626872 = header.getOrDefault("X-Amz-Date")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Date", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Security-Token", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Target")
  valid_21626874 = validateParameter(valid_21626874, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDomains"))
  if valid_21626874 != nil:
    section.add "X-Amz-Target", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-Algorithm", valid_21626876
  var valid_21626877 = header.getOrDefault("X-Amz-Signature")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "X-Amz-Signature", valid_21626877
  var valid_21626878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626878
  var valid_21626879 = header.getOrDefault("X-Amz-Credential")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "X-Amz-Credential", valid_21626879
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

proc call*(call_21626881: Call_GetDomains_21626869; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all domains in the user's account.
  ## 
  let valid = call_21626881.validator(path, query, header, formData, body, _)
  let scheme = call_21626881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626881.makeUrl(scheme.get, call_21626881.host, call_21626881.base,
                               call_21626881.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626881, uri, valid, _)

proc call*(call_21626882: Call_GetDomains_21626869; body: JsonNode): Recallable =
  ## getDomains
  ## Returns a list of all domains in the user's account.
  ##   body: JObject (required)
  var body_21626883 = newJObject()
  if body != nil:
    body_21626883 = body
  result = call_21626882.call(nil, nil, nil, nil, body_21626883)

var getDomains* = Call_GetDomains_21626869(name: "getDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDomains",
                                        validator: validate_GetDomains_21626870,
                                        base: "/", makeUrl: url_GetDomains_21626871,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportSnapshotRecords_21626884 = ref object of OpenApiRestCall_21625435
proc url_GetExportSnapshotRecords_21626886(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetExportSnapshotRecords_21626885(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
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
  var valid_21626887 = header.getOrDefault("X-Amz-Date")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "X-Amz-Date", valid_21626887
  var valid_21626888 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "X-Amz-Security-Token", valid_21626888
  var valid_21626889 = header.getOrDefault("X-Amz-Target")
  valid_21626889 = validateParameter(valid_21626889, JString, required = true, default = newJString(
      "Lightsail_20161128.GetExportSnapshotRecords"))
  if valid_21626889 != nil:
    section.add "X-Amz-Target", valid_21626889
  var valid_21626890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626890 = validateParameter(valid_21626890, JString, required = false,
                                   default = nil)
  if valid_21626890 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626890
  var valid_21626891 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626891 = validateParameter(valid_21626891, JString, required = false,
                                   default = nil)
  if valid_21626891 != nil:
    section.add "X-Amz-Algorithm", valid_21626891
  var valid_21626892 = header.getOrDefault("X-Amz-Signature")
  valid_21626892 = validateParameter(valid_21626892, JString, required = false,
                                   default = nil)
  if valid_21626892 != nil:
    section.add "X-Amz-Signature", valid_21626892
  var valid_21626893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626893 = validateParameter(valid_21626893, JString, required = false,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626893
  var valid_21626894 = header.getOrDefault("X-Amz-Credential")
  valid_21626894 = validateParameter(valid_21626894, JString, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "X-Amz-Credential", valid_21626894
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

proc call*(call_21626896: Call_GetExportSnapshotRecords_21626884;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
  ## 
  let valid = call_21626896.validator(path, query, header, formData, body, _)
  let scheme = call_21626896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626896.makeUrl(scheme.get, call_21626896.host, call_21626896.base,
                               call_21626896.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626896, uri, valid, _)

proc call*(call_21626897: Call_GetExportSnapshotRecords_21626884; body: JsonNode): Recallable =
  ## getExportSnapshotRecords
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
  ##   body: JObject (required)
  var body_21626898 = newJObject()
  if body != nil:
    body_21626898 = body
  result = call_21626897.call(nil, nil, nil, nil, body_21626898)

var getExportSnapshotRecords* = Call_GetExportSnapshotRecords_21626884(
    name: "getExportSnapshotRecords", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetExportSnapshotRecords",
    validator: validate_GetExportSnapshotRecords_21626885, base: "/",
    makeUrl: url_GetExportSnapshotRecords_21626886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstance_21626899 = ref object of OpenApiRestCall_21625435
proc url_GetInstance_21626901(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstance_21626900(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626902 = header.getOrDefault("X-Amz-Date")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Date", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Security-Token", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-Target")
  valid_21626904 = validateParameter(valid_21626904, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstance"))
  if valid_21626904 != nil:
    section.add "X-Amz-Target", valid_21626904
  var valid_21626905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626905
  var valid_21626906 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626906 = validateParameter(valid_21626906, JString, required = false,
                                   default = nil)
  if valid_21626906 != nil:
    section.add "X-Amz-Algorithm", valid_21626906
  var valid_21626907 = header.getOrDefault("X-Amz-Signature")
  valid_21626907 = validateParameter(valid_21626907, JString, required = false,
                                   default = nil)
  if valid_21626907 != nil:
    section.add "X-Amz-Signature", valid_21626907
  var valid_21626908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626908 = validateParameter(valid_21626908, JString, required = false,
                                   default = nil)
  if valid_21626908 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626908
  var valid_21626909 = header.getOrDefault("X-Amz-Credential")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Credential", valid_21626909
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

proc call*(call_21626911: Call_GetInstance_21626899; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
  ## 
  let valid = call_21626911.validator(path, query, header, formData, body, _)
  let scheme = call_21626911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626911.makeUrl(scheme.get, call_21626911.host, call_21626911.base,
                               call_21626911.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626911, uri, valid, _)

proc call*(call_21626912: Call_GetInstance_21626899; body: JsonNode): Recallable =
  ## getInstance
  ## Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
  ##   body: JObject (required)
  var body_21626913 = newJObject()
  if body != nil:
    body_21626913 = body
  result = call_21626912.call(nil, nil, nil, nil, body_21626913)

var getInstance* = Call_GetInstance_21626899(name: "getInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstance",
    validator: validate_GetInstance_21626900, base: "/", makeUrl: url_GetInstance_21626901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceAccessDetails_21626914 = ref object of OpenApiRestCall_21625435
proc url_GetInstanceAccessDetails_21626916(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceAccessDetails_21626915(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21626917 = header.getOrDefault("X-Amz-Date")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Date", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Security-Token", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-Target")
  valid_21626919 = validateParameter(valid_21626919, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceAccessDetails"))
  if valid_21626919 != nil:
    section.add "X-Amz-Target", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626920
  var valid_21626921 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "X-Amz-Algorithm", valid_21626921
  var valid_21626922 = header.getOrDefault("X-Amz-Signature")
  valid_21626922 = validateParameter(valid_21626922, JString, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "X-Amz-Signature", valid_21626922
  var valid_21626923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626923 = validateParameter(valid_21626923, JString, required = false,
                                   default = nil)
  if valid_21626923 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626923
  var valid_21626924 = header.getOrDefault("X-Amz-Credential")
  valid_21626924 = validateParameter(valid_21626924, JString, required = false,
                                   default = nil)
  if valid_21626924 != nil:
    section.add "X-Amz-Credential", valid_21626924
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

proc call*(call_21626926: Call_GetInstanceAccessDetails_21626914;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21626926.validator(path, query, header, formData, body, _)
  let scheme = call_21626926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626926.makeUrl(scheme.get, call_21626926.host, call_21626926.base,
                               call_21626926.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626926, uri, valid, _)

proc call*(call_21626927: Call_GetInstanceAccessDetails_21626914; body: JsonNode): Recallable =
  ## getInstanceAccessDetails
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21626928 = newJObject()
  if body != nil:
    body_21626928 = body
  result = call_21626927.call(nil, nil, nil, nil, body_21626928)

var getInstanceAccessDetails* = Call_GetInstanceAccessDetails_21626914(
    name: "getInstanceAccessDetails", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceAccessDetails",
    validator: validate_GetInstanceAccessDetails_21626915, base: "/",
    makeUrl: url_GetInstanceAccessDetails_21626916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceMetricData_21626929 = ref object of OpenApiRestCall_21625435
proc url_GetInstanceMetricData_21626931(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceMetricData_21626930(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626932 = header.getOrDefault("X-Amz-Date")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Date", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Security-Token", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Target")
  valid_21626934 = validateParameter(valid_21626934, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceMetricData"))
  if valid_21626934 != nil:
    section.add "X-Amz-Target", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-Algorithm", valid_21626936
  var valid_21626937 = header.getOrDefault("X-Amz-Signature")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "X-Amz-Signature", valid_21626937
  var valid_21626938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626938 = validateParameter(valid_21626938, JString, required = false,
                                   default = nil)
  if valid_21626938 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626938
  var valid_21626939 = header.getOrDefault("X-Amz-Credential")
  valid_21626939 = validateParameter(valid_21626939, JString, required = false,
                                   default = nil)
  if valid_21626939 != nil:
    section.add "X-Amz-Credential", valid_21626939
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

proc call*(call_21626941: Call_GetInstanceMetricData_21626929;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the data points for the specified Amazon Lightsail instance metric, given an instance name.
  ## 
  let valid = call_21626941.validator(path, query, header, formData, body, _)
  let scheme = call_21626941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626941.makeUrl(scheme.get, call_21626941.host, call_21626941.base,
                               call_21626941.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626941, uri, valid, _)

proc call*(call_21626942: Call_GetInstanceMetricData_21626929; body: JsonNode): Recallable =
  ## getInstanceMetricData
  ## Returns the data points for the specified Amazon Lightsail instance metric, given an instance name.
  ##   body: JObject (required)
  var body_21626943 = newJObject()
  if body != nil:
    body_21626943 = body
  result = call_21626942.call(nil, nil, nil, nil, body_21626943)

var getInstanceMetricData* = Call_GetInstanceMetricData_21626929(
    name: "getInstanceMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceMetricData",
    validator: validate_GetInstanceMetricData_21626930, base: "/",
    makeUrl: url_GetInstanceMetricData_21626931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstancePortStates_21626944 = ref object of OpenApiRestCall_21625435
proc url_GetInstancePortStates_21626946(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstancePortStates_21626945(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626947 = header.getOrDefault("X-Amz-Date")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Date", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Security-Token", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Target")
  valid_21626949 = validateParameter(valid_21626949, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstancePortStates"))
  if valid_21626949 != nil:
    section.add "X-Amz-Target", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Algorithm", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-Signature")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Signature", valid_21626952
  var valid_21626953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626953
  var valid_21626954 = header.getOrDefault("X-Amz-Credential")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-Credential", valid_21626954
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

proc call*(call_21626956: Call_GetInstancePortStates_21626944;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the port states for a specific virtual private server, or <i>instance</i>.
  ## 
  let valid = call_21626956.validator(path, query, header, formData, body, _)
  let scheme = call_21626956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626956.makeUrl(scheme.get, call_21626956.host, call_21626956.base,
                               call_21626956.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626956, uri, valid, _)

proc call*(call_21626957: Call_GetInstancePortStates_21626944; body: JsonNode): Recallable =
  ## getInstancePortStates
  ## Returns the port states for a specific virtual private server, or <i>instance</i>.
  ##   body: JObject (required)
  var body_21626958 = newJObject()
  if body != nil:
    body_21626958 = body
  result = call_21626957.call(nil, nil, nil, nil, body_21626958)

var getInstancePortStates* = Call_GetInstancePortStates_21626944(
    name: "getInstancePortStates", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstancePortStates",
    validator: validate_GetInstancePortStates_21626945, base: "/",
    makeUrl: url_GetInstancePortStates_21626946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceSnapshot_21626959 = ref object of OpenApiRestCall_21625435
proc url_GetInstanceSnapshot_21626961(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceSnapshot_21626960(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626962 = header.getOrDefault("X-Amz-Date")
  valid_21626962 = validateParameter(valid_21626962, JString, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "X-Amz-Date", valid_21626962
  var valid_21626963 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "X-Amz-Security-Token", valid_21626963
  var valid_21626964 = header.getOrDefault("X-Amz-Target")
  valid_21626964 = validateParameter(valid_21626964, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceSnapshot"))
  if valid_21626964 != nil:
    section.add "X-Amz-Target", valid_21626964
  var valid_21626965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-Algorithm", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Signature")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Signature", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626968 = validateParameter(valid_21626968, JString, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-Credential")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-Credential", valid_21626969
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

proc call*(call_21626971: Call_GetInstanceSnapshot_21626959; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific instance snapshot.
  ## 
  let valid = call_21626971.validator(path, query, header, formData, body, _)
  let scheme = call_21626971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626971.makeUrl(scheme.get, call_21626971.host, call_21626971.base,
                               call_21626971.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626971, uri, valid, _)

proc call*(call_21626972: Call_GetInstanceSnapshot_21626959; body: JsonNode): Recallable =
  ## getInstanceSnapshot
  ## Returns information about a specific instance snapshot.
  ##   body: JObject (required)
  var body_21626973 = newJObject()
  if body != nil:
    body_21626973 = body
  result = call_21626972.call(nil, nil, nil, nil, body_21626973)

var getInstanceSnapshot* = Call_GetInstanceSnapshot_21626959(
    name: "getInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceSnapshot",
    validator: validate_GetInstanceSnapshot_21626960, base: "/",
    makeUrl: url_GetInstanceSnapshot_21626961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceSnapshots_21626974 = ref object of OpenApiRestCall_21625435
proc url_GetInstanceSnapshots_21626976(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceSnapshots_21626975(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626977 = header.getOrDefault("X-Amz-Date")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-Date", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Security-Token", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-Target")
  valid_21626979 = validateParameter(valid_21626979, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceSnapshots"))
  if valid_21626979 != nil:
    section.add "X-Amz-Target", valid_21626979
  var valid_21626980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Algorithm", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Signature")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Signature", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Credential")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Credential", valid_21626984
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

proc call*(call_21626986: Call_GetInstanceSnapshots_21626974; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all instance snapshots for the user's account.
  ## 
  let valid = call_21626986.validator(path, query, header, formData, body, _)
  let scheme = call_21626986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626986.makeUrl(scheme.get, call_21626986.host, call_21626986.base,
                               call_21626986.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626986, uri, valid, _)

proc call*(call_21626987: Call_GetInstanceSnapshots_21626974; body: JsonNode): Recallable =
  ## getInstanceSnapshots
  ## Returns all instance snapshots for the user's account.
  ##   body: JObject (required)
  var body_21626988 = newJObject()
  if body != nil:
    body_21626988 = body
  result = call_21626987.call(nil, nil, nil, nil, body_21626988)

var getInstanceSnapshots* = Call_GetInstanceSnapshots_21626974(
    name: "getInstanceSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceSnapshots",
    validator: validate_GetInstanceSnapshots_21626975, base: "/",
    makeUrl: url_GetInstanceSnapshots_21626976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceState_21626989 = ref object of OpenApiRestCall_21625435
proc url_GetInstanceState_21626991(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstanceState_21626990(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626992 = header.getOrDefault("X-Amz-Date")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "X-Amz-Date", valid_21626992
  var valid_21626993 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Security-Token", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-Target")
  valid_21626994 = validateParameter(valid_21626994, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceState"))
  if valid_21626994 != nil:
    section.add "X-Amz-Target", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626995
  var valid_21626996 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Algorithm", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-Signature")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-Signature", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-Credential")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-Credential", valid_21626999
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

proc call*(call_21627001: Call_GetInstanceState_21626989; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the state of a specific instance. Works on one instance at a time.
  ## 
  let valid = call_21627001.validator(path, query, header, formData, body, _)
  let scheme = call_21627001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627001.makeUrl(scheme.get, call_21627001.host, call_21627001.base,
                               call_21627001.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627001, uri, valid, _)

proc call*(call_21627002: Call_GetInstanceState_21626989; body: JsonNode): Recallable =
  ## getInstanceState
  ## Returns the state of a specific instance. Works on one instance at a time.
  ##   body: JObject (required)
  var body_21627003 = newJObject()
  if body != nil:
    body_21627003 = body
  result = call_21627002.call(nil, nil, nil, nil, body_21627003)

var getInstanceState* = Call_GetInstanceState_21626989(name: "getInstanceState",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceState",
    validator: validate_GetInstanceState_21626990, base: "/",
    makeUrl: url_GetInstanceState_21626991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstances_21627004 = ref object of OpenApiRestCall_21625435
proc url_GetInstances_21627006(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInstances_21627005(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
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
  var valid_21627007 = header.getOrDefault("X-Amz-Date")
  valid_21627007 = validateParameter(valid_21627007, JString, required = false,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "X-Amz-Date", valid_21627007
  var valid_21627008 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627008 = validateParameter(valid_21627008, JString, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "X-Amz-Security-Token", valid_21627008
  var valid_21627009 = header.getOrDefault("X-Amz-Target")
  valid_21627009 = validateParameter(valid_21627009, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstances"))
  if valid_21627009 != nil:
    section.add "X-Amz-Target", valid_21627009
  var valid_21627010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Algorithm", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-Signature")
  valid_21627012 = validateParameter(valid_21627012, JString, required = false,
                                   default = nil)
  if valid_21627012 != nil:
    section.add "X-Amz-Signature", valid_21627012
  var valid_21627013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627013
  var valid_21627014 = header.getOrDefault("X-Amz-Credential")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "X-Amz-Credential", valid_21627014
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

proc call*(call_21627016: Call_GetInstances_21627004; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
  ## 
  let valid = call_21627016.validator(path, query, header, formData, body, _)
  let scheme = call_21627016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627016.makeUrl(scheme.get, call_21627016.host, call_21627016.base,
                               call_21627016.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627016, uri, valid, _)

proc call*(call_21627017: Call_GetInstances_21627004; body: JsonNode): Recallable =
  ## getInstances
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
  ##   body: JObject (required)
  var body_21627018 = newJObject()
  if body != nil:
    body_21627018 = body
  result = call_21627017.call(nil, nil, nil, nil, body_21627018)

var getInstances* = Call_GetInstances_21627004(name: "getInstances",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstances",
    validator: validate_GetInstances_21627005, base: "/", makeUrl: url_GetInstances_21627006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPair_21627019 = ref object of OpenApiRestCall_21625435
proc url_GetKeyPair_21627021(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetKeyPair_21627020(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627022 = header.getOrDefault("X-Amz-Date")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-Date", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Security-Token", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-Target")
  valid_21627024 = validateParameter(valid_21627024, JString, required = true, default = newJString(
      "Lightsail_20161128.GetKeyPair"))
  if valid_21627024 != nil:
    section.add "X-Amz-Target", valid_21627024
  var valid_21627025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627025 = validateParameter(valid_21627025, JString, required = false,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627025
  var valid_21627026 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-Algorithm", valid_21627026
  var valid_21627027 = header.getOrDefault("X-Amz-Signature")
  valid_21627027 = validateParameter(valid_21627027, JString, required = false,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "X-Amz-Signature", valid_21627027
  var valid_21627028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627028 = validateParameter(valid_21627028, JString, required = false,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-Credential")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-Credential", valid_21627029
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

proc call*(call_21627031: Call_GetKeyPair_21627019; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific key pair.
  ## 
  let valid = call_21627031.validator(path, query, header, formData, body, _)
  let scheme = call_21627031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627031.makeUrl(scheme.get, call_21627031.host, call_21627031.base,
                               call_21627031.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627031, uri, valid, _)

proc call*(call_21627032: Call_GetKeyPair_21627019; body: JsonNode): Recallable =
  ## getKeyPair
  ## Returns information about a specific key pair.
  ##   body: JObject (required)
  var body_21627033 = newJObject()
  if body != nil:
    body_21627033 = body
  result = call_21627032.call(nil, nil, nil, nil, body_21627033)

var getKeyPair* = Call_GetKeyPair_21627019(name: "getKeyPair",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetKeyPair",
                                        validator: validate_GetKeyPair_21627020,
                                        base: "/", makeUrl: url_GetKeyPair_21627021,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPairs_21627034 = ref object of OpenApiRestCall_21625435
proc url_GetKeyPairs_21627036(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetKeyPairs_21627035(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627037 = header.getOrDefault("X-Amz-Date")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "X-Amz-Date", valid_21627037
  var valid_21627038 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-Security-Token", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-Target")
  valid_21627039 = validateParameter(valid_21627039, JString, required = true, default = newJString(
      "Lightsail_20161128.GetKeyPairs"))
  if valid_21627039 != nil:
    section.add "X-Amz-Target", valid_21627039
  var valid_21627040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627040
  var valid_21627041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-Algorithm", valid_21627041
  var valid_21627042 = header.getOrDefault("X-Amz-Signature")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Signature", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627043 = validateParameter(valid_21627043, JString, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-Credential")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-Credential", valid_21627044
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

proc call*(call_21627046: Call_GetKeyPairs_21627034; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all key pairs in the user's account.
  ## 
  let valid = call_21627046.validator(path, query, header, formData, body, _)
  let scheme = call_21627046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627046.makeUrl(scheme.get, call_21627046.host, call_21627046.base,
                               call_21627046.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627046, uri, valid, _)

proc call*(call_21627047: Call_GetKeyPairs_21627034; body: JsonNode): Recallable =
  ## getKeyPairs
  ## Returns information about all key pairs in the user's account.
  ##   body: JObject (required)
  var body_21627048 = newJObject()
  if body != nil:
    body_21627048 = body
  result = call_21627047.call(nil, nil, nil, nil, body_21627048)

var getKeyPairs* = Call_GetKeyPairs_21627034(name: "getKeyPairs",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetKeyPairs",
    validator: validate_GetKeyPairs_21627035, base: "/", makeUrl: url_GetKeyPairs_21627036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancer_21627049 = ref object of OpenApiRestCall_21625435
proc url_GetLoadBalancer_21627051(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLoadBalancer_21627050(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627052 = header.getOrDefault("X-Amz-Date")
  valid_21627052 = validateParameter(valid_21627052, JString, required = false,
                                   default = nil)
  if valid_21627052 != nil:
    section.add "X-Amz-Date", valid_21627052
  var valid_21627053 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "X-Amz-Security-Token", valid_21627053
  var valid_21627054 = header.getOrDefault("X-Amz-Target")
  valid_21627054 = validateParameter(valid_21627054, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancer"))
  if valid_21627054 != nil:
    section.add "X-Amz-Target", valid_21627054
  var valid_21627055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627055
  var valid_21627056 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-Algorithm", valid_21627056
  var valid_21627057 = header.getOrDefault("X-Amz-Signature")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Signature", valid_21627057
  var valid_21627058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-Credential")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-Credential", valid_21627059
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

proc call*(call_21627061: Call_GetLoadBalancer_21627049; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified Lightsail load balancer.
  ## 
  let valid = call_21627061.validator(path, query, header, formData, body, _)
  let scheme = call_21627061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627061.makeUrl(scheme.get, call_21627061.host, call_21627061.base,
                               call_21627061.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627061, uri, valid, _)

proc call*(call_21627062: Call_GetLoadBalancer_21627049; body: JsonNode): Recallable =
  ## getLoadBalancer
  ## Returns information about the specified Lightsail load balancer.
  ##   body: JObject (required)
  var body_21627063 = newJObject()
  if body != nil:
    body_21627063 = body
  result = call_21627062.call(nil, nil, nil, nil, body_21627063)

var getLoadBalancer* = Call_GetLoadBalancer_21627049(name: "getLoadBalancer",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancer",
    validator: validate_GetLoadBalancer_21627050, base: "/",
    makeUrl: url_GetLoadBalancer_21627051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancerMetricData_21627064 = ref object of OpenApiRestCall_21625435
proc url_GetLoadBalancerMetricData_21627066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLoadBalancerMetricData_21627065(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about health metrics for your Lightsail load balancer.
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
  var valid_21627067 = header.getOrDefault("X-Amz-Date")
  valid_21627067 = validateParameter(valid_21627067, JString, required = false,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "X-Amz-Date", valid_21627067
  var valid_21627068 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Security-Token", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-Target")
  valid_21627069 = validateParameter(valid_21627069, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancerMetricData"))
  if valid_21627069 != nil:
    section.add "X-Amz-Target", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627070
  var valid_21627071 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-Algorithm", valid_21627071
  var valid_21627072 = header.getOrDefault("X-Amz-Signature")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "X-Amz-Signature", valid_21627072
  var valid_21627073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-Credential")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Credential", valid_21627074
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

proc call*(call_21627076: Call_GetLoadBalancerMetricData_21627064;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about health metrics for your Lightsail load balancer.
  ## 
  let valid = call_21627076.validator(path, query, header, formData, body, _)
  let scheme = call_21627076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627076.makeUrl(scheme.get, call_21627076.host, call_21627076.base,
                               call_21627076.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627076, uri, valid, _)

proc call*(call_21627077: Call_GetLoadBalancerMetricData_21627064; body: JsonNode): Recallable =
  ## getLoadBalancerMetricData
  ## Returns information about health metrics for your Lightsail load balancer.
  ##   body: JObject (required)
  var body_21627078 = newJObject()
  if body != nil:
    body_21627078 = body
  result = call_21627077.call(nil, nil, nil, nil, body_21627078)

var getLoadBalancerMetricData* = Call_GetLoadBalancerMetricData_21627064(
    name: "getLoadBalancerMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancerMetricData",
    validator: validate_GetLoadBalancerMetricData_21627065, base: "/",
    makeUrl: url_GetLoadBalancerMetricData_21627066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancerTlsCertificates_21627079 = ref object of OpenApiRestCall_21625435
proc url_GetLoadBalancerTlsCertificates_21627081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLoadBalancerTlsCertificates_21627080(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627082 = header.getOrDefault("X-Amz-Date")
  valid_21627082 = validateParameter(valid_21627082, JString, required = false,
                                   default = nil)
  if valid_21627082 != nil:
    section.add "X-Amz-Date", valid_21627082
  var valid_21627083 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-Security-Token", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-Target")
  valid_21627084 = validateParameter(valid_21627084, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancerTlsCertificates"))
  if valid_21627084 != nil:
    section.add "X-Amz-Target", valid_21627084
  var valid_21627085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627085
  var valid_21627086 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-Algorithm", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Signature")
  valid_21627087 = validateParameter(valid_21627087, JString, required = false,
                                   default = nil)
  if valid_21627087 != nil:
    section.add "X-Amz-Signature", valid_21627087
  var valid_21627088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-Credential")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-Credential", valid_21627089
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

proc call*(call_21627091: Call_GetLoadBalancerTlsCertificates_21627079;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the TLS certificates that are associated with the specified Lightsail load balancer.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.</p>
  ## 
  let valid = call_21627091.validator(path, query, header, formData, body, _)
  let scheme = call_21627091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627091.makeUrl(scheme.get, call_21627091.host, call_21627091.base,
                               call_21627091.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627091, uri, valid, _)

proc call*(call_21627092: Call_GetLoadBalancerTlsCertificates_21627079;
          body: JsonNode): Recallable =
  ## getLoadBalancerTlsCertificates
  ## <p>Returns information about the TLS certificates that are associated with the specified Lightsail load balancer.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.</p>
  ##   body: JObject (required)
  var body_21627093 = newJObject()
  if body != nil:
    body_21627093 = body
  result = call_21627092.call(nil, nil, nil, nil, body_21627093)

var getLoadBalancerTlsCertificates* = Call_GetLoadBalancerTlsCertificates_21627079(
    name: "getLoadBalancerTlsCertificates", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancerTlsCertificates",
    validator: validate_GetLoadBalancerTlsCertificates_21627080, base: "/",
    makeUrl: url_GetLoadBalancerTlsCertificates_21627081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancers_21627094 = ref object of OpenApiRestCall_21625435
proc url_GetLoadBalancers_21627096(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLoadBalancers_21627095(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627097 = header.getOrDefault("X-Amz-Date")
  valid_21627097 = validateParameter(valid_21627097, JString, required = false,
                                   default = nil)
  if valid_21627097 != nil:
    section.add "X-Amz-Date", valid_21627097
  var valid_21627098 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627098 = validateParameter(valid_21627098, JString, required = false,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "X-Amz-Security-Token", valid_21627098
  var valid_21627099 = header.getOrDefault("X-Amz-Target")
  valid_21627099 = validateParameter(valid_21627099, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancers"))
  if valid_21627099 != nil:
    section.add "X-Amz-Target", valid_21627099
  var valid_21627100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627100
  var valid_21627101 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-Algorithm", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Signature")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "X-Amz-Signature", valid_21627102
  var valid_21627103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-Credential")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-Credential", valid_21627104
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

proc call*(call_21627106: Call_GetLoadBalancers_21627094; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all load balancers in an account.
  ## 
  let valid = call_21627106.validator(path, query, header, formData, body, _)
  let scheme = call_21627106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627106.makeUrl(scheme.get, call_21627106.host, call_21627106.base,
                               call_21627106.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627106, uri, valid, _)

proc call*(call_21627107: Call_GetLoadBalancers_21627094; body: JsonNode): Recallable =
  ## getLoadBalancers
  ## Returns information about all load balancers in an account.
  ##   body: JObject (required)
  var body_21627108 = newJObject()
  if body != nil:
    body_21627108 = body
  result = call_21627107.call(nil, nil, nil, nil, body_21627108)

var getLoadBalancers* = Call_GetLoadBalancers_21627094(name: "getLoadBalancers",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancers",
    validator: validate_GetLoadBalancers_21627095, base: "/",
    makeUrl: url_GetLoadBalancers_21627096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperation_21627109 = ref object of OpenApiRestCall_21625435
proc url_GetOperation_21627111(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOperation_21627110(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
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
  var valid_21627112 = header.getOrDefault("X-Amz-Date")
  valid_21627112 = validateParameter(valid_21627112, JString, required = false,
                                   default = nil)
  if valid_21627112 != nil:
    section.add "X-Amz-Date", valid_21627112
  var valid_21627113 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627113 = validateParameter(valid_21627113, JString, required = false,
                                   default = nil)
  if valid_21627113 != nil:
    section.add "X-Amz-Security-Token", valid_21627113
  var valid_21627114 = header.getOrDefault("X-Amz-Target")
  valid_21627114 = validateParameter(valid_21627114, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperation"))
  if valid_21627114 != nil:
    section.add "X-Amz-Target", valid_21627114
  var valid_21627115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627115 = validateParameter(valid_21627115, JString, required = false,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Algorithm", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Signature")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Signature", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-Credential")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-Credential", valid_21627119
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

proc call*(call_21627121: Call_GetOperation_21627109; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
  ## 
  let valid = call_21627121.validator(path, query, header, formData, body, _)
  let scheme = call_21627121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627121.makeUrl(scheme.get, call_21627121.host, call_21627121.base,
                               call_21627121.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627121, uri, valid, _)

proc call*(call_21627122: Call_GetOperation_21627109; body: JsonNode): Recallable =
  ## getOperation
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
  ##   body: JObject (required)
  var body_21627123 = newJObject()
  if body != nil:
    body_21627123 = body
  result = call_21627122.call(nil, nil, nil, nil, body_21627123)

var getOperation* = Call_GetOperation_21627109(name: "getOperation",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperation",
    validator: validate_GetOperation_21627110, base: "/", makeUrl: url_GetOperation_21627111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperations_21627124 = ref object of OpenApiRestCall_21625435
proc url_GetOperations_21627126(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOperations_21627125(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
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
  var valid_21627127 = header.getOrDefault("X-Amz-Date")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "X-Amz-Date", valid_21627127
  var valid_21627128 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "X-Amz-Security-Token", valid_21627128
  var valid_21627129 = header.getOrDefault("X-Amz-Target")
  valid_21627129 = validateParameter(valid_21627129, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperations"))
  if valid_21627129 != nil:
    section.add "X-Amz-Target", valid_21627129
  var valid_21627130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627130 = validateParameter(valid_21627130, JString, required = false,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627130
  var valid_21627131 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "X-Amz-Algorithm", valid_21627131
  var valid_21627132 = header.getOrDefault("X-Amz-Signature")
  valid_21627132 = validateParameter(valid_21627132, JString, required = false,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "X-Amz-Signature", valid_21627132
  var valid_21627133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-Credential")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-Credential", valid_21627134
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

proc call*(call_21627136: Call_GetOperations_21627124; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
  ## 
  let valid = call_21627136.validator(path, query, header, formData, body, _)
  let scheme = call_21627136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627136.makeUrl(scheme.get, call_21627136.host, call_21627136.base,
                               call_21627136.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627136, uri, valid, _)

proc call*(call_21627137: Call_GetOperations_21627124; body: JsonNode): Recallable =
  ## getOperations
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
  ##   body: JObject (required)
  var body_21627138 = newJObject()
  if body != nil:
    body_21627138 = body
  result = call_21627137.call(nil, nil, nil, nil, body_21627138)

var getOperations* = Call_GetOperations_21627124(name: "getOperations",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperations",
    validator: validate_GetOperations_21627125, base: "/",
    makeUrl: url_GetOperations_21627126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperationsForResource_21627139 = ref object of OpenApiRestCall_21625435
proc url_GetOperationsForResource_21627141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOperationsForResource_21627140(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
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
  var valid_21627142 = header.getOrDefault("X-Amz-Date")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "X-Amz-Date", valid_21627142
  var valid_21627143 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "X-Amz-Security-Token", valid_21627143
  var valid_21627144 = header.getOrDefault("X-Amz-Target")
  valid_21627144 = validateParameter(valid_21627144, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperationsForResource"))
  if valid_21627144 != nil:
    section.add "X-Amz-Target", valid_21627144
  var valid_21627145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627145 = validateParameter(valid_21627145, JString, required = false,
                                   default = nil)
  if valid_21627145 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627145
  var valid_21627146 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627146 = validateParameter(valid_21627146, JString, required = false,
                                   default = nil)
  if valid_21627146 != nil:
    section.add "X-Amz-Algorithm", valid_21627146
  var valid_21627147 = header.getOrDefault("X-Amz-Signature")
  valid_21627147 = validateParameter(valid_21627147, JString, required = false,
                                   default = nil)
  if valid_21627147 != nil:
    section.add "X-Amz-Signature", valid_21627147
  var valid_21627148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627148 = validateParameter(valid_21627148, JString, required = false,
                                   default = nil)
  if valid_21627148 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627148
  var valid_21627149 = header.getOrDefault("X-Amz-Credential")
  valid_21627149 = validateParameter(valid_21627149, JString, required = false,
                                   default = nil)
  if valid_21627149 != nil:
    section.add "X-Amz-Credential", valid_21627149
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

proc call*(call_21627151: Call_GetOperationsForResource_21627139;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
  ## 
  let valid = call_21627151.validator(path, query, header, formData, body, _)
  let scheme = call_21627151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627151.makeUrl(scheme.get, call_21627151.host, call_21627151.base,
                               call_21627151.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627151, uri, valid, _)

proc call*(call_21627152: Call_GetOperationsForResource_21627139; body: JsonNode): Recallable =
  ## getOperationsForResource
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
  ##   body: JObject (required)
  var body_21627153 = newJObject()
  if body != nil:
    body_21627153 = body
  result = call_21627152.call(nil, nil, nil, nil, body_21627153)

var getOperationsForResource* = Call_GetOperationsForResource_21627139(
    name: "getOperationsForResource", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperationsForResource",
    validator: validate_GetOperationsForResource_21627140, base: "/",
    makeUrl: url_GetOperationsForResource_21627141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegions_21627154 = ref object of OpenApiRestCall_21625435
proc url_GetRegions_21627156(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRegions_21627155(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627157 = header.getOrDefault("X-Amz-Date")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "X-Amz-Date", valid_21627157
  var valid_21627158 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-Security-Token", valid_21627158
  var valid_21627159 = header.getOrDefault("X-Amz-Target")
  valid_21627159 = validateParameter(valid_21627159, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRegions"))
  if valid_21627159 != nil:
    section.add "X-Amz-Target", valid_21627159
  var valid_21627160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627160 = validateParameter(valid_21627160, JString, required = false,
                                   default = nil)
  if valid_21627160 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627160
  var valid_21627161 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627161 = validateParameter(valid_21627161, JString, required = false,
                                   default = nil)
  if valid_21627161 != nil:
    section.add "X-Amz-Algorithm", valid_21627161
  var valid_21627162 = header.getOrDefault("X-Amz-Signature")
  valid_21627162 = validateParameter(valid_21627162, JString, required = false,
                                   default = nil)
  if valid_21627162 != nil:
    section.add "X-Amz-Signature", valid_21627162
  var valid_21627163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627163 = validateParameter(valid_21627163, JString, required = false,
                                   default = nil)
  if valid_21627163 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627163
  var valid_21627164 = header.getOrDefault("X-Amz-Credential")
  valid_21627164 = validateParameter(valid_21627164, JString, required = false,
                                   default = nil)
  if valid_21627164 != nil:
    section.add "X-Amz-Credential", valid_21627164
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

proc call*(call_21627166: Call_GetRegions_21627154; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all valid regions for Amazon Lightsail. Use the <code>include availability zones</code> parameter to also return the Availability Zones in a region.
  ## 
  let valid = call_21627166.validator(path, query, header, formData, body, _)
  let scheme = call_21627166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627166.makeUrl(scheme.get, call_21627166.host, call_21627166.base,
                               call_21627166.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627166, uri, valid, _)

proc call*(call_21627167: Call_GetRegions_21627154; body: JsonNode): Recallable =
  ## getRegions
  ## Returns a list of all valid regions for Amazon Lightsail. Use the <code>include availability zones</code> parameter to also return the Availability Zones in a region.
  ##   body: JObject (required)
  var body_21627168 = newJObject()
  if body != nil:
    body_21627168 = body
  result = call_21627167.call(nil, nil, nil, nil, body_21627168)

var getRegions* = Call_GetRegions_21627154(name: "getRegions",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetRegions",
                                        validator: validate_GetRegions_21627155,
                                        base: "/", makeUrl: url_GetRegions_21627156,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabase_21627169 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabase_21627171(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabase_21627170(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627172 = header.getOrDefault("X-Amz-Date")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-Date", valid_21627172
  var valid_21627173 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Security-Token", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-Target")
  valid_21627174 = validateParameter(valid_21627174, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabase"))
  if valid_21627174 != nil:
    section.add "X-Amz-Target", valid_21627174
  var valid_21627175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627175 = validateParameter(valid_21627175, JString, required = false,
                                   default = nil)
  if valid_21627175 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627175
  var valid_21627176 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627176 = validateParameter(valid_21627176, JString, required = false,
                                   default = nil)
  if valid_21627176 != nil:
    section.add "X-Amz-Algorithm", valid_21627176
  var valid_21627177 = header.getOrDefault("X-Amz-Signature")
  valid_21627177 = validateParameter(valid_21627177, JString, required = false,
                                   default = nil)
  if valid_21627177 != nil:
    section.add "X-Amz-Signature", valid_21627177
  var valid_21627178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627178 = validateParameter(valid_21627178, JString, required = false,
                                   default = nil)
  if valid_21627178 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627178
  var valid_21627179 = header.getOrDefault("X-Amz-Credential")
  valid_21627179 = validateParameter(valid_21627179, JString, required = false,
                                   default = nil)
  if valid_21627179 != nil:
    section.add "X-Amz-Credential", valid_21627179
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

proc call*(call_21627181: Call_GetRelationalDatabase_21627169;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific database in Amazon Lightsail.
  ## 
  let valid = call_21627181.validator(path, query, header, formData, body, _)
  let scheme = call_21627181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627181.makeUrl(scheme.get, call_21627181.host, call_21627181.base,
                               call_21627181.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627181, uri, valid, _)

proc call*(call_21627182: Call_GetRelationalDatabase_21627169; body: JsonNode): Recallable =
  ## getRelationalDatabase
  ## Returns information about a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_21627183 = newJObject()
  if body != nil:
    body_21627183 = body
  result = call_21627182.call(nil, nil, nil, nil, body_21627183)

var getRelationalDatabase* = Call_GetRelationalDatabase_21627169(
    name: "getRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabase",
    validator: validate_GetRelationalDatabase_21627170, base: "/",
    makeUrl: url_GetRelationalDatabase_21627171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseBlueprints_21627184 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabaseBlueprints_21627186(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseBlueprints_21627185(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627187 = header.getOrDefault("X-Amz-Date")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-Date", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Security-Token", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-Target")
  valid_21627189 = validateParameter(valid_21627189, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseBlueprints"))
  if valid_21627189 != nil:
    section.add "X-Amz-Target", valid_21627189
  var valid_21627190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627190 = validateParameter(valid_21627190, JString, required = false,
                                   default = nil)
  if valid_21627190 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627190
  var valid_21627191 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627191 = validateParameter(valid_21627191, JString, required = false,
                                   default = nil)
  if valid_21627191 != nil:
    section.add "X-Amz-Algorithm", valid_21627191
  var valid_21627192 = header.getOrDefault("X-Amz-Signature")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-Signature", valid_21627192
  var valid_21627193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627193 = validateParameter(valid_21627193, JString, required = false,
                                   default = nil)
  if valid_21627193 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627193
  var valid_21627194 = header.getOrDefault("X-Amz-Credential")
  valid_21627194 = validateParameter(valid_21627194, JString, required = false,
                                   default = nil)
  if valid_21627194 != nil:
    section.add "X-Amz-Credential", valid_21627194
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

proc call*(call_21627196: Call_GetRelationalDatabaseBlueprints_21627184;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database.</p> <p>You can use a blueprint ID to create a new database that runs a specific database engine.</p>
  ## 
  let valid = call_21627196.validator(path, query, header, formData, body, _)
  let scheme = call_21627196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627196.makeUrl(scheme.get, call_21627196.host, call_21627196.base,
                               call_21627196.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627196, uri, valid, _)

proc call*(call_21627197: Call_GetRelationalDatabaseBlueprints_21627184;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseBlueprints
  ## <p>Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database.</p> <p>You can use a blueprint ID to create a new database that runs a specific database engine.</p>
  ##   body: JObject (required)
  var body_21627198 = newJObject()
  if body != nil:
    body_21627198 = body
  result = call_21627197.call(nil, nil, nil, nil, body_21627198)

var getRelationalDatabaseBlueprints* = Call_GetRelationalDatabaseBlueprints_21627184(
    name: "getRelationalDatabaseBlueprints", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseBlueprints",
    validator: validate_GetRelationalDatabaseBlueprints_21627185, base: "/",
    makeUrl: url_GetRelationalDatabaseBlueprints_21627186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseBundles_21627199 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabaseBundles_21627201(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseBundles_21627200(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627202 = header.getOrDefault("X-Amz-Date")
  valid_21627202 = validateParameter(valid_21627202, JString, required = false,
                                   default = nil)
  if valid_21627202 != nil:
    section.add "X-Amz-Date", valid_21627202
  var valid_21627203 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-Security-Token", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-Target")
  valid_21627204 = validateParameter(valid_21627204, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseBundles"))
  if valid_21627204 != nil:
    section.add "X-Amz-Target", valid_21627204
  var valid_21627205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627205 = validateParameter(valid_21627205, JString, required = false,
                                   default = nil)
  if valid_21627205 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627205
  var valid_21627206 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "X-Amz-Algorithm", valid_21627206
  var valid_21627207 = header.getOrDefault("X-Amz-Signature")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "X-Amz-Signature", valid_21627207
  var valid_21627208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627208 = validateParameter(valid_21627208, JString, required = false,
                                   default = nil)
  if valid_21627208 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627208
  var valid_21627209 = header.getOrDefault("X-Amz-Credential")
  valid_21627209 = validateParameter(valid_21627209, JString, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "X-Amz-Credential", valid_21627209
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

proc call*(call_21627211: Call_GetRelationalDatabaseBundles_21627199;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database.</p> <p>You can use a bundle ID to create a new database with explicit performance specifications.</p>
  ## 
  let valid = call_21627211.validator(path, query, header, formData, body, _)
  let scheme = call_21627211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627211.makeUrl(scheme.get, call_21627211.host, call_21627211.base,
                               call_21627211.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627211, uri, valid, _)

proc call*(call_21627212: Call_GetRelationalDatabaseBundles_21627199;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseBundles
  ## <p>Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database.</p> <p>You can use a bundle ID to create a new database with explicit performance specifications.</p>
  ##   body: JObject (required)
  var body_21627213 = newJObject()
  if body != nil:
    body_21627213 = body
  result = call_21627212.call(nil, nil, nil, nil, body_21627213)

var getRelationalDatabaseBundles* = Call_GetRelationalDatabaseBundles_21627199(
    name: "getRelationalDatabaseBundles", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseBundles",
    validator: validate_GetRelationalDatabaseBundles_21627200, base: "/",
    makeUrl: url_GetRelationalDatabaseBundles_21627201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseEvents_21627214 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabaseEvents_21627216(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseEvents_21627215(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of events for a specific database in Amazon Lightsail.
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
  var valid_21627217 = header.getOrDefault("X-Amz-Date")
  valid_21627217 = validateParameter(valid_21627217, JString, required = false,
                                   default = nil)
  if valid_21627217 != nil:
    section.add "X-Amz-Date", valid_21627217
  var valid_21627218 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627218 = validateParameter(valid_21627218, JString, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "X-Amz-Security-Token", valid_21627218
  var valid_21627219 = header.getOrDefault("X-Amz-Target")
  valid_21627219 = validateParameter(valid_21627219, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseEvents"))
  if valid_21627219 != nil:
    section.add "X-Amz-Target", valid_21627219
  var valid_21627220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627220 = validateParameter(valid_21627220, JString, required = false,
                                   default = nil)
  if valid_21627220 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627220
  var valid_21627221 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-Algorithm", valid_21627221
  var valid_21627222 = header.getOrDefault("X-Amz-Signature")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Signature", valid_21627222
  var valid_21627223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627223 = validateParameter(valid_21627223, JString, required = false,
                                   default = nil)
  if valid_21627223 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627223
  var valid_21627224 = header.getOrDefault("X-Amz-Credential")
  valid_21627224 = validateParameter(valid_21627224, JString, required = false,
                                   default = nil)
  if valid_21627224 != nil:
    section.add "X-Amz-Credential", valid_21627224
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

proc call*(call_21627226: Call_GetRelationalDatabaseEvents_21627214;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of events for a specific database in Amazon Lightsail.
  ## 
  let valid = call_21627226.validator(path, query, header, formData, body, _)
  let scheme = call_21627226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627226.makeUrl(scheme.get, call_21627226.host, call_21627226.base,
                               call_21627226.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627226, uri, valid, _)

proc call*(call_21627227: Call_GetRelationalDatabaseEvents_21627214; body: JsonNode): Recallable =
  ## getRelationalDatabaseEvents
  ## Returns a list of events for a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_21627228 = newJObject()
  if body != nil:
    body_21627228 = body
  result = call_21627227.call(nil, nil, nil, nil, body_21627228)

var getRelationalDatabaseEvents* = Call_GetRelationalDatabaseEvents_21627214(
    name: "getRelationalDatabaseEvents", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseEvents",
    validator: validate_GetRelationalDatabaseEvents_21627215, base: "/",
    makeUrl: url_GetRelationalDatabaseEvents_21627216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseLogEvents_21627229 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabaseLogEvents_21627231(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseLogEvents_21627230(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627232 = header.getOrDefault("X-Amz-Date")
  valid_21627232 = validateParameter(valid_21627232, JString, required = false,
                                   default = nil)
  if valid_21627232 != nil:
    section.add "X-Amz-Date", valid_21627232
  var valid_21627233 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627233 = validateParameter(valid_21627233, JString, required = false,
                                   default = nil)
  if valid_21627233 != nil:
    section.add "X-Amz-Security-Token", valid_21627233
  var valid_21627234 = header.getOrDefault("X-Amz-Target")
  valid_21627234 = validateParameter(valid_21627234, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseLogEvents"))
  if valid_21627234 != nil:
    section.add "X-Amz-Target", valid_21627234
  var valid_21627235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627235 = validateParameter(valid_21627235, JString, required = false,
                                   default = nil)
  if valid_21627235 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627235
  var valid_21627236 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "X-Amz-Algorithm", valid_21627236
  var valid_21627237 = header.getOrDefault("X-Amz-Signature")
  valid_21627237 = validateParameter(valid_21627237, JString, required = false,
                                   default = nil)
  if valid_21627237 != nil:
    section.add "X-Amz-Signature", valid_21627237
  var valid_21627238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627238 = validateParameter(valid_21627238, JString, required = false,
                                   default = nil)
  if valid_21627238 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627238
  var valid_21627239 = header.getOrDefault("X-Amz-Credential")
  valid_21627239 = validateParameter(valid_21627239, JString, required = false,
                                   default = nil)
  if valid_21627239 != nil:
    section.add "X-Amz-Credential", valid_21627239
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

proc call*(call_21627241: Call_GetRelationalDatabaseLogEvents_21627229;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of log events for a database in Amazon Lightsail.
  ## 
  let valid = call_21627241.validator(path, query, header, formData, body, _)
  let scheme = call_21627241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627241.makeUrl(scheme.get, call_21627241.host, call_21627241.base,
                               call_21627241.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627241, uri, valid, _)

proc call*(call_21627242: Call_GetRelationalDatabaseLogEvents_21627229;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseLogEvents
  ## Returns a list of log events for a database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_21627243 = newJObject()
  if body != nil:
    body_21627243 = body
  result = call_21627242.call(nil, nil, nil, nil, body_21627243)

var getRelationalDatabaseLogEvents* = Call_GetRelationalDatabaseLogEvents_21627229(
    name: "getRelationalDatabaseLogEvents", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseLogEvents",
    validator: validate_GetRelationalDatabaseLogEvents_21627230, base: "/",
    makeUrl: url_GetRelationalDatabaseLogEvents_21627231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseLogStreams_21627244 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabaseLogStreams_21627246(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseLogStreams_21627245(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627247 = header.getOrDefault("X-Amz-Date")
  valid_21627247 = validateParameter(valid_21627247, JString, required = false,
                                   default = nil)
  if valid_21627247 != nil:
    section.add "X-Amz-Date", valid_21627247
  var valid_21627248 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627248 = validateParameter(valid_21627248, JString, required = false,
                                   default = nil)
  if valid_21627248 != nil:
    section.add "X-Amz-Security-Token", valid_21627248
  var valid_21627249 = header.getOrDefault("X-Amz-Target")
  valid_21627249 = validateParameter(valid_21627249, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseLogStreams"))
  if valid_21627249 != nil:
    section.add "X-Amz-Target", valid_21627249
  var valid_21627250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627250 = validateParameter(valid_21627250, JString, required = false,
                                   default = nil)
  if valid_21627250 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627250
  var valid_21627251 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627251 = validateParameter(valid_21627251, JString, required = false,
                                   default = nil)
  if valid_21627251 != nil:
    section.add "X-Amz-Algorithm", valid_21627251
  var valid_21627252 = header.getOrDefault("X-Amz-Signature")
  valid_21627252 = validateParameter(valid_21627252, JString, required = false,
                                   default = nil)
  if valid_21627252 != nil:
    section.add "X-Amz-Signature", valid_21627252
  var valid_21627253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627253 = validateParameter(valid_21627253, JString, required = false,
                                   default = nil)
  if valid_21627253 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627253
  var valid_21627254 = header.getOrDefault("X-Amz-Credential")
  valid_21627254 = validateParameter(valid_21627254, JString, required = false,
                                   default = nil)
  if valid_21627254 != nil:
    section.add "X-Amz-Credential", valid_21627254
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

proc call*(call_21627256: Call_GetRelationalDatabaseLogStreams_21627244;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of available log streams for a specific database in Amazon Lightsail.
  ## 
  let valid = call_21627256.validator(path, query, header, formData, body, _)
  let scheme = call_21627256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627256.makeUrl(scheme.get, call_21627256.host, call_21627256.base,
                               call_21627256.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627256, uri, valid, _)

proc call*(call_21627257: Call_GetRelationalDatabaseLogStreams_21627244;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseLogStreams
  ## Returns a list of available log streams for a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_21627258 = newJObject()
  if body != nil:
    body_21627258 = body
  result = call_21627257.call(nil, nil, nil, nil, body_21627258)

var getRelationalDatabaseLogStreams* = Call_GetRelationalDatabaseLogStreams_21627244(
    name: "getRelationalDatabaseLogStreams", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseLogStreams",
    validator: validate_GetRelationalDatabaseLogStreams_21627245, base: "/",
    makeUrl: url_GetRelationalDatabaseLogStreams_21627246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseMasterUserPassword_21627259 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabaseMasterUserPassword_21627261(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseMasterUserPassword_21627260(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627262 = header.getOrDefault("X-Amz-Date")
  valid_21627262 = validateParameter(valid_21627262, JString, required = false,
                                   default = nil)
  if valid_21627262 != nil:
    section.add "X-Amz-Date", valid_21627262
  var valid_21627263 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627263 = validateParameter(valid_21627263, JString, required = false,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "X-Amz-Security-Token", valid_21627263
  var valid_21627264 = header.getOrDefault("X-Amz-Target")
  valid_21627264 = validateParameter(valid_21627264, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseMasterUserPassword"))
  if valid_21627264 != nil:
    section.add "X-Amz-Target", valid_21627264
  var valid_21627265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627265 = validateParameter(valid_21627265, JString, required = false,
                                   default = nil)
  if valid_21627265 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627265
  var valid_21627266 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627266 = validateParameter(valid_21627266, JString, required = false,
                                   default = nil)
  if valid_21627266 != nil:
    section.add "X-Amz-Algorithm", valid_21627266
  var valid_21627267 = header.getOrDefault("X-Amz-Signature")
  valid_21627267 = validateParameter(valid_21627267, JString, required = false,
                                   default = nil)
  if valid_21627267 != nil:
    section.add "X-Amz-Signature", valid_21627267
  var valid_21627268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627268 = validateParameter(valid_21627268, JString, required = false,
                                   default = nil)
  if valid_21627268 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627268
  var valid_21627269 = header.getOrDefault("X-Amz-Credential")
  valid_21627269 = validateParameter(valid_21627269, JString, required = false,
                                   default = nil)
  if valid_21627269 != nil:
    section.add "X-Amz-Credential", valid_21627269
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

proc call*(call_21627271: Call_GetRelationalDatabaseMasterUserPassword_21627259;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the current, previous, or pending versions of the master user password for a Lightsail database.</p> <p>The <code>GetRelationalDatabaseMasterUserPassword</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.</p>
  ## 
  let valid = call_21627271.validator(path, query, header, formData, body, _)
  let scheme = call_21627271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627271.makeUrl(scheme.get, call_21627271.host, call_21627271.base,
                               call_21627271.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627271, uri, valid, _)

proc call*(call_21627272: Call_GetRelationalDatabaseMasterUserPassword_21627259;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseMasterUserPassword
  ## <p>Returns the current, previous, or pending versions of the master user password for a Lightsail database.</p> <p>The <code>GetRelationalDatabaseMasterUserPassword</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.</p>
  ##   body: JObject (required)
  var body_21627273 = newJObject()
  if body != nil:
    body_21627273 = body
  result = call_21627272.call(nil, nil, nil, nil, body_21627273)

var getRelationalDatabaseMasterUserPassword* = Call_GetRelationalDatabaseMasterUserPassword_21627259(
    name: "getRelationalDatabaseMasterUserPassword", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseMasterUserPassword",
    validator: validate_GetRelationalDatabaseMasterUserPassword_21627260,
    base: "/", makeUrl: url_GetRelationalDatabaseMasterUserPassword_21627261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseMetricData_21627274 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabaseMetricData_21627276(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseMetricData_21627275(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627277 = header.getOrDefault("X-Amz-Date")
  valid_21627277 = validateParameter(valid_21627277, JString, required = false,
                                   default = nil)
  if valid_21627277 != nil:
    section.add "X-Amz-Date", valid_21627277
  var valid_21627278 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "X-Amz-Security-Token", valid_21627278
  var valid_21627279 = header.getOrDefault("X-Amz-Target")
  valid_21627279 = validateParameter(valid_21627279, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseMetricData"))
  if valid_21627279 != nil:
    section.add "X-Amz-Target", valid_21627279
  var valid_21627280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627280 = validateParameter(valid_21627280, JString, required = false,
                                   default = nil)
  if valid_21627280 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627280
  var valid_21627281 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627281 = validateParameter(valid_21627281, JString, required = false,
                                   default = nil)
  if valid_21627281 != nil:
    section.add "X-Amz-Algorithm", valid_21627281
  var valid_21627282 = header.getOrDefault("X-Amz-Signature")
  valid_21627282 = validateParameter(valid_21627282, JString, required = false,
                                   default = nil)
  if valid_21627282 != nil:
    section.add "X-Amz-Signature", valid_21627282
  var valid_21627283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627283 = validateParameter(valid_21627283, JString, required = false,
                                   default = nil)
  if valid_21627283 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627283
  var valid_21627284 = header.getOrDefault("X-Amz-Credential")
  valid_21627284 = validateParameter(valid_21627284, JString, required = false,
                                   default = nil)
  if valid_21627284 != nil:
    section.add "X-Amz-Credential", valid_21627284
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

proc call*(call_21627286: Call_GetRelationalDatabaseMetricData_21627274;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the data points of the specified metric for a database in Amazon Lightsail.
  ## 
  let valid = call_21627286.validator(path, query, header, formData, body, _)
  let scheme = call_21627286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627286.makeUrl(scheme.get, call_21627286.host, call_21627286.base,
                               call_21627286.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627286, uri, valid, _)

proc call*(call_21627287: Call_GetRelationalDatabaseMetricData_21627274;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseMetricData
  ## Returns the data points of the specified metric for a database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_21627288 = newJObject()
  if body != nil:
    body_21627288 = body
  result = call_21627287.call(nil, nil, nil, nil, body_21627288)

var getRelationalDatabaseMetricData* = Call_GetRelationalDatabaseMetricData_21627274(
    name: "getRelationalDatabaseMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseMetricData",
    validator: validate_GetRelationalDatabaseMetricData_21627275, base: "/",
    makeUrl: url_GetRelationalDatabaseMetricData_21627276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseParameters_21627289 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabaseParameters_21627291(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseParameters_21627290(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627292 = header.getOrDefault("X-Amz-Date")
  valid_21627292 = validateParameter(valid_21627292, JString, required = false,
                                   default = nil)
  if valid_21627292 != nil:
    section.add "X-Amz-Date", valid_21627292
  var valid_21627293 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627293 = validateParameter(valid_21627293, JString, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "X-Amz-Security-Token", valid_21627293
  var valid_21627294 = header.getOrDefault("X-Amz-Target")
  valid_21627294 = validateParameter(valid_21627294, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseParameters"))
  if valid_21627294 != nil:
    section.add "X-Amz-Target", valid_21627294
  var valid_21627295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627295 = validateParameter(valid_21627295, JString, required = false,
                                   default = nil)
  if valid_21627295 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627295
  var valid_21627296 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627296 = validateParameter(valid_21627296, JString, required = false,
                                   default = nil)
  if valid_21627296 != nil:
    section.add "X-Amz-Algorithm", valid_21627296
  var valid_21627297 = header.getOrDefault("X-Amz-Signature")
  valid_21627297 = validateParameter(valid_21627297, JString, required = false,
                                   default = nil)
  if valid_21627297 != nil:
    section.add "X-Amz-Signature", valid_21627297
  var valid_21627298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627298 = validateParameter(valid_21627298, JString, required = false,
                                   default = nil)
  if valid_21627298 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627298
  var valid_21627299 = header.getOrDefault("X-Amz-Credential")
  valid_21627299 = validateParameter(valid_21627299, JString, required = false,
                                   default = nil)
  if valid_21627299 != nil:
    section.add "X-Amz-Credential", valid_21627299
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

proc call*(call_21627301: Call_GetRelationalDatabaseParameters_21627289;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail.</p> <p>In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.</p>
  ## 
  let valid = call_21627301.validator(path, query, header, formData, body, _)
  let scheme = call_21627301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627301.makeUrl(scheme.get, call_21627301.host, call_21627301.base,
                               call_21627301.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627301, uri, valid, _)

proc call*(call_21627302: Call_GetRelationalDatabaseParameters_21627289;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseParameters
  ## <p>Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail.</p> <p>In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.</p>
  ##   body: JObject (required)
  var body_21627303 = newJObject()
  if body != nil:
    body_21627303 = body
  result = call_21627302.call(nil, nil, nil, nil, body_21627303)

var getRelationalDatabaseParameters* = Call_GetRelationalDatabaseParameters_21627289(
    name: "getRelationalDatabaseParameters", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseParameters",
    validator: validate_GetRelationalDatabaseParameters_21627290, base: "/",
    makeUrl: url_GetRelationalDatabaseParameters_21627291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseSnapshot_21627304 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabaseSnapshot_21627306(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseSnapshot_21627305(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627307 = header.getOrDefault("X-Amz-Date")
  valid_21627307 = validateParameter(valid_21627307, JString, required = false,
                                   default = nil)
  if valid_21627307 != nil:
    section.add "X-Amz-Date", valid_21627307
  var valid_21627308 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "X-Amz-Security-Token", valid_21627308
  var valid_21627309 = header.getOrDefault("X-Amz-Target")
  valid_21627309 = validateParameter(valid_21627309, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseSnapshot"))
  if valid_21627309 != nil:
    section.add "X-Amz-Target", valid_21627309
  var valid_21627310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627310 = validateParameter(valid_21627310, JString, required = false,
                                   default = nil)
  if valid_21627310 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627310
  var valid_21627311 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627311 = validateParameter(valid_21627311, JString, required = false,
                                   default = nil)
  if valid_21627311 != nil:
    section.add "X-Amz-Algorithm", valid_21627311
  var valid_21627312 = header.getOrDefault("X-Amz-Signature")
  valid_21627312 = validateParameter(valid_21627312, JString, required = false,
                                   default = nil)
  if valid_21627312 != nil:
    section.add "X-Amz-Signature", valid_21627312
  var valid_21627313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627313 = validateParameter(valid_21627313, JString, required = false,
                                   default = nil)
  if valid_21627313 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627313
  var valid_21627314 = header.getOrDefault("X-Amz-Credential")
  valid_21627314 = validateParameter(valid_21627314, JString, required = false,
                                   default = nil)
  if valid_21627314 != nil:
    section.add "X-Amz-Credential", valid_21627314
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

proc call*(call_21627316: Call_GetRelationalDatabaseSnapshot_21627304;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific database snapshot in Amazon Lightsail.
  ## 
  let valid = call_21627316.validator(path, query, header, formData, body, _)
  let scheme = call_21627316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627316.makeUrl(scheme.get, call_21627316.host, call_21627316.base,
                               call_21627316.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627316, uri, valid, _)

proc call*(call_21627317: Call_GetRelationalDatabaseSnapshot_21627304;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseSnapshot
  ## Returns information about a specific database snapshot in Amazon Lightsail.
  ##   body: JObject (required)
  var body_21627318 = newJObject()
  if body != nil:
    body_21627318 = body
  result = call_21627317.call(nil, nil, nil, nil, body_21627318)

var getRelationalDatabaseSnapshot* = Call_GetRelationalDatabaseSnapshot_21627304(
    name: "getRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseSnapshot",
    validator: validate_GetRelationalDatabaseSnapshot_21627305, base: "/",
    makeUrl: url_GetRelationalDatabaseSnapshot_21627306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseSnapshots_21627319 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabaseSnapshots_21627321(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabaseSnapshots_21627320(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627322 = header.getOrDefault("X-Amz-Date")
  valid_21627322 = validateParameter(valid_21627322, JString, required = false,
                                   default = nil)
  if valid_21627322 != nil:
    section.add "X-Amz-Date", valid_21627322
  var valid_21627323 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627323 = validateParameter(valid_21627323, JString, required = false,
                                   default = nil)
  if valid_21627323 != nil:
    section.add "X-Amz-Security-Token", valid_21627323
  var valid_21627324 = header.getOrDefault("X-Amz-Target")
  valid_21627324 = validateParameter(valid_21627324, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseSnapshots"))
  if valid_21627324 != nil:
    section.add "X-Amz-Target", valid_21627324
  var valid_21627325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627325 = validateParameter(valid_21627325, JString, required = false,
                                   default = nil)
  if valid_21627325 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627325
  var valid_21627326 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627326 = validateParameter(valid_21627326, JString, required = false,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "X-Amz-Algorithm", valid_21627326
  var valid_21627327 = header.getOrDefault("X-Amz-Signature")
  valid_21627327 = validateParameter(valid_21627327, JString, required = false,
                                   default = nil)
  if valid_21627327 != nil:
    section.add "X-Amz-Signature", valid_21627327
  var valid_21627328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627328 = validateParameter(valid_21627328, JString, required = false,
                                   default = nil)
  if valid_21627328 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627328
  var valid_21627329 = header.getOrDefault("X-Amz-Credential")
  valid_21627329 = validateParameter(valid_21627329, JString, required = false,
                                   default = nil)
  if valid_21627329 != nil:
    section.add "X-Amz-Credential", valid_21627329
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

proc call*(call_21627331: Call_GetRelationalDatabaseSnapshots_21627319;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all of your database snapshots in Amazon Lightsail.
  ## 
  let valid = call_21627331.validator(path, query, header, formData, body, _)
  let scheme = call_21627331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627331.makeUrl(scheme.get, call_21627331.host, call_21627331.base,
                               call_21627331.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627331, uri, valid, _)

proc call*(call_21627332: Call_GetRelationalDatabaseSnapshots_21627319;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseSnapshots
  ## Returns information about all of your database snapshots in Amazon Lightsail.
  ##   body: JObject (required)
  var body_21627333 = newJObject()
  if body != nil:
    body_21627333 = body
  result = call_21627332.call(nil, nil, nil, nil, body_21627333)

var getRelationalDatabaseSnapshots* = Call_GetRelationalDatabaseSnapshots_21627319(
    name: "getRelationalDatabaseSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseSnapshots",
    validator: validate_GetRelationalDatabaseSnapshots_21627320, base: "/",
    makeUrl: url_GetRelationalDatabaseSnapshots_21627321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabases_21627334 = ref object of OpenApiRestCall_21625435
proc url_GetRelationalDatabases_21627336(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRelationalDatabases_21627335(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627337 = header.getOrDefault("X-Amz-Date")
  valid_21627337 = validateParameter(valid_21627337, JString, required = false,
                                   default = nil)
  if valid_21627337 != nil:
    section.add "X-Amz-Date", valid_21627337
  var valid_21627338 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627338 = validateParameter(valid_21627338, JString, required = false,
                                   default = nil)
  if valid_21627338 != nil:
    section.add "X-Amz-Security-Token", valid_21627338
  var valid_21627339 = header.getOrDefault("X-Amz-Target")
  valid_21627339 = validateParameter(valid_21627339, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabases"))
  if valid_21627339 != nil:
    section.add "X-Amz-Target", valid_21627339
  var valid_21627340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627340 = validateParameter(valid_21627340, JString, required = false,
                                   default = nil)
  if valid_21627340 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627340
  var valid_21627341 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627341 = validateParameter(valid_21627341, JString, required = false,
                                   default = nil)
  if valid_21627341 != nil:
    section.add "X-Amz-Algorithm", valid_21627341
  var valid_21627342 = header.getOrDefault("X-Amz-Signature")
  valid_21627342 = validateParameter(valid_21627342, JString, required = false,
                                   default = nil)
  if valid_21627342 != nil:
    section.add "X-Amz-Signature", valid_21627342
  var valid_21627343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627343 = validateParameter(valid_21627343, JString, required = false,
                                   default = nil)
  if valid_21627343 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627343
  var valid_21627344 = header.getOrDefault("X-Amz-Credential")
  valid_21627344 = validateParameter(valid_21627344, JString, required = false,
                                   default = nil)
  if valid_21627344 != nil:
    section.add "X-Amz-Credential", valid_21627344
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

proc call*(call_21627346: Call_GetRelationalDatabases_21627334;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all of your databases in Amazon Lightsail.
  ## 
  let valid = call_21627346.validator(path, query, header, formData, body, _)
  let scheme = call_21627346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627346.makeUrl(scheme.get, call_21627346.host, call_21627346.base,
                               call_21627346.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627346, uri, valid, _)

proc call*(call_21627347: Call_GetRelationalDatabases_21627334; body: JsonNode): Recallable =
  ## getRelationalDatabases
  ## Returns information about all of your databases in Amazon Lightsail.
  ##   body: JObject (required)
  var body_21627348 = newJObject()
  if body != nil:
    body_21627348 = body
  result = call_21627347.call(nil, nil, nil, nil, body_21627348)

var getRelationalDatabases* = Call_GetRelationalDatabases_21627334(
    name: "getRelationalDatabases", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabases",
    validator: validate_GetRelationalDatabases_21627335, base: "/",
    makeUrl: url_GetRelationalDatabases_21627336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStaticIp_21627349 = ref object of OpenApiRestCall_21625435
proc url_GetStaticIp_21627351(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStaticIp_21627350(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627352 = header.getOrDefault("X-Amz-Date")
  valid_21627352 = validateParameter(valid_21627352, JString, required = false,
                                   default = nil)
  if valid_21627352 != nil:
    section.add "X-Amz-Date", valid_21627352
  var valid_21627353 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627353 = validateParameter(valid_21627353, JString, required = false,
                                   default = nil)
  if valid_21627353 != nil:
    section.add "X-Amz-Security-Token", valid_21627353
  var valid_21627354 = header.getOrDefault("X-Amz-Target")
  valid_21627354 = validateParameter(valid_21627354, JString, required = true, default = newJString(
      "Lightsail_20161128.GetStaticIp"))
  if valid_21627354 != nil:
    section.add "X-Amz-Target", valid_21627354
  var valid_21627355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627355 = validateParameter(valid_21627355, JString, required = false,
                                   default = nil)
  if valid_21627355 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627355
  var valid_21627356 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627356 = validateParameter(valid_21627356, JString, required = false,
                                   default = nil)
  if valid_21627356 != nil:
    section.add "X-Amz-Algorithm", valid_21627356
  var valid_21627357 = header.getOrDefault("X-Amz-Signature")
  valid_21627357 = validateParameter(valid_21627357, JString, required = false,
                                   default = nil)
  if valid_21627357 != nil:
    section.add "X-Amz-Signature", valid_21627357
  var valid_21627358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627358 = validateParameter(valid_21627358, JString, required = false,
                                   default = nil)
  if valid_21627358 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627358
  var valid_21627359 = header.getOrDefault("X-Amz-Credential")
  valid_21627359 = validateParameter(valid_21627359, JString, required = false,
                                   default = nil)
  if valid_21627359 != nil:
    section.add "X-Amz-Credential", valid_21627359
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

proc call*(call_21627361: Call_GetStaticIp_21627349; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specific static IP.
  ## 
  let valid = call_21627361.validator(path, query, header, formData, body, _)
  let scheme = call_21627361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627361.makeUrl(scheme.get, call_21627361.host, call_21627361.base,
                               call_21627361.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627361, uri, valid, _)

proc call*(call_21627362: Call_GetStaticIp_21627349; body: JsonNode): Recallable =
  ## getStaticIp
  ## Returns information about a specific static IP.
  ##   body: JObject (required)
  var body_21627363 = newJObject()
  if body != nil:
    body_21627363 = body
  result = call_21627362.call(nil, nil, nil, nil, body_21627363)

var getStaticIp* = Call_GetStaticIp_21627349(name: "getStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetStaticIp",
    validator: validate_GetStaticIp_21627350, base: "/", makeUrl: url_GetStaticIp_21627351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStaticIps_21627364 = ref object of OpenApiRestCall_21625435
proc url_GetStaticIps_21627366(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStaticIps_21627365(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about all static IPs in the user's account.
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
  var valid_21627367 = header.getOrDefault("X-Amz-Date")
  valid_21627367 = validateParameter(valid_21627367, JString, required = false,
                                   default = nil)
  if valid_21627367 != nil:
    section.add "X-Amz-Date", valid_21627367
  var valid_21627368 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627368 = validateParameter(valid_21627368, JString, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "X-Amz-Security-Token", valid_21627368
  var valid_21627369 = header.getOrDefault("X-Amz-Target")
  valid_21627369 = validateParameter(valid_21627369, JString, required = true, default = newJString(
      "Lightsail_20161128.GetStaticIps"))
  if valid_21627369 != nil:
    section.add "X-Amz-Target", valid_21627369
  var valid_21627370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627370 = validateParameter(valid_21627370, JString, required = false,
                                   default = nil)
  if valid_21627370 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627370
  var valid_21627371 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "X-Amz-Algorithm", valid_21627371
  var valid_21627372 = header.getOrDefault("X-Amz-Signature")
  valid_21627372 = validateParameter(valid_21627372, JString, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "X-Amz-Signature", valid_21627372
  var valid_21627373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627373 = validateParameter(valid_21627373, JString, required = false,
                                   default = nil)
  if valid_21627373 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627373
  var valid_21627374 = header.getOrDefault("X-Amz-Credential")
  valid_21627374 = validateParameter(valid_21627374, JString, required = false,
                                   default = nil)
  if valid_21627374 != nil:
    section.add "X-Amz-Credential", valid_21627374
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

proc call*(call_21627376: Call_GetStaticIps_21627364; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about all static IPs in the user's account.
  ## 
  let valid = call_21627376.validator(path, query, header, formData, body, _)
  let scheme = call_21627376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627376.makeUrl(scheme.get, call_21627376.host, call_21627376.base,
                               call_21627376.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627376, uri, valid, _)

proc call*(call_21627377: Call_GetStaticIps_21627364; body: JsonNode): Recallable =
  ## getStaticIps
  ## Returns information about all static IPs in the user's account.
  ##   body: JObject (required)
  var body_21627378 = newJObject()
  if body != nil:
    body_21627378 = body
  result = call_21627377.call(nil, nil, nil, nil, body_21627378)

var getStaticIps* = Call_GetStaticIps_21627364(name: "getStaticIps",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetStaticIps",
    validator: validate_GetStaticIps_21627365, base: "/", makeUrl: url_GetStaticIps_21627366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportKeyPair_21627379 = ref object of OpenApiRestCall_21625435
proc url_ImportKeyPair_21627381(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportKeyPair_21627380(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Imports a public SSH key from a specific key pair.
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
  var valid_21627382 = header.getOrDefault("X-Amz-Date")
  valid_21627382 = validateParameter(valid_21627382, JString, required = false,
                                   default = nil)
  if valid_21627382 != nil:
    section.add "X-Amz-Date", valid_21627382
  var valid_21627383 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627383 = validateParameter(valid_21627383, JString, required = false,
                                   default = nil)
  if valid_21627383 != nil:
    section.add "X-Amz-Security-Token", valid_21627383
  var valid_21627384 = header.getOrDefault("X-Amz-Target")
  valid_21627384 = validateParameter(valid_21627384, JString, required = true, default = newJString(
      "Lightsail_20161128.ImportKeyPair"))
  if valid_21627384 != nil:
    section.add "X-Amz-Target", valid_21627384
  var valid_21627385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627385 = validateParameter(valid_21627385, JString, required = false,
                                   default = nil)
  if valid_21627385 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627385
  var valid_21627386 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627386 = validateParameter(valid_21627386, JString, required = false,
                                   default = nil)
  if valid_21627386 != nil:
    section.add "X-Amz-Algorithm", valid_21627386
  var valid_21627387 = header.getOrDefault("X-Amz-Signature")
  valid_21627387 = validateParameter(valid_21627387, JString, required = false,
                                   default = nil)
  if valid_21627387 != nil:
    section.add "X-Amz-Signature", valid_21627387
  var valid_21627388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627388 = validateParameter(valid_21627388, JString, required = false,
                                   default = nil)
  if valid_21627388 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627388
  var valid_21627389 = header.getOrDefault("X-Amz-Credential")
  valid_21627389 = validateParameter(valid_21627389, JString, required = false,
                                   default = nil)
  if valid_21627389 != nil:
    section.add "X-Amz-Credential", valid_21627389
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

proc call*(call_21627391: Call_ImportKeyPair_21627379; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Imports a public SSH key from a specific key pair.
  ## 
  let valid = call_21627391.validator(path, query, header, formData, body, _)
  let scheme = call_21627391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627391.makeUrl(scheme.get, call_21627391.host, call_21627391.base,
                               call_21627391.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627391, uri, valid, _)

proc call*(call_21627392: Call_ImportKeyPair_21627379; body: JsonNode): Recallable =
  ## importKeyPair
  ## Imports a public SSH key from a specific key pair.
  ##   body: JObject (required)
  var body_21627393 = newJObject()
  if body != nil:
    body_21627393 = body
  result = call_21627392.call(nil, nil, nil, nil, body_21627393)

var importKeyPair* = Call_ImportKeyPair_21627379(name: "importKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ImportKeyPair",
    validator: validate_ImportKeyPair_21627380, base: "/",
    makeUrl: url_ImportKeyPair_21627381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_IsVpcPeered_21627394 = ref object of OpenApiRestCall_21625435
proc url_IsVpcPeered_21627396(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_IsVpcPeered_21627395(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627397 = header.getOrDefault("X-Amz-Date")
  valid_21627397 = validateParameter(valid_21627397, JString, required = false,
                                   default = nil)
  if valid_21627397 != nil:
    section.add "X-Amz-Date", valid_21627397
  var valid_21627398 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627398 = validateParameter(valid_21627398, JString, required = false,
                                   default = nil)
  if valid_21627398 != nil:
    section.add "X-Amz-Security-Token", valid_21627398
  var valid_21627399 = header.getOrDefault("X-Amz-Target")
  valid_21627399 = validateParameter(valid_21627399, JString, required = true, default = newJString(
      "Lightsail_20161128.IsVpcPeered"))
  if valid_21627399 != nil:
    section.add "X-Amz-Target", valid_21627399
  var valid_21627400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627400 = validateParameter(valid_21627400, JString, required = false,
                                   default = nil)
  if valid_21627400 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627400
  var valid_21627401 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627401 = validateParameter(valid_21627401, JString, required = false,
                                   default = nil)
  if valid_21627401 != nil:
    section.add "X-Amz-Algorithm", valid_21627401
  var valid_21627402 = header.getOrDefault("X-Amz-Signature")
  valid_21627402 = validateParameter(valid_21627402, JString, required = false,
                                   default = nil)
  if valid_21627402 != nil:
    section.add "X-Amz-Signature", valid_21627402
  var valid_21627403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627403 = validateParameter(valid_21627403, JString, required = false,
                                   default = nil)
  if valid_21627403 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627403
  var valid_21627404 = header.getOrDefault("X-Amz-Credential")
  valid_21627404 = validateParameter(valid_21627404, JString, required = false,
                                   default = nil)
  if valid_21627404 != nil:
    section.add "X-Amz-Credential", valid_21627404
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

proc call*(call_21627406: Call_IsVpcPeered_21627394; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a Boolean value indicating whether your Lightsail VPC is peered.
  ## 
  let valid = call_21627406.validator(path, query, header, formData, body, _)
  let scheme = call_21627406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627406.makeUrl(scheme.get, call_21627406.host, call_21627406.base,
                               call_21627406.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627406, uri, valid, _)

proc call*(call_21627407: Call_IsVpcPeered_21627394; body: JsonNode): Recallable =
  ## isVpcPeered
  ## Returns a Boolean value indicating whether your Lightsail VPC is peered.
  ##   body: JObject (required)
  var body_21627408 = newJObject()
  if body != nil:
    body_21627408 = body
  result = call_21627407.call(nil, nil, nil, nil, body_21627408)

var isVpcPeered* = Call_IsVpcPeered_21627394(name: "isVpcPeered",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.IsVpcPeered",
    validator: validate_IsVpcPeered_21627395, base: "/", makeUrl: url_IsVpcPeered_21627396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_OpenInstancePublicPorts_21627409 = ref object of OpenApiRestCall_21625435
proc url_OpenInstancePublicPorts_21627411(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_OpenInstancePublicPorts_21627410(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627412 = header.getOrDefault("X-Amz-Date")
  valid_21627412 = validateParameter(valid_21627412, JString, required = false,
                                   default = nil)
  if valid_21627412 != nil:
    section.add "X-Amz-Date", valid_21627412
  var valid_21627413 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627413 = validateParameter(valid_21627413, JString, required = false,
                                   default = nil)
  if valid_21627413 != nil:
    section.add "X-Amz-Security-Token", valid_21627413
  var valid_21627414 = header.getOrDefault("X-Amz-Target")
  valid_21627414 = validateParameter(valid_21627414, JString, required = true, default = newJString(
      "Lightsail_20161128.OpenInstancePublicPorts"))
  if valid_21627414 != nil:
    section.add "X-Amz-Target", valid_21627414
  var valid_21627415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627415 = validateParameter(valid_21627415, JString, required = false,
                                   default = nil)
  if valid_21627415 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627415
  var valid_21627416 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627416 = validateParameter(valid_21627416, JString, required = false,
                                   default = nil)
  if valid_21627416 != nil:
    section.add "X-Amz-Algorithm", valid_21627416
  var valid_21627417 = header.getOrDefault("X-Amz-Signature")
  valid_21627417 = validateParameter(valid_21627417, JString, required = false,
                                   default = nil)
  if valid_21627417 != nil:
    section.add "X-Amz-Signature", valid_21627417
  var valid_21627418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627418 = validateParameter(valid_21627418, JString, required = false,
                                   default = nil)
  if valid_21627418 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627418
  var valid_21627419 = header.getOrDefault("X-Amz-Credential")
  valid_21627419 = validateParameter(valid_21627419, JString, required = false,
                                   default = nil)
  if valid_21627419 != nil:
    section.add "X-Amz-Credential", valid_21627419
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

proc call*(call_21627421: Call_OpenInstancePublicPorts_21627409;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds public ports to an Amazon Lightsail instance.</p> <p>The <code>open instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627421.validator(path, query, header, formData, body, _)
  let scheme = call_21627421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627421.makeUrl(scheme.get, call_21627421.host, call_21627421.base,
                               call_21627421.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627421, uri, valid, _)

proc call*(call_21627422: Call_OpenInstancePublicPorts_21627409; body: JsonNode): Recallable =
  ## openInstancePublicPorts
  ## <p>Adds public ports to an Amazon Lightsail instance.</p> <p>The <code>open instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627423 = newJObject()
  if body != nil:
    body_21627423 = body
  result = call_21627422.call(nil, nil, nil, nil, body_21627423)

var openInstancePublicPorts* = Call_OpenInstancePublicPorts_21627409(
    name: "openInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.OpenInstancePublicPorts",
    validator: validate_OpenInstancePublicPorts_21627410, base: "/",
    makeUrl: url_OpenInstancePublicPorts_21627411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PeerVpc_21627424 = ref object of OpenApiRestCall_21625435
proc url_PeerVpc_21627426(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PeerVpc_21627425(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627427 = header.getOrDefault("X-Amz-Date")
  valid_21627427 = validateParameter(valid_21627427, JString, required = false,
                                   default = nil)
  if valid_21627427 != nil:
    section.add "X-Amz-Date", valid_21627427
  var valid_21627428 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627428 = validateParameter(valid_21627428, JString, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "X-Amz-Security-Token", valid_21627428
  var valid_21627429 = header.getOrDefault("X-Amz-Target")
  valid_21627429 = validateParameter(valid_21627429, JString, required = true, default = newJString(
      "Lightsail_20161128.PeerVpc"))
  if valid_21627429 != nil:
    section.add "X-Amz-Target", valid_21627429
  var valid_21627430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627430 = validateParameter(valid_21627430, JString, required = false,
                                   default = nil)
  if valid_21627430 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627430
  var valid_21627431 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627431 = validateParameter(valid_21627431, JString, required = false,
                                   default = nil)
  if valid_21627431 != nil:
    section.add "X-Amz-Algorithm", valid_21627431
  var valid_21627432 = header.getOrDefault("X-Amz-Signature")
  valid_21627432 = validateParameter(valid_21627432, JString, required = false,
                                   default = nil)
  if valid_21627432 != nil:
    section.add "X-Amz-Signature", valid_21627432
  var valid_21627433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627433 = validateParameter(valid_21627433, JString, required = false,
                                   default = nil)
  if valid_21627433 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627433
  var valid_21627434 = header.getOrDefault("X-Amz-Credential")
  valid_21627434 = validateParameter(valid_21627434, JString, required = false,
                                   default = nil)
  if valid_21627434 != nil:
    section.add "X-Amz-Credential", valid_21627434
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

proc call*(call_21627436: Call_PeerVpc_21627424; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Tries to peer the Lightsail VPC with the user's default VPC.
  ## 
  let valid = call_21627436.validator(path, query, header, formData, body, _)
  let scheme = call_21627436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627436.makeUrl(scheme.get, call_21627436.host, call_21627436.base,
                               call_21627436.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627436, uri, valid, _)

proc call*(call_21627437: Call_PeerVpc_21627424; body: JsonNode): Recallable =
  ## peerVpc
  ## Tries to peer the Lightsail VPC with the user's default VPC.
  ##   body: JObject (required)
  var body_21627438 = newJObject()
  if body != nil:
    body_21627438 = body
  result = call_21627437.call(nil, nil, nil, nil, body_21627438)

var peerVpc* = Call_PeerVpc_21627424(name: "peerVpc", meth: HttpMethod.HttpPost,
                                  host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.PeerVpc",
                                  validator: validate_PeerVpc_21627425, base: "/",
                                  makeUrl: url_PeerVpc_21627426,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAlarm_21627439 = ref object of OpenApiRestCall_21625435
proc url_PutAlarm_21627441(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAlarm_21627440(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627442 = header.getOrDefault("X-Amz-Date")
  valid_21627442 = validateParameter(valid_21627442, JString, required = false,
                                   default = nil)
  if valid_21627442 != nil:
    section.add "X-Amz-Date", valid_21627442
  var valid_21627443 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627443 = validateParameter(valid_21627443, JString, required = false,
                                   default = nil)
  if valid_21627443 != nil:
    section.add "X-Amz-Security-Token", valid_21627443
  var valid_21627444 = header.getOrDefault("X-Amz-Target")
  valid_21627444 = validateParameter(valid_21627444, JString, required = true, default = newJString(
      "Lightsail_20161128.PutAlarm"))
  if valid_21627444 != nil:
    section.add "X-Amz-Target", valid_21627444
  var valid_21627445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627445 = validateParameter(valid_21627445, JString, required = false,
                                   default = nil)
  if valid_21627445 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627445
  var valid_21627446 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627446 = validateParameter(valid_21627446, JString, required = false,
                                   default = nil)
  if valid_21627446 != nil:
    section.add "X-Amz-Algorithm", valid_21627446
  var valid_21627447 = header.getOrDefault("X-Amz-Signature")
  valid_21627447 = validateParameter(valid_21627447, JString, required = false,
                                   default = nil)
  if valid_21627447 != nil:
    section.add "X-Amz-Signature", valid_21627447
  var valid_21627448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627448 = validateParameter(valid_21627448, JString, required = false,
                                   default = nil)
  if valid_21627448 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627448
  var valid_21627449 = header.getOrDefault("X-Amz-Credential")
  valid_21627449 = validateParameter(valid_21627449, JString, required = false,
                                   default = nil)
  if valid_21627449 != nil:
    section.add "X-Amz-Credential", valid_21627449
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

proc call*(call_21627451: Call_PutAlarm_21627439; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates or updates an alarm, and associates it with the specified metric.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p> <p>When this action creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm. The alarm is then evaluated with the updated configuration.</p>
  ## 
  let valid = call_21627451.validator(path, query, header, formData, body, _)
  let scheme = call_21627451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627451.makeUrl(scheme.get, call_21627451.host, call_21627451.base,
                               call_21627451.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627451, uri, valid, _)

proc call*(call_21627452: Call_PutAlarm_21627439; body: JsonNode): Recallable =
  ## putAlarm
  ## <p>Creates or updates an alarm, and associates it with the specified metric.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p> <p>When this action creates an alarm, the alarm state is immediately set to <code>INSUFFICIENT_DATA</code>. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed.</p> <p>When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm. The alarm is then evaluated with the updated configuration.</p>
  ##   body: JObject (required)
  var body_21627453 = newJObject()
  if body != nil:
    body_21627453 = body
  result = call_21627452.call(nil, nil, nil, nil, body_21627453)

var putAlarm* = Call_PutAlarm_21627439(name: "putAlarm", meth: HttpMethod.HttpPost,
                                    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.PutAlarm",
                                    validator: validate_PutAlarm_21627440,
                                    base: "/", makeUrl: url_PutAlarm_21627441,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInstancePublicPorts_21627454 = ref object of OpenApiRestCall_21625435
proc url_PutInstancePublicPorts_21627456(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutInstancePublicPorts_21627455(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627457 = header.getOrDefault("X-Amz-Date")
  valid_21627457 = validateParameter(valid_21627457, JString, required = false,
                                   default = nil)
  if valid_21627457 != nil:
    section.add "X-Amz-Date", valid_21627457
  var valid_21627458 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627458 = validateParameter(valid_21627458, JString, required = false,
                                   default = nil)
  if valid_21627458 != nil:
    section.add "X-Amz-Security-Token", valid_21627458
  var valid_21627459 = header.getOrDefault("X-Amz-Target")
  valid_21627459 = validateParameter(valid_21627459, JString, required = true, default = newJString(
      "Lightsail_20161128.PutInstancePublicPorts"))
  if valid_21627459 != nil:
    section.add "X-Amz-Target", valid_21627459
  var valid_21627460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627460 = validateParameter(valid_21627460, JString, required = false,
                                   default = nil)
  if valid_21627460 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627460
  var valid_21627461 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627461 = validateParameter(valid_21627461, JString, required = false,
                                   default = nil)
  if valid_21627461 != nil:
    section.add "X-Amz-Algorithm", valid_21627461
  var valid_21627462 = header.getOrDefault("X-Amz-Signature")
  valid_21627462 = validateParameter(valid_21627462, JString, required = false,
                                   default = nil)
  if valid_21627462 != nil:
    section.add "X-Amz-Signature", valid_21627462
  var valid_21627463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627463 = validateParameter(valid_21627463, JString, required = false,
                                   default = nil)
  if valid_21627463 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627463
  var valid_21627464 = header.getOrDefault("X-Amz-Credential")
  valid_21627464 = validateParameter(valid_21627464, JString, required = false,
                                   default = nil)
  if valid_21627464 != nil:
    section.add "X-Amz-Credential", valid_21627464
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

proc call*(call_21627466: Call_PutInstancePublicPorts_21627454;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the specified open ports for an Amazon Lightsail instance, and closes all ports for every protocol not included in the current request.</p> <p>The <code>put instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627466.validator(path, query, header, formData, body, _)
  let scheme = call_21627466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627466.makeUrl(scheme.get, call_21627466.host, call_21627466.base,
                               call_21627466.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627466, uri, valid, _)

proc call*(call_21627467: Call_PutInstancePublicPorts_21627454; body: JsonNode): Recallable =
  ## putInstancePublicPorts
  ## <p>Sets the specified open ports for an Amazon Lightsail instance, and closes all ports for every protocol not included in the current request.</p> <p>The <code>put instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627468 = newJObject()
  if body != nil:
    body_21627468 = body
  result = call_21627467.call(nil, nil, nil, nil, body_21627468)

var putInstancePublicPorts* = Call_PutInstancePublicPorts_21627454(
    name: "putInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.PutInstancePublicPorts",
    validator: validate_PutInstancePublicPorts_21627455, base: "/",
    makeUrl: url_PutInstancePublicPorts_21627456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootInstance_21627469 = ref object of OpenApiRestCall_21625435
proc url_RebootInstance_21627471(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RebootInstance_21627470(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627472 = header.getOrDefault("X-Amz-Date")
  valid_21627472 = validateParameter(valid_21627472, JString, required = false,
                                   default = nil)
  if valid_21627472 != nil:
    section.add "X-Amz-Date", valid_21627472
  var valid_21627473 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627473 = validateParameter(valid_21627473, JString, required = false,
                                   default = nil)
  if valid_21627473 != nil:
    section.add "X-Amz-Security-Token", valid_21627473
  var valid_21627474 = header.getOrDefault("X-Amz-Target")
  valid_21627474 = validateParameter(valid_21627474, JString, required = true, default = newJString(
      "Lightsail_20161128.RebootInstance"))
  if valid_21627474 != nil:
    section.add "X-Amz-Target", valid_21627474
  var valid_21627475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627475 = validateParameter(valid_21627475, JString, required = false,
                                   default = nil)
  if valid_21627475 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627475
  var valid_21627476 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627476 = validateParameter(valid_21627476, JString, required = false,
                                   default = nil)
  if valid_21627476 != nil:
    section.add "X-Amz-Algorithm", valid_21627476
  var valid_21627477 = header.getOrDefault("X-Amz-Signature")
  valid_21627477 = validateParameter(valid_21627477, JString, required = false,
                                   default = nil)
  if valid_21627477 != nil:
    section.add "X-Amz-Signature", valid_21627477
  var valid_21627478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627478 = validateParameter(valid_21627478, JString, required = false,
                                   default = nil)
  if valid_21627478 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627478
  var valid_21627479 = header.getOrDefault("X-Amz-Credential")
  valid_21627479 = validateParameter(valid_21627479, JString, required = false,
                                   default = nil)
  if valid_21627479 != nil:
    section.add "X-Amz-Credential", valid_21627479
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

proc call*(call_21627481: Call_RebootInstance_21627469; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Restarts a specific instance.</p> <p>The <code>reboot instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627481.validator(path, query, header, formData, body, _)
  let scheme = call_21627481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627481.makeUrl(scheme.get, call_21627481.host, call_21627481.base,
                               call_21627481.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627481, uri, valid, _)

proc call*(call_21627482: Call_RebootInstance_21627469; body: JsonNode): Recallable =
  ## rebootInstance
  ## <p>Restarts a specific instance.</p> <p>The <code>reboot instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627483 = newJObject()
  if body != nil:
    body_21627483 = body
  result = call_21627482.call(nil, nil, nil, nil, body_21627483)

var rebootInstance* = Call_RebootInstance_21627469(name: "rebootInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.RebootInstance",
    validator: validate_RebootInstance_21627470, base: "/",
    makeUrl: url_RebootInstance_21627471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootRelationalDatabase_21627484 = ref object of OpenApiRestCall_21625435
proc url_RebootRelationalDatabase_21627486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RebootRelationalDatabase_21627485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21627487 = header.getOrDefault("X-Amz-Date")
  valid_21627487 = validateParameter(valid_21627487, JString, required = false,
                                   default = nil)
  if valid_21627487 != nil:
    section.add "X-Amz-Date", valid_21627487
  var valid_21627488 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627488 = validateParameter(valid_21627488, JString, required = false,
                                   default = nil)
  if valid_21627488 != nil:
    section.add "X-Amz-Security-Token", valid_21627488
  var valid_21627489 = header.getOrDefault("X-Amz-Target")
  valid_21627489 = validateParameter(valid_21627489, JString, required = true, default = newJString(
      "Lightsail_20161128.RebootRelationalDatabase"))
  if valid_21627489 != nil:
    section.add "X-Amz-Target", valid_21627489
  var valid_21627490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627490 = validateParameter(valid_21627490, JString, required = false,
                                   default = nil)
  if valid_21627490 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627490
  var valid_21627491 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627491 = validateParameter(valid_21627491, JString, required = false,
                                   default = nil)
  if valid_21627491 != nil:
    section.add "X-Amz-Algorithm", valid_21627491
  var valid_21627492 = header.getOrDefault("X-Amz-Signature")
  valid_21627492 = validateParameter(valid_21627492, JString, required = false,
                                   default = nil)
  if valid_21627492 != nil:
    section.add "X-Amz-Signature", valid_21627492
  var valid_21627493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627493 = validateParameter(valid_21627493, JString, required = false,
                                   default = nil)
  if valid_21627493 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627493
  var valid_21627494 = header.getOrDefault("X-Amz-Credential")
  valid_21627494 = validateParameter(valid_21627494, JString, required = false,
                                   default = nil)
  if valid_21627494 != nil:
    section.add "X-Amz-Credential", valid_21627494
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

proc call*(call_21627496: Call_RebootRelationalDatabase_21627484;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627496.validator(path, query, header, formData, body, _)
  let scheme = call_21627496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627496.makeUrl(scheme.get, call_21627496.host, call_21627496.base,
                               call_21627496.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627496, uri, valid, _)

proc call*(call_21627497: Call_RebootRelationalDatabase_21627484; body: JsonNode): Recallable =
  ## rebootRelationalDatabase
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627498 = newJObject()
  if body != nil:
    body_21627498 = body
  result = call_21627497.call(nil, nil, nil, nil, body_21627498)

var rebootRelationalDatabase* = Call_RebootRelationalDatabase_21627484(
    name: "rebootRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.RebootRelationalDatabase",
    validator: validate_RebootRelationalDatabase_21627485, base: "/",
    makeUrl: url_RebootRelationalDatabase_21627486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReleaseStaticIp_21627499 = ref object of OpenApiRestCall_21625435
proc url_ReleaseStaticIp_21627501(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ReleaseStaticIp_21627500(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627502 = header.getOrDefault("X-Amz-Date")
  valid_21627502 = validateParameter(valid_21627502, JString, required = false,
                                   default = nil)
  if valid_21627502 != nil:
    section.add "X-Amz-Date", valid_21627502
  var valid_21627503 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627503 = validateParameter(valid_21627503, JString, required = false,
                                   default = nil)
  if valid_21627503 != nil:
    section.add "X-Amz-Security-Token", valid_21627503
  var valid_21627504 = header.getOrDefault("X-Amz-Target")
  valid_21627504 = validateParameter(valid_21627504, JString, required = true, default = newJString(
      "Lightsail_20161128.ReleaseStaticIp"))
  if valid_21627504 != nil:
    section.add "X-Amz-Target", valid_21627504
  var valid_21627505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627505 = validateParameter(valid_21627505, JString, required = false,
                                   default = nil)
  if valid_21627505 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627505
  var valid_21627506 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627506 = validateParameter(valid_21627506, JString, required = false,
                                   default = nil)
  if valid_21627506 != nil:
    section.add "X-Amz-Algorithm", valid_21627506
  var valid_21627507 = header.getOrDefault("X-Amz-Signature")
  valid_21627507 = validateParameter(valid_21627507, JString, required = false,
                                   default = nil)
  if valid_21627507 != nil:
    section.add "X-Amz-Signature", valid_21627507
  var valid_21627508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627508 = validateParameter(valid_21627508, JString, required = false,
                                   default = nil)
  if valid_21627508 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627508
  var valid_21627509 = header.getOrDefault("X-Amz-Credential")
  valid_21627509 = validateParameter(valid_21627509, JString, required = false,
                                   default = nil)
  if valid_21627509 != nil:
    section.add "X-Amz-Credential", valid_21627509
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

proc call*(call_21627511: Call_ReleaseStaticIp_21627499; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specific static IP from your account.
  ## 
  let valid = call_21627511.validator(path, query, header, formData, body, _)
  let scheme = call_21627511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627511.makeUrl(scheme.get, call_21627511.host, call_21627511.base,
                               call_21627511.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627511, uri, valid, _)

proc call*(call_21627512: Call_ReleaseStaticIp_21627499; body: JsonNode): Recallable =
  ## releaseStaticIp
  ## Deletes a specific static IP from your account.
  ##   body: JObject (required)
  var body_21627513 = newJObject()
  if body != nil:
    body_21627513 = body
  result = call_21627512.call(nil, nil, nil, nil, body_21627513)

var releaseStaticIp* = Call_ReleaseStaticIp_21627499(name: "releaseStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ReleaseStaticIp",
    validator: validate_ReleaseStaticIp_21627500, base: "/",
    makeUrl: url_ReleaseStaticIp_21627501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendContactMethodVerification_21627514 = ref object of OpenApiRestCall_21625435
proc url_SendContactMethodVerification_21627516(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendContactMethodVerification_21627515(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627517 = header.getOrDefault("X-Amz-Date")
  valid_21627517 = validateParameter(valid_21627517, JString, required = false,
                                   default = nil)
  if valid_21627517 != nil:
    section.add "X-Amz-Date", valid_21627517
  var valid_21627518 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627518 = validateParameter(valid_21627518, JString, required = false,
                                   default = nil)
  if valid_21627518 != nil:
    section.add "X-Amz-Security-Token", valid_21627518
  var valid_21627519 = header.getOrDefault("X-Amz-Target")
  valid_21627519 = validateParameter(valid_21627519, JString, required = true, default = newJString(
      "Lightsail_20161128.SendContactMethodVerification"))
  if valid_21627519 != nil:
    section.add "X-Amz-Target", valid_21627519
  var valid_21627520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627520 = validateParameter(valid_21627520, JString, required = false,
                                   default = nil)
  if valid_21627520 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627520
  var valid_21627521 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627521 = validateParameter(valid_21627521, JString, required = false,
                                   default = nil)
  if valid_21627521 != nil:
    section.add "X-Amz-Algorithm", valid_21627521
  var valid_21627522 = header.getOrDefault("X-Amz-Signature")
  valid_21627522 = validateParameter(valid_21627522, JString, required = false,
                                   default = nil)
  if valid_21627522 != nil:
    section.add "X-Amz-Signature", valid_21627522
  var valid_21627523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627523 = validateParameter(valid_21627523, JString, required = false,
                                   default = nil)
  if valid_21627523 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627523
  var valid_21627524 = header.getOrDefault("X-Amz-Credential")
  valid_21627524 = validateParameter(valid_21627524, JString, required = false,
                                   default = nil)
  if valid_21627524 != nil:
    section.add "X-Amz-Credential", valid_21627524
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

proc call*(call_21627526: Call_SendContactMethodVerification_21627514;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sends a verification request to an email contact method to ensure it’s owned by the requester. SMS contact methods don’t need to be verified.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p> <p>A verification request is sent to the contact method when you initially create it. Use this action to send another verification request if a previous verification request was deleted, or has expired.</p> <important> <p>Notifications are not sent to an email contact method until after it is verified, and confirmed as valid.</p> </important>
  ## 
  let valid = call_21627526.validator(path, query, header, formData, body, _)
  let scheme = call_21627526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627526.makeUrl(scheme.get, call_21627526.host, call_21627526.base,
                               call_21627526.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627526, uri, valid, _)

proc call*(call_21627527: Call_SendContactMethodVerification_21627514;
          body: JsonNode): Recallable =
  ## sendContactMethodVerification
  ## <p>Sends a verification request to an email contact method to ensure it’s owned by the requester. SMS contact methods don’t need to be verified.</p> <p>A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each AWS Region. However, SMS text messaging is not supported in some AWS Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications">Notifications in Amazon Lightsail</a>.</p> <p>A verification request is sent to the contact method when you initially create it. Use this action to send another verification request if a previous verification request was deleted, or has expired.</p> <important> <p>Notifications are not sent to an email contact method until after it is verified, and confirmed as valid.</p> </important>
  ##   body: JObject (required)
  var body_21627528 = newJObject()
  if body != nil:
    body_21627528 = body
  result = call_21627527.call(nil, nil, nil, nil, body_21627528)

var sendContactMethodVerification* = Call_SendContactMethodVerification_21627514(
    name: "sendContactMethodVerification", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.SendContactMethodVerification",
    validator: validate_SendContactMethodVerification_21627515, base: "/",
    makeUrl: url_SendContactMethodVerification_21627516,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartInstance_21627529 = ref object of OpenApiRestCall_21625435
proc url_StartInstance_21627531(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartInstance_21627530(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21627532 = header.getOrDefault("X-Amz-Date")
  valid_21627532 = validateParameter(valid_21627532, JString, required = false,
                                   default = nil)
  if valid_21627532 != nil:
    section.add "X-Amz-Date", valid_21627532
  var valid_21627533 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627533 = validateParameter(valid_21627533, JString, required = false,
                                   default = nil)
  if valid_21627533 != nil:
    section.add "X-Amz-Security-Token", valid_21627533
  var valid_21627534 = header.getOrDefault("X-Amz-Target")
  valid_21627534 = validateParameter(valid_21627534, JString, required = true, default = newJString(
      "Lightsail_20161128.StartInstance"))
  if valid_21627534 != nil:
    section.add "X-Amz-Target", valid_21627534
  var valid_21627535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627535 = validateParameter(valid_21627535, JString, required = false,
                                   default = nil)
  if valid_21627535 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627535
  var valid_21627536 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627536 = validateParameter(valid_21627536, JString, required = false,
                                   default = nil)
  if valid_21627536 != nil:
    section.add "X-Amz-Algorithm", valid_21627536
  var valid_21627537 = header.getOrDefault("X-Amz-Signature")
  valid_21627537 = validateParameter(valid_21627537, JString, required = false,
                                   default = nil)
  if valid_21627537 != nil:
    section.add "X-Amz-Signature", valid_21627537
  var valid_21627538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627538 = validateParameter(valid_21627538, JString, required = false,
                                   default = nil)
  if valid_21627538 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627538
  var valid_21627539 = header.getOrDefault("X-Amz-Credential")
  valid_21627539 = validateParameter(valid_21627539, JString, required = false,
                                   default = nil)
  if valid_21627539 != nil:
    section.add "X-Amz-Credential", valid_21627539
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

proc call*(call_21627541: Call_StartInstance_21627529; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627541.validator(path, query, header, formData, body, _)
  let scheme = call_21627541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627541.makeUrl(scheme.get, call_21627541.host, call_21627541.base,
                               call_21627541.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627541, uri, valid, _)

proc call*(call_21627542: Call_StartInstance_21627529; body: JsonNode): Recallable =
  ## startInstance
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627543 = newJObject()
  if body != nil:
    body_21627543 = body
  result = call_21627542.call(nil, nil, nil, nil, body_21627543)

var startInstance* = Call_StartInstance_21627529(name: "startInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StartInstance",
    validator: validate_StartInstance_21627530, base: "/",
    makeUrl: url_StartInstance_21627531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRelationalDatabase_21627544 = ref object of OpenApiRestCall_21625435
proc url_StartRelationalDatabase_21627546(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartRelationalDatabase_21627545(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627547 = header.getOrDefault("X-Amz-Date")
  valid_21627547 = validateParameter(valid_21627547, JString, required = false,
                                   default = nil)
  if valid_21627547 != nil:
    section.add "X-Amz-Date", valid_21627547
  var valid_21627548 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627548 = validateParameter(valid_21627548, JString, required = false,
                                   default = nil)
  if valid_21627548 != nil:
    section.add "X-Amz-Security-Token", valid_21627548
  var valid_21627549 = header.getOrDefault("X-Amz-Target")
  valid_21627549 = validateParameter(valid_21627549, JString, required = true, default = newJString(
      "Lightsail_20161128.StartRelationalDatabase"))
  if valid_21627549 != nil:
    section.add "X-Amz-Target", valid_21627549
  var valid_21627550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627550 = validateParameter(valid_21627550, JString, required = false,
                                   default = nil)
  if valid_21627550 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627550
  var valid_21627551 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627551 = validateParameter(valid_21627551, JString, required = false,
                                   default = nil)
  if valid_21627551 != nil:
    section.add "X-Amz-Algorithm", valid_21627551
  var valid_21627552 = header.getOrDefault("X-Amz-Signature")
  valid_21627552 = validateParameter(valid_21627552, JString, required = false,
                                   default = nil)
  if valid_21627552 != nil:
    section.add "X-Amz-Signature", valid_21627552
  var valid_21627553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627553 = validateParameter(valid_21627553, JString, required = false,
                                   default = nil)
  if valid_21627553 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627553
  var valid_21627554 = header.getOrDefault("X-Amz-Credential")
  valid_21627554 = validateParameter(valid_21627554, JString, required = false,
                                   default = nil)
  if valid_21627554 != nil:
    section.add "X-Amz-Credential", valid_21627554
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

proc call*(call_21627556: Call_StartRelationalDatabase_21627544;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the <code>reboot relational database</code> operation.</p> <p>The <code>start relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627556.validator(path, query, header, formData, body, _)
  let scheme = call_21627556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627556.makeUrl(scheme.get, call_21627556.host, call_21627556.base,
                               call_21627556.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627556, uri, valid, _)

proc call*(call_21627557: Call_StartRelationalDatabase_21627544; body: JsonNode): Recallable =
  ## startRelationalDatabase
  ## <p>Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the <code>reboot relational database</code> operation.</p> <p>The <code>start relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627558 = newJObject()
  if body != nil:
    body_21627558 = body
  result = call_21627557.call(nil, nil, nil, nil, body_21627558)

var startRelationalDatabase* = Call_StartRelationalDatabase_21627544(
    name: "startRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StartRelationalDatabase",
    validator: validate_StartRelationalDatabase_21627545, base: "/",
    makeUrl: url_StartRelationalDatabase_21627546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopInstance_21627559 = ref object of OpenApiRestCall_21625435
proc url_StopInstance_21627561(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopInstance_21627560(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21627562 = header.getOrDefault("X-Amz-Date")
  valid_21627562 = validateParameter(valid_21627562, JString, required = false,
                                   default = nil)
  if valid_21627562 != nil:
    section.add "X-Amz-Date", valid_21627562
  var valid_21627563 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627563 = validateParameter(valid_21627563, JString, required = false,
                                   default = nil)
  if valid_21627563 != nil:
    section.add "X-Amz-Security-Token", valid_21627563
  var valid_21627564 = header.getOrDefault("X-Amz-Target")
  valid_21627564 = validateParameter(valid_21627564, JString, required = true, default = newJString(
      "Lightsail_20161128.StopInstance"))
  if valid_21627564 != nil:
    section.add "X-Amz-Target", valid_21627564
  var valid_21627565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627565 = validateParameter(valid_21627565, JString, required = false,
                                   default = nil)
  if valid_21627565 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627565
  var valid_21627566 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627566 = validateParameter(valid_21627566, JString, required = false,
                                   default = nil)
  if valid_21627566 != nil:
    section.add "X-Amz-Algorithm", valid_21627566
  var valid_21627567 = header.getOrDefault("X-Amz-Signature")
  valid_21627567 = validateParameter(valid_21627567, JString, required = false,
                                   default = nil)
  if valid_21627567 != nil:
    section.add "X-Amz-Signature", valid_21627567
  var valid_21627568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627568 = validateParameter(valid_21627568, JString, required = false,
                                   default = nil)
  if valid_21627568 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627568
  var valid_21627569 = header.getOrDefault("X-Amz-Credential")
  valid_21627569 = validateParameter(valid_21627569, JString, required = false,
                                   default = nil)
  if valid_21627569 != nil:
    section.add "X-Amz-Credential", valid_21627569
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

proc call*(call_21627571: Call_StopInstance_21627559; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627571.validator(path, query, header, formData, body, _)
  let scheme = call_21627571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627571.makeUrl(scheme.get, call_21627571.host, call_21627571.base,
                               call_21627571.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627571, uri, valid, _)

proc call*(call_21627572: Call_StopInstance_21627559; body: JsonNode): Recallable =
  ## stopInstance
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627573 = newJObject()
  if body != nil:
    body_21627573 = body
  result = call_21627572.call(nil, nil, nil, nil, body_21627573)

var stopInstance* = Call_StopInstance_21627559(name: "stopInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StopInstance",
    validator: validate_StopInstance_21627560, base: "/", makeUrl: url_StopInstance_21627561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRelationalDatabase_21627574 = ref object of OpenApiRestCall_21625435
proc url_StopRelationalDatabase_21627576(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopRelationalDatabase_21627575(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627577 = header.getOrDefault("X-Amz-Date")
  valid_21627577 = validateParameter(valid_21627577, JString, required = false,
                                   default = nil)
  if valid_21627577 != nil:
    section.add "X-Amz-Date", valid_21627577
  var valid_21627578 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627578 = validateParameter(valid_21627578, JString, required = false,
                                   default = nil)
  if valid_21627578 != nil:
    section.add "X-Amz-Security-Token", valid_21627578
  var valid_21627579 = header.getOrDefault("X-Amz-Target")
  valid_21627579 = validateParameter(valid_21627579, JString, required = true, default = newJString(
      "Lightsail_20161128.StopRelationalDatabase"))
  if valid_21627579 != nil:
    section.add "X-Amz-Target", valid_21627579
  var valid_21627580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627580 = validateParameter(valid_21627580, JString, required = false,
                                   default = nil)
  if valid_21627580 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627580
  var valid_21627581 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627581 = validateParameter(valid_21627581, JString, required = false,
                                   default = nil)
  if valid_21627581 != nil:
    section.add "X-Amz-Algorithm", valid_21627581
  var valid_21627582 = header.getOrDefault("X-Amz-Signature")
  valid_21627582 = validateParameter(valid_21627582, JString, required = false,
                                   default = nil)
  if valid_21627582 != nil:
    section.add "X-Amz-Signature", valid_21627582
  var valid_21627583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627583 = validateParameter(valid_21627583, JString, required = false,
                                   default = nil)
  if valid_21627583 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627583
  var valid_21627584 = header.getOrDefault("X-Amz-Credential")
  valid_21627584 = validateParameter(valid_21627584, JString, required = false,
                                   default = nil)
  if valid_21627584 != nil:
    section.add "X-Amz-Credential", valid_21627584
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

proc call*(call_21627586: Call_StopRelationalDatabase_21627574;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a specific database that is currently running in Amazon Lightsail.</p> <p>The <code>stop relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627586.validator(path, query, header, formData, body, _)
  let scheme = call_21627586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627586.makeUrl(scheme.get, call_21627586.host, call_21627586.base,
                               call_21627586.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627586, uri, valid, _)

proc call*(call_21627587: Call_StopRelationalDatabase_21627574; body: JsonNode): Recallable =
  ## stopRelationalDatabase
  ## <p>Stops a specific database that is currently running in Amazon Lightsail.</p> <p>The <code>stop relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627588 = newJObject()
  if body != nil:
    body_21627588 = body
  result = call_21627587.call(nil, nil, nil, nil, body_21627588)

var stopRelationalDatabase* = Call_StopRelationalDatabase_21627574(
    name: "stopRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StopRelationalDatabase",
    validator: validate_StopRelationalDatabase_21627575, base: "/",
    makeUrl: url_StopRelationalDatabase_21627576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21627589 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21627591(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21627590(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627592 = header.getOrDefault("X-Amz-Date")
  valid_21627592 = validateParameter(valid_21627592, JString, required = false,
                                   default = nil)
  if valid_21627592 != nil:
    section.add "X-Amz-Date", valid_21627592
  var valid_21627593 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627593 = validateParameter(valid_21627593, JString, required = false,
                                   default = nil)
  if valid_21627593 != nil:
    section.add "X-Amz-Security-Token", valid_21627593
  var valid_21627594 = header.getOrDefault("X-Amz-Target")
  valid_21627594 = validateParameter(valid_21627594, JString, required = true, default = newJString(
      "Lightsail_20161128.TagResource"))
  if valid_21627594 != nil:
    section.add "X-Amz-Target", valid_21627594
  var valid_21627595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627595 = validateParameter(valid_21627595, JString, required = false,
                                   default = nil)
  if valid_21627595 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627595
  var valid_21627596 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627596 = validateParameter(valid_21627596, JString, required = false,
                                   default = nil)
  if valid_21627596 != nil:
    section.add "X-Amz-Algorithm", valid_21627596
  var valid_21627597 = header.getOrDefault("X-Amz-Signature")
  valid_21627597 = validateParameter(valid_21627597, JString, required = false,
                                   default = nil)
  if valid_21627597 != nil:
    section.add "X-Amz-Signature", valid_21627597
  var valid_21627598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627598 = validateParameter(valid_21627598, JString, required = false,
                                   default = nil)
  if valid_21627598 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627598
  var valid_21627599 = header.getOrDefault("X-Amz-Credential")
  valid_21627599 = validateParameter(valid_21627599, JString, required = false,
                                   default = nil)
  if valid_21627599 != nil:
    section.add "X-Amz-Credential", valid_21627599
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

proc call*(call_21627601: Call_TagResource_21627589; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-tags">Lightsail Dev Guide</a>.</p> <p>The <code>tag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627601.validator(path, query, header, formData, body, _)
  let scheme = call_21627601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627601.makeUrl(scheme.get, call_21627601.host, call_21627601.base,
                               call_21627601.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627601, uri, valid, _)

proc call*(call_21627602: Call_TagResource_21627589; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-tags">Lightsail Dev Guide</a>.</p> <p>The <code>tag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627603 = newJObject()
  if body != nil:
    body_21627603 = body
  result = call_21627602.call(nil, nil, nil, nil, body_21627603)

var tagResource* = Call_TagResource_21627589(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.TagResource",
    validator: validate_TagResource_21627590, base: "/", makeUrl: url_TagResource_21627591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestAlarm_21627604 = ref object of OpenApiRestCall_21625435
proc url_TestAlarm_21627606(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestAlarm_21627605(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627607 = header.getOrDefault("X-Amz-Date")
  valid_21627607 = validateParameter(valid_21627607, JString, required = false,
                                   default = nil)
  if valid_21627607 != nil:
    section.add "X-Amz-Date", valid_21627607
  var valid_21627608 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627608 = validateParameter(valid_21627608, JString, required = false,
                                   default = nil)
  if valid_21627608 != nil:
    section.add "X-Amz-Security-Token", valid_21627608
  var valid_21627609 = header.getOrDefault("X-Amz-Target")
  valid_21627609 = validateParameter(valid_21627609, JString, required = true, default = newJString(
      "Lightsail_20161128.TestAlarm"))
  if valid_21627609 != nil:
    section.add "X-Amz-Target", valid_21627609
  var valid_21627610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627610 = validateParameter(valid_21627610, JString, required = false,
                                   default = nil)
  if valid_21627610 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627610
  var valid_21627611 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627611 = validateParameter(valid_21627611, JString, required = false,
                                   default = nil)
  if valid_21627611 != nil:
    section.add "X-Amz-Algorithm", valid_21627611
  var valid_21627612 = header.getOrDefault("X-Amz-Signature")
  valid_21627612 = validateParameter(valid_21627612, JString, required = false,
                                   default = nil)
  if valid_21627612 != nil:
    section.add "X-Amz-Signature", valid_21627612
  var valid_21627613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627613 = validateParameter(valid_21627613, JString, required = false,
                                   default = nil)
  if valid_21627613 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627613
  var valid_21627614 = header.getOrDefault("X-Amz-Credential")
  valid_21627614 = validateParameter(valid_21627614, JString, required = false,
                                   default = nil)
  if valid_21627614 != nil:
    section.add "X-Amz-Credential", valid_21627614
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

proc call*(call_21627616: Call_TestAlarm_21627604; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Tests an alarm by displaying a banner on the Amazon Lightsail console. If a notification trigger is configured for the specified alarm, the test also sends a notification to the notification protocol (<code>Email</code> and/or <code>SMS</code>) configured for the alarm.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
  ## 
  let valid = call_21627616.validator(path, query, header, formData, body, _)
  let scheme = call_21627616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627616.makeUrl(scheme.get, call_21627616.host, call_21627616.base,
                               call_21627616.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627616, uri, valid, _)

proc call*(call_21627617: Call_TestAlarm_21627604; body: JsonNode): Recallable =
  ## testAlarm
  ## <p>Tests an alarm by displaying a banner on the Amazon Lightsail console. If a notification trigger is configured for the specified alarm, the test also sends a notification to the notification protocol (<code>Email</code> and/or <code>SMS</code>) configured for the alarm.</p> <p>An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms">Alarms in Amazon Lightsail</a>.</p>
  ##   body: JObject (required)
  var body_21627618 = newJObject()
  if body != nil:
    body_21627618 = body
  result = call_21627617.call(nil, nil, nil, nil, body_21627618)

var testAlarm* = Call_TestAlarm_21627604(name: "testAlarm",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.TestAlarm",
                                      validator: validate_TestAlarm_21627605,
                                      base: "/", makeUrl: url_TestAlarm_21627606,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnpeerVpc_21627619 = ref object of OpenApiRestCall_21625435
proc url_UnpeerVpc_21627621(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UnpeerVpc_21627620(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627622 = header.getOrDefault("X-Amz-Date")
  valid_21627622 = validateParameter(valid_21627622, JString, required = false,
                                   default = nil)
  if valid_21627622 != nil:
    section.add "X-Amz-Date", valid_21627622
  var valid_21627623 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627623 = validateParameter(valid_21627623, JString, required = false,
                                   default = nil)
  if valid_21627623 != nil:
    section.add "X-Amz-Security-Token", valid_21627623
  var valid_21627624 = header.getOrDefault("X-Amz-Target")
  valid_21627624 = validateParameter(valid_21627624, JString, required = true, default = newJString(
      "Lightsail_20161128.UnpeerVpc"))
  if valid_21627624 != nil:
    section.add "X-Amz-Target", valid_21627624
  var valid_21627625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627625 = validateParameter(valid_21627625, JString, required = false,
                                   default = nil)
  if valid_21627625 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627625
  var valid_21627626 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627626 = validateParameter(valid_21627626, JString, required = false,
                                   default = nil)
  if valid_21627626 != nil:
    section.add "X-Amz-Algorithm", valid_21627626
  var valid_21627627 = header.getOrDefault("X-Amz-Signature")
  valid_21627627 = validateParameter(valid_21627627, JString, required = false,
                                   default = nil)
  if valid_21627627 != nil:
    section.add "X-Amz-Signature", valid_21627627
  var valid_21627628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627628 = validateParameter(valid_21627628, JString, required = false,
                                   default = nil)
  if valid_21627628 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627628
  var valid_21627629 = header.getOrDefault("X-Amz-Credential")
  valid_21627629 = validateParameter(valid_21627629, JString, required = false,
                                   default = nil)
  if valid_21627629 != nil:
    section.add "X-Amz-Credential", valid_21627629
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

proc call*(call_21627631: Call_UnpeerVpc_21627619; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to unpeer the Lightsail VPC from the user's default VPC.
  ## 
  let valid = call_21627631.validator(path, query, header, formData, body, _)
  let scheme = call_21627631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627631.makeUrl(scheme.get, call_21627631.host, call_21627631.base,
                               call_21627631.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627631, uri, valid, _)

proc call*(call_21627632: Call_UnpeerVpc_21627619; body: JsonNode): Recallable =
  ## unpeerVpc
  ## Attempts to unpeer the Lightsail VPC from the user's default VPC.
  ##   body: JObject (required)
  var body_21627633 = newJObject()
  if body != nil:
    body_21627633 = body
  result = call_21627632.call(nil, nil, nil, nil, body_21627633)

var unpeerVpc* = Call_UnpeerVpc_21627619(name: "unpeerVpc",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.UnpeerVpc",
                                      validator: validate_UnpeerVpc_21627620,
                                      base: "/", makeUrl: url_UnpeerVpc_21627621,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21627634 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21627636(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21627635(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21627637 = header.getOrDefault("X-Amz-Date")
  valid_21627637 = validateParameter(valid_21627637, JString, required = false,
                                   default = nil)
  if valid_21627637 != nil:
    section.add "X-Amz-Date", valid_21627637
  var valid_21627638 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627638 = validateParameter(valid_21627638, JString, required = false,
                                   default = nil)
  if valid_21627638 != nil:
    section.add "X-Amz-Security-Token", valid_21627638
  var valid_21627639 = header.getOrDefault("X-Amz-Target")
  valid_21627639 = validateParameter(valid_21627639, JString, required = true, default = newJString(
      "Lightsail_20161128.UntagResource"))
  if valid_21627639 != nil:
    section.add "X-Amz-Target", valid_21627639
  var valid_21627640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627640 = validateParameter(valid_21627640, JString, required = false,
                                   default = nil)
  if valid_21627640 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627640
  var valid_21627641 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627641 = validateParameter(valid_21627641, JString, required = false,
                                   default = nil)
  if valid_21627641 != nil:
    section.add "X-Amz-Algorithm", valid_21627641
  var valid_21627642 = header.getOrDefault("X-Amz-Signature")
  valid_21627642 = validateParameter(valid_21627642, JString, required = false,
                                   default = nil)
  if valid_21627642 != nil:
    section.add "X-Amz-Signature", valid_21627642
  var valid_21627643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627643 = validateParameter(valid_21627643, JString, required = false,
                                   default = nil)
  if valid_21627643 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627643
  var valid_21627644 = header.getOrDefault("X-Amz-Credential")
  valid_21627644 = validateParameter(valid_21627644, JString, required = false,
                                   default = nil)
  if valid_21627644 != nil:
    section.add "X-Amz-Credential", valid_21627644
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

proc call*(call_21627646: Call_UntagResource_21627634; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627646.validator(path, query, header, formData, body, _)
  let scheme = call_21627646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627646.makeUrl(scheme.get, call_21627646.host, call_21627646.base,
                               call_21627646.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627646, uri, valid, _)

proc call*(call_21627647: Call_UntagResource_21627634; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627648 = newJObject()
  if body != nil:
    body_21627648 = body
  result = call_21627647.call(nil, nil, nil, nil, body_21627648)

var untagResource* = Call_UntagResource_21627634(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UntagResource",
    validator: validate_UntagResource_21627635, base: "/",
    makeUrl: url_UntagResource_21627636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainEntry_21627649 = ref object of OpenApiRestCall_21625435
proc url_UpdateDomainEntry_21627651(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDomainEntry_21627650(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627652 = header.getOrDefault("X-Amz-Date")
  valid_21627652 = validateParameter(valid_21627652, JString, required = false,
                                   default = nil)
  if valid_21627652 != nil:
    section.add "X-Amz-Date", valid_21627652
  var valid_21627653 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627653 = validateParameter(valid_21627653, JString, required = false,
                                   default = nil)
  if valid_21627653 != nil:
    section.add "X-Amz-Security-Token", valid_21627653
  var valid_21627654 = header.getOrDefault("X-Amz-Target")
  valid_21627654 = validateParameter(valid_21627654, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateDomainEntry"))
  if valid_21627654 != nil:
    section.add "X-Amz-Target", valid_21627654
  var valid_21627655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627655 = validateParameter(valid_21627655, JString, required = false,
                                   default = nil)
  if valid_21627655 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627655
  var valid_21627656 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627656 = validateParameter(valid_21627656, JString, required = false,
                                   default = nil)
  if valid_21627656 != nil:
    section.add "X-Amz-Algorithm", valid_21627656
  var valid_21627657 = header.getOrDefault("X-Amz-Signature")
  valid_21627657 = validateParameter(valid_21627657, JString, required = false,
                                   default = nil)
  if valid_21627657 != nil:
    section.add "X-Amz-Signature", valid_21627657
  var valid_21627658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627658 = validateParameter(valid_21627658, JString, required = false,
                                   default = nil)
  if valid_21627658 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627658
  var valid_21627659 = header.getOrDefault("X-Amz-Credential")
  valid_21627659 = validateParameter(valid_21627659, JString, required = false,
                                   default = nil)
  if valid_21627659 != nil:
    section.add "X-Amz-Credential", valid_21627659
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

proc call*(call_21627661: Call_UpdateDomainEntry_21627649; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates a domain recordset after it is created.</p> <p>The <code>update domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627661.validator(path, query, header, formData, body, _)
  let scheme = call_21627661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627661.makeUrl(scheme.get, call_21627661.host, call_21627661.base,
                               call_21627661.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627661, uri, valid, _)

proc call*(call_21627662: Call_UpdateDomainEntry_21627649; body: JsonNode): Recallable =
  ## updateDomainEntry
  ## <p>Updates a domain recordset after it is created.</p> <p>The <code>update domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627663 = newJObject()
  if body != nil:
    body_21627663 = body
  result = call_21627662.call(nil, nil, nil, nil, body_21627663)

var updateDomainEntry* = Call_UpdateDomainEntry_21627649(name: "updateDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateDomainEntry",
    validator: validate_UpdateDomainEntry_21627650, base: "/",
    makeUrl: url_UpdateDomainEntry_21627651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoadBalancerAttribute_21627664 = ref object of OpenApiRestCall_21625435
proc url_UpdateLoadBalancerAttribute_21627666(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLoadBalancerAttribute_21627665(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21627667 = header.getOrDefault("X-Amz-Date")
  valid_21627667 = validateParameter(valid_21627667, JString, required = false,
                                   default = nil)
  if valid_21627667 != nil:
    section.add "X-Amz-Date", valid_21627667
  var valid_21627668 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627668 = validateParameter(valid_21627668, JString, required = false,
                                   default = nil)
  if valid_21627668 != nil:
    section.add "X-Amz-Security-Token", valid_21627668
  var valid_21627669 = header.getOrDefault("X-Amz-Target")
  valid_21627669 = validateParameter(valid_21627669, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateLoadBalancerAttribute"))
  if valid_21627669 != nil:
    section.add "X-Amz-Target", valid_21627669
  var valid_21627670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627670 = validateParameter(valid_21627670, JString, required = false,
                                   default = nil)
  if valid_21627670 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627670
  var valid_21627671 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627671 = validateParameter(valid_21627671, JString, required = false,
                                   default = nil)
  if valid_21627671 != nil:
    section.add "X-Amz-Algorithm", valid_21627671
  var valid_21627672 = header.getOrDefault("X-Amz-Signature")
  valid_21627672 = validateParameter(valid_21627672, JString, required = false,
                                   default = nil)
  if valid_21627672 != nil:
    section.add "X-Amz-Signature", valid_21627672
  var valid_21627673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627673 = validateParameter(valid_21627673, JString, required = false,
                                   default = nil)
  if valid_21627673 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627673
  var valid_21627674 = header.getOrDefault("X-Amz-Credential")
  valid_21627674 = validateParameter(valid_21627674, JString, required = false,
                                   default = nil)
  if valid_21627674 != nil:
    section.add "X-Amz-Credential", valid_21627674
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

proc call*(call_21627676: Call_UpdateLoadBalancerAttribute_21627664;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627676.validator(path, query, header, formData, body, _)
  let scheme = call_21627676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627676.makeUrl(scheme.get, call_21627676.host, call_21627676.base,
                               call_21627676.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627676, uri, valid, _)

proc call*(call_21627677: Call_UpdateLoadBalancerAttribute_21627664; body: JsonNode): Recallable =
  ## updateLoadBalancerAttribute
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627678 = newJObject()
  if body != nil:
    body_21627678 = body
  result = call_21627677.call(nil, nil, nil, nil, body_21627678)

var updateLoadBalancerAttribute* = Call_UpdateLoadBalancerAttribute_21627664(
    name: "updateLoadBalancerAttribute", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateLoadBalancerAttribute",
    validator: validate_UpdateLoadBalancerAttribute_21627665, base: "/",
    makeUrl: url_UpdateLoadBalancerAttribute_21627666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRelationalDatabase_21627679 = ref object of OpenApiRestCall_21625435
proc url_UpdateRelationalDatabase_21627681(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRelationalDatabase_21627680(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_21627682 = header.getOrDefault("X-Amz-Date")
  valid_21627682 = validateParameter(valid_21627682, JString, required = false,
                                   default = nil)
  if valid_21627682 != nil:
    section.add "X-Amz-Date", valid_21627682
  var valid_21627683 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627683 = validateParameter(valid_21627683, JString, required = false,
                                   default = nil)
  if valid_21627683 != nil:
    section.add "X-Amz-Security-Token", valid_21627683
  var valid_21627684 = header.getOrDefault("X-Amz-Target")
  valid_21627684 = validateParameter(valid_21627684, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateRelationalDatabase"))
  if valid_21627684 != nil:
    section.add "X-Amz-Target", valid_21627684
  var valid_21627685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627685 = validateParameter(valid_21627685, JString, required = false,
                                   default = nil)
  if valid_21627685 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627685
  var valid_21627686 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627686 = validateParameter(valid_21627686, JString, required = false,
                                   default = nil)
  if valid_21627686 != nil:
    section.add "X-Amz-Algorithm", valid_21627686
  var valid_21627687 = header.getOrDefault("X-Amz-Signature")
  valid_21627687 = validateParameter(valid_21627687, JString, required = false,
                                   default = nil)
  if valid_21627687 != nil:
    section.add "X-Amz-Signature", valid_21627687
  var valid_21627688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627688 = validateParameter(valid_21627688, JString, required = false,
                                   default = nil)
  if valid_21627688 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627688
  var valid_21627689 = header.getOrDefault("X-Amz-Credential")
  valid_21627689 = validateParameter(valid_21627689, JString, required = false,
                                   default = nil)
  if valid_21627689 != nil:
    section.add "X-Amz-Credential", valid_21627689
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

proc call*(call_21627691: Call_UpdateRelationalDatabase_21627679;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627691.validator(path, query, header, formData, body, _)
  let scheme = call_21627691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627691.makeUrl(scheme.get, call_21627691.host, call_21627691.base,
                               call_21627691.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627691, uri, valid, _)

proc call*(call_21627692: Call_UpdateRelationalDatabase_21627679; body: JsonNode): Recallable =
  ## updateRelationalDatabase
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627693 = newJObject()
  if body != nil:
    body_21627693 = body
  result = call_21627692.call(nil, nil, nil, nil, body_21627693)

var updateRelationalDatabase* = Call_UpdateRelationalDatabase_21627679(
    name: "updateRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateRelationalDatabase",
    validator: validate_UpdateRelationalDatabase_21627680, base: "/",
    makeUrl: url_UpdateRelationalDatabase_21627681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRelationalDatabaseParameters_21627694 = ref object of OpenApiRestCall_21625435
proc url_UpdateRelationalDatabaseParameters_21627696(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRelationalDatabaseParameters_21627695(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627697 = header.getOrDefault("X-Amz-Date")
  valid_21627697 = validateParameter(valid_21627697, JString, required = false,
                                   default = nil)
  if valid_21627697 != nil:
    section.add "X-Amz-Date", valid_21627697
  var valid_21627698 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627698 = validateParameter(valid_21627698, JString, required = false,
                                   default = nil)
  if valid_21627698 != nil:
    section.add "X-Amz-Security-Token", valid_21627698
  var valid_21627699 = header.getOrDefault("X-Amz-Target")
  valid_21627699 = validateParameter(valid_21627699, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateRelationalDatabaseParameters"))
  if valid_21627699 != nil:
    section.add "X-Amz-Target", valid_21627699
  var valid_21627700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627700 = validateParameter(valid_21627700, JString, required = false,
                                   default = nil)
  if valid_21627700 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627700
  var valid_21627701 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627701 = validateParameter(valid_21627701, JString, required = false,
                                   default = nil)
  if valid_21627701 != nil:
    section.add "X-Amz-Algorithm", valid_21627701
  var valid_21627702 = header.getOrDefault("X-Amz-Signature")
  valid_21627702 = validateParameter(valid_21627702, JString, required = false,
                                   default = nil)
  if valid_21627702 != nil:
    section.add "X-Amz-Signature", valid_21627702
  var valid_21627703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627703 = validateParameter(valid_21627703, JString, required = false,
                                   default = nil)
  if valid_21627703 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627703
  var valid_21627704 = header.getOrDefault("X-Amz-Credential")
  valid_21627704 = validateParameter(valid_21627704, JString, required = false,
                                   default = nil)
  if valid_21627704 != nil:
    section.add "X-Amz-Credential", valid_21627704
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

proc call*(call_21627706: Call_UpdateRelationalDatabaseParameters_21627694;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which parameter updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_21627706.validator(path, query, header, formData, body, _)
  let scheme = call_21627706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627706.makeUrl(scheme.get, call_21627706.host, call_21627706.base,
                               call_21627706.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627706, uri, valid, _)

proc call*(call_21627707: Call_UpdateRelationalDatabaseParameters_21627694;
          body: JsonNode): Recallable =
  ## updateRelationalDatabaseParameters
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which parameter updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_21627708 = newJObject()
  if body != nil:
    body_21627708 = body
  result = call_21627707.call(nil, nil, nil, nil, body_21627708)

var updateRelationalDatabaseParameters* = Call_UpdateRelationalDatabaseParameters_21627694(
    name: "updateRelationalDatabaseParameters", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.UpdateRelationalDatabaseParameters",
    validator: validate_UpdateRelationalDatabaseParameters_21627695, base: "/",
    makeUrl: url_UpdateRelationalDatabaseParameters_21627696,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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