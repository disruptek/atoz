
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
  Call_AllocateStaticIp_601727 = ref object of OpenApiRestCall_601389
proc url_AllocateStaticIp_601729(protocol: Scheme; host: string; base: string;
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

proc validate_AllocateStaticIp_601728(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "Lightsail_20161128.AllocateStaticIp"))
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

proc call*(call_601885: Call_AllocateStaticIp_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allocates a static IP address.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_AllocateStaticIp_601727; body: JsonNode): Recallable =
  ## allocateStaticIp
  ## Allocates a static IP address.
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var allocateStaticIp* = Call_AllocateStaticIp_601727(name: "allocateStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AllocateStaticIp",
    validator: validate_AllocateStaticIp_601728, base: "/",
    url: url_AllocateStaticIp_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachDisk_601996 = ref object of OpenApiRestCall_601389
proc url_AttachDisk_601998(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_AttachDisk_601997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachDisk"))
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

proc call*(call_602008: Call_AttachDisk_601996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name.</p> <p>The <code>attach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_AttachDisk_601996; body: JsonNode): Recallable =
  ## attachDisk
  ## <p>Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name.</p> <p>The <code>attach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var attachDisk* = Call_AttachDisk_601996(name: "attachDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.AttachDisk",
                                      validator: validate_AttachDisk_601997,
                                      base: "/", url: url_AttachDisk_601998,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachInstancesToLoadBalancer_602011 = ref object of OpenApiRestCall_601389
proc url_AttachInstancesToLoadBalancer_602013(protocol: Scheme; host: string;
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

proc validate_AttachInstancesToLoadBalancer_602012(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachInstancesToLoadBalancer"))
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

proc call*(call_602023: Call_AttachInstancesToLoadBalancer_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches one or more Lightsail instances to a load balancer.</p> <p>After some time, the instances are attached to the load balancer and the health check status is available.</p> <p>The <code>attach instances to load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_AttachInstancesToLoadBalancer_602011; body: JsonNode): Recallable =
  ## attachInstancesToLoadBalancer
  ## <p>Attaches one or more Lightsail instances to a load balancer.</p> <p>After some time, the instances are attached to the load balancer and the health check status is available.</p> <p>The <code>attach instances to load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var attachInstancesToLoadBalancer* = Call_AttachInstancesToLoadBalancer_602011(
    name: "attachInstancesToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AttachInstancesToLoadBalancer",
    validator: validate_AttachInstancesToLoadBalancer_602012, base: "/",
    url: url_AttachInstancesToLoadBalancer_602013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachLoadBalancerTlsCertificate_602026 = ref object of OpenApiRestCall_601389
proc url_AttachLoadBalancerTlsCertificate_602028(protocol: Scheme; host: string;
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

proc validate_AttachLoadBalancerTlsCertificate_602027(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachLoadBalancerTlsCertificate"))
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

proc call*(call_602038: Call_AttachLoadBalancerTlsCertificate_602026;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>attach load balancer tls certificate</code> operation with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>attach load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_AttachLoadBalancerTlsCertificate_602026;
          body: JsonNode): Recallable =
  ## attachLoadBalancerTlsCertificate
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>attach load balancer tls certificate</code> operation with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>attach load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var attachLoadBalancerTlsCertificate* = Call_AttachLoadBalancerTlsCertificate_602026(
    name: "attachLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.AttachLoadBalancerTlsCertificate",
    validator: validate_AttachLoadBalancerTlsCertificate_602027, base: "/",
    url: url_AttachLoadBalancerTlsCertificate_602028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachStaticIp_602041 = ref object of OpenApiRestCall_601389
proc url_AttachStaticIp_602043(protocol: Scheme; host: string; base: string;
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

proc validate_AttachStaticIp_602042(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachStaticIp"))
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

proc call*(call_602053: Call_AttachStaticIp_602041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a static IP address to a specific Amazon Lightsail instance.
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_AttachStaticIp_602041; body: JsonNode): Recallable =
  ## attachStaticIp
  ## Attaches a static IP address to a specific Amazon Lightsail instance.
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var attachStaticIp* = Call_AttachStaticIp_602041(name: "attachStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AttachStaticIp",
    validator: validate_AttachStaticIp_602042, base: "/", url: url_AttachStaticIp_602043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CloseInstancePublicPorts_602056 = ref object of OpenApiRestCall_601389
proc url_CloseInstancePublicPorts_602058(protocol: Scheme; host: string;
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

proc validate_CloseInstancePublicPorts_602057(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "Lightsail_20161128.CloseInstancePublicPorts"))
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

proc call*(call_602068: Call_CloseInstancePublicPorts_602056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_CloseInstancePublicPorts_602056; body: JsonNode): Recallable =
  ## closeInstancePublicPorts
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var closeInstancePublicPorts* = Call_CloseInstancePublicPorts_602056(
    name: "closeInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CloseInstancePublicPorts",
    validator: validate_CloseInstancePublicPorts_602057, base: "/",
    url: url_CloseInstancePublicPorts_602058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopySnapshot_602071 = ref object of OpenApiRestCall_601389
proc url_CopySnapshot_602073(protocol: Scheme; host: string; base: string;
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

proc validate_CopySnapshot_602072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "Lightsail_20161128.CopySnapshot"))
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

proc call*(call_602083: Call_CopySnapshot_602071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a manual snapshot of an instance or disk as another manual snapshot, or copies an automatic snapshot of an instance or disk as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p>
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_CopySnapshot_602071; body: JsonNode): Recallable =
  ## copySnapshot
  ## <p>Copies a manual snapshot of an instance or disk as another manual snapshot, or copies an automatic snapshot of an instance or disk as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p>
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var copySnapshot* = Call_CopySnapshot_602071(name: "copySnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CopySnapshot",
    validator: validate_CopySnapshot_602072, base: "/", url: url_CopySnapshot_602073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationStack_602086 = ref object of OpenApiRestCall_601389
proc url_CreateCloudFormationStack_602088(protocol: Scheme; host: string;
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

proc validate_CreateCloudFormationStack_602087(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateCloudFormationStack"))
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

proc call*(call_602098: Call_CreateCloudFormationStack_602086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_CreateCloudFormationStack_602086; body: JsonNode): Recallable =
  ## createCloudFormationStack
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var createCloudFormationStack* = Call_CreateCloudFormationStack_602086(
    name: "createCloudFormationStack", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateCloudFormationStack",
    validator: validate_CreateCloudFormationStack_602087, base: "/",
    url: url_CreateCloudFormationStack_602088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDisk_602101 = ref object of OpenApiRestCall_601389
proc url_CreateDisk_602103(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateDisk_602102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDisk"))
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

proc call*(call_602113: Call_CreateDisk_602101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_CreateDisk_602101; body: JsonNode): Recallable =
  ## createDisk
  ## <p>Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var createDisk* = Call_CreateDisk_602101(name: "createDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateDisk",
                                      validator: validate_CreateDisk_602102,
                                      base: "/", url: url_CreateDisk_602103,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDiskFromSnapshot_602116 = ref object of OpenApiRestCall_601389
proc url_CreateDiskFromSnapshot_602118(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDiskFromSnapshot_602117(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602119 = header.getOrDefault("X-Amz-Target")
  valid_602119 = validateParameter(valid_602119, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDiskFromSnapshot"))
  if valid_602119 != nil:
    section.add "X-Amz-Target", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Signature")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Signature", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Content-Sha256", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Date")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Date", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Credential")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Credential", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Security-Token")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Security-Token", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Algorithm")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Algorithm", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-SignedHeaders", valid_602126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_CreateDiskFromSnapshot_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_CreateDiskFromSnapshot_602116; body: JsonNode): Recallable =
  ## createDiskFromSnapshot
  ## <p>Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602130 = newJObject()
  if body != nil:
    body_602130 = body
  result = call_602129.call(nil, nil, nil, nil, body_602130)

var createDiskFromSnapshot* = Call_CreateDiskFromSnapshot_602116(
    name: "createDiskFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDiskFromSnapshot",
    validator: validate_CreateDiskFromSnapshot_602117, base: "/",
    url: url_CreateDiskFromSnapshot_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDiskSnapshot_602131 = ref object of OpenApiRestCall_601389
proc url_CreateDiskSnapshot_602133(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDiskSnapshot_602132(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602134 = header.getOrDefault("X-Amz-Target")
  valid_602134 = validateParameter(valid_602134, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDiskSnapshot"))
  if valid_602134 != nil:
    section.add "X-Amz-Target", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602143: Call_CreateDiskSnapshot_602131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance.</p> <p>You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending.</p> <p>You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the <code>instance name</code> parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk.</p> <p>The <code>create disk snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602143, url, valid)

proc call*(call_602144: Call_CreateDiskSnapshot_602131; body: JsonNode): Recallable =
  ## createDiskSnapshot
  ## <p>Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance.</p> <p>You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending.</p> <p>You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the <code>instance name</code> parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk.</p> <p>The <code>create disk snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602145 = newJObject()
  if body != nil:
    body_602145 = body
  result = call_602144.call(nil, nil, nil, nil, body_602145)

var createDiskSnapshot* = Call_CreateDiskSnapshot_602131(
    name: "createDiskSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDiskSnapshot",
    validator: validate_CreateDiskSnapshot_602132, base: "/",
    url: url_CreateDiskSnapshot_602133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_602146 = ref object of OpenApiRestCall_601389
proc url_CreateDomain_602148(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomain_602147(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602149 = header.getOrDefault("X-Amz-Target")
  valid_602149 = validateParameter(valid_602149, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDomain"))
  if valid_602149 != nil:
    section.add "X-Amz-Target", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602158: Call_CreateDomain_602146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602158.validator(path, query, header, formData, body)
  let scheme = call_602158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602158.url(scheme.get, call_602158.host, call_602158.base,
                         call_602158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602158, url, valid)

proc call*(call_602159: Call_CreateDomain_602146; body: JsonNode): Recallable =
  ## createDomain
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602160 = newJObject()
  if body != nil:
    body_602160 = body
  result = call_602159.call(nil, nil, nil, nil, body_602160)

var createDomain* = Call_CreateDomain_602146(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDomain",
    validator: validate_CreateDomain_602147, base: "/", url: url_CreateDomain_602148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainEntry_602161 = ref object of OpenApiRestCall_601389
proc url_CreateDomainEntry_602163(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainEntry_602162(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602164 = header.getOrDefault("X-Amz-Target")
  valid_602164 = validateParameter(valid_602164, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDomainEntry"))
  if valid_602164 != nil:
    section.add "X-Amz-Target", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Signature")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Signature", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Content-Sha256", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Date")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Date", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Credential")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Credential", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Security-Token")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Security-Token", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Algorithm")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Algorithm", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-SignedHeaders", valid_602171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602173: Call_CreateDomainEntry_602161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one of the following entry records associated with the domain: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT).</p> <p>The <code>create domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602173.validator(path, query, header, formData, body)
  let scheme = call_602173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602173.url(scheme.get, call_602173.host, call_602173.base,
                         call_602173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602173, url, valid)

proc call*(call_602174: Call_CreateDomainEntry_602161; body: JsonNode): Recallable =
  ## createDomainEntry
  ## <p>Creates one of the following entry records associated with the domain: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT).</p> <p>The <code>create domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602175 = newJObject()
  if body != nil:
    body_602175 = body
  result = call_602174.call(nil, nil, nil, nil, body_602175)

var createDomainEntry* = Call_CreateDomainEntry_602161(name: "createDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDomainEntry",
    validator: validate_CreateDomainEntry_602162, base: "/",
    url: url_CreateDomainEntry_602163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceSnapshot_602176 = ref object of OpenApiRestCall_601389
proc url_CreateInstanceSnapshot_602178(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInstanceSnapshot_602177(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602179 = header.getOrDefault("X-Amz-Target")
  valid_602179 = validateParameter(valid_602179, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstanceSnapshot"))
  if valid_602179 != nil:
    section.add "X-Amz-Target", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Signature")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Signature", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Content-Sha256", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Date")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Date", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Credential")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Credential", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Security-Token")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Security-Token", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Algorithm")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Algorithm", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-SignedHeaders", valid_602186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602188: Call_CreateInstanceSnapshot_602176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a snapshot of a specific virtual private server, or <i>instance</i>. You can use a snapshot to create a new instance that is based on that snapshot.</p> <p>The <code>create instance snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_CreateInstanceSnapshot_602176; body: JsonNode): Recallable =
  ## createInstanceSnapshot
  ## <p>Creates a snapshot of a specific virtual private server, or <i>instance</i>. You can use a snapshot to create a new instance that is based on that snapshot.</p> <p>The <code>create instance snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602190 = newJObject()
  if body != nil:
    body_602190 = body
  result = call_602189.call(nil, nil, nil, nil, body_602190)

var createInstanceSnapshot* = Call_CreateInstanceSnapshot_602176(
    name: "createInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstanceSnapshot",
    validator: validate_CreateInstanceSnapshot_602177, base: "/",
    url: url_CreateInstanceSnapshot_602178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstances_602191 = ref object of OpenApiRestCall_601389
proc url_CreateInstances_602193(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInstances_602192(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602194 = header.getOrDefault("X-Amz-Target")
  valid_602194 = validateParameter(valid_602194, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstances"))
  if valid_602194 != nil:
    section.add "X-Amz-Target", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Signature")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Signature", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Content-Sha256", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Date")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Date", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Credential")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Credential", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Security-Token")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Security-Token", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Algorithm")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Algorithm", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-SignedHeaders", valid_602201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_CreateInstances_602191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more Amazon Lightsail instances.</p> <p>The <code>create instances</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602203, url, valid)

proc call*(call_602204: Call_CreateInstances_602191; body: JsonNode): Recallable =
  ## createInstances
  ## <p>Creates one or more Amazon Lightsail instances.</p> <p>The <code>create instances</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602205 = newJObject()
  if body != nil:
    body_602205 = body
  result = call_602204.call(nil, nil, nil, nil, body_602205)

var createInstances* = Call_CreateInstances_602191(name: "createInstances",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstances",
    validator: validate_CreateInstances_602192, base: "/", url: url_CreateInstances_602193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstancesFromSnapshot_602206 = ref object of OpenApiRestCall_601389
proc url_CreateInstancesFromSnapshot_602208(protocol: Scheme; host: string;
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

proc validate_CreateInstancesFromSnapshot_602207(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602209 = header.getOrDefault("X-Amz-Target")
  valid_602209 = validateParameter(valid_602209, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstancesFromSnapshot"))
  if valid_602209 != nil:
    section.add "X-Amz-Target", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Signature")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Signature", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Content-Sha256", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Date")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Date", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Credential")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Credential", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Security-Token")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Security-Token", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Algorithm")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Algorithm", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-SignedHeaders", valid_602216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602218: Call_CreateInstancesFromSnapshot_602206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602218.validator(path, query, header, formData, body)
  let scheme = call_602218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602218.url(scheme.get, call_602218.host, call_602218.base,
                         call_602218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602218, url, valid)

proc call*(call_602219: Call_CreateInstancesFromSnapshot_602206; body: JsonNode): Recallable =
  ## createInstancesFromSnapshot
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602220 = newJObject()
  if body != nil:
    body_602220 = body
  result = call_602219.call(nil, nil, nil, nil, body_602220)

var createInstancesFromSnapshot* = Call_CreateInstancesFromSnapshot_602206(
    name: "createInstancesFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstancesFromSnapshot",
    validator: validate_CreateInstancesFromSnapshot_602207, base: "/",
    url: url_CreateInstancesFromSnapshot_602208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateKeyPair_602221 = ref object of OpenApiRestCall_601389
proc url_CreateKeyPair_602223(protocol: Scheme; host: string; base: string;
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

proc validate_CreateKeyPair_602222(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602224 = header.getOrDefault("X-Amz-Target")
  valid_602224 = validateParameter(valid_602224, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateKeyPair"))
  if valid_602224 != nil:
    section.add "X-Amz-Target", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Signature")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Signature", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Content-Sha256", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Credential")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Credential", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Security-Token")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Security-Token", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-SignedHeaders", valid_602231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602233: Call_CreateKeyPair_602221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602233.validator(path, query, header, formData, body)
  let scheme = call_602233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602233.url(scheme.get, call_602233.host, call_602233.base,
                         call_602233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602233, url, valid)

proc call*(call_602234: Call_CreateKeyPair_602221; body: JsonNode): Recallable =
  ## createKeyPair
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602235 = newJObject()
  if body != nil:
    body_602235 = body
  result = call_602234.call(nil, nil, nil, nil, body_602235)

var createKeyPair* = Call_CreateKeyPair_602221(name: "createKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateKeyPair",
    validator: validate_CreateKeyPair_602222, base: "/", url: url_CreateKeyPair_602223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoadBalancer_602236 = ref object of OpenApiRestCall_601389
proc url_CreateLoadBalancer_602238(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLoadBalancer_602237(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602239 = header.getOrDefault("X-Amz-Target")
  valid_602239 = validateParameter(valid_602239, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateLoadBalancer"))
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

proc call*(call_602248: Call_CreateLoadBalancer_602236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see <a href="https://lightsail.aws.amazon.com/ls/docs/how-to/article/configure-lightsail-instances-for-load-balancing">Configure your Lightsail instances for load balancing</a>. You can create up to 5 load balancers per AWS Region in your account.</p> <p>When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the <code>UpdateLoadBalancerAttribute</code> operation.</p> <p>The <code>create load balancer</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602248.validator(path, query, header, formData, body)
  let scheme = call_602248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602248.url(scheme.get, call_602248.host, call_602248.base,
                         call_602248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602248, url, valid)

proc call*(call_602249: Call_CreateLoadBalancer_602236; body: JsonNode): Recallable =
  ## createLoadBalancer
  ## <p>Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see <a href="https://lightsail.aws.amazon.com/ls/docs/how-to/article/configure-lightsail-instances-for-load-balancing">Configure your Lightsail instances for load balancing</a>. You can create up to 5 load balancers per AWS Region in your account.</p> <p>When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the <code>UpdateLoadBalancerAttribute</code> operation.</p> <p>The <code>create load balancer</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602250 = newJObject()
  if body != nil:
    body_602250 = body
  result = call_602249.call(nil, nil, nil, nil, body_602250)

var createLoadBalancer* = Call_CreateLoadBalancer_602236(
    name: "createLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateLoadBalancer",
    validator: validate_CreateLoadBalancer_602237, base: "/",
    url: url_CreateLoadBalancer_602238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoadBalancerTlsCertificate_602251 = ref object of OpenApiRestCall_601389
proc url_CreateLoadBalancerTlsCertificate_602253(protocol: Scheme; host: string;
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

proc validate_CreateLoadBalancerTlsCertificate_602252(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602254 = header.getOrDefault("X-Amz-Target")
  valid_602254 = validateParameter(valid_602254, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateLoadBalancerTlsCertificate"))
  if valid_602254 != nil:
    section.add "X-Amz-Target", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Signature")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Signature", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Content-Sha256", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Date")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Date", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Credential")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Credential", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Security-Token")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Security-Token", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Algorithm")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Algorithm", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-SignedHeaders", valid_602261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602263: Call_CreateLoadBalancerTlsCertificate_602251;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>create load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602263.validator(path, query, header, formData, body)
  let scheme = call_602263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602263.url(scheme.get, call_602263.host, call_602263.base,
                         call_602263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602263, url, valid)

proc call*(call_602264: Call_CreateLoadBalancerTlsCertificate_602251;
          body: JsonNode): Recallable =
  ## createLoadBalancerTlsCertificate
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>create load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602265 = newJObject()
  if body != nil:
    body_602265 = body
  result = call_602264.call(nil, nil, nil, nil, body_602265)

var createLoadBalancerTlsCertificate* = Call_CreateLoadBalancerTlsCertificate_602251(
    name: "createLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateLoadBalancerTlsCertificate",
    validator: validate_CreateLoadBalancerTlsCertificate_602252, base: "/",
    url: url_CreateLoadBalancerTlsCertificate_602253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabase_602266 = ref object of OpenApiRestCall_601389
proc url_CreateRelationalDatabase_602268(protocol: Scheme; host: string;
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

proc validate_CreateRelationalDatabase_602267(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602269 = header.getOrDefault("X-Amz-Target")
  valid_602269 = validateParameter(valid_602269, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabase"))
  if valid_602269 != nil:
    section.add "X-Amz-Target", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Signature")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Signature", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Content-Sha256", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Date")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Date", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Credential")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Credential", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Security-Token")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Security-Token", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Algorithm")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Algorithm", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-SignedHeaders", valid_602276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602278: Call_CreateRelationalDatabase_602266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602278.validator(path, query, header, formData, body)
  let scheme = call_602278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602278.url(scheme.get, call_602278.host, call_602278.base,
                         call_602278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602278, url, valid)

proc call*(call_602279: Call_CreateRelationalDatabase_602266; body: JsonNode): Recallable =
  ## createRelationalDatabase
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602280 = newJObject()
  if body != nil:
    body_602280 = body
  result = call_602279.call(nil, nil, nil, nil, body_602280)

var createRelationalDatabase* = Call_CreateRelationalDatabase_602266(
    name: "createRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabase",
    validator: validate_CreateRelationalDatabase_602267, base: "/",
    url: url_CreateRelationalDatabase_602268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabaseFromSnapshot_602281 = ref object of OpenApiRestCall_601389
proc url_CreateRelationalDatabaseFromSnapshot_602283(protocol: Scheme;
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

proc validate_CreateRelationalDatabaseFromSnapshot_602282(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602284 = header.getOrDefault("X-Amz-Target")
  valid_602284 = validateParameter(valid_602284, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabaseFromSnapshot"))
  if valid_602284 != nil:
    section.add "X-Amz-Target", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Signature")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Signature", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Content-Sha256", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Date")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Date", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Credential")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Credential", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Security-Token")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Security-Token", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Algorithm")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Algorithm", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-SignedHeaders", valid_602291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602293: Call_CreateRelationalDatabaseFromSnapshot_602281;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new database from an existing database snapshot in Amazon Lightsail.</p> <p>You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan.</p> <p>The <code>create relational database from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602293.validator(path, query, header, formData, body)
  let scheme = call_602293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602293.url(scheme.get, call_602293.host, call_602293.base,
                         call_602293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602293, url, valid)

proc call*(call_602294: Call_CreateRelationalDatabaseFromSnapshot_602281;
          body: JsonNode): Recallable =
  ## createRelationalDatabaseFromSnapshot
  ## <p>Creates a new database from an existing database snapshot in Amazon Lightsail.</p> <p>You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan.</p> <p>The <code>create relational database from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602295 = newJObject()
  if body != nil:
    body_602295 = body
  result = call_602294.call(nil, nil, nil, nil, body_602295)

var createRelationalDatabaseFromSnapshot* = Call_CreateRelationalDatabaseFromSnapshot_602281(
    name: "createRelationalDatabaseFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabaseFromSnapshot",
    validator: validate_CreateRelationalDatabaseFromSnapshot_602282, base: "/",
    url: url_CreateRelationalDatabaseFromSnapshot_602283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabaseSnapshot_602296 = ref object of OpenApiRestCall_601389
proc url_CreateRelationalDatabaseSnapshot_602298(protocol: Scheme; host: string;
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

proc validate_CreateRelationalDatabaseSnapshot_602297(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602299 = header.getOrDefault("X-Amz-Target")
  valid_602299 = validateParameter(valid_602299, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabaseSnapshot"))
  if valid_602299 != nil:
    section.add "X-Amz-Target", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Signature")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Signature", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Content-Sha256", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Date")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Date", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Credential")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Credential", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Security-Token")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Security-Token", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Algorithm")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Algorithm", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-SignedHeaders", valid_602306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602308: Call_CreateRelationalDatabaseSnapshot_602296;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database.</p> <p>The <code>create relational database snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602308.validator(path, query, header, formData, body)
  let scheme = call_602308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602308.url(scheme.get, call_602308.host, call_602308.base,
                         call_602308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602308, url, valid)

proc call*(call_602309: Call_CreateRelationalDatabaseSnapshot_602296;
          body: JsonNode): Recallable =
  ## createRelationalDatabaseSnapshot
  ## <p>Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database.</p> <p>The <code>create relational database snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602310 = newJObject()
  if body != nil:
    body_602310 = body
  result = call_602309.call(nil, nil, nil, nil, body_602310)

var createRelationalDatabaseSnapshot* = Call_CreateRelationalDatabaseSnapshot_602296(
    name: "createRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabaseSnapshot",
    validator: validate_CreateRelationalDatabaseSnapshot_602297, base: "/",
    url: url_CreateRelationalDatabaseSnapshot_602298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAutoSnapshot_602311 = ref object of OpenApiRestCall_601389
proc url_DeleteAutoSnapshot_602313(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAutoSnapshot_602312(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602314 = header.getOrDefault("X-Amz-Target")
  valid_602314 = validateParameter(valid_602314, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteAutoSnapshot"))
  if valid_602314 != nil:
    section.add "X-Amz-Target", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Signature")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Signature", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Content-Sha256", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Date")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Date", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Credential")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Credential", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Security-Token")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Security-Token", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Algorithm")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Algorithm", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-SignedHeaders", valid_602321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602323: Call_DeleteAutoSnapshot_602311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an automatic snapshot of an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_602323.validator(path, query, header, formData, body)
  let scheme = call_602323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602323.url(scheme.get, call_602323.host, call_602323.base,
                         call_602323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602323, url, valid)

proc call*(call_602324: Call_DeleteAutoSnapshot_602311; body: JsonNode): Recallable =
  ## deleteAutoSnapshot
  ## Deletes an automatic snapshot of an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_602325 = newJObject()
  if body != nil:
    body_602325 = body
  result = call_602324.call(nil, nil, nil, nil, body_602325)

var deleteAutoSnapshot* = Call_DeleteAutoSnapshot_602311(
    name: "deleteAutoSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteAutoSnapshot",
    validator: validate_DeleteAutoSnapshot_602312, base: "/",
    url: url_DeleteAutoSnapshot_602313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDisk_602326 = ref object of OpenApiRestCall_601389
proc url_DeleteDisk_602328(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteDisk_602327(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602329 = header.getOrDefault("X-Amz-Target")
  valid_602329 = validateParameter(valid_602329, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDisk"))
  if valid_602329 != nil:
    section.add "X-Amz-Target", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Signature")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Signature", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Content-Sha256", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Date")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Date", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Credential")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Credential", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Security-Token")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Security-Token", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Algorithm")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Algorithm", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-SignedHeaders", valid_602336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602338: Call_DeleteDisk_602326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified block storage disk. The disk must be in the <code>available</code> state (not attached to a Lightsail instance).</p> <note> <p>The disk may remain in the <code>deleting</code> state for several minutes.</p> </note> <p>The <code>delete disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602338.validator(path, query, header, formData, body)
  let scheme = call_602338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602338.url(scheme.get, call_602338.host, call_602338.base,
                         call_602338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602338, url, valid)

proc call*(call_602339: Call_DeleteDisk_602326; body: JsonNode): Recallable =
  ## deleteDisk
  ## <p>Deletes the specified block storage disk. The disk must be in the <code>available</code> state (not attached to a Lightsail instance).</p> <note> <p>The disk may remain in the <code>deleting</code> state for several minutes.</p> </note> <p>The <code>delete disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602340 = newJObject()
  if body != nil:
    body_602340 = body
  result = call_602339.call(nil, nil, nil, nil, body_602340)

var deleteDisk* = Call_DeleteDisk_602326(name: "deleteDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteDisk",
                                      validator: validate_DeleteDisk_602327,
                                      base: "/", url: url_DeleteDisk_602328,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiskSnapshot_602341 = ref object of OpenApiRestCall_601389
proc url_DeleteDiskSnapshot_602343(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDiskSnapshot_602342(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602344 = header.getOrDefault("X-Amz-Target")
  valid_602344 = validateParameter(valid_602344, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDiskSnapshot"))
  if valid_602344 != nil:
    section.add "X-Amz-Target", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Signature")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Signature", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Content-Sha256", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Date")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Date", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Credential")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Credential", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Security-Token")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Security-Token", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Algorithm")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Algorithm", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-SignedHeaders", valid_602351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602353: Call_DeleteDiskSnapshot_602341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified disk snapshot.</p> <p>When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk.</p> <p>The <code>delete disk snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602353.validator(path, query, header, formData, body)
  let scheme = call_602353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602353.url(scheme.get, call_602353.host, call_602353.base,
                         call_602353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602353, url, valid)

proc call*(call_602354: Call_DeleteDiskSnapshot_602341; body: JsonNode): Recallable =
  ## deleteDiskSnapshot
  ## <p>Deletes the specified disk snapshot.</p> <p>When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk.</p> <p>The <code>delete disk snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602355 = newJObject()
  if body != nil:
    body_602355 = body
  result = call_602354.call(nil, nil, nil, nil, body_602355)

var deleteDiskSnapshot* = Call_DeleteDiskSnapshot_602341(
    name: "deleteDiskSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDiskSnapshot",
    validator: validate_DeleteDiskSnapshot_602342, base: "/",
    url: url_DeleteDiskSnapshot_602343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_602356 = ref object of OpenApiRestCall_601389
proc url_DeleteDomain_602358(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomain_602357(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602359 = header.getOrDefault("X-Amz-Target")
  valid_602359 = validateParameter(valid_602359, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDomain"))
  if valid_602359 != nil:
    section.add "X-Amz-Target", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Signature")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Signature", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Content-Sha256", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Date")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Date", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Credential")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Credential", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Security-Token")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Security-Token", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Algorithm")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Algorithm", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-SignedHeaders", valid_602366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602368: Call_DeleteDomain_602356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602368.validator(path, query, header, formData, body)
  let scheme = call_602368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602368.url(scheme.get, call_602368.host, call_602368.base,
                         call_602368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602368, url, valid)

proc call*(call_602369: Call_DeleteDomain_602356; body: JsonNode): Recallable =
  ## deleteDomain
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602370 = newJObject()
  if body != nil:
    body_602370 = body
  result = call_602369.call(nil, nil, nil, nil, body_602370)

var deleteDomain* = Call_DeleteDomain_602356(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDomain",
    validator: validate_DeleteDomain_602357, base: "/", url: url_DeleteDomain_602358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainEntry_602371 = ref object of OpenApiRestCall_601389
proc url_DeleteDomainEntry_602373(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainEntry_602372(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602374 = header.getOrDefault("X-Amz-Target")
  valid_602374 = validateParameter(valid_602374, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDomainEntry"))
  if valid_602374 != nil:
    section.add "X-Amz-Target", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Signature")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Signature", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Content-Sha256", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Date")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Date", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Credential")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Credential", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Security-Token")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Security-Token", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Algorithm")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Algorithm", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-SignedHeaders", valid_602381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602383: Call_DeleteDomainEntry_602371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific domain entry.</p> <p>The <code>delete domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602383.validator(path, query, header, formData, body)
  let scheme = call_602383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602383.url(scheme.get, call_602383.host, call_602383.base,
                         call_602383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602383, url, valid)

proc call*(call_602384: Call_DeleteDomainEntry_602371; body: JsonNode): Recallable =
  ## deleteDomainEntry
  ## <p>Deletes a specific domain entry.</p> <p>The <code>delete domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602385 = newJObject()
  if body != nil:
    body_602385 = body
  result = call_602384.call(nil, nil, nil, nil, body_602385)

var deleteDomainEntry* = Call_DeleteDomainEntry_602371(name: "deleteDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDomainEntry",
    validator: validate_DeleteDomainEntry_602372, base: "/",
    url: url_DeleteDomainEntry_602373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstance_602386 = ref object of OpenApiRestCall_601389
proc url_DeleteInstance_602388(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInstance_602387(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602389 = header.getOrDefault("X-Amz-Target")
  valid_602389 = validateParameter(valid_602389, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteInstance"))
  if valid_602389 != nil:
    section.add "X-Amz-Target", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Signature")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Signature", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Content-Sha256", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Date")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Date", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-Credential")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Credential", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Security-Token")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Security-Token", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Algorithm")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Algorithm", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-SignedHeaders", valid_602396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602398: Call_DeleteInstance_602386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an Amazon Lightsail instance.</p> <p>The <code>delete instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602398.validator(path, query, header, formData, body)
  let scheme = call_602398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602398.url(scheme.get, call_602398.host, call_602398.base,
                         call_602398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602398, url, valid)

proc call*(call_602399: Call_DeleteInstance_602386; body: JsonNode): Recallable =
  ## deleteInstance
  ## <p>Deletes an Amazon Lightsail instance.</p> <p>The <code>delete instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602400 = newJObject()
  if body != nil:
    body_602400 = body
  result = call_602399.call(nil, nil, nil, nil, body_602400)

var deleteInstance* = Call_DeleteInstance_602386(name: "deleteInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteInstance",
    validator: validate_DeleteInstance_602387, base: "/", url: url_DeleteInstance_602388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceSnapshot_602401 = ref object of OpenApiRestCall_601389
proc url_DeleteInstanceSnapshot_602403(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInstanceSnapshot_602402(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602404 = header.getOrDefault("X-Amz-Target")
  valid_602404 = validateParameter(valid_602404, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteInstanceSnapshot"))
  if valid_602404 != nil:
    section.add "X-Amz-Target", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Signature")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Signature", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Content-Sha256", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Date")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Date", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Credential")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Credential", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Security-Token")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Security-Token", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Algorithm")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Algorithm", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-SignedHeaders", valid_602411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602413: Call_DeleteInstanceSnapshot_602401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific snapshot of a virtual private server (or <i>instance</i>).</p> <p>The <code>delete instance snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602413.validator(path, query, header, formData, body)
  let scheme = call_602413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602413.url(scheme.get, call_602413.host, call_602413.base,
                         call_602413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602413, url, valid)

proc call*(call_602414: Call_DeleteInstanceSnapshot_602401; body: JsonNode): Recallable =
  ## deleteInstanceSnapshot
  ## <p>Deletes a specific snapshot of a virtual private server (or <i>instance</i>).</p> <p>The <code>delete instance snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602415 = newJObject()
  if body != nil:
    body_602415 = body
  result = call_602414.call(nil, nil, nil, nil, body_602415)

var deleteInstanceSnapshot* = Call_DeleteInstanceSnapshot_602401(
    name: "deleteInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteInstanceSnapshot",
    validator: validate_DeleteInstanceSnapshot_602402, base: "/",
    url: url_DeleteInstanceSnapshot_602403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteKeyPair_602416 = ref object of OpenApiRestCall_601389
proc url_DeleteKeyPair_602418(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteKeyPair_602417(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602419 = header.getOrDefault("X-Amz-Target")
  valid_602419 = validateParameter(valid_602419, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteKeyPair"))
  if valid_602419 != nil:
    section.add "X-Amz-Target", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Signature")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Signature", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Content-Sha256", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Date")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Date", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-Credential")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Credential", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Security-Token")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Security-Token", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Algorithm")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Algorithm", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-SignedHeaders", valid_602426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602428: Call_DeleteKeyPair_602416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602428.validator(path, query, header, formData, body)
  let scheme = call_602428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602428.url(scheme.get, call_602428.host, call_602428.base,
                         call_602428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602428, url, valid)

proc call*(call_602429: Call_DeleteKeyPair_602416; body: JsonNode): Recallable =
  ## deleteKeyPair
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602430 = newJObject()
  if body != nil:
    body_602430 = body
  result = call_602429.call(nil, nil, nil, nil, body_602430)

var deleteKeyPair* = Call_DeleteKeyPair_602416(name: "deleteKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteKeyPair",
    validator: validate_DeleteKeyPair_602417, base: "/", url: url_DeleteKeyPair_602418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteKnownHostKeys_602431 = ref object of OpenApiRestCall_601389
proc url_DeleteKnownHostKeys_602433(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteKnownHostKeys_602432(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602434 = header.getOrDefault("X-Amz-Target")
  valid_602434 = validateParameter(valid_602434, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteKnownHostKeys"))
  if valid_602434 != nil:
    section.add "X-Amz-Target", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Signature")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Signature", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Content-Sha256", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Date")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Date", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Credential")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Credential", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Security-Token")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Security-Token", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Algorithm")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Algorithm", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-SignedHeaders", valid_602441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602443: Call_DeleteKnownHostKeys_602431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch.</p> <important> <p>Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection">Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client</a>.</p> </important>
  ## 
  let valid = call_602443.validator(path, query, header, formData, body)
  let scheme = call_602443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602443.url(scheme.get, call_602443.host, call_602443.base,
                         call_602443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602443, url, valid)

proc call*(call_602444: Call_DeleteKnownHostKeys_602431; body: JsonNode): Recallable =
  ## deleteKnownHostKeys
  ## <p>Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch.</p> <important> <p>Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection">Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client</a>.</p> </important>
  ##   body: JObject (required)
  var body_602445 = newJObject()
  if body != nil:
    body_602445 = body
  result = call_602444.call(nil, nil, nil, nil, body_602445)

var deleteKnownHostKeys* = Call_DeleteKnownHostKeys_602431(
    name: "deleteKnownHostKeys", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteKnownHostKeys",
    validator: validate_DeleteKnownHostKeys_602432, base: "/",
    url: url_DeleteKnownHostKeys_602433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoadBalancer_602446 = ref object of OpenApiRestCall_601389
proc url_DeleteLoadBalancer_602448(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLoadBalancer_602447(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602449 = header.getOrDefault("X-Amz-Target")
  valid_602449 = validateParameter(valid_602449, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteLoadBalancer"))
  if valid_602449 != nil:
    section.add "X-Amz-Target", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Signature")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Signature", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Content-Sha256", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Date")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Date", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Credential")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Credential", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Security-Token")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Security-Token", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Algorithm")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Algorithm", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-SignedHeaders", valid_602456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602458: Call_DeleteLoadBalancer_602446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again.</p> <p>The <code>delete load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602458.validator(path, query, header, formData, body)
  let scheme = call_602458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602458.url(scheme.get, call_602458.host, call_602458.base,
                         call_602458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602458, url, valid)

proc call*(call_602459: Call_DeleteLoadBalancer_602446; body: JsonNode): Recallable =
  ## deleteLoadBalancer
  ## <p>Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again.</p> <p>The <code>delete load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602460 = newJObject()
  if body != nil:
    body_602460 = body
  result = call_602459.call(nil, nil, nil, nil, body_602460)

var deleteLoadBalancer* = Call_DeleteLoadBalancer_602446(
    name: "deleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteLoadBalancer",
    validator: validate_DeleteLoadBalancer_602447, base: "/",
    url: url_DeleteLoadBalancer_602448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoadBalancerTlsCertificate_602461 = ref object of OpenApiRestCall_601389
proc url_DeleteLoadBalancerTlsCertificate_602463(protocol: Scheme; host: string;
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

proc validate_DeleteLoadBalancerTlsCertificate_602462(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602464 = header.getOrDefault("X-Amz-Target")
  valid_602464 = validateParameter(valid_602464, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteLoadBalancerTlsCertificate"))
  if valid_602464 != nil:
    section.add "X-Amz-Target", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Signature")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Signature", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Content-Sha256", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Date")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Date", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-Credential")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Credential", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Security-Token")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Security-Token", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Algorithm")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Algorithm", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-SignedHeaders", valid_602471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602473: Call_DeleteLoadBalancerTlsCertificate_602461;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>delete load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602473.validator(path, query, header, formData, body)
  let scheme = call_602473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602473.url(scheme.get, call_602473.host, call_602473.base,
                         call_602473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602473, url, valid)

proc call*(call_602474: Call_DeleteLoadBalancerTlsCertificate_602461;
          body: JsonNode): Recallable =
  ## deleteLoadBalancerTlsCertificate
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>delete load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602475 = newJObject()
  if body != nil:
    body_602475 = body
  result = call_602474.call(nil, nil, nil, nil, body_602475)

var deleteLoadBalancerTlsCertificate* = Call_DeleteLoadBalancerTlsCertificate_602461(
    name: "deleteLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteLoadBalancerTlsCertificate",
    validator: validate_DeleteLoadBalancerTlsCertificate_602462, base: "/",
    url: url_DeleteLoadBalancerTlsCertificate_602463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRelationalDatabase_602476 = ref object of OpenApiRestCall_601389
proc url_DeleteRelationalDatabase_602478(protocol: Scheme; host: string;
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

proc validate_DeleteRelationalDatabase_602477(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602479 = header.getOrDefault("X-Amz-Target")
  valid_602479 = validateParameter(valid_602479, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteRelationalDatabase"))
  if valid_602479 != nil:
    section.add "X-Amz-Target", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Signature")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Signature", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Content-Sha256", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Date")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Date", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-Credential")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Credential", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Security-Token")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Security-Token", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Algorithm")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Algorithm", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-SignedHeaders", valid_602486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602488: Call_DeleteRelationalDatabase_602476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602488.validator(path, query, header, formData, body)
  let scheme = call_602488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602488.url(scheme.get, call_602488.host, call_602488.base,
                         call_602488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602488, url, valid)

proc call*(call_602489: Call_DeleteRelationalDatabase_602476; body: JsonNode): Recallable =
  ## deleteRelationalDatabase
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602490 = newJObject()
  if body != nil:
    body_602490 = body
  result = call_602489.call(nil, nil, nil, nil, body_602490)

var deleteRelationalDatabase* = Call_DeleteRelationalDatabase_602476(
    name: "deleteRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteRelationalDatabase",
    validator: validate_DeleteRelationalDatabase_602477, base: "/",
    url: url_DeleteRelationalDatabase_602478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRelationalDatabaseSnapshot_602491 = ref object of OpenApiRestCall_601389
proc url_DeleteRelationalDatabaseSnapshot_602493(protocol: Scheme; host: string;
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

proc validate_DeleteRelationalDatabaseSnapshot_602492(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602494 = header.getOrDefault("X-Amz-Target")
  valid_602494 = validateParameter(valid_602494, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteRelationalDatabaseSnapshot"))
  if valid_602494 != nil:
    section.add "X-Amz-Target", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Signature")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Signature", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Content-Sha256", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Date")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Date", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Credential")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Credential", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Security-Token")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Security-Token", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Algorithm")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Algorithm", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-SignedHeaders", valid_602501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602503: Call_DeleteRelationalDatabaseSnapshot_602491;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes a database snapshot in Amazon Lightsail.</p> <p>The <code>delete relational database snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602503.validator(path, query, header, formData, body)
  let scheme = call_602503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602503.url(scheme.get, call_602503.host, call_602503.base,
                         call_602503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602503, url, valid)

proc call*(call_602504: Call_DeleteRelationalDatabaseSnapshot_602491;
          body: JsonNode): Recallable =
  ## deleteRelationalDatabaseSnapshot
  ## <p>Deletes a database snapshot in Amazon Lightsail.</p> <p>The <code>delete relational database snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602505 = newJObject()
  if body != nil:
    body_602505 = body
  result = call_602504.call(nil, nil, nil, nil, body_602505)

var deleteRelationalDatabaseSnapshot* = Call_DeleteRelationalDatabaseSnapshot_602491(
    name: "deleteRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteRelationalDatabaseSnapshot",
    validator: validate_DeleteRelationalDatabaseSnapshot_602492, base: "/",
    url: url_DeleteRelationalDatabaseSnapshot_602493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachDisk_602506 = ref object of OpenApiRestCall_601389
proc url_DetachDisk_602508(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DetachDisk_602507(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602509 = header.getOrDefault("X-Amz-Target")
  valid_602509 = validateParameter(valid_602509, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachDisk"))
  if valid_602509 != nil:
    section.add "X-Amz-Target", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Signature")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Signature", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Content-Sha256", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Date")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Date", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Credential")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Credential", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Security-Token")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Security-Token", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-Algorithm")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-Algorithm", valid_602515
  var valid_602516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "X-Amz-SignedHeaders", valid_602516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602518: Call_DetachDisk_602506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk.</p> <p>The <code>detach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602518.validator(path, query, header, formData, body)
  let scheme = call_602518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602518.url(scheme.get, call_602518.host, call_602518.base,
                         call_602518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602518, url, valid)

proc call*(call_602519: Call_DetachDisk_602506; body: JsonNode): Recallable =
  ## detachDisk
  ## <p>Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk.</p> <p>The <code>detach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602520 = newJObject()
  if body != nil:
    body_602520 = body
  result = call_602519.call(nil, nil, nil, nil, body_602520)

var detachDisk* = Call_DetachDisk_602506(name: "detachDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DetachDisk",
                                      validator: validate_DetachDisk_602507,
                                      base: "/", url: url_DetachDisk_602508,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachInstancesFromLoadBalancer_602521 = ref object of OpenApiRestCall_601389
proc url_DetachInstancesFromLoadBalancer_602523(protocol: Scheme; host: string;
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

proc validate_DetachInstancesFromLoadBalancer_602522(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602524 = header.getOrDefault("X-Amz-Target")
  valid_602524 = validateParameter(valid_602524, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachInstancesFromLoadBalancer"))
  if valid_602524 != nil:
    section.add "X-Amz-Target", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Signature")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Signature", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Content-Sha256", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-Date")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-Date", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-Credential")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Credential", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-Security-Token")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Security-Token", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-Algorithm")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Algorithm", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-SignedHeaders", valid_602531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602533: Call_DetachInstancesFromLoadBalancer_602521;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Detaches the specified instances from a Lightsail load balancer.</p> <p>This operation waits until the instances are no longer needed before they are detached from the load balancer.</p> <p>The <code>detach instances from load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602533.validator(path, query, header, formData, body)
  let scheme = call_602533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602533.url(scheme.get, call_602533.host, call_602533.base,
                         call_602533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602533, url, valid)

proc call*(call_602534: Call_DetachInstancesFromLoadBalancer_602521; body: JsonNode): Recallable =
  ## detachInstancesFromLoadBalancer
  ## <p>Detaches the specified instances from a Lightsail load balancer.</p> <p>This operation waits until the instances are no longer needed before they are detached from the load balancer.</p> <p>The <code>detach instances from load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602535 = newJObject()
  if body != nil:
    body_602535 = body
  result = call_602534.call(nil, nil, nil, nil, body_602535)

var detachInstancesFromLoadBalancer* = Call_DetachInstancesFromLoadBalancer_602521(
    name: "detachInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DetachInstancesFromLoadBalancer",
    validator: validate_DetachInstancesFromLoadBalancer_602522, base: "/",
    url: url_DetachInstancesFromLoadBalancer_602523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachStaticIp_602536 = ref object of OpenApiRestCall_601389
proc url_DetachStaticIp_602538(protocol: Scheme; host: string; base: string;
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

proc validate_DetachStaticIp_602537(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602539 = header.getOrDefault("X-Amz-Target")
  valid_602539 = validateParameter(valid_602539, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachStaticIp"))
  if valid_602539 != nil:
    section.add "X-Amz-Target", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Signature")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Signature", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Content-Sha256", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Date")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Date", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Credential")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Credential", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Security-Token")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Security-Token", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Algorithm")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Algorithm", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-SignedHeaders", valid_602546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602548: Call_DetachStaticIp_602536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a static IP from the Amazon Lightsail instance to which it is attached.
  ## 
  let valid = call_602548.validator(path, query, header, formData, body)
  let scheme = call_602548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602548.url(scheme.get, call_602548.host, call_602548.base,
                         call_602548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602548, url, valid)

proc call*(call_602549: Call_DetachStaticIp_602536; body: JsonNode): Recallable =
  ## detachStaticIp
  ## Detaches a static IP from the Amazon Lightsail instance to which it is attached.
  ##   body: JObject (required)
  var body_602550 = newJObject()
  if body != nil:
    body_602550 = body
  result = call_602549.call(nil, nil, nil, nil, body_602550)

var detachStaticIp* = Call_DetachStaticIp_602536(name: "detachStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DetachStaticIp",
    validator: validate_DetachStaticIp_602537, base: "/", url: url_DetachStaticIp_602538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAddOn_602551 = ref object of OpenApiRestCall_601389
proc url_DisableAddOn_602553(protocol: Scheme; host: string; base: string;
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

proc validate_DisableAddOn_602552(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602554 = header.getOrDefault("X-Amz-Target")
  valid_602554 = validateParameter(valid_602554, JString, required = true, default = newJString(
      "Lightsail_20161128.DisableAddOn"))
  if valid_602554 != nil:
    section.add "X-Amz-Target", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Signature")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Signature", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Content-Sha256", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Date")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Date", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-Credential")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-Credential", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Security-Token")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Security-Token", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Algorithm")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Algorithm", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-SignedHeaders", valid_602561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602563: Call_DisableAddOn_602551; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_602563.validator(path, query, header, formData, body)
  let scheme = call_602563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602563.url(scheme.get, call_602563.host, call_602563.base,
                         call_602563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602563, url, valid)

proc call*(call_602564: Call_DisableAddOn_602551; body: JsonNode): Recallable =
  ## disableAddOn
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_602565 = newJObject()
  if body != nil:
    body_602565 = body
  result = call_602564.call(nil, nil, nil, nil, body_602565)

var disableAddOn* = Call_DisableAddOn_602551(name: "disableAddOn",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DisableAddOn",
    validator: validate_DisableAddOn_602552, base: "/", url: url_DisableAddOn_602553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DownloadDefaultKeyPair_602566 = ref object of OpenApiRestCall_601389
proc url_DownloadDefaultKeyPair_602568(protocol: Scheme; host: string; base: string;
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

proc validate_DownloadDefaultKeyPair_602567(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602569 = header.getOrDefault("X-Amz-Target")
  valid_602569 = validateParameter(valid_602569, JString, required = true, default = newJString(
      "Lightsail_20161128.DownloadDefaultKeyPair"))
  if valid_602569 != nil:
    section.add "X-Amz-Target", valid_602569
  var valid_602570 = header.getOrDefault("X-Amz-Signature")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "X-Amz-Signature", valid_602570
  var valid_602571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "X-Amz-Content-Sha256", valid_602571
  var valid_602572 = header.getOrDefault("X-Amz-Date")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "X-Amz-Date", valid_602572
  var valid_602573 = header.getOrDefault("X-Amz-Credential")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "X-Amz-Credential", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-Security-Token")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-Security-Token", valid_602574
  var valid_602575 = header.getOrDefault("X-Amz-Algorithm")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Algorithm", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-SignedHeaders", valid_602576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602578: Call_DownloadDefaultKeyPair_602566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Downloads the default SSH key pair from the user's account.
  ## 
  let valid = call_602578.validator(path, query, header, formData, body)
  let scheme = call_602578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602578.url(scheme.get, call_602578.host, call_602578.base,
                         call_602578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602578, url, valid)

proc call*(call_602579: Call_DownloadDefaultKeyPair_602566; body: JsonNode): Recallable =
  ## downloadDefaultKeyPair
  ## Downloads the default SSH key pair from the user's account.
  ##   body: JObject (required)
  var body_602580 = newJObject()
  if body != nil:
    body_602580 = body
  result = call_602579.call(nil, nil, nil, nil, body_602580)

var downloadDefaultKeyPair* = Call_DownloadDefaultKeyPair_602566(
    name: "downloadDefaultKeyPair", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DownloadDefaultKeyPair",
    validator: validate_DownloadDefaultKeyPair_602567, base: "/",
    url: url_DownloadDefaultKeyPair_602568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAddOn_602581 = ref object of OpenApiRestCall_601389
proc url_EnableAddOn_602583(protocol: Scheme; host: string; base: string;
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

proc validate_EnableAddOn_602582(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602584 = header.getOrDefault("X-Amz-Target")
  valid_602584 = validateParameter(valid_602584, JString, required = true, default = newJString(
      "Lightsail_20161128.EnableAddOn"))
  if valid_602584 != nil:
    section.add "X-Amz-Target", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Signature")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Signature", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Content-Sha256", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-Date")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Date", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Credential")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Credential", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Security-Token")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Security-Token", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Algorithm")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Algorithm", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-SignedHeaders", valid_602591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602593: Call_EnableAddOn_602581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_602593.validator(path, query, header, formData, body)
  let scheme = call_602593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602593.url(scheme.get, call_602593.host, call_602593.base,
                         call_602593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602593, url, valid)

proc call*(call_602594: Call_EnableAddOn_602581; body: JsonNode): Recallable =
  ## enableAddOn
  ## Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_602595 = newJObject()
  if body != nil:
    body_602595 = body
  result = call_602594.call(nil, nil, nil, nil, body_602595)

var enableAddOn* = Call_EnableAddOn_602581(name: "enableAddOn",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.EnableAddOn",
                                        validator: validate_EnableAddOn_602582,
                                        base: "/", url: url_EnableAddOn_602583,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportSnapshot_602596 = ref object of OpenApiRestCall_601389
proc url_ExportSnapshot_602598(protocol: Scheme; host: string; base: string;
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

proc validate_ExportSnapshot_602597(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602599 = header.getOrDefault("X-Amz-Target")
  valid_602599 = validateParameter(valid_602599, JString, required = true, default = newJString(
      "Lightsail_20161128.ExportSnapshot"))
  if valid_602599 != nil:
    section.add "X-Amz-Target", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Signature")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Signature", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-Content-Sha256", valid_602601
  var valid_602602 = header.getOrDefault("X-Amz-Date")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-Date", valid_602602
  var valid_602603 = header.getOrDefault("X-Amz-Credential")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-Credential", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-Security-Token")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Security-Token", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-Algorithm")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Algorithm", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-SignedHeaders", valid_602606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602608: Call_ExportSnapshot_602596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the <code>create cloud formation stack</code> operation to create new Amazon EC2 instances.</p> <p>Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot.</p> <p/> <p>The <code>export snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>source snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p> <note> <p>Use the <code>get instance snapshots</code> or <code>get disk snapshots</code> operations to get a list of snapshots that you can export to Amazon EC2.</p> </note>
  ## 
  let valid = call_602608.validator(path, query, header, formData, body)
  let scheme = call_602608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602608.url(scheme.get, call_602608.host, call_602608.base,
                         call_602608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602608, url, valid)

proc call*(call_602609: Call_ExportSnapshot_602596; body: JsonNode): Recallable =
  ## exportSnapshot
  ## <p>Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the <code>create cloud formation stack</code> operation to create new Amazon EC2 instances.</p> <p>Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot.</p> <p/> <p>The <code>export snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>source snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p> <note> <p>Use the <code>get instance snapshots</code> or <code>get disk snapshots</code> operations to get a list of snapshots that you can export to Amazon EC2.</p> </note>
  ##   body: JObject (required)
  var body_602610 = newJObject()
  if body != nil:
    body_602610 = body
  result = call_602609.call(nil, nil, nil, nil, body_602610)

var exportSnapshot* = Call_ExportSnapshot_602596(name: "exportSnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ExportSnapshot",
    validator: validate_ExportSnapshot_602597, base: "/", url: url_ExportSnapshot_602598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetActiveNames_602611 = ref object of OpenApiRestCall_601389
proc url_GetActiveNames_602613(protocol: Scheme; host: string; base: string;
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

proc validate_GetActiveNames_602612(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602614 = header.getOrDefault("X-Amz-Target")
  valid_602614 = validateParameter(valid_602614, JString, required = true, default = newJString(
      "Lightsail_20161128.GetActiveNames"))
  if valid_602614 != nil:
    section.add "X-Amz-Target", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-Signature")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Signature", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Content-Sha256", valid_602616
  var valid_602617 = header.getOrDefault("X-Amz-Date")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-Date", valid_602617
  var valid_602618 = header.getOrDefault("X-Amz-Credential")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "X-Amz-Credential", valid_602618
  var valid_602619 = header.getOrDefault("X-Amz-Security-Token")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "X-Amz-Security-Token", valid_602619
  var valid_602620 = header.getOrDefault("X-Amz-Algorithm")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-Algorithm", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-SignedHeaders", valid_602621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602623: Call_GetActiveNames_602611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the names of all active (not deleted) resources.
  ## 
  let valid = call_602623.validator(path, query, header, formData, body)
  let scheme = call_602623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602623.url(scheme.get, call_602623.host, call_602623.base,
                         call_602623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602623, url, valid)

proc call*(call_602624: Call_GetActiveNames_602611; body: JsonNode): Recallable =
  ## getActiveNames
  ## Returns the names of all active (not deleted) resources.
  ##   body: JObject (required)
  var body_602625 = newJObject()
  if body != nil:
    body_602625 = body
  result = call_602624.call(nil, nil, nil, nil, body_602625)

var getActiveNames* = Call_GetActiveNames_602611(name: "getActiveNames",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetActiveNames",
    validator: validate_GetActiveNames_602612, base: "/", url: url_GetActiveNames_602613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutoSnapshots_602626 = ref object of OpenApiRestCall_601389
proc url_GetAutoSnapshots_602628(protocol: Scheme; host: string; base: string;
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

proc validate_GetAutoSnapshots_602627(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602629 = header.getOrDefault("X-Amz-Target")
  valid_602629 = validateParameter(valid_602629, JString, required = true, default = newJString(
      "Lightsail_20161128.GetAutoSnapshots"))
  if valid_602629 != nil:
    section.add "X-Amz-Target", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Signature")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Signature", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Content-Sha256", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-Date")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-Date", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-Credential")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Credential", valid_602633
  var valid_602634 = header.getOrDefault("X-Amz-Security-Token")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-Security-Token", valid_602634
  var valid_602635 = header.getOrDefault("X-Amz-Algorithm")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-Algorithm", valid_602635
  var valid_602636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-SignedHeaders", valid_602636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602638: Call_GetAutoSnapshots_602626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the available automatic snapshots for an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_602638.validator(path, query, header, formData, body)
  let scheme = call_602638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602638.url(scheme.get, call_602638.host, call_602638.base,
                         call_602638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602638, url, valid)

proc call*(call_602639: Call_GetAutoSnapshots_602626; body: JsonNode): Recallable =
  ## getAutoSnapshots
  ## Returns the available automatic snapshots for an instance or disk. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_602640 = newJObject()
  if body != nil:
    body_602640 = body
  result = call_602639.call(nil, nil, nil, nil, body_602640)

var getAutoSnapshots* = Call_GetAutoSnapshots_602626(name: "getAutoSnapshots",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetAutoSnapshots",
    validator: validate_GetAutoSnapshots_602627, base: "/",
    url: url_GetAutoSnapshots_602628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlueprints_602641 = ref object of OpenApiRestCall_601389
proc url_GetBlueprints_602643(protocol: Scheme; host: string; base: string;
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

proc validate_GetBlueprints_602642(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602644 = header.getOrDefault("X-Amz-Target")
  valid_602644 = validateParameter(valid_602644, JString, required = true, default = newJString(
      "Lightsail_20161128.GetBlueprints"))
  if valid_602644 != nil:
    section.add "X-Amz-Target", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Signature")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Signature", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Content-Sha256", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-Date")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Date", valid_602647
  var valid_602648 = header.getOrDefault("X-Amz-Credential")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Credential", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Security-Token")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Security-Token", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Algorithm")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Algorithm", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-SignedHeaders", valid_602651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602653: Call_GetBlueprints_602641; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
  ## 
  let valid = call_602653.validator(path, query, header, formData, body)
  let scheme = call_602653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602653.url(scheme.get, call_602653.host, call_602653.base,
                         call_602653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602653, url, valid)

proc call*(call_602654: Call_GetBlueprints_602641; body: JsonNode): Recallable =
  ## getBlueprints
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
  ##   body: JObject (required)
  var body_602655 = newJObject()
  if body != nil:
    body_602655 = body
  result = call_602654.call(nil, nil, nil, nil, body_602655)

var getBlueprints* = Call_GetBlueprints_602641(name: "getBlueprints",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetBlueprints",
    validator: validate_GetBlueprints_602642, base: "/", url: url_GetBlueprints_602643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBundles_602656 = ref object of OpenApiRestCall_601389
proc url_GetBundles_602658(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBundles_602657(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602659 = header.getOrDefault("X-Amz-Target")
  valid_602659 = validateParameter(valid_602659, JString, required = true, default = newJString(
      "Lightsail_20161128.GetBundles"))
  if valid_602659 != nil:
    section.add "X-Amz-Target", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Signature")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Signature", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Content-Sha256", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-Date")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Date", valid_602662
  var valid_602663 = header.getOrDefault("X-Amz-Credential")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-Credential", valid_602663
  var valid_602664 = header.getOrDefault("X-Amz-Security-Token")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "X-Amz-Security-Token", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-Algorithm")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Algorithm", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-SignedHeaders", valid_602666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602668: Call_GetBundles_602656; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of bundles that are available for purchase. A bundle describes the specs for your virtual private server (or <i>instance</i>).
  ## 
  let valid = call_602668.validator(path, query, header, formData, body)
  let scheme = call_602668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602668.url(scheme.get, call_602668.host, call_602668.base,
                         call_602668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602668, url, valid)

proc call*(call_602669: Call_GetBundles_602656; body: JsonNode): Recallable =
  ## getBundles
  ## Returns the list of bundles that are available for purchase. A bundle describes the specs for your virtual private server (or <i>instance</i>).
  ##   body: JObject (required)
  var body_602670 = newJObject()
  if body != nil:
    body_602670 = body
  result = call_602669.call(nil, nil, nil, nil, body_602670)

var getBundles* = Call_GetBundles_602656(name: "getBundles",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetBundles",
                                      validator: validate_GetBundles_602657,
                                      base: "/", url: url_GetBundles_602658,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFormationStackRecords_602671 = ref object of OpenApiRestCall_601389
proc url_GetCloudFormationStackRecords_602673(protocol: Scheme; host: string;
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

proc validate_GetCloudFormationStackRecords_602672(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602674 = header.getOrDefault("X-Amz-Target")
  valid_602674 = validateParameter(valid_602674, JString, required = true, default = newJString(
      "Lightsail_20161128.GetCloudFormationStackRecords"))
  if valid_602674 != nil:
    section.add "X-Amz-Target", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Signature")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Signature", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Content-Sha256", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Date")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Date", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Credential")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Credential", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Security-Token")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Security-Token", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-Algorithm")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-Algorithm", valid_602680
  var valid_602681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-SignedHeaders", valid_602681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602683: Call_GetCloudFormationStackRecords_602671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the CloudFormation stack record created as a result of the <code>create cloud formation stack</code> operation.</p> <p>An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.</p>
  ## 
  let valid = call_602683.validator(path, query, header, formData, body)
  let scheme = call_602683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602683.url(scheme.get, call_602683.host, call_602683.base,
                         call_602683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602683, url, valid)

proc call*(call_602684: Call_GetCloudFormationStackRecords_602671; body: JsonNode): Recallable =
  ## getCloudFormationStackRecords
  ## <p>Returns the CloudFormation stack record created as a result of the <code>create cloud formation stack</code> operation.</p> <p>An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.</p>
  ##   body: JObject (required)
  var body_602685 = newJObject()
  if body != nil:
    body_602685 = body
  result = call_602684.call(nil, nil, nil, nil, body_602685)

var getCloudFormationStackRecords* = Call_GetCloudFormationStackRecords_602671(
    name: "getCloudFormationStackRecords", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetCloudFormationStackRecords",
    validator: validate_GetCloudFormationStackRecords_602672, base: "/",
    url: url_GetCloudFormationStackRecords_602673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisk_602686 = ref object of OpenApiRestCall_601389
proc url_GetDisk_602688(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDisk_602687(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602689 = header.getOrDefault("X-Amz-Target")
  valid_602689 = validateParameter(valid_602689, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDisk"))
  if valid_602689 != nil:
    section.add "X-Amz-Target", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Signature")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Signature", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Content-Sha256", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Date")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Date", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Credential")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Credential", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-Security-Token")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Security-Token", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-Algorithm")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-Algorithm", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-SignedHeaders", valid_602696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602698: Call_GetDisk_602686; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific block storage disk.
  ## 
  let valid = call_602698.validator(path, query, header, formData, body)
  let scheme = call_602698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602698.url(scheme.get, call_602698.host, call_602698.base,
                         call_602698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602698, url, valid)

proc call*(call_602699: Call_GetDisk_602686; body: JsonNode): Recallable =
  ## getDisk
  ## Returns information about a specific block storage disk.
  ##   body: JObject (required)
  var body_602700 = newJObject()
  if body != nil:
    body_602700 = body
  result = call_602699.call(nil, nil, nil, nil, body_602700)

var getDisk* = Call_GetDisk_602686(name: "getDisk", meth: HttpMethod.HttpPost,
                                host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDisk",
                                validator: validate_GetDisk_602687, base: "/",
                                url: url_GetDisk_602688,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiskSnapshot_602701 = ref object of OpenApiRestCall_601389
proc url_GetDiskSnapshot_602703(protocol: Scheme; host: string; base: string;
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

proc validate_GetDiskSnapshot_602702(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602704 = header.getOrDefault("X-Amz-Target")
  valid_602704 = validateParameter(valid_602704, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDiskSnapshot"))
  if valid_602704 != nil:
    section.add "X-Amz-Target", valid_602704
  var valid_602705 = header.getOrDefault("X-Amz-Signature")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "X-Amz-Signature", valid_602705
  var valid_602706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-Content-Sha256", valid_602706
  var valid_602707 = header.getOrDefault("X-Amz-Date")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "X-Amz-Date", valid_602707
  var valid_602708 = header.getOrDefault("X-Amz-Credential")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-Credential", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-Security-Token")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Security-Token", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-Algorithm")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Algorithm", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-SignedHeaders", valid_602711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602713: Call_GetDiskSnapshot_602701; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific block storage disk snapshot.
  ## 
  let valid = call_602713.validator(path, query, header, formData, body)
  let scheme = call_602713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602713.url(scheme.get, call_602713.host, call_602713.base,
                         call_602713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602713, url, valid)

proc call*(call_602714: Call_GetDiskSnapshot_602701; body: JsonNode): Recallable =
  ## getDiskSnapshot
  ## Returns information about a specific block storage disk snapshot.
  ##   body: JObject (required)
  var body_602715 = newJObject()
  if body != nil:
    body_602715 = body
  result = call_602714.call(nil, nil, nil, nil, body_602715)

var getDiskSnapshot* = Call_GetDiskSnapshot_602701(name: "getDiskSnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDiskSnapshot",
    validator: validate_GetDiskSnapshot_602702, base: "/", url: url_GetDiskSnapshot_602703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiskSnapshots_602716 = ref object of OpenApiRestCall_601389
proc url_GetDiskSnapshots_602718(protocol: Scheme; host: string; base: string;
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

proc validate_GetDiskSnapshots_602717(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602719 = header.getOrDefault("X-Amz-Target")
  valid_602719 = validateParameter(valid_602719, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDiskSnapshots"))
  if valid_602719 != nil:
    section.add "X-Amz-Target", valid_602719
  var valid_602720 = header.getOrDefault("X-Amz-Signature")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "X-Amz-Signature", valid_602720
  var valid_602721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Content-Sha256", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-Date")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-Date", valid_602722
  var valid_602723 = header.getOrDefault("X-Amz-Credential")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Credential", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-Security-Token")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Security-Token", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Algorithm")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Algorithm", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-SignedHeaders", valid_602726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602728: Call_GetDiskSnapshots_602716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all block storage disk snapshots in your AWS account and region.</p> <p>If you are describing a long list of disk snapshots, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ## 
  let valid = call_602728.validator(path, query, header, formData, body)
  let scheme = call_602728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602728.url(scheme.get, call_602728.host, call_602728.base,
                         call_602728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602728, url, valid)

proc call*(call_602729: Call_GetDiskSnapshots_602716; body: JsonNode): Recallable =
  ## getDiskSnapshots
  ## <p>Returns information about all block storage disk snapshots in your AWS account and region.</p> <p>If you are describing a long list of disk snapshots, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ##   body: JObject (required)
  var body_602730 = newJObject()
  if body != nil:
    body_602730 = body
  result = call_602729.call(nil, nil, nil, nil, body_602730)

var getDiskSnapshots* = Call_GetDiskSnapshots_602716(name: "getDiskSnapshots",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDiskSnapshots",
    validator: validate_GetDiskSnapshots_602717, base: "/",
    url: url_GetDiskSnapshots_602718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisks_602731 = ref object of OpenApiRestCall_601389
proc url_GetDisks_602733(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDisks_602732(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602734 = header.getOrDefault("X-Amz-Target")
  valid_602734 = validateParameter(valid_602734, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDisks"))
  if valid_602734 != nil:
    section.add "X-Amz-Target", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-Signature")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-Signature", valid_602735
  var valid_602736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Content-Sha256", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-Date")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Date", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-Credential")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Credential", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-Security-Token")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-Security-Token", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Algorithm")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Algorithm", valid_602740
  var valid_602741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-SignedHeaders", valid_602741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602743: Call_GetDisks_602731; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all block storage disks in your AWS account and region.</p> <p>If you are describing a long list of disks, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ## 
  let valid = call_602743.validator(path, query, header, formData, body)
  let scheme = call_602743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602743.url(scheme.get, call_602743.host, call_602743.base,
                         call_602743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602743, url, valid)

proc call*(call_602744: Call_GetDisks_602731; body: JsonNode): Recallable =
  ## getDisks
  ## <p>Returns information about all block storage disks in your AWS account and region.</p> <p>If you are describing a long list of disks, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ##   body: JObject (required)
  var body_602745 = newJObject()
  if body != nil:
    body_602745 = body
  result = call_602744.call(nil, nil, nil, nil, body_602745)

var getDisks* = Call_GetDisks_602731(name: "getDisks", meth: HttpMethod.HttpPost,
                                  host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDisks",
                                  validator: validate_GetDisks_602732, base: "/",
                                  url: url_GetDisks_602733,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomain_602746 = ref object of OpenApiRestCall_601389
proc url_GetDomain_602748(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDomain_602747(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602749 = header.getOrDefault("X-Amz-Target")
  valid_602749 = validateParameter(valid_602749, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDomain"))
  if valid_602749 != nil:
    section.add "X-Amz-Target", valid_602749
  var valid_602750 = header.getOrDefault("X-Amz-Signature")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-Signature", valid_602750
  var valid_602751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "X-Amz-Content-Sha256", valid_602751
  var valid_602752 = header.getOrDefault("X-Amz-Date")
  valid_602752 = validateParameter(valid_602752, JString, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "X-Amz-Date", valid_602752
  var valid_602753 = header.getOrDefault("X-Amz-Credential")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Credential", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Security-Token")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Security-Token", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Algorithm")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Algorithm", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-SignedHeaders", valid_602756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602758: Call_GetDomain_602746; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific domain recordset.
  ## 
  let valid = call_602758.validator(path, query, header, formData, body)
  let scheme = call_602758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602758.url(scheme.get, call_602758.host, call_602758.base,
                         call_602758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602758, url, valid)

proc call*(call_602759: Call_GetDomain_602746; body: JsonNode): Recallable =
  ## getDomain
  ## Returns information about a specific domain recordset.
  ##   body: JObject (required)
  var body_602760 = newJObject()
  if body != nil:
    body_602760 = body
  result = call_602759.call(nil, nil, nil, nil, body_602760)

var getDomain* = Call_GetDomain_602746(name: "getDomain", meth: HttpMethod.HttpPost,
                                    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDomain",
                                    validator: validate_GetDomain_602747,
                                    base: "/", url: url_GetDomain_602748,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomains_602761 = ref object of OpenApiRestCall_601389
proc url_GetDomains_602763(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDomains_602762(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602764 = header.getOrDefault("X-Amz-Target")
  valid_602764 = validateParameter(valid_602764, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDomains"))
  if valid_602764 != nil:
    section.add "X-Amz-Target", valid_602764
  var valid_602765 = header.getOrDefault("X-Amz-Signature")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "X-Amz-Signature", valid_602765
  var valid_602766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602766 = validateParameter(valid_602766, JString, required = false,
                                 default = nil)
  if valid_602766 != nil:
    section.add "X-Amz-Content-Sha256", valid_602766
  var valid_602767 = header.getOrDefault("X-Amz-Date")
  valid_602767 = validateParameter(valid_602767, JString, required = false,
                                 default = nil)
  if valid_602767 != nil:
    section.add "X-Amz-Date", valid_602767
  var valid_602768 = header.getOrDefault("X-Amz-Credential")
  valid_602768 = validateParameter(valid_602768, JString, required = false,
                                 default = nil)
  if valid_602768 != nil:
    section.add "X-Amz-Credential", valid_602768
  var valid_602769 = header.getOrDefault("X-Amz-Security-Token")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Security-Token", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Algorithm")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Algorithm", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-SignedHeaders", valid_602771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602773: Call_GetDomains_602761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all domains in the user's account.
  ## 
  let valid = call_602773.validator(path, query, header, formData, body)
  let scheme = call_602773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602773.url(scheme.get, call_602773.host, call_602773.base,
                         call_602773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602773, url, valid)

proc call*(call_602774: Call_GetDomains_602761; body: JsonNode): Recallable =
  ## getDomains
  ## Returns a list of all domains in the user's account.
  ##   body: JObject (required)
  var body_602775 = newJObject()
  if body != nil:
    body_602775 = body
  result = call_602774.call(nil, nil, nil, nil, body_602775)

var getDomains* = Call_GetDomains_602761(name: "getDomains",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDomains",
                                      validator: validate_GetDomains_602762,
                                      base: "/", url: url_GetDomains_602763,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportSnapshotRecords_602776 = ref object of OpenApiRestCall_601389
proc url_GetExportSnapshotRecords_602778(protocol: Scheme; host: string;
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

proc validate_GetExportSnapshotRecords_602777(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602779 = header.getOrDefault("X-Amz-Target")
  valid_602779 = validateParameter(valid_602779, JString, required = true, default = newJString(
      "Lightsail_20161128.GetExportSnapshotRecords"))
  if valid_602779 != nil:
    section.add "X-Amz-Target", valid_602779
  var valid_602780 = header.getOrDefault("X-Amz-Signature")
  valid_602780 = validateParameter(valid_602780, JString, required = false,
                                 default = nil)
  if valid_602780 != nil:
    section.add "X-Amz-Signature", valid_602780
  var valid_602781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602781 = validateParameter(valid_602781, JString, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "X-Amz-Content-Sha256", valid_602781
  var valid_602782 = header.getOrDefault("X-Amz-Date")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "X-Amz-Date", valid_602782
  var valid_602783 = header.getOrDefault("X-Amz-Credential")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-Credential", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Security-Token")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Security-Token", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Algorithm")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Algorithm", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-SignedHeaders", valid_602786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602788: Call_GetExportSnapshotRecords_602776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
  ## 
  let valid = call_602788.validator(path, query, header, formData, body)
  let scheme = call_602788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602788.url(scheme.get, call_602788.host, call_602788.base,
                         call_602788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602788, url, valid)

proc call*(call_602789: Call_GetExportSnapshotRecords_602776; body: JsonNode): Recallable =
  ## getExportSnapshotRecords
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
  ##   body: JObject (required)
  var body_602790 = newJObject()
  if body != nil:
    body_602790 = body
  result = call_602789.call(nil, nil, nil, nil, body_602790)

var getExportSnapshotRecords* = Call_GetExportSnapshotRecords_602776(
    name: "getExportSnapshotRecords", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetExportSnapshotRecords",
    validator: validate_GetExportSnapshotRecords_602777, base: "/",
    url: url_GetExportSnapshotRecords_602778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstance_602791 = ref object of OpenApiRestCall_601389
proc url_GetInstance_602793(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstance_602792(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602794 = header.getOrDefault("X-Amz-Target")
  valid_602794 = validateParameter(valid_602794, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstance"))
  if valid_602794 != nil:
    section.add "X-Amz-Target", valid_602794
  var valid_602795 = header.getOrDefault("X-Amz-Signature")
  valid_602795 = validateParameter(valid_602795, JString, required = false,
                                 default = nil)
  if valid_602795 != nil:
    section.add "X-Amz-Signature", valid_602795
  var valid_602796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Content-Sha256", valid_602796
  var valid_602797 = header.getOrDefault("X-Amz-Date")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Date", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-Credential")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Credential", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Security-Token")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Security-Token", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Algorithm")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Algorithm", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-SignedHeaders", valid_602801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602803: Call_GetInstance_602791; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
  ## 
  let valid = call_602803.validator(path, query, header, formData, body)
  let scheme = call_602803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602803.url(scheme.get, call_602803.host, call_602803.base,
                         call_602803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602803, url, valid)

proc call*(call_602804: Call_GetInstance_602791; body: JsonNode): Recallable =
  ## getInstance
  ## Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
  ##   body: JObject (required)
  var body_602805 = newJObject()
  if body != nil:
    body_602805 = body
  result = call_602804.call(nil, nil, nil, nil, body_602805)

var getInstance* = Call_GetInstance_602791(name: "getInstance",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetInstance",
                                        validator: validate_GetInstance_602792,
                                        base: "/", url: url_GetInstance_602793,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceAccessDetails_602806 = ref object of OpenApiRestCall_601389
proc url_GetInstanceAccessDetails_602808(protocol: Scheme; host: string;
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

proc validate_GetInstanceAccessDetails_602807(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602809 = header.getOrDefault("X-Amz-Target")
  valid_602809 = validateParameter(valid_602809, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceAccessDetails"))
  if valid_602809 != nil:
    section.add "X-Amz-Target", valid_602809
  var valid_602810 = header.getOrDefault("X-Amz-Signature")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "X-Amz-Signature", valid_602810
  var valid_602811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "X-Amz-Content-Sha256", valid_602811
  var valid_602812 = header.getOrDefault("X-Amz-Date")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "X-Amz-Date", valid_602812
  var valid_602813 = header.getOrDefault("X-Amz-Credential")
  valid_602813 = validateParameter(valid_602813, JString, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "X-Amz-Credential", valid_602813
  var valid_602814 = header.getOrDefault("X-Amz-Security-Token")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "X-Amz-Security-Token", valid_602814
  var valid_602815 = header.getOrDefault("X-Amz-Algorithm")
  valid_602815 = validateParameter(valid_602815, JString, required = false,
                                 default = nil)
  if valid_602815 != nil:
    section.add "X-Amz-Algorithm", valid_602815
  var valid_602816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602816 = validateParameter(valid_602816, JString, required = false,
                                 default = nil)
  if valid_602816 != nil:
    section.add "X-Amz-SignedHeaders", valid_602816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602818: Call_GetInstanceAccessDetails_602806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_602818.validator(path, query, header, formData, body)
  let scheme = call_602818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602818.url(scheme.get, call_602818.host, call_602818.base,
                         call_602818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602818, url, valid)

proc call*(call_602819: Call_GetInstanceAccessDetails_602806; body: JsonNode): Recallable =
  ## getInstanceAccessDetails
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_602820 = newJObject()
  if body != nil:
    body_602820 = body
  result = call_602819.call(nil, nil, nil, nil, body_602820)

var getInstanceAccessDetails* = Call_GetInstanceAccessDetails_602806(
    name: "getInstanceAccessDetails", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceAccessDetails",
    validator: validate_GetInstanceAccessDetails_602807, base: "/",
    url: url_GetInstanceAccessDetails_602808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceMetricData_602821 = ref object of OpenApiRestCall_601389
proc url_GetInstanceMetricData_602823(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstanceMetricData_602822(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602824 = header.getOrDefault("X-Amz-Target")
  valid_602824 = validateParameter(valid_602824, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceMetricData"))
  if valid_602824 != nil:
    section.add "X-Amz-Target", valid_602824
  var valid_602825 = header.getOrDefault("X-Amz-Signature")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "X-Amz-Signature", valid_602825
  var valid_602826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "X-Amz-Content-Sha256", valid_602826
  var valid_602827 = header.getOrDefault("X-Amz-Date")
  valid_602827 = validateParameter(valid_602827, JString, required = false,
                                 default = nil)
  if valid_602827 != nil:
    section.add "X-Amz-Date", valid_602827
  var valid_602828 = header.getOrDefault("X-Amz-Credential")
  valid_602828 = validateParameter(valid_602828, JString, required = false,
                                 default = nil)
  if valid_602828 != nil:
    section.add "X-Amz-Credential", valid_602828
  var valid_602829 = header.getOrDefault("X-Amz-Security-Token")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "X-Amz-Security-Token", valid_602829
  var valid_602830 = header.getOrDefault("X-Amz-Algorithm")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "X-Amz-Algorithm", valid_602830
  var valid_602831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602831 = validateParameter(valid_602831, JString, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "X-Amz-SignedHeaders", valid_602831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602833: Call_GetInstanceMetricData_602821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the data points for the specified Amazon Lightsail instance metric, given an instance name.
  ## 
  let valid = call_602833.validator(path, query, header, formData, body)
  let scheme = call_602833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602833.url(scheme.get, call_602833.host, call_602833.base,
                         call_602833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602833, url, valid)

proc call*(call_602834: Call_GetInstanceMetricData_602821; body: JsonNode): Recallable =
  ## getInstanceMetricData
  ## Returns the data points for the specified Amazon Lightsail instance metric, given an instance name.
  ##   body: JObject (required)
  var body_602835 = newJObject()
  if body != nil:
    body_602835 = body
  result = call_602834.call(nil, nil, nil, nil, body_602835)

var getInstanceMetricData* = Call_GetInstanceMetricData_602821(
    name: "getInstanceMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceMetricData",
    validator: validate_GetInstanceMetricData_602822, base: "/",
    url: url_GetInstanceMetricData_602823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstancePortStates_602836 = ref object of OpenApiRestCall_601389
proc url_GetInstancePortStates_602838(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstancePortStates_602837(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602839 = header.getOrDefault("X-Amz-Target")
  valid_602839 = validateParameter(valid_602839, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstancePortStates"))
  if valid_602839 != nil:
    section.add "X-Amz-Target", valid_602839
  var valid_602840 = header.getOrDefault("X-Amz-Signature")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "X-Amz-Signature", valid_602840
  var valid_602841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602841 = validateParameter(valid_602841, JString, required = false,
                                 default = nil)
  if valid_602841 != nil:
    section.add "X-Amz-Content-Sha256", valid_602841
  var valid_602842 = header.getOrDefault("X-Amz-Date")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "X-Amz-Date", valid_602842
  var valid_602843 = header.getOrDefault("X-Amz-Credential")
  valid_602843 = validateParameter(valid_602843, JString, required = false,
                                 default = nil)
  if valid_602843 != nil:
    section.add "X-Amz-Credential", valid_602843
  var valid_602844 = header.getOrDefault("X-Amz-Security-Token")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "X-Amz-Security-Token", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-Algorithm")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-Algorithm", valid_602845
  var valid_602846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-SignedHeaders", valid_602846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602848: Call_GetInstancePortStates_602836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the port states for a specific virtual private server, or <i>instance</i>.
  ## 
  let valid = call_602848.validator(path, query, header, formData, body)
  let scheme = call_602848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602848.url(scheme.get, call_602848.host, call_602848.base,
                         call_602848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602848, url, valid)

proc call*(call_602849: Call_GetInstancePortStates_602836; body: JsonNode): Recallable =
  ## getInstancePortStates
  ## Returns the port states for a specific virtual private server, or <i>instance</i>.
  ##   body: JObject (required)
  var body_602850 = newJObject()
  if body != nil:
    body_602850 = body
  result = call_602849.call(nil, nil, nil, nil, body_602850)

var getInstancePortStates* = Call_GetInstancePortStates_602836(
    name: "getInstancePortStates", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstancePortStates",
    validator: validate_GetInstancePortStates_602837, base: "/",
    url: url_GetInstancePortStates_602838, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceSnapshot_602851 = ref object of OpenApiRestCall_601389
proc url_GetInstanceSnapshot_602853(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstanceSnapshot_602852(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602854 = header.getOrDefault("X-Amz-Target")
  valid_602854 = validateParameter(valid_602854, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceSnapshot"))
  if valid_602854 != nil:
    section.add "X-Amz-Target", valid_602854
  var valid_602855 = header.getOrDefault("X-Amz-Signature")
  valid_602855 = validateParameter(valid_602855, JString, required = false,
                                 default = nil)
  if valid_602855 != nil:
    section.add "X-Amz-Signature", valid_602855
  var valid_602856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602856 = validateParameter(valid_602856, JString, required = false,
                                 default = nil)
  if valid_602856 != nil:
    section.add "X-Amz-Content-Sha256", valid_602856
  var valid_602857 = header.getOrDefault("X-Amz-Date")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "X-Amz-Date", valid_602857
  var valid_602858 = header.getOrDefault("X-Amz-Credential")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "X-Amz-Credential", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Security-Token")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Security-Token", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Algorithm")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Algorithm", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-SignedHeaders", valid_602861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602863: Call_GetInstanceSnapshot_602851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific instance snapshot.
  ## 
  let valid = call_602863.validator(path, query, header, formData, body)
  let scheme = call_602863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602863.url(scheme.get, call_602863.host, call_602863.base,
                         call_602863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602863, url, valid)

proc call*(call_602864: Call_GetInstanceSnapshot_602851; body: JsonNode): Recallable =
  ## getInstanceSnapshot
  ## Returns information about a specific instance snapshot.
  ##   body: JObject (required)
  var body_602865 = newJObject()
  if body != nil:
    body_602865 = body
  result = call_602864.call(nil, nil, nil, nil, body_602865)

var getInstanceSnapshot* = Call_GetInstanceSnapshot_602851(
    name: "getInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceSnapshot",
    validator: validate_GetInstanceSnapshot_602852, base: "/",
    url: url_GetInstanceSnapshot_602853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceSnapshots_602866 = ref object of OpenApiRestCall_601389
proc url_GetInstanceSnapshots_602868(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstanceSnapshots_602867(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602869 = header.getOrDefault("X-Amz-Target")
  valid_602869 = validateParameter(valid_602869, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceSnapshots"))
  if valid_602869 != nil:
    section.add "X-Amz-Target", valid_602869
  var valid_602870 = header.getOrDefault("X-Amz-Signature")
  valid_602870 = validateParameter(valid_602870, JString, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "X-Amz-Signature", valid_602870
  var valid_602871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Content-Sha256", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Date")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Date", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Credential")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Credential", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Security-Token")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Security-Token", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Algorithm")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Algorithm", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-SignedHeaders", valid_602876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602878: Call_GetInstanceSnapshots_602866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all instance snapshots for the user's account.
  ## 
  let valid = call_602878.validator(path, query, header, formData, body)
  let scheme = call_602878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602878.url(scheme.get, call_602878.host, call_602878.base,
                         call_602878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602878, url, valid)

proc call*(call_602879: Call_GetInstanceSnapshots_602866; body: JsonNode): Recallable =
  ## getInstanceSnapshots
  ## Returns all instance snapshots for the user's account.
  ##   body: JObject (required)
  var body_602880 = newJObject()
  if body != nil:
    body_602880 = body
  result = call_602879.call(nil, nil, nil, nil, body_602880)

var getInstanceSnapshots* = Call_GetInstanceSnapshots_602866(
    name: "getInstanceSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceSnapshots",
    validator: validate_GetInstanceSnapshots_602867, base: "/",
    url: url_GetInstanceSnapshots_602868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceState_602881 = ref object of OpenApiRestCall_601389
proc url_GetInstanceState_602883(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstanceState_602882(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602884 = header.getOrDefault("X-Amz-Target")
  valid_602884 = validateParameter(valid_602884, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceState"))
  if valid_602884 != nil:
    section.add "X-Amz-Target", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Signature")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Signature", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Content-Sha256", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Date")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Date", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Credential")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Credential", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Security-Token")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Security-Token", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Algorithm")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Algorithm", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-SignedHeaders", valid_602891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602893: Call_GetInstanceState_602881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the state of a specific instance. Works on one instance at a time.
  ## 
  let valid = call_602893.validator(path, query, header, formData, body)
  let scheme = call_602893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602893.url(scheme.get, call_602893.host, call_602893.base,
                         call_602893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602893, url, valid)

proc call*(call_602894: Call_GetInstanceState_602881; body: JsonNode): Recallable =
  ## getInstanceState
  ## Returns the state of a specific instance. Works on one instance at a time.
  ##   body: JObject (required)
  var body_602895 = newJObject()
  if body != nil:
    body_602895 = body
  result = call_602894.call(nil, nil, nil, nil, body_602895)

var getInstanceState* = Call_GetInstanceState_602881(name: "getInstanceState",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceState",
    validator: validate_GetInstanceState_602882, base: "/",
    url: url_GetInstanceState_602883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstances_602896 = ref object of OpenApiRestCall_601389
proc url_GetInstances_602898(protocol: Scheme; host: string; base: string;
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

proc validate_GetInstances_602897(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602899 = header.getOrDefault("X-Amz-Target")
  valid_602899 = validateParameter(valid_602899, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstances"))
  if valid_602899 != nil:
    section.add "X-Amz-Target", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Signature")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Signature", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Content-Sha256", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Date")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Date", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Credential")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Credential", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Security-Token")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Security-Token", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Algorithm")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Algorithm", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-SignedHeaders", valid_602906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602908: Call_GetInstances_602896; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
  ## 
  let valid = call_602908.validator(path, query, header, formData, body)
  let scheme = call_602908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602908.url(scheme.get, call_602908.host, call_602908.base,
                         call_602908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602908, url, valid)

proc call*(call_602909: Call_GetInstances_602896; body: JsonNode): Recallable =
  ## getInstances
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
  ##   body: JObject (required)
  var body_602910 = newJObject()
  if body != nil:
    body_602910 = body
  result = call_602909.call(nil, nil, nil, nil, body_602910)

var getInstances* = Call_GetInstances_602896(name: "getInstances",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstances",
    validator: validate_GetInstances_602897, base: "/", url: url_GetInstances_602898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPair_602911 = ref object of OpenApiRestCall_601389
proc url_GetKeyPair_602913(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetKeyPair_602912(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602914 = header.getOrDefault("X-Amz-Target")
  valid_602914 = validateParameter(valid_602914, JString, required = true, default = newJString(
      "Lightsail_20161128.GetKeyPair"))
  if valid_602914 != nil:
    section.add "X-Amz-Target", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-Signature")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-Signature", valid_602915
  var valid_602916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-Content-Sha256", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Credential")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Credential", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-Security-Token")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Security-Token", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Algorithm")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Algorithm", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-SignedHeaders", valid_602921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602923: Call_GetKeyPair_602911; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific key pair.
  ## 
  let valid = call_602923.validator(path, query, header, formData, body)
  let scheme = call_602923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602923.url(scheme.get, call_602923.host, call_602923.base,
                         call_602923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602923, url, valid)

proc call*(call_602924: Call_GetKeyPair_602911; body: JsonNode): Recallable =
  ## getKeyPair
  ## Returns information about a specific key pair.
  ##   body: JObject (required)
  var body_602925 = newJObject()
  if body != nil:
    body_602925 = body
  result = call_602924.call(nil, nil, nil, nil, body_602925)

var getKeyPair* = Call_GetKeyPair_602911(name: "getKeyPair",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetKeyPair",
                                      validator: validate_GetKeyPair_602912,
                                      base: "/", url: url_GetKeyPair_602913,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPairs_602926 = ref object of OpenApiRestCall_601389
proc url_GetKeyPairs_602928(protocol: Scheme; host: string; base: string;
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

proc validate_GetKeyPairs_602927(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602929 = header.getOrDefault("X-Amz-Target")
  valid_602929 = validateParameter(valid_602929, JString, required = true, default = newJString(
      "Lightsail_20161128.GetKeyPairs"))
  if valid_602929 != nil:
    section.add "X-Amz-Target", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-Signature")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Signature", valid_602930
  var valid_602931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-Content-Sha256", valid_602931
  var valid_602932 = header.getOrDefault("X-Amz-Date")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Date", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Credential")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Credential", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Security-Token")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Security-Token", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Algorithm")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Algorithm", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602938: Call_GetKeyPairs_602926; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all key pairs in the user's account.
  ## 
  let valid = call_602938.validator(path, query, header, formData, body)
  let scheme = call_602938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602938.url(scheme.get, call_602938.host, call_602938.base,
                         call_602938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602938, url, valid)

proc call*(call_602939: Call_GetKeyPairs_602926; body: JsonNode): Recallable =
  ## getKeyPairs
  ## Returns information about all key pairs in the user's account.
  ##   body: JObject (required)
  var body_602940 = newJObject()
  if body != nil:
    body_602940 = body
  result = call_602939.call(nil, nil, nil, nil, body_602940)

var getKeyPairs* = Call_GetKeyPairs_602926(name: "getKeyPairs",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetKeyPairs",
                                        validator: validate_GetKeyPairs_602927,
                                        base: "/", url: url_GetKeyPairs_602928,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancer_602941 = ref object of OpenApiRestCall_601389
proc url_GetLoadBalancer_602943(protocol: Scheme; host: string; base: string;
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

proc validate_GetLoadBalancer_602942(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602944 = header.getOrDefault("X-Amz-Target")
  valid_602944 = validateParameter(valid_602944, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancer"))
  if valid_602944 != nil:
    section.add "X-Amz-Target", valid_602944
  var valid_602945 = header.getOrDefault("X-Amz-Signature")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "X-Amz-Signature", valid_602945
  var valid_602946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "X-Amz-Content-Sha256", valid_602946
  var valid_602947 = header.getOrDefault("X-Amz-Date")
  valid_602947 = validateParameter(valid_602947, JString, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "X-Amz-Date", valid_602947
  var valid_602948 = header.getOrDefault("X-Amz-Credential")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "X-Amz-Credential", valid_602948
  var valid_602949 = header.getOrDefault("X-Amz-Security-Token")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-Security-Token", valid_602949
  var valid_602950 = header.getOrDefault("X-Amz-Algorithm")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-Algorithm", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-SignedHeaders", valid_602951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602953: Call_GetLoadBalancer_602941; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified Lightsail load balancer.
  ## 
  let valid = call_602953.validator(path, query, header, formData, body)
  let scheme = call_602953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602953.url(scheme.get, call_602953.host, call_602953.base,
                         call_602953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602953, url, valid)

proc call*(call_602954: Call_GetLoadBalancer_602941; body: JsonNode): Recallable =
  ## getLoadBalancer
  ## Returns information about the specified Lightsail load balancer.
  ##   body: JObject (required)
  var body_602955 = newJObject()
  if body != nil:
    body_602955 = body
  result = call_602954.call(nil, nil, nil, nil, body_602955)

var getLoadBalancer* = Call_GetLoadBalancer_602941(name: "getLoadBalancer",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancer",
    validator: validate_GetLoadBalancer_602942, base: "/", url: url_GetLoadBalancer_602943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancerMetricData_602956 = ref object of OpenApiRestCall_601389
proc url_GetLoadBalancerMetricData_602958(protocol: Scheme; host: string;
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

proc validate_GetLoadBalancerMetricData_602957(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602959 = header.getOrDefault("X-Amz-Target")
  valid_602959 = validateParameter(valid_602959, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancerMetricData"))
  if valid_602959 != nil:
    section.add "X-Amz-Target", valid_602959
  var valid_602960 = header.getOrDefault("X-Amz-Signature")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "X-Amz-Signature", valid_602960
  var valid_602961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "X-Amz-Content-Sha256", valid_602961
  var valid_602962 = header.getOrDefault("X-Amz-Date")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-Date", valid_602962
  var valid_602963 = header.getOrDefault("X-Amz-Credential")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "X-Amz-Credential", valid_602963
  var valid_602964 = header.getOrDefault("X-Amz-Security-Token")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "X-Amz-Security-Token", valid_602964
  var valid_602965 = header.getOrDefault("X-Amz-Algorithm")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "X-Amz-Algorithm", valid_602965
  var valid_602966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602966 = validateParameter(valid_602966, JString, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "X-Amz-SignedHeaders", valid_602966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602968: Call_GetLoadBalancerMetricData_602956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about health metrics for your Lightsail load balancer.
  ## 
  let valid = call_602968.validator(path, query, header, formData, body)
  let scheme = call_602968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602968.url(scheme.get, call_602968.host, call_602968.base,
                         call_602968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602968, url, valid)

proc call*(call_602969: Call_GetLoadBalancerMetricData_602956; body: JsonNode): Recallable =
  ## getLoadBalancerMetricData
  ## Returns information about health metrics for your Lightsail load balancer.
  ##   body: JObject (required)
  var body_602970 = newJObject()
  if body != nil:
    body_602970 = body
  result = call_602969.call(nil, nil, nil, nil, body_602970)

var getLoadBalancerMetricData* = Call_GetLoadBalancerMetricData_602956(
    name: "getLoadBalancerMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancerMetricData",
    validator: validate_GetLoadBalancerMetricData_602957, base: "/",
    url: url_GetLoadBalancerMetricData_602958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancerTlsCertificates_602971 = ref object of OpenApiRestCall_601389
proc url_GetLoadBalancerTlsCertificates_602973(protocol: Scheme; host: string;
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

proc validate_GetLoadBalancerTlsCertificates_602972(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602974 = header.getOrDefault("X-Amz-Target")
  valid_602974 = validateParameter(valid_602974, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancerTlsCertificates"))
  if valid_602974 != nil:
    section.add "X-Amz-Target", valid_602974
  var valid_602975 = header.getOrDefault("X-Amz-Signature")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-Signature", valid_602975
  var valid_602976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Content-Sha256", valid_602976
  var valid_602977 = header.getOrDefault("X-Amz-Date")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "X-Amz-Date", valid_602977
  var valid_602978 = header.getOrDefault("X-Amz-Credential")
  valid_602978 = validateParameter(valid_602978, JString, required = false,
                                 default = nil)
  if valid_602978 != nil:
    section.add "X-Amz-Credential", valid_602978
  var valid_602979 = header.getOrDefault("X-Amz-Security-Token")
  valid_602979 = validateParameter(valid_602979, JString, required = false,
                                 default = nil)
  if valid_602979 != nil:
    section.add "X-Amz-Security-Token", valid_602979
  var valid_602980 = header.getOrDefault("X-Amz-Algorithm")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "X-Amz-Algorithm", valid_602980
  var valid_602981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602981 = validateParameter(valid_602981, JString, required = false,
                                 default = nil)
  if valid_602981 != nil:
    section.add "X-Amz-SignedHeaders", valid_602981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602983: Call_GetLoadBalancerTlsCertificates_602971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the TLS certificates that are associated with the specified Lightsail load balancer.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.</p>
  ## 
  let valid = call_602983.validator(path, query, header, formData, body)
  let scheme = call_602983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602983.url(scheme.get, call_602983.host, call_602983.base,
                         call_602983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602983, url, valid)

proc call*(call_602984: Call_GetLoadBalancerTlsCertificates_602971; body: JsonNode): Recallable =
  ## getLoadBalancerTlsCertificates
  ## <p>Returns information about the TLS certificates that are associated with the specified Lightsail load balancer.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.</p>
  ##   body: JObject (required)
  var body_602985 = newJObject()
  if body != nil:
    body_602985 = body
  result = call_602984.call(nil, nil, nil, nil, body_602985)

var getLoadBalancerTlsCertificates* = Call_GetLoadBalancerTlsCertificates_602971(
    name: "getLoadBalancerTlsCertificates", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancerTlsCertificates",
    validator: validate_GetLoadBalancerTlsCertificates_602972, base: "/",
    url: url_GetLoadBalancerTlsCertificates_602973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancers_602986 = ref object of OpenApiRestCall_601389
proc url_GetLoadBalancers_602988(protocol: Scheme; host: string; base: string;
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

proc validate_GetLoadBalancers_602987(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602989 = header.getOrDefault("X-Amz-Target")
  valid_602989 = validateParameter(valid_602989, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancers"))
  if valid_602989 != nil:
    section.add "X-Amz-Target", valid_602989
  var valid_602990 = header.getOrDefault("X-Amz-Signature")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "X-Amz-Signature", valid_602990
  var valid_602991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602991 = validateParameter(valid_602991, JString, required = false,
                                 default = nil)
  if valid_602991 != nil:
    section.add "X-Amz-Content-Sha256", valid_602991
  var valid_602992 = header.getOrDefault("X-Amz-Date")
  valid_602992 = validateParameter(valid_602992, JString, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "X-Amz-Date", valid_602992
  var valid_602993 = header.getOrDefault("X-Amz-Credential")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "X-Amz-Credential", valid_602993
  var valid_602994 = header.getOrDefault("X-Amz-Security-Token")
  valid_602994 = validateParameter(valid_602994, JString, required = false,
                                 default = nil)
  if valid_602994 != nil:
    section.add "X-Amz-Security-Token", valid_602994
  var valid_602995 = header.getOrDefault("X-Amz-Algorithm")
  valid_602995 = validateParameter(valid_602995, JString, required = false,
                                 default = nil)
  if valid_602995 != nil:
    section.add "X-Amz-Algorithm", valid_602995
  var valid_602996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602996 = validateParameter(valid_602996, JString, required = false,
                                 default = nil)
  if valid_602996 != nil:
    section.add "X-Amz-SignedHeaders", valid_602996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602998: Call_GetLoadBalancers_602986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all load balancers in an account.</p> <p>If you are describing a long list of load balancers, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ## 
  let valid = call_602998.validator(path, query, header, formData, body)
  let scheme = call_602998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602998.url(scheme.get, call_602998.host, call_602998.base,
                         call_602998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602998, url, valid)

proc call*(call_602999: Call_GetLoadBalancers_602986; body: JsonNode): Recallable =
  ## getLoadBalancers
  ## <p>Returns information about all load balancers in an account.</p> <p>If you are describing a long list of load balancers, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var getLoadBalancers* = Call_GetLoadBalancers_602986(name: "getLoadBalancers",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancers",
    validator: validate_GetLoadBalancers_602987, base: "/",
    url: url_GetLoadBalancers_602988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperation_603001 = ref object of OpenApiRestCall_601389
proc url_GetOperation_603003(protocol: Scheme; host: string; base: string;
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

proc validate_GetOperation_603002(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603004 = header.getOrDefault("X-Amz-Target")
  valid_603004 = validateParameter(valid_603004, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperation"))
  if valid_603004 != nil:
    section.add "X-Amz-Target", valid_603004
  var valid_603005 = header.getOrDefault("X-Amz-Signature")
  valid_603005 = validateParameter(valid_603005, JString, required = false,
                                 default = nil)
  if valid_603005 != nil:
    section.add "X-Amz-Signature", valid_603005
  var valid_603006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "X-Amz-Content-Sha256", valid_603006
  var valid_603007 = header.getOrDefault("X-Amz-Date")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "X-Amz-Date", valid_603007
  var valid_603008 = header.getOrDefault("X-Amz-Credential")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "X-Amz-Credential", valid_603008
  var valid_603009 = header.getOrDefault("X-Amz-Security-Token")
  valid_603009 = validateParameter(valid_603009, JString, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "X-Amz-Security-Token", valid_603009
  var valid_603010 = header.getOrDefault("X-Amz-Algorithm")
  valid_603010 = validateParameter(valid_603010, JString, required = false,
                                 default = nil)
  if valid_603010 != nil:
    section.add "X-Amz-Algorithm", valid_603010
  var valid_603011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "X-Amz-SignedHeaders", valid_603011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603013: Call_GetOperation_603001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
  ## 
  let valid = call_603013.validator(path, query, header, formData, body)
  let scheme = call_603013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603013.url(scheme.get, call_603013.host, call_603013.base,
                         call_603013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603013, url, valid)

proc call*(call_603014: Call_GetOperation_603001; body: JsonNode): Recallable =
  ## getOperation
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
  ##   body: JObject (required)
  var body_603015 = newJObject()
  if body != nil:
    body_603015 = body
  result = call_603014.call(nil, nil, nil, nil, body_603015)

var getOperation* = Call_GetOperation_603001(name: "getOperation",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperation",
    validator: validate_GetOperation_603002, base: "/", url: url_GetOperation_603003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperations_603016 = ref object of OpenApiRestCall_601389
proc url_GetOperations_603018(protocol: Scheme; host: string; base: string;
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

proc validate_GetOperations_603017(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603019 = header.getOrDefault("X-Amz-Target")
  valid_603019 = validateParameter(valid_603019, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperations"))
  if valid_603019 != nil:
    section.add "X-Amz-Target", valid_603019
  var valid_603020 = header.getOrDefault("X-Amz-Signature")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "X-Amz-Signature", valid_603020
  var valid_603021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "X-Amz-Content-Sha256", valid_603021
  var valid_603022 = header.getOrDefault("X-Amz-Date")
  valid_603022 = validateParameter(valid_603022, JString, required = false,
                                 default = nil)
  if valid_603022 != nil:
    section.add "X-Amz-Date", valid_603022
  var valid_603023 = header.getOrDefault("X-Amz-Credential")
  valid_603023 = validateParameter(valid_603023, JString, required = false,
                                 default = nil)
  if valid_603023 != nil:
    section.add "X-Amz-Credential", valid_603023
  var valid_603024 = header.getOrDefault("X-Amz-Security-Token")
  valid_603024 = validateParameter(valid_603024, JString, required = false,
                                 default = nil)
  if valid_603024 != nil:
    section.add "X-Amz-Security-Token", valid_603024
  var valid_603025 = header.getOrDefault("X-Amz-Algorithm")
  valid_603025 = validateParameter(valid_603025, JString, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "X-Amz-Algorithm", valid_603025
  var valid_603026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-SignedHeaders", valid_603026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603028: Call_GetOperations_603016; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
  ## 
  let valid = call_603028.validator(path, query, header, formData, body)
  let scheme = call_603028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603028.url(scheme.get, call_603028.host, call_603028.base,
                         call_603028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603028, url, valid)

proc call*(call_603029: Call_GetOperations_603016; body: JsonNode): Recallable =
  ## getOperations
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
  ##   body: JObject (required)
  var body_603030 = newJObject()
  if body != nil:
    body_603030 = body
  result = call_603029.call(nil, nil, nil, nil, body_603030)

var getOperations* = Call_GetOperations_603016(name: "getOperations",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperations",
    validator: validate_GetOperations_603017, base: "/", url: url_GetOperations_603018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperationsForResource_603031 = ref object of OpenApiRestCall_601389
proc url_GetOperationsForResource_603033(protocol: Scheme; host: string;
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

proc validate_GetOperationsForResource_603032(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603034 = header.getOrDefault("X-Amz-Target")
  valid_603034 = validateParameter(valid_603034, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperationsForResource"))
  if valid_603034 != nil:
    section.add "X-Amz-Target", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Signature")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Signature", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Content-Sha256", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Date")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Date", valid_603037
  var valid_603038 = header.getOrDefault("X-Amz-Credential")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-Credential", valid_603038
  var valid_603039 = header.getOrDefault("X-Amz-Security-Token")
  valid_603039 = validateParameter(valid_603039, JString, required = false,
                                 default = nil)
  if valid_603039 != nil:
    section.add "X-Amz-Security-Token", valid_603039
  var valid_603040 = header.getOrDefault("X-Amz-Algorithm")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-Algorithm", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-SignedHeaders", valid_603041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603043: Call_GetOperationsForResource_603031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
  ## 
  let valid = call_603043.validator(path, query, header, formData, body)
  let scheme = call_603043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603043.url(scheme.get, call_603043.host, call_603043.base,
                         call_603043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603043, url, valid)

proc call*(call_603044: Call_GetOperationsForResource_603031; body: JsonNode): Recallable =
  ## getOperationsForResource
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
  ##   body: JObject (required)
  var body_603045 = newJObject()
  if body != nil:
    body_603045 = body
  result = call_603044.call(nil, nil, nil, nil, body_603045)

var getOperationsForResource* = Call_GetOperationsForResource_603031(
    name: "getOperationsForResource", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperationsForResource",
    validator: validate_GetOperationsForResource_603032, base: "/",
    url: url_GetOperationsForResource_603033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegions_603046 = ref object of OpenApiRestCall_601389
proc url_GetRegions_603048(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRegions_603047(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603049 = header.getOrDefault("X-Amz-Target")
  valid_603049 = validateParameter(valid_603049, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRegions"))
  if valid_603049 != nil:
    section.add "X-Amz-Target", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Signature")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Signature", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Content-Sha256", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Date")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Date", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Credential")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Credential", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Security-Token")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Security-Token", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Algorithm")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Algorithm", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-SignedHeaders", valid_603056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603058: Call_GetRegions_603046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all valid regions for Amazon Lightsail. Use the <code>include availability zones</code> parameter to also return the Availability Zones in a region.
  ## 
  let valid = call_603058.validator(path, query, header, formData, body)
  let scheme = call_603058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603058.url(scheme.get, call_603058.host, call_603058.base,
                         call_603058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603058, url, valid)

proc call*(call_603059: Call_GetRegions_603046; body: JsonNode): Recallable =
  ## getRegions
  ## Returns a list of all valid regions for Amazon Lightsail. Use the <code>include availability zones</code> parameter to also return the Availability Zones in a region.
  ##   body: JObject (required)
  var body_603060 = newJObject()
  if body != nil:
    body_603060 = body
  result = call_603059.call(nil, nil, nil, nil, body_603060)

var getRegions* = Call_GetRegions_603046(name: "getRegions",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetRegions",
                                      validator: validate_GetRegions_603047,
                                      base: "/", url: url_GetRegions_603048,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabase_603061 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabase_603063(protocol: Scheme; host: string; base: string;
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

proc validate_GetRelationalDatabase_603062(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603064 = header.getOrDefault("X-Amz-Target")
  valid_603064 = validateParameter(valid_603064, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabase"))
  if valid_603064 != nil:
    section.add "X-Amz-Target", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Signature")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Signature", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Content-Sha256", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Date")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Date", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Credential")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Credential", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Security-Token")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Security-Token", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Algorithm")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Algorithm", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-SignedHeaders", valid_603071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603073: Call_GetRelationalDatabase_603061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific database in Amazon Lightsail.
  ## 
  let valid = call_603073.validator(path, query, header, formData, body)
  let scheme = call_603073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603073.url(scheme.get, call_603073.host, call_603073.base,
                         call_603073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603073, url, valid)

proc call*(call_603074: Call_GetRelationalDatabase_603061; body: JsonNode): Recallable =
  ## getRelationalDatabase
  ## Returns information about a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_603075 = newJObject()
  if body != nil:
    body_603075 = body
  result = call_603074.call(nil, nil, nil, nil, body_603075)

var getRelationalDatabase* = Call_GetRelationalDatabase_603061(
    name: "getRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabase",
    validator: validate_GetRelationalDatabase_603062, base: "/",
    url: url_GetRelationalDatabase_603063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseBlueprints_603076 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabaseBlueprints_603078(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseBlueprints_603077(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603079 = header.getOrDefault("X-Amz-Target")
  valid_603079 = validateParameter(valid_603079, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseBlueprints"))
  if valid_603079 != nil:
    section.add "X-Amz-Target", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Content-Sha256", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Date")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Date", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Credential")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Credential", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Security-Token")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Security-Token", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Algorithm")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Algorithm", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-SignedHeaders", valid_603086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603088: Call_GetRelationalDatabaseBlueprints_603076;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database.</p> <p>You can use a blueprint ID to create a new database that runs a specific database engine.</p>
  ## 
  let valid = call_603088.validator(path, query, header, formData, body)
  let scheme = call_603088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603088.url(scheme.get, call_603088.host, call_603088.base,
                         call_603088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603088, url, valid)

proc call*(call_603089: Call_GetRelationalDatabaseBlueprints_603076; body: JsonNode): Recallable =
  ## getRelationalDatabaseBlueprints
  ## <p>Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database.</p> <p>You can use a blueprint ID to create a new database that runs a specific database engine.</p>
  ##   body: JObject (required)
  var body_603090 = newJObject()
  if body != nil:
    body_603090 = body
  result = call_603089.call(nil, nil, nil, nil, body_603090)

var getRelationalDatabaseBlueprints* = Call_GetRelationalDatabaseBlueprints_603076(
    name: "getRelationalDatabaseBlueprints", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseBlueprints",
    validator: validate_GetRelationalDatabaseBlueprints_603077, base: "/",
    url: url_GetRelationalDatabaseBlueprints_603078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseBundles_603091 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabaseBundles_603093(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseBundles_603092(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603094 = header.getOrDefault("X-Amz-Target")
  valid_603094 = validateParameter(valid_603094, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseBundles"))
  if valid_603094 != nil:
    section.add "X-Amz-Target", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Content-Sha256", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Date")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Date", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Credential")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Credential", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Security-Token")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Security-Token", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Algorithm")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Algorithm", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-SignedHeaders", valid_603101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603103: Call_GetRelationalDatabaseBundles_603091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database.</p> <p>You can use a bundle ID to create a new database with explicit performance specifications.</p>
  ## 
  let valid = call_603103.validator(path, query, header, formData, body)
  let scheme = call_603103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603103.url(scheme.get, call_603103.host, call_603103.base,
                         call_603103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603103, url, valid)

proc call*(call_603104: Call_GetRelationalDatabaseBundles_603091; body: JsonNode): Recallable =
  ## getRelationalDatabaseBundles
  ## <p>Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database.</p> <p>You can use a bundle ID to create a new database with explicit performance specifications.</p>
  ##   body: JObject (required)
  var body_603105 = newJObject()
  if body != nil:
    body_603105 = body
  result = call_603104.call(nil, nil, nil, nil, body_603105)

var getRelationalDatabaseBundles* = Call_GetRelationalDatabaseBundles_603091(
    name: "getRelationalDatabaseBundles", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseBundles",
    validator: validate_GetRelationalDatabaseBundles_603092, base: "/",
    url: url_GetRelationalDatabaseBundles_603093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseEvents_603106 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabaseEvents_603108(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseEvents_603107(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603109 = header.getOrDefault("X-Amz-Target")
  valid_603109 = validateParameter(valid_603109, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseEvents"))
  if valid_603109 != nil:
    section.add "X-Amz-Target", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Content-Sha256", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Date")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Date", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Credential")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Credential", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Security-Token")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Security-Token", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Algorithm")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Algorithm", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-SignedHeaders", valid_603116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603118: Call_GetRelationalDatabaseEvents_603106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of events for a specific database in Amazon Lightsail.
  ## 
  let valid = call_603118.validator(path, query, header, formData, body)
  let scheme = call_603118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603118.url(scheme.get, call_603118.host, call_603118.base,
                         call_603118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603118, url, valid)

proc call*(call_603119: Call_GetRelationalDatabaseEvents_603106; body: JsonNode): Recallable =
  ## getRelationalDatabaseEvents
  ## Returns a list of events for a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_603120 = newJObject()
  if body != nil:
    body_603120 = body
  result = call_603119.call(nil, nil, nil, nil, body_603120)

var getRelationalDatabaseEvents* = Call_GetRelationalDatabaseEvents_603106(
    name: "getRelationalDatabaseEvents", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseEvents",
    validator: validate_GetRelationalDatabaseEvents_603107, base: "/",
    url: url_GetRelationalDatabaseEvents_603108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseLogEvents_603121 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabaseLogEvents_603123(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseLogEvents_603122(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603124 = header.getOrDefault("X-Amz-Target")
  valid_603124 = validateParameter(valid_603124, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseLogEvents"))
  if valid_603124 != nil:
    section.add "X-Amz-Target", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Content-Sha256", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Date")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Date", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Credential")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Credential", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Security-Token")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Security-Token", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Algorithm")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Algorithm", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-SignedHeaders", valid_603131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603133: Call_GetRelationalDatabaseLogEvents_603121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of log events for a database in Amazon Lightsail.
  ## 
  let valid = call_603133.validator(path, query, header, formData, body)
  let scheme = call_603133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603133.url(scheme.get, call_603133.host, call_603133.base,
                         call_603133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603133, url, valid)

proc call*(call_603134: Call_GetRelationalDatabaseLogEvents_603121; body: JsonNode): Recallable =
  ## getRelationalDatabaseLogEvents
  ## Returns a list of log events for a database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_603135 = newJObject()
  if body != nil:
    body_603135 = body
  result = call_603134.call(nil, nil, nil, nil, body_603135)

var getRelationalDatabaseLogEvents* = Call_GetRelationalDatabaseLogEvents_603121(
    name: "getRelationalDatabaseLogEvents", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseLogEvents",
    validator: validate_GetRelationalDatabaseLogEvents_603122, base: "/",
    url: url_GetRelationalDatabaseLogEvents_603123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseLogStreams_603136 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabaseLogStreams_603138(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseLogStreams_603137(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603139 = header.getOrDefault("X-Amz-Target")
  valid_603139 = validateParameter(valid_603139, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseLogStreams"))
  if valid_603139 != nil:
    section.add "X-Amz-Target", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Content-Sha256", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Date")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Date", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Credential")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Credential", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Security-Token")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Security-Token", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Algorithm")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Algorithm", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-SignedHeaders", valid_603146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603148: Call_GetRelationalDatabaseLogStreams_603136;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of available log streams for a specific database in Amazon Lightsail.
  ## 
  let valid = call_603148.validator(path, query, header, formData, body)
  let scheme = call_603148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603148.url(scheme.get, call_603148.host, call_603148.base,
                         call_603148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603148, url, valid)

proc call*(call_603149: Call_GetRelationalDatabaseLogStreams_603136; body: JsonNode): Recallable =
  ## getRelationalDatabaseLogStreams
  ## Returns a list of available log streams for a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_603150 = newJObject()
  if body != nil:
    body_603150 = body
  result = call_603149.call(nil, nil, nil, nil, body_603150)

var getRelationalDatabaseLogStreams* = Call_GetRelationalDatabaseLogStreams_603136(
    name: "getRelationalDatabaseLogStreams", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseLogStreams",
    validator: validate_GetRelationalDatabaseLogStreams_603137, base: "/",
    url: url_GetRelationalDatabaseLogStreams_603138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseMasterUserPassword_603151 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabaseMasterUserPassword_603153(protocol: Scheme;
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

proc validate_GetRelationalDatabaseMasterUserPassword_603152(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603154 = header.getOrDefault("X-Amz-Target")
  valid_603154 = validateParameter(valid_603154, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseMasterUserPassword"))
  if valid_603154 != nil:
    section.add "X-Amz-Target", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Content-Sha256", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Date")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Date", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Credential")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Credential", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Security-Token")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Security-Token", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Algorithm")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Algorithm", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-SignedHeaders", valid_603161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603163: Call_GetRelationalDatabaseMasterUserPassword_603151;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the current, previous, or pending versions of the master user password for a Lightsail database.</p> <p>The <code>GetRelationalDatabaseMasterUserPassword</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.</p>
  ## 
  let valid = call_603163.validator(path, query, header, formData, body)
  let scheme = call_603163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603163.url(scheme.get, call_603163.host, call_603163.base,
                         call_603163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603163, url, valid)

proc call*(call_603164: Call_GetRelationalDatabaseMasterUserPassword_603151;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseMasterUserPassword
  ## <p>Returns the current, previous, or pending versions of the master user password for a Lightsail database.</p> <p>The <code>GetRelationalDatabaseMasterUserPassword</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.</p>
  ##   body: JObject (required)
  var body_603165 = newJObject()
  if body != nil:
    body_603165 = body
  result = call_603164.call(nil, nil, nil, nil, body_603165)

var getRelationalDatabaseMasterUserPassword* = Call_GetRelationalDatabaseMasterUserPassword_603151(
    name: "getRelationalDatabaseMasterUserPassword", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseMasterUserPassword",
    validator: validate_GetRelationalDatabaseMasterUserPassword_603152, base: "/",
    url: url_GetRelationalDatabaseMasterUserPassword_603153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseMetricData_603166 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabaseMetricData_603168(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseMetricData_603167(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603169 = header.getOrDefault("X-Amz-Target")
  valid_603169 = validateParameter(valid_603169, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseMetricData"))
  if valid_603169 != nil:
    section.add "X-Amz-Target", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Content-Sha256", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Date")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Date", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Credential")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Credential", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Security-Token")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Security-Token", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Algorithm")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Algorithm", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-SignedHeaders", valid_603176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_GetRelationalDatabaseMetricData_603166;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the data points of the specified metric for a database in Amazon Lightsail.
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603178, url, valid)

proc call*(call_603179: Call_GetRelationalDatabaseMetricData_603166; body: JsonNode): Recallable =
  ## getRelationalDatabaseMetricData
  ## Returns the data points of the specified metric for a database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_603180 = newJObject()
  if body != nil:
    body_603180 = body
  result = call_603179.call(nil, nil, nil, nil, body_603180)

var getRelationalDatabaseMetricData* = Call_GetRelationalDatabaseMetricData_603166(
    name: "getRelationalDatabaseMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseMetricData",
    validator: validate_GetRelationalDatabaseMetricData_603167, base: "/",
    url: url_GetRelationalDatabaseMetricData_603168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseParameters_603181 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabaseParameters_603183(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseParameters_603182(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603184 = header.getOrDefault("X-Amz-Target")
  valid_603184 = validateParameter(valid_603184, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseParameters"))
  if valid_603184 != nil:
    section.add "X-Amz-Target", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Content-Sha256", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Date")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Date", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Credential")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Credential", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Security-Token")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Security-Token", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Algorithm")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Algorithm", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-SignedHeaders", valid_603191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603193: Call_GetRelationalDatabaseParameters_603181;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail.</p> <p>In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.</p>
  ## 
  let valid = call_603193.validator(path, query, header, formData, body)
  let scheme = call_603193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603193.url(scheme.get, call_603193.host, call_603193.base,
                         call_603193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603193, url, valid)

proc call*(call_603194: Call_GetRelationalDatabaseParameters_603181; body: JsonNode): Recallable =
  ## getRelationalDatabaseParameters
  ## <p>Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail.</p> <p>In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.</p>
  ##   body: JObject (required)
  var body_603195 = newJObject()
  if body != nil:
    body_603195 = body
  result = call_603194.call(nil, nil, nil, nil, body_603195)

var getRelationalDatabaseParameters* = Call_GetRelationalDatabaseParameters_603181(
    name: "getRelationalDatabaseParameters", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseParameters",
    validator: validate_GetRelationalDatabaseParameters_603182, base: "/",
    url: url_GetRelationalDatabaseParameters_603183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseSnapshot_603196 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabaseSnapshot_603198(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseSnapshot_603197(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603199 = header.getOrDefault("X-Amz-Target")
  valid_603199 = validateParameter(valid_603199, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseSnapshot"))
  if valid_603199 != nil:
    section.add "X-Amz-Target", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Content-Sha256", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Date")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Date", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Credential")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Credential", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Security-Token")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Security-Token", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Algorithm")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Algorithm", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-SignedHeaders", valid_603206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603208: Call_GetRelationalDatabaseSnapshot_603196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific database snapshot in Amazon Lightsail.
  ## 
  let valid = call_603208.validator(path, query, header, formData, body)
  let scheme = call_603208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603208.url(scheme.get, call_603208.host, call_603208.base,
                         call_603208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603208, url, valid)

proc call*(call_603209: Call_GetRelationalDatabaseSnapshot_603196; body: JsonNode): Recallable =
  ## getRelationalDatabaseSnapshot
  ## Returns information about a specific database snapshot in Amazon Lightsail.
  ##   body: JObject (required)
  var body_603210 = newJObject()
  if body != nil:
    body_603210 = body
  result = call_603209.call(nil, nil, nil, nil, body_603210)

var getRelationalDatabaseSnapshot* = Call_GetRelationalDatabaseSnapshot_603196(
    name: "getRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseSnapshot",
    validator: validate_GetRelationalDatabaseSnapshot_603197, base: "/",
    url: url_GetRelationalDatabaseSnapshot_603198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseSnapshots_603211 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabaseSnapshots_603213(protocol: Scheme; host: string;
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

proc validate_GetRelationalDatabaseSnapshots_603212(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603214 = header.getOrDefault("X-Amz-Target")
  valid_603214 = validateParameter(valid_603214, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseSnapshots"))
  if valid_603214 != nil:
    section.add "X-Amz-Target", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Content-Sha256", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Date")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Date", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Credential")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Credential", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Security-Token")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Security-Token", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Algorithm")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Algorithm", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-SignedHeaders", valid_603221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603223: Call_GetRelationalDatabaseSnapshots_603211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all of your database snapshots in Amazon Lightsail.
  ## 
  let valid = call_603223.validator(path, query, header, formData, body)
  let scheme = call_603223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603223.url(scheme.get, call_603223.host, call_603223.base,
                         call_603223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603223, url, valid)

proc call*(call_603224: Call_GetRelationalDatabaseSnapshots_603211; body: JsonNode): Recallable =
  ## getRelationalDatabaseSnapshots
  ## Returns information about all of your database snapshots in Amazon Lightsail.
  ##   body: JObject (required)
  var body_603225 = newJObject()
  if body != nil:
    body_603225 = body
  result = call_603224.call(nil, nil, nil, nil, body_603225)

var getRelationalDatabaseSnapshots* = Call_GetRelationalDatabaseSnapshots_603211(
    name: "getRelationalDatabaseSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseSnapshots",
    validator: validate_GetRelationalDatabaseSnapshots_603212, base: "/",
    url: url_GetRelationalDatabaseSnapshots_603213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabases_603226 = ref object of OpenApiRestCall_601389
proc url_GetRelationalDatabases_603228(protocol: Scheme; host: string; base: string;
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

proc validate_GetRelationalDatabases_603227(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603229 = header.getOrDefault("X-Amz-Target")
  valid_603229 = validateParameter(valid_603229, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabases"))
  if valid_603229 != nil:
    section.add "X-Amz-Target", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Content-Sha256", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Date")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Date", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Credential")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Credential", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Security-Token")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Security-Token", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Algorithm")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Algorithm", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-SignedHeaders", valid_603236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603238: Call_GetRelationalDatabases_603226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all of your databases in Amazon Lightsail.
  ## 
  let valid = call_603238.validator(path, query, header, formData, body)
  let scheme = call_603238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603238.url(scheme.get, call_603238.host, call_603238.base,
                         call_603238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603238, url, valid)

proc call*(call_603239: Call_GetRelationalDatabases_603226; body: JsonNode): Recallable =
  ## getRelationalDatabases
  ## Returns information about all of your databases in Amazon Lightsail.
  ##   body: JObject (required)
  var body_603240 = newJObject()
  if body != nil:
    body_603240 = body
  result = call_603239.call(nil, nil, nil, nil, body_603240)

var getRelationalDatabases* = Call_GetRelationalDatabases_603226(
    name: "getRelationalDatabases", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabases",
    validator: validate_GetRelationalDatabases_603227, base: "/",
    url: url_GetRelationalDatabases_603228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStaticIp_603241 = ref object of OpenApiRestCall_601389
proc url_GetStaticIp_603243(protocol: Scheme; host: string; base: string;
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

proc validate_GetStaticIp_603242(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603244 = header.getOrDefault("X-Amz-Target")
  valid_603244 = validateParameter(valid_603244, JString, required = true, default = newJString(
      "Lightsail_20161128.GetStaticIp"))
  if valid_603244 != nil:
    section.add "X-Amz-Target", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Content-Sha256", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Date")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Date", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Credential")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Credential", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Security-Token")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Security-Token", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Algorithm")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Algorithm", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-SignedHeaders", valid_603251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603253: Call_GetStaticIp_603241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific static IP.
  ## 
  let valid = call_603253.validator(path, query, header, formData, body)
  let scheme = call_603253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603253.url(scheme.get, call_603253.host, call_603253.base,
                         call_603253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603253, url, valid)

proc call*(call_603254: Call_GetStaticIp_603241; body: JsonNode): Recallable =
  ## getStaticIp
  ## Returns information about a specific static IP.
  ##   body: JObject (required)
  var body_603255 = newJObject()
  if body != nil:
    body_603255 = body
  result = call_603254.call(nil, nil, nil, nil, body_603255)

var getStaticIp* = Call_GetStaticIp_603241(name: "getStaticIp",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetStaticIp",
                                        validator: validate_GetStaticIp_603242,
                                        base: "/", url: url_GetStaticIp_603243,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStaticIps_603256 = ref object of OpenApiRestCall_601389
proc url_GetStaticIps_603258(protocol: Scheme; host: string; base: string;
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

proc validate_GetStaticIps_603257(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603259 = header.getOrDefault("X-Amz-Target")
  valid_603259 = validateParameter(valid_603259, JString, required = true, default = newJString(
      "Lightsail_20161128.GetStaticIps"))
  if valid_603259 != nil:
    section.add "X-Amz-Target", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Content-Sha256", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Date")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Date", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Credential")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Credential", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Security-Token")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Security-Token", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Algorithm")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Algorithm", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-SignedHeaders", valid_603266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603268: Call_GetStaticIps_603256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all static IPs in the user's account.
  ## 
  let valid = call_603268.validator(path, query, header, formData, body)
  let scheme = call_603268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603268.url(scheme.get, call_603268.host, call_603268.base,
                         call_603268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603268, url, valid)

proc call*(call_603269: Call_GetStaticIps_603256; body: JsonNode): Recallable =
  ## getStaticIps
  ## Returns information about all static IPs in the user's account.
  ##   body: JObject (required)
  var body_603270 = newJObject()
  if body != nil:
    body_603270 = body
  result = call_603269.call(nil, nil, nil, nil, body_603270)

var getStaticIps* = Call_GetStaticIps_603256(name: "getStaticIps",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetStaticIps",
    validator: validate_GetStaticIps_603257, base: "/", url: url_GetStaticIps_603258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportKeyPair_603271 = ref object of OpenApiRestCall_601389
proc url_ImportKeyPair_603273(protocol: Scheme; host: string; base: string;
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

proc validate_ImportKeyPair_603272(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603274 = header.getOrDefault("X-Amz-Target")
  valid_603274 = validateParameter(valid_603274, JString, required = true, default = newJString(
      "Lightsail_20161128.ImportKeyPair"))
  if valid_603274 != nil:
    section.add "X-Amz-Target", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Content-Sha256", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Date")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Date", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Credential")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Credential", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Security-Token")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Security-Token", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Algorithm")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Algorithm", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-SignedHeaders", valid_603281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603283: Call_ImportKeyPair_603271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports a public SSH key from a specific key pair.
  ## 
  let valid = call_603283.validator(path, query, header, formData, body)
  let scheme = call_603283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603283.url(scheme.get, call_603283.host, call_603283.base,
                         call_603283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603283, url, valid)

proc call*(call_603284: Call_ImportKeyPair_603271; body: JsonNode): Recallable =
  ## importKeyPair
  ## Imports a public SSH key from a specific key pair.
  ##   body: JObject (required)
  var body_603285 = newJObject()
  if body != nil:
    body_603285 = body
  result = call_603284.call(nil, nil, nil, nil, body_603285)

var importKeyPair* = Call_ImportKeyPair_603271(name: "importKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ImportKeyPair",
    validator: validate_ImportKeyPair_603272, base: "/", url: url_ImportKeyPair_603273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_IsVpcPeered_603286 = ref object of OpenApiRestCall_601389
proc url_IsVpcPeered_603288(protocol: Scheme; host: string; base: string;
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

proc validate_IsVpcPeered_603287(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603289 = header.getOrDefault("X-Amz-Target")
  valid_603289 = validateParameter(valid_603289, JString, required = true, default = newJString(
      "Lightsail_20161128.IsVpcPeered"))
  if valid_603289 != nil:
    section.add "X-Amz-Target", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Content-Sha256", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Date")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Date", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Credential")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Credential", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Security-Token")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Security-Token", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Algorithm")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Algorithm", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-SignedHeaders", valid_603296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603298: Call_IsVpcPeered_603286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a Boolean value indicating whether your Lightsail VPC is peered.
  ## 
  let valid = call_603298.validator(path, query, header, formData, body)
  let scheme = call_603298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603298.url(scheme.get, call_603298.host, call_603298.base,
                         call_603298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603298, url, valid)

proc call*(call_603299: Call_IsVpcPeered_603286; body: JsonNode): Recallable =
  ## isVpcPeered
  ## Returns a Boolean value indicating whether your Lightsail VPC is peered.
  ##   body: JObject (required)
  var body_603300 = newJObject()
  if body != nil:
    body_603300 = body
  result = call_603299.call(nil, nil, nil, nil, body_603300)

var isVpcPeered* = Call_IsVpcPeered_603286(name: "isVpcPeered",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.IsVpcPeered",
                                        validator: validate_IsVpcPeered_603287,
                                        base: "/", url: url_IsVpcPeered_603288,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_OpenInstancePublicPorts_603301 = ref object of OpenApiRestCall_601389
proc url_OpenInstancePublicPorts_603303(protocol: Scheme; host: string; base: string;
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

proc validate_OpenInstancePublicPorts_603302(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603304 = header.getOrDefault("X-Amz-Target")
  valid_603304 = validateParameter(valid_603304, JString, required = true, default = newJString(
      "Lightsail_20161128.OpenInstancePublicPorts"))
  if valid_603304 != nil:
    section.add "X-Amz-Target", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Content-Sha256", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Date")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Date", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Credential")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Credential", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Security-Token")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Security-Token", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Algorithm")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Algorithm", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-SignedHeaders", valid_603311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603313: Call_OpenInstancePublicPorts_603301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds public ports to an Amazon Lightsail instance.</p> <p>The <code>open instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603313.validator(path, query, header, formData, body)
  let scheme = call_603313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603313.url(scheme.get, call_603313.host, call_603313.base,
                         call_603313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603313, url, valid)

proc call*(call_603314: Call_OpenInstancePublicPorts_603301; body: JsonNode): Recallable =
  ## openInstancePublicPorts
  ## <p>Adds public ports to an Amazon Lightsail instance.</p> <p>The <code>open instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603315 = newJObject()
  if body != nil:
    body_603315 = body
  result = call_603314.call(nil, nil, nil, nil, body_603315)

var openInstancePublicPorts* = Call_OpenInstancePublicPorts_603301(
    name: "openInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.OpenInstancePublicPorts",
    validator: validate_OpenInstancePublicPorts_603302, base: "/",
    url: url_OpenInstancePublicPorts_603303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PeerVpc_603316 = ref object of OpenApiRestCall_601389
proc url_PeerVpc_603318(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PeerVpc_603317(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603319 = header.getOrDefault("X-Amz-Target")
  valid_603319 = validateParameter(valid_603319, JString, required = true, default = newJString(
      "Lightsail_20161128.PeerVpc"))
  if valid_603319 != nil:
    section.add "X-Amz-Target", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Content-Sha256", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Date")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Date", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Credential")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Credential", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Security-Token")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Security-Token", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Algorithm")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Algorithm", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-SignedHeaders", valid_603326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603328: Call_PeerVpc_603316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tries to peer the Lightsail VPC with the user's default VPC.
  ## 
  let valid = call_603328.validator(path, query, header, formData, body)
  let scheme = call_603328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603328.url(scheme.get, call_603328.host, call_603328.base,
                         call_603328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603328, url, valid)

proc call*(call_603329: Call_PeerVpc_603316; body: JsonNode): Recallable =
  ## peerVpc
  ## Tries to peer the Lightsail VPC with the user's default VPC.
  ##   body: JObject (required)
  var body_603330 = newJObject()
  if body != nil:
    body_603330 = body
  result = call_603329.call(nil, nil, nil, nil, body_603330)

var peerVpc* = Call_PeerVpc_603316(name: "peerVpc", meth: HttpMethod.HttpPost,
                                host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.PeerVpc",
                                validator: validate_PeerVpc_603317, base: "/",
                                url: url_PeerVpc_603318,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInstancePublicPorts_603331 = ref object of OpenApiRestCall_601389
proc url_PutInstancePublicPorts_603333(protocol: Scheme; host: string; base: string;
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

proc validate_PutInstancePublicPorts_603332(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603334 = header.getOrDefault("X-Amz-Target")
  valid_603334 = validateParameter(valid_603334, JString, required = true, default = newJString(
      "Lightsail_20161128.PutInstancePublicPorts"))
  if valid_603334 != nil:
    section.add "X-Amz-Target", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Content-Sha256", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Date")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Date", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Credential")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Credential", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Security-Token")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Security-Token", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Algorithm")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Algorithm", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-SignedHeaders", valid_603341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603343: Call_PutInstancePublicPorts_603331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the specified open ports for an Amazon Lightsail instance, and closes all ports for every protocol not included in the current request.</p> <p>The <code>put instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603343.validator(path, query, header, formData, body)
  let scheme = call_603343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603343.url(scheme.get, call_603343.host, call_603343.base,
                         call_603343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603343, url, valid)

proc call*(call_603344: Call_PutInstancePublicPorts_603331; body: JsonNode): Recallable =
  ## putInstancePublicPorts
  ## <p>Sets the specified open ports for an Amazon Lightsail instance, and closes all ports for every protocol not included in the current request.</p> <p>The <code>put instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603345 = newJObject()
  if body != nil:
    body_603345 = body
  result = call_603344.call(nil, nil, nil, nil, body_603345)

var putInstancePublicPorts* = Call_PutInstancePublicPorts_603331(
    name: "putInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.PutInstancePublicPorts",
    validator: validate_PutInstancePublicPorts_603332, base: "/",
    url: url_PutInstancePublicPorts_603333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootInstance_603346 = ref object of OpenApiRestCall_601389
proc url_RebootInstance_603348(protocol: Scheme; host: string; base: string;
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

proc validate_RebootInstance_603347(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603349 = header.getOrDefault("X-Amz-Target")
  valid_603349 = validateParameter(valid_603349, JString, required = true, default = newJString(
      "Lightsail_20161128.RebootInstance"))
  if valid_603349 != nil:
    section.add "X-Amz-Target", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Content-Sha256", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Date")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Date", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Credential")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Credential", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Security-Token")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Security-Token", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Algorithm")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Algorithm", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-SignedHeaders", valid_603356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603358: Call_RebootInstance_603346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restarts a specific instance.</p> <p>The <code>reboot instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603358.validator(path, query, header, formData, body)
  let scheme = call_603358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603358.url(scheme.get, call_603358.host, call_603358.base,
                         call_603358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603358, url, valid)

proc call*(call_603359: Call_RebootInstance_603346; body: JsonNode): Recallable =
  ## rebootInstance
  ## <p>Restarts a specific instance.</p> <p>The <code>reboot instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603360 = newJObject()
  if body != nil:
    body_603360 = body
  result = call_603359.call(nil, nil, nil, nil, body_603360)

var rebootInstance* = Call_RebootInstance_603346(name: "rebootInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.RebootInstance",
    validator: validate_RebootInstance_603347, base: "/", url: url_RebootInstance_603348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootRelationalDatabase_603361 = ref object of OpenApiRestCall_601389
proc url_RebootRelationalDatabase_603363(protocol: Scheme; host: string;
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

proc validate_RebootRelationalDatabase_603362(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603364 = header.getOrDefault("X-Amz-Target")
  valid_603364 = validateParameter(valid_603364, JString, required = true, default = newJString(
      "Lightsail_20161128.RebootRelationalDatabase"))
  if valid_603364 != nil:
    section.add "X-Amz-Target", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Content-Sha256", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Date")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Date", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Credential")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Credential", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Security-Token")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Security-Token", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Algorithm")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Algorithm", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-SignedHeaders", valid_603371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603373: Call_RebootRelationalDatabase_603361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603373.validator(path, query, header, formData, body)
  let scheme = call_603373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603373.url(scheme.get, call_603373.host, call_603373.base,
                         call_603373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603373, url, valid)

proc call*(call_603374: Call_RebootRelationalDatabase_603361; body: JsonNode): Recallable =
  ## rebootRelationalDatabase
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603375 = newJObject()
  if body != nil:
    body_603375 = body
  result = call_603374.call(nil, nil, nil, nil, body_603375)

var rebootRelationalDatabase* = Call_RebootRelationalDatabase_603361(
    name: "rebootRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.RebootRelationalDatabase",
    validator: validate_RebootRelationalDatabase_603362, base: "/",
    url: url_RebootRelationalDatabase_603363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReleaseStaticIp_603376 = ref object of OpenApiRestCall_601389
proc url_ReleaseStaticIp_603378(protocol: Scheme; host: string; base: string;
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

proc validate_ReleaseStaticIp_603377(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603379 = header.getOrDefault("X-Amz-Target")
  valid_603379 = validateParameter(valid_603379, JString, required = true, default = newJString(
      "Lightsail_20161128.ReleaseStaticIp"))
  if valid_603379 != nil:
    section.add "X-Amz-Target", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Content-Sha256", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Date")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Date", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Credential")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Credential", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-Security-Token")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Security-Token", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Algorithm")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Algorithm", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-SignedHeaders", valid_603386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603388: Call_ReleaseStaticIp_603376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specific static IP from your account.
  ## 
  let valid = call_603388.validator(path, query, header, formData, body)
  let scheme = call_603388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603388.url(scheme.get, call_603388.host, call_603388.base,
                         call_603388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603388, url, valid)

proc call*(call_603389: Call_ReleaseStaticIp_603376; body: JsonNode): Recallable =
  ## releaseStaticIp
  ## Deletes a specific static IP from your account.
  ##   body: JObject (required)
  var body_603390 = newJObject()
  if body != nil:
    body_603390 = body
  result = call_603389.call(nil, nil, nil, nil, body_603390)

var releaseStaticIp* = Call_ReleaseStaticIp_603376(name: "releaseStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ReleaseStaticIp",
    validator: validate_ReleaseStaticIp_603377, base: "/", url: url_ReleaseStaticIp_603378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartInstance_603391 = ref object of OpenApiRestCall_601389
proc url_StartInstance_603393(protocol: Scheme; host: string; base: string;
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

proc validate_StartInstance_603392(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603394 = header.getOrDefault("X-Amz-Target")
  valid_603394 = validateParameter(valid_603394, JString, required = true, default = newJString(
      "Lightsail_20161128.StartInstance"))
  if valid_603394 != nil:
    section.add "X-Amz-Target", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Content-Sha256", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Date")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Date", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Credential")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Credential", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Security-Token")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Security-Token", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Algorithm")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Algorithm", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-SignedHeaders", valid_603401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603403: Call_StartInstance_603391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603403.validator(path, query, header, formData, body)
  let scheme = call_603403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603403.url(scheme.get, call_603403.host, call_603403.base,
                         call_603403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603403, url, valid)

proc call*(call_603404: Call_StartInstance_603391; body: JsonNode): Recallable =
  ## startInstance
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603405 = newJObject()
  if body != nil:
    body_603405 = body
  result = call_603404.call(nil, nil, nil, nil, body_603405)

var startInstance* = Call_StartInstance_603391(name: "startInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StartInstance",
    validator: validate_StartInstance_603392, base: "/", url: url_StartInstance_603393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRelationalDatabase_603406 = ref object of OpenApiRestCall_601389
proc url_StartRelationalDatabase_603408(protocol: Scheme; host: string; base: string;
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

proc validate_StartRelationalDatabase_603407(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603409 = header.getOrDefault("X-Amz-Target")
  valid_603409 = validateParameter(valid_603409, JString, required = true, default = newJString(
      "Lightsail_20161128.StartRelationalDatabase"))
  if valid_603409 != nil:
    section.add "X-Amz-Target", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Content-Sha256", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Date")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Date", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Credential")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Credential", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Security-Token")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Security-Token", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Algorithm")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Algorithm", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-SignedHeaders", valid_603416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603418: Call_StartRelationalDatabase_603406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the <code>reboot relational database</code> operation.</p> <p>The <code>start relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603418.validator(path, query, header, formData, body)
  let scheme = call_603418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603418.url(scheme.get, call_603418.host, call_603418.base,
                         call_603418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603418, url, valid)

proc call*(call_603419: Call_StartRelationalDatabase_603406; body: JsonNode): Recallable =
  ## startRelationalDatabase
  ## <p>Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the <code>reboot relational database</code> operation.</p> <p>The <code>start relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603420 = newJObject()
  if body != nil:
    body_603420 = body
  result = call_603419.call(nil, nil, nil, nil, body_603420)

var startRelationalDatabase* = Call_StartRelationalDatabase_603406(
    name: "startRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StartRelationalDatabase",
    validator: validate_StartRelationalDatabase_603407, base: "/",
    url: url_StartRelationalDatabase_603408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopInstance_603421 = ref object of OpenApiRestCall_601389
proc url_StopInstance_603423(protocol: Scheme; host: string; base: string;
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

proc validate_StopInstance_603422(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603424 = header.getOrDefault("X-Amz-Target")
  valid_603424 = validateParameter(valid_603424, JString, required = true, default = newJString(
      "Lightsail_20161128.StopInstance"))
  if valid_603424 != nil:
    section.add "X-Amz-Target", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Signature")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Signature", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Content-Sha256", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Date")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Date", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Credential")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Credential", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Security-Token")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Security-Token", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Algorithm")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Algorithm", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-SignedHeaders", valid_603431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603433: Call_StopInstance_603421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603433.validator(path, query, header, formData, body)
  let scheme = call_603433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603433.url(scheme.get, call_603433.host, call_603433.base,
                         call_603433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603433, url, valid)

proc call*(call_603434: Call_StopInstance_603421; body: JsonNode): Recallable =
  ## stopInstance
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603435 = newJObject()
  if body != nil:
    body_603435 = body
  result = call_603434.call(nil, nil, nil, nil, body_603435)

var stopInstance* = Call_StopInstance_603421(name: "stopInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StopInstance",
    validator: validate_StopInstance_603422, base: "/", url: url_StopInstance_603423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRelationalDatabase_603436 = ref object of OpenApiRestCall_601389
proc url_StopRelationalDatabase_603438(protocol: Scheme; host: string; base: string;
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

proc validate_StopRelationalDatabase_603437(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603439 = header.getOrDefault("X-Amz-Target")
  valid_603439 = validateParameter(valid_603439, JString, required = true, default = newJString(
      "Lightsail_20161128.StopRelationalDatabase"))
  if valid_603439 != nil:
    section.add "X-Amz-Target", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Signature")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Signature", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Content-Sha256", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Date")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Date", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Credential")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Credential", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Security-Token")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Security-Token", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Algorithm")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Algorithm", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-SignedHeaders", valid_603446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603448: Call_StopRelationalDatabase_603436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a specific database that is currently running in Amazon Lightsail.</p> <p>The <code>stop relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603448.validator(path, query, header, formData, body)
  let scheme = call_603448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603448.url(scheme.get, call_603448.host, call_603448.base,
                         call_603448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603448, url, valid)

proc call*(call_603449: Call_StopRelationalDatabase_603436; body: JsonNode): Recallable =
  ## stopRelationalDatabase
  ## <p>Stops a specific database that is currently running in Amazon Lightsail.</p> <p>The <code>stop relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603450 = newJObject()
  if body != nil:
    body_603450 = body
  result = call_603449.call(nil, nil, nil, nil, body_603450)

var stopRelationalDatabase* = Call_StopRelationalDatabase_603436(
    name: "stopRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StopRelationalDatabase",
    validator: validate_StopRelationalDatabase_603437, base: "/",
    url: url_StopRelationalDatabase_603438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603451 = ref object of OpenApiRestCall_601389
proc url_TagResource_603453(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_603452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603454 = header.getOrDefault("X-Amz-Target")
  valid_603454 = validateParameter(valid_603454, JString, required = true, default = newJString(
      "Lightsail_20161128.TagResource"))
  if valid_603454 != nil:
    section.add "X-Amz-Target", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Signature")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Signature", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Content-Sha256", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Date")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Date", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Credential")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Credential", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Security-Token")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Security-Token", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Algorithm")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Algorithm", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-SignedHeaders", valid_603461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603463: Call_TagResource_603451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-tags">Lightsail Dev Guide</a>.</p> <p>The <code>tag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603463.validator(path, query, header, formData, body)
  let scheme = call_603463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603463.url(scheme.get, call_603463.host, call_603463.base,
                         call_603463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603463, url, valid)

proc call*(call_603464: Call_TagResource_603451; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-tags">Lightsail Dev Guide</a>.</p> <p>The <code>tag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603465 = newJObject()
  if body != nil:
    body_603465 = body
  result = call_603464.call(nil, nil, nil, nil, body_603465)

var tagResource* = Call_TagResource_603451(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.TagResource",
                                        validator: validate_TagResource_603452,
                                        base: "/", url: url_TagResource_603453,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnpeerVpc_603466 = ref object of OpenApiRestCall_601389
proc url_UnpeerVpc_603468(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UnpeerVpc_603467(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603469 = header.getOrDefault("X-Amz-Target")
  valid_603469 = validateParameter(valid_603469, JString, required = true, default = newJString(
      "Lightsail_20161128.UnpeerVpc"))
  if valid_603469 != nil:
    section.add "X-Amz-Target", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Content-Sha256", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Date")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Date", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Credential")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Credential", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Security-Token")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Security-Token", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Algorithm")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Algorithm", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-SignedHeaders", valid_603476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603478: Call_UnpeerVpc_603466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to unpeer the Lightsail VPC from the user's default VPC.
  ## 
  let valid = call_603478.validator(path, query, header, formData, body)
  let scheme = call_603478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603478.url(scheme.get, call_603478.host, call_603478.base,
                         call_603478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603478, url, valid)

proc call*(call_603479: Call_UnpeerVpc_603466; body: JsonNode): Recallable =
  ## unpeerVpc
  ## Attempts to unpeer the Lightsail VPC from the user's default VPC.
  ##   body: JObject (required)
  var body_603480 = newJObject()
  if body != nil:
    body_603480 = body
  result = call_603479.call(nil, nil, nil, nil, body_603480)

var unpeerVpc* = Call_UnpeerVpc_603466(name: "unpeerVpc", meth: HttpMethod.HttpPost,
                                    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.UnpeerVpc",
                                    validator: validate_UnpeerVpc_603467,
                                    base: "/", url: url_UnpeerVpc_603468,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603481 = ref object of OpenApiRestCall_601389
proc url_UntagResource_603483(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_603482(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603484 = header.getOrDefault("X-Amz-Target")
  valid_603484 = validateParameter(valid_603484, JString, required = true, default = newJString(
      "Lightsail_20161128.UntagResource"))
  if valid_603484 != nil:
    section.add "X-Amz-Target", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Signature")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Signature", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Content-Sha256", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Date")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Date", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Credential")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Credential", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Security-Token")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Security-Token", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Algorithm")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Algorithm", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-SignedHeaders", valid_603491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603493: Call_UntagResource_603481; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603493.validator(path, query, header, formData, body)
  let scheme = call_603493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603493.url(scheme.get, call_603493.host, call_603493.base,
                         call_603493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603493, url, valid)

proc call*(call_603494: Call_UntagResource_603481; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603495 = newJObject()
  if body != nil:
    body_603495 = body
  result = call_603494.call(nil, nil, nil, nil, body_603495)

var untagResource* = Call_UntagResource_603481(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UntagResource",
    validator: validate_UntagResource_603482, base: "/", url: url_UntagResource_603483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainEntry_603496 = ref object of OpenApiRestCall_601389
proc url_UpdateDomainEntry_603498(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainEntry_603497(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603499 = header.getOrDefault("X-Amz-Target")
  valid_603499 = validateParameter(valid_603499, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateDomainEntry"))
  if valid_603499 != nil:
    section.add "X-Amz-Target", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Signature")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Signature", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Content-Sha256", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Date")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Date", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Credential")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Credential", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Security-Token")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Security-Token", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Algorithm")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Algorithm", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-SignedHeaders", valid_603506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603508: Call_UpdateDomainEntry_603496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a domain recordset after it is created.</p> <p>The <code>update domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603508.validator(path, query, header, formData, body)
  let scheme = call_603508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603508.url(scheme.get, call_603508.host, call_603508.base,
                         call_603508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603508, url, valid)

proc call*(call_603509: Call_UpdateDomainEntry_603496; body: JsonNode): Recallable =
  ## updateDomainEntry
  ## <p>Updates a domain recordset after it is created.</p> <p>The <code>update domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603510 = newJObject()
  if body != nil:
    body_603510 = body
  result = call_603509.call(nil, nil, nil, nil, body_603510)

var updateDomainEntry* = Call_UpdateDomainEntry_603496(name: "updateDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateDomainEntry",
    validator: validate_UpdateDomainEntry_603497, base: "/",
    url: url_UpdateDomainEntry_603498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoadBalancerAttribute_603511 = ref object of OpenApiRestCall_601389
proc url_UpdateLoadBalancerAttribute_603513(protocol: Scheme; host: string;
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

proc validate_UpdateLoadBalancerAttribute_603512(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603514 = header.getOrDefault("X-Amz-Target")
  valid_603514 = validateParameter(valid_603514, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateLoadBalancerAttribute"))
  if valid_603514 != nil:
    section.add "X-Amz-Target", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Signature")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Signature", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Content-Sha256", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Date")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Date", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Credential")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Credential", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Security-Token")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Security-Token", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Algorithm")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Algorithm", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-SignedHeaders", valid_603521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603523: Call_UpdateLoadBalancerAttribute_603511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603523.validator(path, query, header, formData, body)
  let scheme = call_603523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603523.url(scheme.get, call_603523.host, call_603523.base,
                         call_603523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603523, url, valid)

proc call*(call_603524: Call_UpdateLoadBalancerAttribute_603511; body: JsonNode): Recallable =
  ## updateLoadBalancerAttribute
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603525 = newJObject()
  if body != nil:
    body_603525 = body
  result = call_603524.call(nil, nil, nil, nil, body_603525)

var updateLoadBalancerAttribute* = Call_UpdateLoadBalancerAttribute_603511(
    name: "updateLoadBalancerAttribute", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateLoadBalancerAttribute",
    validator: validate_UpdateLoadBalancerAttribute_603512, base: "/",
    url: url_UpdateLoadBalancerAttribute_603513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRelationalDatabase_603526 = ref object of OpenApiRestCall_601389
proc url_UpdateRelationalDatabase_603528(protocol: Scheme; host: string;
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

proc validate_UpdateRelationalDatabase_603527(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603529 = header.getOrDefault("X-Amz-Target")
  valid_603529 = validateParameter(valid_603529, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateRelationalDatabase"))
  if valid_603529 != nil:
    section.add "X-Amz-Target", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Signature")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Signature", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Content-Sha256", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Date")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Date", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Credential")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Credential", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Security-Token")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Security-Token", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Algorithm")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Algorithm", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-SignedHeaders", valid_603536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603538: Call_UpdateRelationalDatabase_603526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603538.validator(path, query, header, formData, body)
  let scheme = call_603538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603538.url(scheme.get, call_603538.host, call_603538.base,
                         call_603538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603538, url, valid)

proc call*(call_603539: Call_UpdateRelationalDatabase_603526; body: JsonNode): Recallable =
  ## updateRelationalDatabase
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603540 = newJObject()
  if body != nil:
    body_603540 = body
  result = call_603539.call(nil, nil, nil, nil, body_603540)

var updateRelationalDatabase* = Call_UpdateRelationalDatabase_603526(
    name: "updateRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateRelationalDatabase",
    validator: validate_UpdateRelationalDatabase_603527, base: "/",
    url: url_UpdateRelationalDatabase_603528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRelationalDatabaseParameters_603541 = ref object of OpenApiRestCall_601389
proc url_UpdateRelationalDatabaseParameters_603543(protocol: Scheme; host: string;
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

proc validate_UpdateRelationalDatabaseParameters_603542(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603544 = header.getOrDefault("X-Amz-Target")
  valid_603544 = validateParameter(valid_603544, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateRelationalDatabaseParameters"))
  if valid_603544 != nil:
    section.add "X-Amz-Target", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Signature")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Signature", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Content-Sha256", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Date")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Date", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Credential")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Credential", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Security-Token")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Security-Token", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Algorithm")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Algorithm", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-SignedHeaders", valid_603551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603553: Call_UpdateRelationalDatabaseParameters_603541;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which parameter updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603553.validator(path, query, header, formData, body)
  let scheme = call_603553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603553.url(scheme.get, call_603553.host, call_603553.base,
                         call_603553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603553, url, valid)

proc call*(call_603554: Call_UpdateRelationalDatabaseParameters_603541;
          body: JsonNode): Recallable =
  ## updateRelationalDatabaseParameters
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which parameter updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603555 = newJObject()
  if body != nil:
    body_603555 = body
  result = call_603554.call(nil, nil, nil, nil, body_603555)

var updateRelationalDatabaseParameters* = Call_UpdateRelationalDatabaseParameters_603541(
    name: "updateRelationalDatabaseParameters", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.UpdateRelationalDatabaseParameters",
    validator: validate_UpdateRelationalDatabaseParameters_603542, base: "/",
    url: url_UpdateRelationalDatabaseParameters_603543,
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
