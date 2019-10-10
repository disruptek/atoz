
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AllocateStaticIp_602803 = ref object of OpenApiRestCall_602466
proc url_AllocateStaticIp_602805(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AllocateStaticIp_602804(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "Lightsail_20161128.AllocateStaticIp"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_AllocateStaticIp_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allocates a static IP address.
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_AllocateStaticIp_602803; body: JsonNode): Recallable =
  ## allocateStaticIp
  ## Allocates a static IP address.
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var allocateStaticIp* = Call_AllocateStaticIp_602803(name: "allocateStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AllocateStaticIp",
    validator: validate_AllocateStaticIp_602804, base: "/",
    url: url_AllocateStaticIp_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachDisk_603072 = ref object of OpenApiRestCall_602466
proc url_AttachDisk_603074(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachDisk_603073(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachDisk"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_AttachDisk_603072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name.</p> <p>The <code>attach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_AttachDisk_603072; body: JsonNode): Recallable =
  ## attachDisk
  ## <p>Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name.</p> <p>The <code>attach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var attachDisk* = Call_AttachDisk_603072(name: "attachDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.AttachDisk",
                                      validator: validate_AttachDisk_603073,
                                      base: "/", url: url_AttachDisk_603074,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachInstancesToLoadBalancer_603087 = ref object of OpenApiRestCall_602466
proc url_AttachInstancesToLoadBalancer_603089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachInstancesToLoadBalancer_603088(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachInstancesToLoadBalancer"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_AttachInstancesToLoadBalancer_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches one or more Lightsail instances to a load balancer.</p> <p>After some time, the instances are attached to the load balancer and the health check status is available.</p> <p>The <code>attach instances to load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_AttachInstancesToLoadBalancer_603087; body: JsonNode): Recallable =
  ## attachInstancesToLoadBalancer
  ## <p>Attaches one or more Lightsail instances to a load balancer.</p> <p>After some time, the instances are attached to the load balancer and the health check status is available.</p> <p>The <code>attach instances to load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var attachInstancesToLoadBalancer* = Call_AttachInstancesToLoadBalancer_603087(
    name: "attachInstancesToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AttachInstancesToLoadBalancer",
    validator: validate_AttachInstancesToLoadBalancer_603088, base: "/",
    url: url_AttachInstancesToLoadBalancer_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachLoadBalancerTlsCertificate_603102 = ref object of OpenApiRestCall_602466
proc url_AttachLoadBalancerTlsCertificate_603104(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachLoadBalancerTlsCertificate_603103(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachLoadBalancerTlsCertificate"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_AttachLoadBalancerTlsCertificate_603102;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>attach load balancer tls certificate</code> operation with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>attach load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_AttachLoadBalancerTlsCertificate_603102;
          body: JsonNode): Recallable =
  ## attachLoadBalancerTlsCertificate
  ## <p>Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the <code>attach load balancer tls certificate</code> operation with the non-attached certificate, and it will replace the existing one and become the attached certificate.</p> <p>The <code>attach load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var attachLoadBalancerTlsCertificate* = Call_AttachLoadBalancerTlsCertificate_603102(
    name: "attachLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.AttachLoadBalancerTlsCertificate",
    validator: validate_AttachLoadBalancerTlsCertificate_603103, base: "/",
    url: url_AttachLoadBalancerTlsCertificate_603104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachStaticIp_603117 = ref object of OpenApiRestCall_602466
proc url_AttachStaticIp_603119(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachStaticIp_603118(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "Lightsail_20161128.AttachStaticIp"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
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
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_AttachStaticIp_603117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a static IP address to a specific Amazon Lightsail instance.
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_AttachStaticIp_603117; body: JsonNode): Recallable =
  ## attachStaticIp
  ## Attaches a static IP address to a specific Amazon Lightsail instance.
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var attachStaticIp* = Call_AttachStaticIp_603117(name: "attachStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.AttachStaticIp",
    validator: validate_AttachStaticIp_603118, base: "/", url: url_AttachStaticIp_603119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CloseInstancePublicPorts_603132 = ref object of OpenApiRestCall_602466
proc url_CloseInstancePublicPorts_603134(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CloseInstancePublicPorts_603133(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "Lightsail_20161128.CloseInstancePublicPorts"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_CloseInstancePublicPorts_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_CloseInstancePublicPorts_603132; body: JsonNode): Recallable =
  ## closeInstancePublicPorts
  ## <p>Closes the public ports on a specific Amazon Lightsail instance.</p> <p>The <code>close instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var closeInstancePublicPorts* = Call_CloseInstancePublicPorts_603132(
    name: "closeInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CloseInstancePublicPorts",
    validator: validate_CloseInstancePublicPorts_603133, base: "/",
    url: url_CloseInstancePublicPorts_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopySnapshot_603147 = ref object of OpenApiRestCall_602466
proc url_CopySnapshot_603149(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CopySnapshot_603148(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Copies a manual instance or disk snapshot as another manual snapshot, or copies an automatic instance or disk snapshot as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p> <note> <p>Database snapshots cannot be copied at this time.</p> </note>
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
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "Lightsail_20161128.CopySnapshot"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_CopySnapshot_603147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a manual instance or disk snapshot as another manual snapshot, or copies an automatic instance or disk snapshot as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p> <note> <p>Database snapshots cannot be copied at this time.</p> </note>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_CopySnapshot_603147; body: JsonNode): Recallable =
  ## copySnapshot
  ## <p>Copies a manual instance or disk snapshot as another manual snapshot, or copies an automatic instance or disk snapshot as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one AWS Region to another in Amazon Lightsail.</p> <p>When copying a <i>manual snapshot</i>, be sure to define the <code>source region</code>, <code>source snapshot name</code>, and <code>target snapshot name</code> parameters.</p> <p>When copying an <i>automatic snapshot</i>, be sure to define the <code>source region</code>, <code>source resource name</code>, <code>target snapshot name</code>, and either the <code>restore date</code> or the <code>use latest restorable auto snapshot</code> parameters.</p> <note> <p>Database snapshots cannot be copied at this time.</p> </note>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var copySnapshot* = Call_CopySnapshot_603147(name: "copySnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CopySnapshot",
    validator: validate_CopySnapshot_603148, base: "/", url: url_CopySnapshot_603149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCloudFormationStack_603162 = ref object of OpenApiRestCall_602466
proc url_CreateCloudFormationStack_603164(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCloudFormationStack_603163(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateCloudFormationStack"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
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
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_CreateCloudFormationStack_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_CreateCloudFormationStack_603162; body: JsonNode): Recallable =
  ## createCloudFormationStack
  ## <p>Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the <code>get cloud formation stack records</code> operation to get a list of the CloudFormation stacks created.</p> <important> <p>Wait until after your new Amazon EC2 instance is created before running the <code>create cloud formation stack</code> operation again with the same export snapshot record.</p> </important>
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var createCloudFormationStack* = Call_CreateCloudFormationStack_603162(
    name: "createCloudFormationStack", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateCloudFormationStack",
    validator: validate_CreateCloudFormationStack_603163, base: "/",
    url: url_CreateCloudFormationStack_603164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDisk_603177 = ref object of OpenApiRestCall_602466
proc url_CreateDisk_603179(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDisk_603178(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDisk"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_CreateDisk_603177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_CreateDisk_603177; body: JsonNode): Recallable =
  ## createDisk
  ## <p>Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var createDisk* = Call_CreateDisk_603177(name: "createDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateDisk",
                                      validator: validate_CreateDisk_603178,
                                      base: "/", url: url_CreateDisk_603179,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDiskFromSnapshot_603192 = ref object of OpenApiRestCall_602466
proc url_CreateDiskFromSnapshot_603194(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDiskFromSnapshot_603193(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDiskFromSnapshot"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_CreateDiskFromSnapshot_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_CreateDiskFromSnapshot_603192; body: JsonNode): Recallable =
  ## createDiskFromSnapshot
  ## <p>Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., <code>us-east-2a</code>).</p> <p>The <code>create disk from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var createDiskFromSnapshot* = Call_CreateDiskFromSnapshot_603192(
    name: "createDiskFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDiskFromSnapshot",
    validator: validate_CreateDiskFromSnapshot_603193, base: "/",
    url: url_CreateDiskFromSnapshot_603194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDiskSnapshot_603207 = ref object of OpenApiRestCall_602466
proc url_CreateDiskSnapshot_603209(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDiskSnapshot_603208(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDiskSnapshot"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_CreateDiskSnapshot_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance.</p> <p>You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending.</p> <p>You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the <code>instance name</code> parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk.</p> <p>The <code>create disk snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_CreateDiskSnapshot_603207; body: JsonNode): Recallable =
  ## createDiskSnapshot
  ## <p>Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance.</p> <p>You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending.</p> <p>You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the <code>instance name</code> parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk.</p> <p>The <code>create disk snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var createDiskSnapshot* = Call_CreateDiskSnapshot_603207(
    name: "createDiskSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDiskSnapshot",
    validator: validate_CreateDiskSnapshot_603208, base: "/",
    url: url_CreateDiskSnapshot_603209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_603222 = ref object of OpenApiRestCall_602466
proc url_CreateDomain_603224(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDomain_603223(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDomain"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_CreateDomain_603222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_CreateDomain_603222; body: JsonNode): Recallable =
  ## createDomain
  ## <p>Creates a domain resource for the specified domain (e.g., example.com).</p> <p>The <code>create domain</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var createDomain* = Call_CreateDomain_603222(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDomain",
    validator: validate_CreateDomain_603223, base: "/", url: url_CreateDomain_603224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainEntry_603237 = ref object of OpenApiRestCall_602466
proc url_CreateDomainEntry_603239(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDomainEntry_603238(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateDomainEntry"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_CreateDomainEntry_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one of the following entry records associated with the domain: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT).</p> <p>The <code>create domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_CreateDomainEntry_603237; body: JsonNode): Recallable =
  ## createDomainEntry
  ## <p>Creates one of the following entry records associated with the domain: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT).</p> <p>The <code>create domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var createDomainEntry* = Call_CreateDomainEntry_603237(name: "createDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateDomainEntry",
    validator: validate_CreateDomainEntry_603238, base: "/",
    url: url_CreateDomainEntry_603239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstanceSnapshot_603252 = ref object of OpenApiRestCall_602466
proc url_CreateInstanceSnapshot_603254(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateInstanceSnapshot_603253(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstanceSnapshot"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_CreateInstanceSnapshot_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a snapshot of a specific virtual private server, or <i>instance</i>. You can use a snapshot to create a new instance that is based on that snapshot.</p> <p>The <code>create instance snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_CreateInstanceSnapshot_603252; body: JsonNode): Recallable =
  ## createInstanceSnapshot
  ## <p>Creates a snapshot of a specific virtual private server, or <i>instance</i>. You can use a snapshot to create a new instance that is based on that snapshot.</p> <p>The <code>create instance snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var createInstanceSnapshot* = Call_CreateInstanceSnapshot_603252(
    name: "createInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstanceSnapshot",
    validator: validate_CreateInstanceSnapshot_603253, base: "/",
    url: url_CreateInstanceSnapshot_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstances_603267 = ref object of OpenApiRestCall_602466
proc url_CreateInstances_603269(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateInstances_603268(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstances"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_CreateInstances_603267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more Amazon Lightsail instances.</p> <p>The <code>create instances</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_CreateInstances_603267; body: JsonNode): Recallable =
  ## createInstances
  ## <p>Creates one or more Amazon Lightsail instances.</p> <p>The <code>create instances</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var createInstances* = Call_CreateInstances_603267(name: "createInstances",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstances",
    validator: validate_CreateInstances_603268, base: "/", url: url_CreateInstances_603269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInstancesFromSnapshot_603282 = ref object of OpenApiRestCall_602466
proc url_CreateInstancesFromSnapshot_603284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateInstancesFromSnapshot_603283(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateInstancesFromSnapshot"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_CreateInstancesFromSnapshot_603282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_CreateInstancesFromSnapshot_603282; body: JsonNode): Recallable =
  ## createInstancesFromSnapshot
  ## <p>Creates one or more new instances from a manual or automatic snapshot of an instance.</p> <p>The <code>create instances from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var createInstancesFromSnapshot* = Call_CreateInstancesFromSnapshot_603282(
    name: "createInstancesFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateInstancesFromSnapshot",
    validator: validate_CreateInstancesFromSnapshot_603283, base: "/",
    url: url_CreateInstancesFromSnapshot_603284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateKeyPair_603297 = ref object of OpenApiRestCall_602466
proc url_CreateKeyPair_603299(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateKeyPair_603298(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateKeyPair"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_CreateKeyPair_603297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_CreateKeyPair_603297; body: JsonNode): Recallable =
  ## createKeyPair
  ## <p>Creates an SSH key pair.</p> <p>The <code>create key pair</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var createKeyPair* = Call_CreateKeyPair_603297(name: "createKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateKeyPair",
    validator: validate_CreateKeyPair_603298, base: "/", url: url_CreateKeyPair_603299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoadBalancer_603312 = ref object of OpenApiRestCall_602466
proc url_CreateLoadBalancer_603314(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLoadBalancer_603313(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateLoadBalancer"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_CreateLoadBalancer_603312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see <a href="https://lightsail.aws.amazon.com/ls/docs/how-to/article/configure-lightsail-instances-for-load-balancing">Configure your Lightsail instances for load balancing</a>. You can create up to 5 load balancers per AWS Region in your account.</p> <p>When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the <code>UpdateLoadBalancerAttribute</code> operation.</p> <p>The <code>create load balancer</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_CreateLoadBalancer_603312; body: JsonNode): Recallable =
  ## createLoadBalancer
  ## <p>Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see <a href="https://lightsail.aws.amazon.com/ls/docs/how-to/article/configure-lightsail-instances-for-load-balancing">Configure your Lightsail instances for load balancing</a>. You can create up to 5 load balancers per AWS Region in your account.</p> <p>When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the <code>UpdateLoadBalancerAttribute</code> operation.</p> <p>The <code>create load balancer</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603326 = newJObject()
  if body != nil:
    body_603326 = body
  result = call_603325.call(nil, nil, nil, nil, body_603326)

var createLoadBalancer* = Call_CreateLoadBalancer_603312(
    name: "createLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateLoadBalancer",
    validator: validate_CreateLoadBalancer_603313, base: "/",
    url: url_CreateLoadBalancer_603314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLoadBalancerTlsCertificate_603327 = ref object of OpenApiRestCall_602466
proc url_CreateLoadBalancerTlsCertificate_603329(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLoadBalancerTlsCertificate_603328(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateLoadBalancerTlsCertificate"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_CreateLoadBalancerTlsCertificate_603327;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>create load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_CreateLoadBalancerTlsCertificate_603327;
          body: JsonNode): Recallable =
  ## createLoadBalancerTlsCertificate
  ## <p>Creates a Lightsail load balancer TLS certificate.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>The <code>create load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var createLoadBalancerTlsCertificate* = Call_CreateLoadBalancerTlsCertificate_603327(
    name: "createLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateLoadBalancerTlsCertificate",
    validator: validate_CreateLoadBalancerTlsCertificate_603328, base: "/",
    url: url_CreateLoadBalancerTlsCertificate_603329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabase_603342 = ref object of OpenApiRestCall_602466
proc url_CreateRelationalDatabase_603344(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRelationalDatabase_603343(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabase"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Algorithm")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Algorithm", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-SignedHeaders", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_CreateRelationalDatabase_603342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_CreateRelationalDatabase_603342; body: JsonNode): Recallable =
  ## createRelationalDatabase
  ## <p>Creates a new database in Amazon Lightsail.</p> <p>The <code>create relational database</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603356 = newJObject()
  if body != nil:
    body_603356 = body
  result = call_603355.call(nil, nil, nil, nil, body_603356)

var createRelationalDatabase* = Call_CreateRelationalDatabase_603342(
    name: "createRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabase",
    validator: validate_CreateRelationalDatabase_603343, base: "/",
    url: url_CreateRelationalDatabase_603344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabaseFromSnapshot_603357 = ref object of OpenApiRestCall_602466
proc url_CreateRelationalDatabaseFromSnapshot_603359(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRelationalDatabaseFromSnapshot_603358(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603362 = header.getOrDefault("X-Amz-Target")
  valid_603362 = validateParameter(valid_603362, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabaseFromSnapshot"))
  if valid_603362 != nil:
    section.add "X-Amz-Target", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Content-Sha256", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Algorithm")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Algorithm", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-SignedHeaders", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Credential")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Credential", valid_603367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603369: Call_CreateRelationalDatabaseFromSnapshot_603357;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new database from an existing database snapshot in Amazon Lightsail.</p> <p>You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan.</p> <p>The <code>create relational database from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603369.validator(path, query, header, formData, body)
  let scheme = call_603369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603369.url(scheme.get, call_603369.host, call_603369.base,
                         call_603369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603369, url, valid)

proc call*(call_603370: Call_CreateRelationalDatabaseFromSnapshot_603357;
          body: JsonNode): Recallable =
  ## createRelationalDatabaseFromSnapshot
  ## <p>Creates a new database from an existing database snapshot in Amazon Lightsail.</p> <p>You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan.</p> <p>The <code>create relational database from snapshot</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603371 = newJObject()
  if body != nil:
    body_603371 = body
  result = call_603370.call(nil, nil, nil, nil, body_603371)

var createRelationalDatabaseFromSnapshot* = Call_CreateRelationalDatabaseFromSnapshot_603357(
    name: "createRelationalDatabaseFromSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabaseFromSnapshot",
    validator: validate_CreateRelationalDatabaseFromSnapshot_603358, base: "/",
    url: url_CreateRelationalDatabaseFromSnapshot_603359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRelationalDatabaseSnapshot_603372 = ref object of OpenApiRestCall_602466
proc url_CreateRelationalDatabaseSnapshot_603374(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRelationalDatabaseSnapshot_603373(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603377 = header.getOrDefault("X-Amz-Target")
  valid_603377 = validateParameter(valid_603377, JString, required = true, default = newJString(
      "Lightsail_20161128.CreateRelationalDatabaseSnapshot"))
  if valid_603377 != nil:
    section.add "X-Amz-Target", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_CreateRelationalDatabaseSnapshot_603372;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database.</p> <p>The <code>create relational database snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_CreateRelationalDatabaseSnapshot_603372;
          body: JsonNode): Recallable =
  ## createRelationalDatabaseSnapshot
  ## <p>Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database.</p> <p>The <code>create relational database snapshot</code> operation supports tag-based access control via request tags. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603386 = newJObject()
  if body != nil:
    body_603386 = body
  result = call_603385.call(nil, nil, nil, nil, body_603386)

var createRelationalDatabaseSnapshot* = Call_CreateRelationalDatabaseSnapshot_603372(
    name: "createRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.CreateRelationalDatabaseSnapshot",
    validator: validate_CreateRelationalDatabaseSnapshot_603373, base: "/",
    url: url_CreateRelationalDatabaseSnapshot_603374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAutoSnapshot_603387 = ref object of OpenApiRestCall_602466
proc url_DeleteAutoSnapshot_603389(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAutoSnapshot_603388(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes an automatic snapshot for an instance or disk.
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
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603392 = header.getOrDefault("X-Amz-Target")
  valid_603392 = validateParameter(valid_603392, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteAutoSnapshot"))
  if valid_603392 != nil:
    section.add "X-Amz-Target", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Content-Sha256", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Algorithm")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Algorithm", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-SignedHeaders", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Credential")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Credential", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603399: Call_DeleteAutoSnapshot_603387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an automatic snapshot for an instance or disk.
  ## 
  let valid = call_603399.validator(path, query, header, formData, body)
  let scheme = call_603399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603399.url(scheme.get, call_603399.host, call_603399.base,
                         call_603399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603399, url, valid)

proc call*(call_603400: Call_DeleteAutoSnapshot_603387; body: JsonNode): Recallable =
  ## deleteAutoSnapshot
  ## Deletes an automatic snapshot for an instance or disk.
  ##   body: JObject (required)
  var body_603401 = newJObject()
  if body != nil:
    body_603401 = body
  result = call_603400.call(nil, nil, nil, nil, body_603401)

var deleteAutoSnapshot* = Call_DeleteAutoSnapshot_603387(
    name: "deleteAutoSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteAutoSnapshot",
    validator: validate_DeleteAutoSnapshot_603388, base: "/",
    url: url_DeleteAutoSnapshot_603389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDisk_603402 = ref object of OpenApiRestCall_602466
proc url_DeleteDisk_603404(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDisk_603403(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603405 = header.getOrDefault("X-Amz-Date")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Date", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Security-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Security-Token", valid_603406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603407 = header.getOrDefault("X-Amz-Target")
  valid_603407 = validateParameter(valid_603407, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDisk"))
  if valid_603407 != nil:
    section.add "X-Amz-Target", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Content-Sha256", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603414: Call_DeleteDisk_603402; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified block storage disk. The disk must be in the <code>available</code> state (not attached to a Lightsail instance).</p> <note> <p>The disk may remain in the <code>deleting</code> state for several minutes.</p> </note> <p>The <code>delete disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_DeleteDisk_603402; body: JsonNode): Recallable =
  ## deleteDisk
  ## <p>Deletes the specified block storage disk. The disk must be in the <code>available</code> state (not attached to a Lightsail instance).</p> <note> <p>The disk may remain in the <code>deleting</code> state for several minutes.</p> </note> <p>The <code>delete disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603416 = newJObject()
  if body != nil:
    body_603416 = body
  result = call_603415.call(nil, nil, nil, nil, body_603416)

var deleteDisk* = Call_DeleteDisk_603402(name: "deleteDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteDisk",
                                      validator: validate_DeleteDisk_603403,
                                      base: "/", url: url_DeleteDisk_603404,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiskSnapshot_603417 = ref object of OpenApiRestCall_602466
proc url_DeleteDiskSnapshot_603419(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDiskSnapshot_603418(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603420 = header.getOrDefault("X-Amz-Date")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Date", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Security-Token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Security-Token", valid_603421
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603422 = header.getOrDefault("X-Amz-Target")
  valid_603422 = validateParameter(valid_603422, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDiskSnapshot"))
  if valid_603422 != nil:
    section.add "X-Amz-Target", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Content-Sha256", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Algorithm")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Algorithm", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Signature")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Signature", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-SignedHeaders", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Credential")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Credential", valid_603427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_DeleteDiskSnapshot_603417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified disk snapshot.</p> <p>When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk.</p> <p>The <code>delete disk snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_DeleteDiskSnapshot_603417; body: JsonNode): Recallable =
  ## deleteDiskSnapshot
  ## <p>Deletes the specified disk snapshot.</p> <p>When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk.</p> <p>The <code>delete disk snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603431 = newJObject()
  if body != nil:
    body_603431 = body
  result = call_603430.call(nil, nil, nil, nil, body_603431)

var deleteDiskSnapshot* = Call_DeleteDiskSnapshot_603417(
    name: "deleteDiskSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDiskSnapshot",
    validator: validate_DeleteDiskSnapshot_603418, base: "/",
    url: url_DeleteDiskSnapshot_603419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_603432 = ref object of OpenApiRestCall_602466
proc url_DeleteDomain_603434(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDomain_603433(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603435 = header.getOrDefault("X-Amz-Date")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Date", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Security-Token")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Security-Token", valid_603436
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603437 = header.getOrDefault("X-Amz-Target")
  valid_603437 = validateParameter(valid_603437, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDomain"))
  if valid_603437 != nil:
    section.add "X-Amz-Target", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Content-Sha256", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Algorithm")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Algorithm", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Signature")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Signature", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-SignedHeaders", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Credential")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Credential", valid_603442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603444: Call_DeleteDomain_603432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603444.validator(path, query, header, formData, body)
  let scheme = call_603444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603444.url(scheme.get, call_603444.host, call_603444.base,
                         call_603444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603444, url, valid)

proc call*(call_603445: Call_DeleteDomain_603432; body: JsonNode): Recallable =
  ## deleteDomain
  ## <p>Deletes the specified domain recordset and all of its domain records.</p> <p>The <code>delete domain</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603446 = newJObject()
  if body != nil:
    body_603446 = body
  result = call_603445.call(nil, nil, nil, nil, body_603446)

var deleteDomain* = Call_DeleteDomain_603432(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDomain",
    validator: validate_DeleteDomain_603433, base: "/", url: url_DeleteDomain_603434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainEntry_603447 = ref object of OpenApiRestCall_602466
proc url_DeleteDomainEntry_603449(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDomainEntry_603448(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603450 = header.getOrDefault("X-Amz-Date")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Date", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Security-Token")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Security-Token", valid_603451
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603452 = header.getOrDefault("X-Amz-Target")
  valid_603452 = validateParameter(valid_603452, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteDomainEntry"))
  if valid_603452 != nil:
    section.add "X-Amz-Target", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Content-Sha256", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Algorithm")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Algorithm", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Signature")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Signature", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-SignedHeaders", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Credential")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Credential", valid_603457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603459: Call_DeleteDomainEntry_603447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific domain entry.</p> <p>The <code>delete domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603459.validator(path, query, header, formData, body)
  let scheme = call_603459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603459.url(scheme.get, call_603459.host, call_603459.base,
                         call_603459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603459, url, valid)

proc call*(call_603460: Call_DeleteDomainEntry_603447; body: JsonNode): Recallable =
  ## deleteDomainEntry
  ## <p>Deletes a specific domain entry.</p> <p>The <code>delete domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603461 = newJObject()
  if body != nil:
    body_603461 = body
  result = call_603460.call(nil, nil, nil, nil, body_603461)

var deleteDomainEntry* = Call_DeleteDomainEntry_603447(name: "deleteDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteDomainEntry",
    validator: validate_DeleteDomainEntry_603448, base: "/",
    url: url_DeleteDomainEntry_603449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstance_603462 = ref object of OpenApiRestCall_602466
proc url_DeleteInstance_603464(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteInstance_603463(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603465 = header.getOrDefault("X-Amz-Date")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Date", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Security-Token")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Security-Token", valid_603466
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603467 = header.getOrDefault("X-Amz-Target")
  valid_603467 = validateParameter(valid_603467, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteInstance"))
  if valid_603467 != nil:
    section.add "X-Amz-Target", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Content-Sha256", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Algorithm")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Algorithm", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-SignedHeaders", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Credential")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Credential", valid_603472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603474: Call_DeleteInstance_603462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an Amazon Lightsail instance.</p> <p>The <code>delete instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603474.validator(path, query, header, formData, body)
  let scheme = call_603474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603474.url(scheme.get, call_603474.host, call_603474.base,
                         call_603474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603474, url, valid)

proc call*(call_603475: Call_DeleteInstance_603462; body: JsonNode): Recallable =
  ## deleteInstance
  ## <p>Deletes an Amazon Lightsail instance.</p> <p>The <code>delete instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603476 = newJObject()
  if body != nil:
    body_603476 = body
  result = call_603475.call(nil, nil, nil, nil, body_603476)

var deleteInstance* = Call_DeleteInstance_603462(name: "deleteInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteInstance",
    validator: validate_DeleteInstance_603463, base: "/", url: url_DeleteInstance_603464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInstanceSnapshot_603477 = ref object of OpenApiRestCall_602466
proc url_DeleteInstanceSnapshot_603479(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteInstanceSnapshot_603478(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603480 = header.getOrDefault("X-Amz-Date")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Date", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Security-Token")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Security-Token", valid_603481
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603482 = header.getOrDefault("X-Amz-Target")
  valid_603482 = validateParameter(valid_603482, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteInstanceSnapshot"))
  if valid_603482 != nil:
    section.add "X-Amz-Target", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Content-Sha256", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Algorithm")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Algorithm", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Signature")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Signature", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-SignedHeaders", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Credential")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Credential", valid_603487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603489: Call_DeleteInstanceSnapshot_603477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific snapshot of a virtual private server (or <i>instance</i>).</p> <p>The <code>delete instance snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603489.validator(path, query, header, formData, body)
  let scheme = call_603489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603489.url(scheme.get, call_603489.host, call_603489.base,
                         call_603489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603489, url, valid)

proc call*(call_603490: Call_DeleteInstanceSnapshot_603477; body: JsonNode): Recallable =
  ## deleteInstanceSnapshot
  ## <p>Deletes a specific snapshot of a virtual private server (or <i>instance</i>).</p> <p>The <code>delete instance snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603491 = newJObject()
  if body != nil:
    body_603491 = body
  result = call_603490.call(nil, nil, nil, nil, body_603491)

var deleteInstanceSnapshot* = Call_DeleteInstanceSnapshot_603477(
    name: "deleteInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteInstanceSnapshot",
    validator: validate_DeleteInstanceSnapshot_603478, base: "/",
    url: url_DeleteInstanceSnapshot_603479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteKeyPair_603492 = ref object of OpenApiRestCall_602466
proc url_DeleteKeyPair_603494(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteKeyPair_603493(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603495 = header.getOrDefault("X-Amz-Date")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Date", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Security-Token")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Security-Token", valid_603496
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603497 = header.getOrDefault("X-Amz-Target")
  valid_603497 = validateParameter(valid_603497, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteKeyPair"))
  if valid_603497 != nil:
    section.add "X-Amz-Target", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Content-Sha256", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Algorithm")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Algorithm", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Signature")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Signature", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-SignedHeaders", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Credential")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Credential", valid_603502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603504: Call_DeleteKeyPair_603492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603504.validator(path, query, header, formData, body)
  let scheme = call_603504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603504.url(scheme.get, call_603504.host, call_603504.base,
                         call_603504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603504, url, valid)

proc call*(call_603505: Call_DeleteKeyPair_603492; body: JsonNode): Recallable =
  ## deleteKeyPair
  ## <p>Deletes a specific SSH key pair.</p> <p>The <code>delete key pair</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>key pair name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603506 = newJObject()
  if body != nil:
    body_603506 = body
  result = call_603505.call(nil, nil, nil, nil, body_603506)

var deleteKeyPair* = Call_DeleteKeyPair_603492(name: "deleteKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteKeyPair",
    validator: validate_DeleteKeyPair_603493, base: "/", url: url_DeleteKeyPair_603494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteKnownHostKeys_603507 = ref object of OpenApiRestCall_602466
proc url_DeleteKnownHostKeys_603509(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteKnownHostKeys_603508(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603510 = header.getOrDefault("X-Amz-Date")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Date", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Security-Token")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Security-Token", valid_603511
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603512 = header.getOrDefault("X-Amz-Target")
  valid_603512 = validateParameter(valid_603512, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteKnownHostKeys"))
  if valid_603512 != nil:
    section.add "X-Amz-Target", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Content-Sha256", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Algorithm")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Algorithm", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Signature")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Signature", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-SignedHeaders", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Credential")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Credential", valid_603517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603519: Call_DeleteKnownHostKeys_603507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch.</p> <important> <p>Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection">Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client</a>.</p> </important>
  ## 
  let valid = call_603519.validator(path, query, header, formData, body)
  let scheme = call_603519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603519.url(scheme.get, call_603519.host, call_603519.base,
                         call_603519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603519, url, valid)

proc call*(call_603520: Call_DeleteKnownHostKeys_603507; body: JsonNode): Recallable =
  ## deleteKnownHostKeys
  ## <p>Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch.</p> <important> <p>Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection">Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client</a>.</p> </important>
  ##   body: JObject (required)
  var body_603521 = newJObject()
  if body != nil:
    body_603521 = body
  result = call_603520.call(nil, nil, nil, nil, body_603521)

var deleteKnownHostKeys* = Call_DeleteKnownHostKeys_603507(
    name: "deleteKnownHostKeys", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteKnownHostKeys",
    validator: validate_DeleteKnownHostKeys_603508, base: "/",
    url: url_DeleteKnownHostKeys_603509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoadBalancer_603522 = ref object of OpenApiRestCall_602466
proc url_DeleteLoadBalancer_603524(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLoadBalancer_603523(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603525 = header.getOrDefault("X-Amz-Date")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Date", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Security-Token")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Security-Token", valid_603526
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603527 = header.getOrDefault("X-Amz-Target")
  valid_603527 = validateParameter(valid_603527, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteLoadBalancer"))
  if valid_603527 != nil:
    section.add "X-Amz-Target", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Content-Sha256", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Algorithm")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Algorithm", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Signature")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Signature", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-SignedHeaders", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Credential")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Credential", valid_603532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603534: Call_DeleteLoadBalancer_603522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again.</p> <p>The <code>delete load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603534.validator(path, query, header, formData, body)
  let scheme = call_603534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603534.url(scheme.get, call_603534.host, call_603534.base,
                         call_603534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603534, url, valid)

proc call*(call_603535: Call_DeleteLoadBalancer_603522; body: JsonNode): Recallable =
  ## deleteLoadBalancer
  ## <p>Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again.</p> <p>The <code>delete load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603536 = newJObject()
  if body != nil:
    body_603536 = body
  result = call_603535.call(nil, nil, nil, nil, body_603536)

var deleteLoadBalancer* = Call_DeleteLoadBalancer_603522(
    name: "deleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteLoadBalancer",
    validator: validate_DeleteLoadBalancer_603523, base: "/",
    url: url_DeleteLoadBalancer_603524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoadBalancerTlsCertificate_603537 = ref object of OpenApiRestCall_602466
proc url_DeleteLoadBalancerTlsCertificate_603539(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLoadBalancerTlsCertificate_603538(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603540 = header.getOrDefault("X-Amz-Date")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Date", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Security-Token")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Security-Token", valid_603541
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603542 = header.getOrDefault("X-Amz-Target")
  valid_603542 = validateParameter(valid_603542, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteLoadBalancerTlsCertificate"))
  if valid_603542 != nil:
    section.add "X-Amz-Target", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Content-Sha256", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Algorithm")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Algorithm", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Signature")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Signature", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-SignedHeaders", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Credential")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Credential", valid_603547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603549: Call_DeleteLoadBalancerTlsCertificate_603537;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>delete load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603549.validator(path, query, header, formData, body)
  let scheme = call_603549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603549.url(scheme.get, call_603549.host, call_603549.base,
                         call_603549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603549, url, valid)

proc call*(call_603550: Call_DeleteLoadBalancerTlsCertificate_603537;
          body: JsonNode): Recallable =
  ## deleteLoadBalancerTlsCertificate
  ## <p>Deletes an SSL/TLS certificate associated with a Lightsail load balancer.</p> <p>The <code>delete load balancer tls certificate</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603551 = newJObject()
  if body != nil:
    body_603551 = body
  result = call_603550.call(nil, nil, nil, nil, body_603551)

var deleteLoadBalancerTlsCertificate* = Call_DeleteLoadBalancerTlsCertificate_603537(
    name: "deleteLoadBalancerTlsCertificate", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteLoadBalancerTlsCertificate",
    validator: validate_DeleteLoadBalancerTlsCertificate_603538, base: "/",
    url: url_DeleteLoadBalancerTlsCertificate_603539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRelationalDatabase_603552 = ref object of OpenApiRestCall_602466
proc url_DeleteRelationalDatabase_603554(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRelationalDatabase_603553(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603555 = header.getOrDefault("X-Amz-Date")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Date", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Security-Token")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Security-Token", valid_603556
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603557 = header.getOrDefault("X-Amz-Target")
  valid_603557 = validateParameter(valid_603557, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteRelationalDatabase"))
  if valid_603557 != nil:
    section.add "X-Amz-Target", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Content-Sha256", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Algorithm")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Algorithm", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Signature")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Signature", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-SignedHeaders", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Credential")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Credential", valid_603562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603564: Call_DeleteRelationalDatabase_603552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603564.validator(path, query, header, formData, body)
  let scheme = call_603564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603564.url(scheme.get, call_603564.host, call_603564.base,
                         call_603564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603564, url, valid)

proc call*(call_603565: Call_DeleteRelationalDatabase_603552; body: JsonNode): Recallable =
  ## deleteRelationalDatabase
  ## <p>Deletes a database in Amazon Lightsail.</p> <p>The <code>delete relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603566 = newJObject()
  if body != nil:
    body_603566 = body
  result = call_603565.call(nil, nil, nil, nil, body_603566)

var deleteRelationalDatabase* = Call_DeleteRelationalDatabase_603552(
    name: "deleteRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DeleteRelationalDatabase",
    validator: validate_DeleteRelationalDatabase_603553, base: "/",
    url: url_DeleteRelationalDatabase_603554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRelationalDatabaseSnapshot_603567 = ref object of OpenApiRestCall_602466
proc url_DeleteRelationalDatabaseSnapshot_603569(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRelationalDatabaseSnapshot_603568(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603570 = header.getOrDefault("X-Amz-Date")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Date", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Security-Token")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Security-Token", valid_603571
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603572 = header.getOrDefault("X-Amz-Target")
  valid_603572 = validateParameter(valid_603572, JString, required = true, default = newJString(
      "Lightsail_20161128.DeleteRelationalDatabaseSnapshot"))
  if valid_603572 != nil:
    section.add "X-Amz-Target", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Content-Sha256", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Algorithm")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Algorithm", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Signature")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Signature", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-SignedHeaders", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Credential")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Credential", valid_603577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603579: Call_DeleteRelationalDatabaseSnapshot_603567;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes a database snapshot in Amazon Lightsail.</p> <p>The <code>delete relational database snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603579.validator(path, query, header, formData, body)
  let scheme = call_603579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603579.url(scheme.get, call_603579.host, call_603579.base,
                         call_603579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603579, url, valid)

proc call*(call_603580: Call_DeleteRelationalDatabaseSnapshot_603567;
          body: JsonNode): Recallable =
  ## deleteRelationalDatabaseSnapshot
  ## <p>Deletes a database snapshot in Amazon Lightsail.</p> <p>The <code>delete relational database snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603581 = newJObject()
  if body != nil:
    body_603581 = body
  result = call_603580.call(nil, nil, nil, nil, body_603581)

var deleteRelationalDatabaseSnapshot* = Call_DeleteRelationalDatabaseSnapshot_603567(
    name: "deleteRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DeleteRelationalDatabaseSnapshot",
    validator: validate_DeleteRelationalDatabaseSnapshot_603568, base: "/",
    url: url_DeleteRelationalDatabaseSnapshot_603569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachDisk_603582 = ref object of OpenApiRestCall_602466
proc url_DetachDisk_603584(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachDisk_603583(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603585 = header.getOrDefault("X-Amz-Date")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Date", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Security-Token")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Security-Token", valid_603586
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603587 = header.getOrDefault("X-Amz-Target")
  valid_603587 = validateParameter(valid_603587, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachDisk"))
  if valid_603587 != nil:
    section.add "X-Amz-Target", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Content-Sha256", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Algorithm")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Algorithm", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Signature")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Signature", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-SignedHeaders", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Credential")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Credential", valid_603592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603594: Call_DetachDisk_603582; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk.</p> <p>The <code>detach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603594.validator(path, query, header, formData, body)
  let scheme = call_603594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603594.url(scheme.get, call_603594.host, call_603594.base,
                         call_603594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603594, url, valid)

proc call*(call_603595: Call_DetachDisk_603582; body: JsonNode): Recallable =
  ## detachDisk
  ## <p>Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk.</p> <p>The <code>detach disk</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>disk name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603596 = newJObject()
  if body != nil:
    body_603596 = body
  result = call_603595.call(nil, nil, nil, nil, body_603596)

var detachDisk* = Call_DetachDisk_603582(name: "detachDisk",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.DetachDisk",
                                      validator: validate_DetachDisk_603583,
                                      base: "/", url: url_DetachDisk_603584,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachInstancesFromLoadBalancer_603597 = ref object of OpenApiRestCall_602466
proc url_DetachInstancesFromLoadBalancer_603599(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachInstancesFromLoadBalancer_603598(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603600 = header.getOrDefault("X-Amz-Date")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Date", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Security-Token")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Security-Token", valid_603601
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603602 = header.getOrDefault("X-Amz-Target")
  valid_603602 = validateParameter(valid_603602, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachInstancesFromLoadBalancer"))
  if valid_603602 != nil:
    section.add "X-Amz-Target", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Content-Sha256", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Algorithm")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Algorithm", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Signature")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Signature", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-SignedHeaders", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Credential")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Credential", valid_603607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603609: Call_DetachInstancesFromLoadBalancer_603597;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Detaches the specified instances from a Lightsail load balancer.</p> <p>This operation waits until the instances are no longer needed before they are detached from the load balancer.</p> <p>The <code>detach instances from load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603609.validator(path, query, header, formData, body)
  let scheme = call_603609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603609.url(scheme.get, call_603609.host, call_603609.base,
                         call_603609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603609, url, valid)

proc call*(call_603610: Call_DetachInstancesFromLoadBalancer_603597; body: JsonNode): Recallable =
  ## detachInstancesFromLoadBalancer
  ## <p>Detaches the specified instances from a Lightsail load balancer.</p> <p>This operation waits until the instances are no longer needed before they are detached from the load balancer.</p> <p>The <code>detach instances from load balancer</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603611 = newJObject()
  if body != nil:
    body_603611 = body
  result = call_603610.call(nil, nil, nil, nil, body_603611)

var detachInstancesFromLoadBalancer* = Call_DetachInstancesFromLoadBalancer_603597(
    name: "detachInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DetachInstancesFromLoadBalancer",
    validator: validate_DetachInstancesFromLoadBalancer_603598, base: "/",
    url: url_DetachInstancesFromLoadBalancer_603599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachStaticIp_603612 = ref object of OpenApiRestCall_602466
proc url_DetachStaticIp_603614(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachStaticIp_603613(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603615 = header.getOrDefault("X-Amz-Date")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Date", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Security-Token")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Security-Token", valid_603616
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603617 = header.getOrDefault("X-Amz-Target")
  valid_603617 = validateParameter(valid_603617, JString, required = true, default = newJString(
      "Lightsail_20161128.DetachStaticIp"))
  if valid_603617 != nil:
    section.add "X-Amz-Target", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Content-Sha256", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Algorithm")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Algorithm", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Signature")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Signature", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-SignedHeaders", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Credential")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Credential", valid_603622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603624: Call_DetachStaticIp_603612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a static IP from the Amazon Lightsail instance to which it is attached.
  ## 
  let valid = call_603624.validator(path, query, header, formData, body)
  let scheme = call_603624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603624.url(scheme.get, call_603624.host, call_603624.base,
                         call_603624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603624, url, valid)

proc call*(call_603625: Call_DetachStaticIp_603612; body: JsonNode): Recallable =
  ## detachStaticIp
  ## Detaches a static IP from the Amazon Lightsail instance to which it is attached.
  ##   body: JObject (required)
  var body_603626 = newJObject()
  if body != nil:
    body_603626 = body
  result = call_603625.call(nil, nil, nil, nil, body_603626)

var detachStaticIp* = Call_DetachStaticIp_603612(name: "detachStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DetachStaticIp",
    validator: validate_DetachStaticIp_603613, base: "/", url: url_DetachStaticIp_603614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAddOn_603627 = ref object of OpenApiRestCall_602466
proc url_DisableAddOn_603629(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableAddOn_603628(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603630 = header.getOrDefault("X-Amz-Date")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Date", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Security-Token")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Security-Token", valid_603631
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603632 = header.getOrDefault("X-Amz-Target")
  valid_603632 = validateParameter(valid_603632, JString, required = true, default = newJString(
      "Lightsail_20161128.DisableAddOn"))
  if valid_603632 != nil:
    section.add "X-Amz-Target", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Content-Sha256", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Algorithm")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Algorithm", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Signature")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Signature", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-SignedHeaders", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Credential")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Credential", valid_603637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603639: Call_DisableAddOn_603627; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_603639.validator(path, query, header, formData, body)
  let scheme = call_603639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603639.url(scheme.get, call_603639.host, call_603639.base,
                         call_603639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603639, url, valid)

proc call*(call_603640: Call_DisableAddOn_603627; body: JsonNode): Recallable =
  ## disableAddOn
  ## Disables an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_603641 = newJObject()
  if body != nil:
    body_603641 = body
  result = call_603640.call(nil, nil, nil, nil, body_603641)

var disableAddOn* = Call_DisableAddOn_603627(name: "disableAddOn",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DisableAddOn",
    validator: validate_DisableAddOn_603628, base: "/", url: url_DisableAddOn_603629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DownloadDefaultKeyPair_603642 = ref object of OpenApiRestCall_602466
proc url_DownloadDefaultKeyPair_603644(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DownloadDefaultKeyPair_603643(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603645 = header.getOrDefault("X-Amz-Date")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Date", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Security-Token")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Security-Token", valid_603646
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603647 = header.getOrDefault("X-Amz-Target")
  valid_603647 = validateParameter(valid_603647, JString, required = true, default = newJString(
      "Lightsail_20161128.DownloadDefaultKeyPair"))
  if valid_603647 != nil:
    section.add "X-Amz-Target", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Content-Sha256", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Algorithm")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Algorithm", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Signature")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Signature", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-SignedHeaders", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Credential")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Credential", valid_603652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603654: Call_DownloadDefaultKeyPair_603642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Downloads the default SSH key pair from the user's account.
  ## 
  let valid = call_603654.validator(path, query, header, formData, body)
  let scheme = call_603654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603654.url(scheme.get, call_603654.host, call_603654.base,
                         call_603654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603654, url, valid)

proc call*(call_603655: Call_DownloadDefaultKeyPair_603642; body: JsonNode): Recallable =
  ## downloadDefaultKeyPair
  ## Downloads the default SSH key pair from the user's account.
  ##   body: JObject (required)
  var body_603656 = newJObject()
  if body != nil:
    body_603656 = body
  result = call_603655.call(nil, nil, nil, nil, body_603656)

var downloadDefaultKeyPair* = Call_DownloadDefaultKeyPair_603642(
    name: "downloadDefaultKeyPair", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.DownloadDefaultKeyPair",
    validator: validate_DownloadDefaultKeyPair_603643, base: "/",
    url: url_DownloadDefaultKeyPair_603644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAddOn_603657 = ref object of OpenApiRestCall_602466
proc url_EnableAddOn_603659(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableAddOn_603658(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603660 = header.getOrDefault("X-Amz-Date")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Date", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Security-Token")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Security-Token", valid_603661
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603662 = header.getOrDefault("X-Amz-Target")
  valid_603662 = validateParameter(valid_603662, JString, required = true, default = newJString(
      "Lightsail_20161128.EnableAddOn"))
  if valid_603662 != nil:
    section.add "X-Amz-Target", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Content-Sha256", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Algorithm")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Algorithm", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Signature")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Signature", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-SignedHeaders", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Credential")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Credential", valid_603667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603669: Call_EnableAddOn_603657; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_603669.validator(path, query, header, formData, body)
  let scheme = call_603669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603669.url(scheme.get, call_603669.host, call_603669.base,
                         call_603669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603669, url, valid)

proc call*(call_603670: Call_EnableAddOn_603657; body: JsonNode): Recallable =
  ## enableAddOn
  ## Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_603671 = newJObject()
  if body != nil:
    body_603671 = body
  result = call_603670.call(nil, nil, nil, nil, body_603671)

var enableAddOn* = Call_EnableAddOn_603657(name: "enableAddOn",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.EnableAddOn",
                                        validator: validate_EnableAddOn_603658,
                                        base: "/", url: url_EnableAddOn_603659,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportSnapshot_603672 = ref object of OpenApiRestCall_602466
proc url_ExportSnapshot_603674(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExportSnapshot_603673(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603675 = header.getOrDefault("X-Amz-Date")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Date", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Security-Token")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Security-Token", valid_603676
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603677 = header.getOrDefault("X-Amz-Target")
  valid_603677 = validateParameter(valid_603677, JString, required = true, default = newJString(
      "Lightsail_20161128.ExportSnapshot"))
  if valid_603677 != nil:
    section.add "X-Amz-Target", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Content-Sha256", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-Algorithm")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Algorithm", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Signature")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Signature", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-SignedHeaders", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Credential")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Credential", valid_603682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603684: Call_ExportSnapshot_603672; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the <code>create cloud formation stack</code> operation to create new Amazon EC2 instances.</p> <p>Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot.</p> <p/> <p>The <code>export snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>source snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p> <note> <p>Use the <code>get instance snapshots</code> or <code>get disk snapshots</code> operations to get a list of snapshots that you can export to Amazon EC2.</p> </note>
  ## 
  let valid = call_603684.validator(path, query, header, formData, body)
  let scheme = call_603684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603684.url(scheme.get, call_603684.host, call_603684.base,
                         call_603684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603684, url, valid)

proc call*(call_603685: Call_ExportSnapshot_603672; body: JsonNode): Recallable =
  ## exportSnapshot
  ## <p>Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the <code>create cloud formation stack</code> operation to create new Amazon EC2 instances.</p> <p>Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot.</p> <p/> <p>The <code>export snapshot</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>source snapshot name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p> <note> <p>Use the <code>get instance snapshots</code> or <code>get disk snapshots</code> operations to get a list of snapshots that you can export to Amazon EC2.</p> </note>
  ##   body: JObject (required)
  var body_603686 = newJObject()
  if body != nil:
    body_603686 = body
  result = call_603685.call(nil, nil, nil, nil, body_603686)

var exportSnapshot* = Call_ExportSnapshot_603672(name: "exportSnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ExportSnapshot",
    validator: validate_ExportSnapshot_603673, base: "/", url: url_ExportSnapshot_603674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetActiveNames_603687 = ref object of OpenApiRestCall_602466
proc url_GetActiveNames_603689(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetActiveNames_603688(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603690 = header.getOrDefault("X-Amz-Date")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Date", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Security-Token")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Security-Token", valid_603691
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603692 = header.getOrDefault("X-Amz-Target")
  valid_603692 = validateParameter(valid_603692, JString, required = true, default = newJString(
      "Lightsail_20161128.GetActiveNames"))
  if valid_603692 != nil:
    section.add "X-Amz-Target", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Content-Sha256", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Algorithm")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Algorithm", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Signature")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Signature", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-SignedHeaders", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Credential")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Credential", valid_603697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603699: Call_GetActiveNames_603687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the names of all active (not deleted) resources.
  ## 
  let valid = call_603699.validator(path, query, header, formData, body)
  let scheme = call_603699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603699.url(scheme.get, call_603699.host, call_603699.base,
                         call_603699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603699, url, valid)

proc call*(call_603700: Call_GetActiveNames_603687; body: JsonNode): Recallable =
  ## getActiveNames
  ## Returns the names of all active (not deleted) resources.
  ##   body: JObject (required)
  var body_603701 = newJObject()
  if body != nil:
    body_603701 = body
  result = call_603700.call(nil, nil, nil, nil, body_603701)

var getActiveNames* = Call_GetActiveNames_603687(name: "getActiveNames",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetActiveNames",
    validator: validate_GetActiveNames_603688, base: "/", url: url_GetActiveNames_603689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutoSnapshots_603702 = ref object of OpenApiRestCall_602466
proc url_GetAutoSnapshots_603704(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAutoSnapshots_603703(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the available automatic snapshots for the specified resource name. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
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
  var valid_603705 = header.getOrDefault("X-Amz-Date")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Date", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Security-Token")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Security-Token", valid_603706
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603707 = header.getOrDefault("X-Amz-Target")
  valid_603707 = validateParameter(valid_603707, JString, required = true, default = newJString(
      "Lightsail_20161128.GetAutoSnapshots"))
  if valid_603707 != nil:
    section.add "X-Amz-Target", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Content-Sha256", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Algorithm")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Algorithm", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Signature")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Signature", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-SignedHeaders", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Credential")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Credential", valid_603712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603714: Call_GetAutoSnapshots_603702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the available automatic snapshots for the specified resource name. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ## 
  let valid = call_603714.validator(path, query, header, formData, body)
  let scheme = call_603714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603714.url(scheme.get, call_603714.host, call_603714.base,
                         call_603714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603714, url, valid)

proc call*(call_603715: Call_GetAutoSnapshots_603702; body: JsonNode): Recallable =
  ## getAutoSnapshots
  ## Returns the available automatic snapshots for the specified resource name. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots">Lightsail Dev Guide</a>.
  ##   body: JObject (required)
  var body_603716 = newJObject()
  if body != nil:
    body_603716 = body
  result = call_603715.call(nil, nil, nil, nil, body_603716)

var getAutoSnapshots* = Call_GetAutoSnapshots_603702(name: "getAutoSnapshots",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetAutoSnapshots",
    validator: validate_GetAutoSnapshots_603703, base: "/",
    url: url_GetAutoSnapshots_603704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlueprints_603717 = ref object of OpenApiRestCall_602466
proc url_GetBlueprints_603719(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBlueprints_603718(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603720 = header.getOrDefault("X-Amz-Date")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Date", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Security-Token")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Security-Token", valid_603721
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603722 = header.getOrDefault("X-Amz-Target")
  valid_603722 = validateParameter(valid_603722, JString, required = true, default = newJString(
      "Lightsail_20161128.GetBlueprints"))
  if valid_603722 != nil:
    section.add "X-Amz-Target", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Content-Sha256", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-Algorithm")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Algorithm", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Signature")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Signature", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-SignedHeaders", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Credential")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Credential", valid_603727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603729: Call_GetBlueprints_603717; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
  ## 
  let valid = call_603729.validator(path, query, header, formData, body)
  let scheme = call_603729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603729.url(scheme.get, call_603729.host, call_603729.base,
                         call_603729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603729, url, valid)

proc call*(call_603730: Call_GetBlueprints_603717; body: JsonNode): Recallable =
  ## getBlueprints
  ## <p>Returns the list of available instance images, or <i>blueprints</i>. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose.</p> <note> <p>Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.</p> </note>
  ##   body: JObject (required)
  var body_603731 = newJObject()
  if body != nil:
    body_603731 = body
  result = call_603730.call(nil, nil, nil, nil, body_603731)

var getBlueprints* = Call_GetBlueprints_603717(name: "getBlueprints",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetBlueprints",
    validator: validate_GetBlueprints_603718, base: "/", url: url_GetBlueprints_603719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBundles_603732 = ref object of OpenApiRestCall_602466
proc url_GetBundles_603734(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBundles_603733(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603735 = header.getOrDefault("X-Amz-Date")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Date", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Security-Token")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Security-Token", valid_603736
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603737 = header.getOrDefault("X-Amz-Target")
  valid_603737 = validateParameter(valid_603737, JString, required = true, default = newJString(
      "Lightsail_20161128.GetBundles"))
  if valid_603737 != nil:
    section.add "X-Amz-Target", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Content-Sha256", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-Algorithm")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Algorithm", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Signature")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Signature", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-SignedHeaders", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Credential")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Credential", valid_603742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603744: Call_GetBundles_603732; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the list of bundles that are available for purchase. A bundle describes the specs for your virtual private server (or <i>instance</i>).
  ## 
  let valid = call_603744.validator(path, query, header, formData, body)
  let scheme = call_603744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603744.url(scheme.get, call_603744.host, call_603744.base,
                         call_603744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603744, url, valid)

proc call*(call_603745: Call_GetBundles_603732; body: JsonNode): Recallable =
  ## getBundles
  ## Returns the list of bundles that are available for purchase. A bundle describes the specs for your virtual private server (or <i>instance</i>).
  ##   body: JObject (required)
  var body_603746 = newJObject()
  if body != nil:
    body_603746 = body
  result = call_603745.call(nil, nil, nil, nil, body_603746)

var getBundles* = Call_GetBundles_603732(name: "getBundles",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetBundles",
                                      validator: validate_GetBundles_603733,
                                      base: "/", url: url_GetBundles_603734,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFormationStackRecords_603747 = ref object of OpenApiRestCall_602466
proc url_GetCloudFormationStackRecords_603749(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCloudFormationStackRecords_603748(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603750 = header.getOrDefault("X-Amz-Date")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Date", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Security-Token")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Security-Token", valid_603751
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603752 = header.getOrDefault("X-Amz-Target")
  valid_603752 = validateParameter(valid_603752, JString, required = true, default = newJString(
      "Lightsail_20161128.GetCloudFormationStackRecords"))
  if valid_603752 != nil:
    section.add "X-Amz-Target", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Content-Sha256", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Algorithm")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Algorithm", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Signature")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Signature", valid_603755
  var valid_603756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-SignedHeaders", valid_603756
  var valid_603757 = header.getOrDefault("X-Amz-Credential")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Credential", valid_603757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603759: Call_GetCloudFormationStackRecords_603747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the CloudFormation stack record created as a result of the <code>create cloud formation stack</code> operation.</p> <p>An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.</p>
  ## 
  let valid = call_603759.validator(path, query, header, formData, body)
  let scheme = call_603759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603759.url(scheme.get, call_603759.host, call_603759.base,
                         call_603759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603759, url, valid)

proc call*(call_603760: Call_GetCloudFormationStackRecords_603747; body: JsonNode): Recallable =
  ## getCloudFormationStackRecords
  ## <p>Returns the CloudFormation stack record created as a result of the <code>create cloud formation stack</code> operation.</p> <p>An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.</p>
  ##   body: JObject (required)
  var body_603761 = newJObject()
  if body != nil:
    body_603761 = body
  result = call_603760.call(nil, nil, nil, nil, body_603761)

var getCloudFormationStackRecords* = Call_GetCloudFormationStackRecords_603747(
    name: "getCloudFormationStackRecords", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetCloudFormationStackRecords",
    validator: validate_GetCloudFormationStackRecords_603748, base: "/",
    url: url_GetCloudFormationStackRecords_603749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisk_603762 = ref object of OpenApiRestCall_602466
proc url_GetDisk_603764(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDisk_603763(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603765 = header.getOrDefault("X-Amz-Date")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Date", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Security-Token")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Security-Token", valid_603766
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603767 = header.getOrDefault("X-Amz-Target")
  valid_603767 = validateParameter(valid_603767, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDisk"))
  if valid_603767 != nil:
    section.add "X-Amz-Target", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Content-Sha256", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Algorithm")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Algorithm", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Signature")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Signature", valid_603770
  var valid_603771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-SignedHeaders", valid_603771
  var valid_603772 = header.getOrDefault("X-Amz-Credential")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Credential", valid_603772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603774: Call_GetDisk_603762; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific block storage disk.
  ## 
  let valid = call_603774.validator(path, query, header, formData, body)
  let scheme = call_603774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603774.url(scheme.get, call_603774.host, call_603774.base,
                         call_603774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603774, url, valid)

proc call*(call_603775: Call_GetDisk_603762; body: JsonNode): Recallable =
  ## getDisk
  ## Returns information about a specific block storage disk.
  ##   body: JObject (required)
  var body_603776 = newJObject()
  if body != nil:
    body_603776 = body
  result = call_603775.call(nil, nil, nil, nil, body_603776)

var getDisk* = Call_GetDisk_603762(name: "getDisk", meth: HttpMethod.HttpPost,
                                host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDisk",
                                validator: validate_GetDisk_603763, base: "/",
                                url: url_GetDisk_603764,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiskSnapshot_603777 = ref object of OpenApiRestCall_602466
proc url_GetDiskSnapshot_603779(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDiskSnapshot_603778(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603780 = header.getOrDefault("X-Amz-Date")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Date", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Security-Token")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Security-Token", valid_603781
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603782 = header.getOrDefault("X-Amz-Target")
  valid_603782 = validateParameter(valid_603782, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDiskSnapshot"))
  if valid_603782 != nil:
    section.add "X-Amz-Target", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Content-Sha256", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Algorithm")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Algorithm", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Signature")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Signature", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-SignedHeaders", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-Credential")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Credential", valid_603787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603789: Call_GetDiskSnapshot_603777; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific block storage disk snapshot.
  ## 
  let valid = call_603789.validator(path, query, header, formData, body)
  let scheme = call_603789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603789.url(scheme.get, call_603789.host, call_603789.base,
                         call_603789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603789, url, valid)

proc call*(call_603790: Call_GetDiskSnapshot_603777; body: JsonNode): Recallable =
  ## getDiskSnapshot
  ## Returns information about a specific block storage disk snapshot.
  ##   body: JObject (required)
  var body_603791 = newJObject()
  if body != nil:
    body_603791 = body
  result = call_603790.call(nil, nil, nil, nil, body_603791)

var getDiskSnapshot* = Call_GetDiskSnapshot_603777(name: "getDiskSnapshot",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDiskSnapshot",
    validator: validate_GetDiskSnapshot_603778, base: "/", url: url_GetDiskSnapshot_603779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiskSnapshots_603792 = ref object of OpenApiRestCall_602466
proc url_GetDiskSnapshots_603794(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDiskSnapshots_603793(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603795 = header.getOrDefault("X-Amz-Date")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Date", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Security-Token")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Security-Token", valid_603796
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603797 = header.getOrDefault("X-Amz-Target")
  valid_603797 = validateParameter(valid_603797, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDiskSnapshots"))
  if valid_603797 != nil:
    section.add "X-Amz-Target", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Content-Sha256", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Algorithm")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Algorithm", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Signature")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Signature", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-SignedHeaders", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Credential")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Credential", valid_603802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603804: Call_GetDiskSnapshots_603792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all block storage disk snapshots in your AWS account and region.</p> <p>If you are describing a long list of disk snapshots, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ## 
  let valid = call_603804.validator(path, query, header, formData, body)
  let scheme = call_603804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603804.url(scheme.get, call_603804.host, call_603804.base,
                         call_603804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603804, url, valid)

proc call*(call_603805: Call_GetDiskSnapshots_603792; body: JsonNode): Recallable =
  ## getDiskSnapshots
  ## <p>Returns information about all block storage disk snapshots in your AWS account and region.</p> <p>If you are describing a long list of disk snapshots, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ##   body: JObject (required)
  var body_603806 = newJObject()
  if body != nil:
    body_603806 = body
  result = call_603805.call(nil, nil, nil, nil, body_603806)

var getDiskSnapshots* = Call_GetDiskSnapshots_603792(name: "getDiskSnapshots",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetDiskSnapshots",
    validator: validate_GetDiskSnapshots_603793, base: "/",
    url: url_GetDiskSnapshots_603794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisks_603807 = ref object of OpenApiRestCall_602466
proc url_GetDisks_603809(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDisks_603808(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603810 = header.getOrDefault("X-Amz-Date")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "X-Amz-Date", valid_603810
  var valid_603811 = header.getOrDefault("X-Amz-Security-Token")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "X-Amz-Security-Token", valid_603811
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603812 = header.getOrDefault("X-Amz-Target")
  valid_603812 = validateParameter(valid_603812, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDisks"))
  if valid_603812 != nil:
    section.add "X-Amz-Target", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Content-Sha256", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Algorithm")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Algorithm", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Signature")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Signature", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-SignedHeaders", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Credential")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Credential", valid_603817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603819: Call_GetDisks_603807; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all block storage disks in your AWS account and region.</p> <p>If you are describing a long list of disks, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ## 
  let valid = call_603819.validator(path, query, header, formData, body)
  let scheme = call_603819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603819.url(scheme.get, call_603819.host, call_603819.base,
                         call_603819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603819, url, valid)

proc call*(call_603820: Call_GetDisks_603807; body: JsonNode): Recallable =
  ## getDisks
  ## <p>Returns information about all block storage disks in your AWS account and region.</p> <p>If you are describing a long list of disks, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ##   body: JObject (required)
  var body_603821 = newJObject()
  if body != nil:
    body_603821 = body
  result = call_603820.call(nil, nil, nil, nil, body_603821)

var getDisks* = Call_GetDisks_603807(name: "getDisks", meth: HttpMethod.HttpPost,
                                  host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDisks",
                                  validator: validate_GetDisks_603808, base: "/",
                                  url: url_GetDisks_603809,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomain_603822 = ref object of OpenApiRestCall_602466
proc url_GetDomain_603824(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDomain_603823(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603825 = header.getOrDefault("X-Amz-Date")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Date", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Security-Token")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Security-Token", valid_603826
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603827 = header.getOrDefault("X-Amz-Target")
  valid_603827 = validateParameter(valid_603827, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDomain"))
  if valid_603827 != nil:
    section.add "X-Amz-Target", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Content-Sha256", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Algorithm")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Algorithm", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Signature")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Signature", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-SignedHeaders", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Credential")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Credential", valid_603832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603834: Call_GetDomain_603822; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific domain recordset.
  ## 
  let valid = call_603834.validator(path, query, header, formData, body)
  let scheme = call_603834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603834.url(scheme.get, call_603834.host, call_603834.base,
                         call_603834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603834, url, valid)

proc call*(call_603835: Call_GetDomain_603822; body: JsonNode): Recallable =
  ## getDomain
  ## Returns information about a specific domain recordset.
  ##   body: JObject (required)
  var body_603836 = newJObject()
  if body != nil:
    body_603836 = body
  result = call_603835.call(nil, nil, nil, nil, body_603836)

var getDomain* = Call_GetDomain_603822(name: "getDomain", meth: HttpMethod.HttpPost,
                                    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDomain",
                                    validator: validate_GetDomain_603823,
                                    base: "/", url: url_GetDomain_603824,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomains_603837 = ref object of OpenApiRestCall_602466
proc url_GetDomains_603839(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDomains_603838(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603840 = header.getOrDefault("X-Amz-Date")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Date", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Security-Token")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Security-Token", valid_603841
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603842 = header.getOrDefault("X-Amz-Target")
  valid_603842 = validateParameter(valid_603842, JString, required = true, default = newJString(
      "Lightsail_20161128.GetDomains"))
  if valid_603842 != nil:
    section.add "X-Amz-Target", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Content-Sha256", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-Algorithm")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Algorithm", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-Signature")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Signature", valid_603845
  var valid_603846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-SignedHeaders", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Credential")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Credential", valid_603847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603849: Call_GetDomains_603837; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all domains in the user's account.
  ## 
  let valid = call_603849.validator(path, query, header, formData, body)
  let scheme = call_603849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603849.url(scheme.get, call_603849.host, call_603849.base,
                         call_603849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603849, url, valid)

proc call*(call_603850: Call_GetDomains_603837; body: JsonNode): Recallable =
  ## getDomains
  ## Returns a list of all domains in the user's account.
  ##   body: JObject (required)
  var body_603851 = newJObject()
  if body != nil:
    body_603851 = body
  result = call_603850.call(nil, nil, nil, nil, body_603851)

var getDomains* = Call_GetDomains_603837(name: "getDomains",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetDomains",
                                      validator: validate_GetDomains_603838,
                                      base: "/", url: url_GetDomains_603839,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExportSnapshotRecords_603852 = ref object of OpenApiRestCall_602466
proc url_GetExportSnapshotRecords_603854(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetExportSnapshotRecords_603853(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603855 = header.getOrDefault("X-Amz-Date")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Date", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Security-Token")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Security-Token", valid_603856
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603857 = header.getOrDefault("X-Amz-Target")
  valid_603857 = validateParameter(valid_603857, JString, required = true, default = newJString(
      "Lightsail_20161128.GetExportSnapshotRecords"))
  if valid_603857 != nil:
    section.add "X-Amz-Target", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Content-Sha256", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Algorithm")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Algorithm", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Signature")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Signature", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-SignedHeaders", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Credential")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Credential", valid_603862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603864: Call_GetExportSnapshotRecords_603852; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
  ## 
  let valid = call_603864.validator(path, query, header, formData, body)
  let scheme = call_603864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603864.url(scheme.get, call_603864.host, call_603864.base,
                         call_603864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603864, url, valid)

proc call*(call_603865: Call_GetExportSnapshotRecords_603852; body: JsonNode): Recallable =
  ## getExportSnapshotRecords
  ## <p>Returns the export snapshot record created as a result of the <code>export snapshot</code> operation.</p> <p>An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the <code>create cloud formation stack</code> operation.</p>
  ##   body: JObject (required)
  var body_603866 = newJObject()
  if body != nil:
    body_603866 = body
  result = call_603865.call(nil, nil, nil, nil, body_603866)

var getExportSnapshotRecords* = Call_GetExportSnapshotRecords_603852(
    name: "getExportSnapshotRecords", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetExportSnapshotRecords",
    validator: validate_GetExportSnapshotRecords_603853, base: "/",
    url: url_GetExportSnapshotRecords_603854, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstance_603867 = ref object of OpenApiRestCall_602466
proc url_GetInstance_603869(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstance_603868(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603870 = header.getOrDefault("X-Amz-Date")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Date", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Security-Token")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Security-Token", valid_603871
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603872 = header.getOrDefault("X-Amz-Target")
  valid_603872 = validateParameter(valid_603872, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstance"))
  if valid_603872 != nil:
    section.add "X-Amz-Target", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Content-Sha256", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Algorithm")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Algorithm", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Signature")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Signature", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-SignedHeaders", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Credential")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Credential", valid_603877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603879: Call_GetInstance_603867; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
  ## 
  let valid = call_603879.validator(path, query, header, formData, body)
  let scheme = call_603879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603879.url(scheme.get, call_603879.host, call_603879.base,
                         call_603879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603879, url, valid)

proc call*(call_603880: Call_GetInstance_603867; body: JsonNode): Recallable =
  ## getInstance
  ## Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
  ##   body: JObject (required)
  var body_603881 = newJObject()
  if body != nil:
    body_603881 = body
  result = call_603880.call(nil, nil, nil, nil, body_603881)

var getInstance* = Call_GetInstance_603867(name: "getInstance",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetInstance",
                                        validator: validate_GetInstance_603868,
                                        base: "/", url: url_GetInstance_603869,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceAccessDetails_603882 = ref object of OpenApiRestCall_602466
proc url_GetInstanceAccessDetails_603884(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstanceAccessDetails_603883(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603885 = header.getOrDefault("X-Amz-Date")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Date", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Security-Token")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Security-Token", valid_603886
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603887 = header.getOrDefault("X-Amz-Target")
  valid_603887 = validateParameter(valid_603887, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceAccessDetails"))
  if valid_603887 != nil:
    section.add "X-Amz-Target", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Content-Sha256", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Algorithm")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Algorithm", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-Signature")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-Signature", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-SignedHeaders", valid_603891
  var valid_603892 = header.getOrDefault("X-Amz-Credential")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-Credential", valid_603892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603894: Call_GetInstanceAccessDetails_603882; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_603894.validator(path, query, header, formData, body)
  let scheme = call_603894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603894.url(scheme.get, call_603894.host, call_603894.base,
                         call_603894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603894, url, valid)

proc call*(call_603895: Call_GetInstanceAccessDetails_603882; body: JsonNode): Recallable =
  ## getInstanceAccessDetails
  ## <p>Returns temporary SSH keys you can use to connect to a specific virtual private server, or <i>instance</i>.</p> <p>The <code>get instance access details</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_603896 = newJObject()
  if body != nil:
    body_603896 = body
  result = call_603895.call(nil, nil, nil, nil, body_603896)

var getInstanceAccessDetails* = Call_GetInstanceAccessDetails_603882(
    name: "getInstanceAccessDetails", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceAccessDetails",
    validator: validate_GetInstanceAccessDetails_603883, base: "/",
    url: url_GetInstanceAccessDetails_603884, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceMetricData_603897 = ref object of OpenApiRestCall_602466
proc url_GetInstanceMetricData_603899(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstanceMetricData_603898(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603900 = header.getOrDefault("X-Amz-Date")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Date", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Security-Token")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Security-Token", valid_603901
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603902 = header.getOrDefault("X-Amz-Target")
  valid_603902 = validateParameter(valid_603902, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceMetricData"))
  if valid_603902 != nil:
    section.add "X-Amz-Target", valid_603902
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603909: Call_GetInstanceMetricData_603897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the data points for the specified Amazon Lightsail instance metric, given an instance name.
  ## 
  let valid = call_603909.validator(path, query, header, formData, body)
  let scheme = call_603909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603909.url(scheme.get, call_603909.host, call_603909.base,
                         call_603909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603909, url, valid)

proc call*(call_603910: Call_GetInstanceMetricData_603897; body: JsonNode): Recallable =
  ## getInstanceMetricData
  ## Returns the data points for the specified Amazon Lightsail instance metric, given an instance name.
  ##   body: JObject (required)
  var body_603911 = newJObject()
  if body != nil:
    body_603911 = body
  result = call_603910.call(nil, nil, nil, nil, body_603911)

var getInstanceMetricData* = Call_GetInstanceMetricData_603897(
    name: "getInstanceMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceMetricData",
    validator: validate_GetInstanceMetricData_603898, base: "/",
    url: url_GetInstanceMetricData_603899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstancePortStates_603912 = ref object of OpenApiRestCall_602466
proc url_GetInstancePortStates_603914(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstancePortStates_603913(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603915 = header.getOrDefault("X-Amz-Date")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Date", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-Security-Token")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Security-Token", valid_603916
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603917 = header.getOrDefault("X-Amz-Target")
  valid_603917 = validateParameter(valid_603917, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstancePortStates"))
  if valid_603917 != nil:
    section.add "X-Amz-Target", valid_603917
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
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603924: Call_GetInstancePortStates_603912; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the port states for a specific virtual private server, or <i>instance</i>.
  ## 
  let valid = call_603924.validator(path, query, header, formData, body)
  let scheme = call_603924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603924.url(scheme.get, call_603924.host, call_603924.base,
                         call_603924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603924, url, valid)

proc call*(call_603925: Call_GetInstancePortStates_603912; body: JsonNode): Recallable =
  ## getInstancePortStates
  ## Returns the port states for a specific virtual private server, or <i>instance</i>.
  ##   body: JObject (required)
  var body_603926 = newJObject()
  if body != nil:
    body_603926 = body
  result = call_603925.call(nil, nil, nil, nil, body_603926)

var getInstancePortStates* = Call_GetInstancePortStates_603912(
    name: "getInstancePortStates", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstancePortStates",
    validator: validate_GetInstancePortStates_603913, base: "/",
    url: url_GetInstancePortStates_603914, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceSnapshot_603927 = ref object of OpenApiRestCall_602466
proc url_GetInstanceSnapshot_603929(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstanceSnapshot_603928(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603930 = header.getOrDefault("X-Amz-Date")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "X-Amz-Date", valid_603930
  var valid_603931 = header.getOrDefault("X-Amz-Security-Token")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "X-Amz-Security-Token", valid_603931
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603932 = header.getOrDefault("X-Amz-Target")
  valid_603932 = validateParameter(valid_603932, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceSnapshot"))
  if valid_603932 != nil:
    section.add "X-Amz-Target", valid_603932
  var valid_603933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "X-Amz-Content-Sha256", valid_603933
  var valid_603934 = header.getOrDefault("X-Amz-Algorithm")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Algorithm", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-Signature")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Signature", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-SignedHeaders", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Credential")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Credential", valid_603937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603939: Call_GetInstanceSnapshot_603927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific instance snapshot.
  ## 
  let valid = call_603939.validator(path, query, header, formData, body)
  let scheme = call_603939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603939.url(scheme.get, call_603939.host, call_603939.base,
                         call_603939.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603939, url, valid)

proc call*(call_603940: Call_GetInstanceSnapshot_603927; body: JsonNode): Recallable =
  ## getInstanceSnapshot
  ## Returns information about a specific instance snapshot.
  ##   body: JObject (required)
  var body_603941 = newJObject()
  if body != nil:
    body_603941 = body
  result = call_603940.call(nil, nil, nil, nil, body_603941)

var getInstanceSnapshot* = Call_GetInstanceSnapshot_603927(
    name: "getInstanceSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceSnapshot",
    validator: validate_GetInstanceSnapshot_603928, base: "/",
    url: url_GetInstanceSnapshot_603929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceSnapshots_603942 = ref object of OpenApiRestCall_602466
proc url_GetInstanceSnapshots_603944(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstanceSnapshots_603943(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603945 = header.getOrDefault("X-Amz-Date")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-Date", valid_603945
  var valid_603946 = header.getOrDefault("X-Amz-Security-Token")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "X-Amz-Security-Token", valid_603946
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603947 = header.getOrDefault("X-Amz-Target")
  valid_603947 = validateParameter(valid_603947, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceSnapshots"))
  if valid_603947 != nil:
    section.add "X-Amz-Target", valid_603947
  var valid_603948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "X-Amz-Content-Sha256", valid_603948
  var valid_603949 = header.getOrDefault("X-Amz-Algorithm")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Algorithm", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Signature")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Signature", valid_603950
  var valid_603951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-SignedHeaders", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Credential")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Credential", valid_603952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603954: Call_GetInstanceSnapshots_603942; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all instance snapshots for the user's account.
  ## 
  let valid = call_603954.validator(path, query, header, formData, body)
  let scheme = call_603954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603954.url(scheme.get, call_603954.host, call_603954.base,
                         call_603954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603954, url, valid)

proc call*(call_603955: Call_GetInstanceSnapshots_603942; body: JsonNode): Recallable =
  ## getInstanceSnapshots
  ## Returns all instance snapshots for the user's account.
  ##   body: JObject (required)
  var body_603956 = newJObject()
  if body != nil:
    body_603956 = body
  result = call_603955.call(nil, nil, nil, nil, body_603956)

var getInstanceSnapshots* = Call_GetInstanceSnapshots_603942(
    name: "getInstanceSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceSnapshots",
    validator: validate_GetInstanceSnapshots_603943, base: "/",
    url: url_GetInstanceSnapshots_603944, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceState_603957 = ref object of OpenApiRestCall_602466
proc url_GetInstanceState_603959(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstanceState_603958(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603960 = header.getOrDefault("X-Amz-Date")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Date", valid_603960
  var valid_603961 = header.getOrDefault("X-Amz-Security-Token")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "X-Amz-Security-Token", valid_603961
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603962 = header.getOrDefault("X-Amz-Target")
  valid_603962 = validateParameter(valid_603962, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstanceState"))
  if valid_603962 != nil:
    section.add "X-Amz-Target", valid_603962
  var valid_603963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "X-Amz-Content-Sha256", valid_603963
  var valid_603964 = header.getOrDefault("X-Amz-Algorithm")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "X-Amz-Algorithm", valid_603964
  var valid_603965 = header.getOrDefault("X-Amz-Signature")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "X-Amz-Signature", valid_603965
  var valid_603966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603966 = validateParameter(valid_603966, JString, required = false,
                                 default = nil)
  if valid_603966 != nil:
    section.add "X-Amz-SignedHeaders", valid_603966
  var valid_603967 = header.getOrDefault("X-Amz-Credential")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "X-Amz-Credential", valid_603967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603969: Call_GetInstanceState_603957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the state of a specific instance. Works on one instance at a time.
  ## 
  let valid = call_603969.validator(path, query, header, formData, body)
  let scheme = call_603969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603969.url(scheme.get, call_603969.host, call_603969.base,
                         call_603969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603969, url, valid)

proc call*(call_603970: Call_GetInstanceState_603957; body: JsonNode): Recallable =
  ## getInstanceState
  ## Returns the state of a specific instance. Works on one instance at a time.
  ##   body: JObject (required)
  var body_603971 = newJObject()
  if body != nil:
    body_603971 = body
  result = call_603970.call(nil, nil, nil, nil, body_603971)

var getInstanceState* = Call_GetInstanceState_603957(name: "getInstanceState",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstanceState",
    validator: validate_GetInstanceState_603958, base: "/",
    url: url_GetInstanceState_603959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstances_603972 = ref object of OpenApiRestCall_602466
proc url_GetInstances_603974(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstances_603973(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603975 = header.getOrDefault("X-Amz-Date")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "X-Amz-Date", valid_603975
  var valid_603976 = header.getOrDefault("X-Amz-Security-Token")
  valid_603976 = validateParameter(valid_603976, JString, required = false,
                                 default = nil)
  if valid_603976 != nil:
    section.add "X-Amz-Security-Token", valid_603976
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603977 = header.getOrDefault("X-Amz-Target")
  valid_603977 = validateParameter(valid_603977, JString, required = true, default = newJString(
      "Lightsail_20161128.GetInstances"))
  if valid_603977 != nil:
    section.add "X-Amz-Target", valid_603977
  var valid_603978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "X-Amz-Content-Sha256", valid_603978
  var valid_603979 = header.getOrDefault("X-Amz-Algorithm")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "X-Amz-Algorithm", valid_603979
  var valid_603980 = header.getOrDefault("X-Amz-Signature")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "X-Amz-Signature", valid_603980
  var valid_603981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "X-Amz-SignedHeaders", valid_603981
  var valid_603982 = header.getOrDefault("X-Amz-Credential")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-Credential", valid_603982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603984: Call_GetInstances_603972; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
  ## 
  let valid = call_603984.validator(path, query, header, formData, body)
  let scheme = call_603984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603984.url(scheme.get, call_603984.host, call_603984.base,
                         call_603984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603984, url, valid)

proc call*(call_603985: Call_GetInstances_603972; body: JsonNode): Recallable =
  ## getInstances
  ## Returns information about all Amazon Lightsail virtual private servers, or <i>instances</i>.
  ##   body: JObject (required)
  var body_603986 = newJObject()
  if body != nil:
    body_603986 = body
  result = call_603985.call(nil, nil, nil, nil, body_603986)

var getInstances* = Call_GetInstances_603972(name: "getInstances",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetInstances",
    validator: validate_GetInstances_603973, base: "/", url: url_GetInstances_603974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPair_603987 = ref object of OpenApiRestCall_602466
proc url_GetKeyPair_603989(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetKeyPair_603988(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603990 = header.getOrDefault("X-Amz-Date")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-Date", valid_603990
  var valid_603991 = header.getOrDefault("X-Amz-Security-Token")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-Security-Token", valid_603991
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603992 = header.getOrDefault("X-Amz-Target")
  valid_603992 = validateParameter(valid_603992, JString, required = true, default = newJString(
      "Lightsail_20161128.GetKeyPair"))
  if valid_603992 != nil:
    section.add "X-Amz-Target", valid_603992
  var valid_603993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603993 = validateParameter(valid_603993, JString, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "X-Amz-Content-Sha256", valid_603993
  var valid_603994 = header.getOrDefault("X-Amz-Algorithm")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Algorithm", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-Signature")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-Signature", valid_603995
  var valid_603996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-SignedHeaders", valid_603996
  var valid_603997 = header.getOrDefault("X-Amz-Credential")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-Credential", valid_603997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603999: Call_GetKeyPair_603987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific key pair.
  ## 
  let valid = call_603999.validator(path, query, header, formData, body)
  let scheme = call_603999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603999.url(scheme.get, call_603999.host, call_603999.base,
                         call_603999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603999, url, valid)

proc call*(call_604000: Call_GetKeyPair_603987; body: JsonNode): Recallable =
  ## getKeyPair
  ## Returns information about a specific key pair.
  ##   body: JObject (required)
  var body_604001 = newJObject()
  if body != nil:
    body_604001 = body
  result = call_604000.call(nil, nil, nil, nil, body_604001)

var getKeyPair* = Call_GetKeyPair_603987(name: "getKeyPair",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetKeyPair",
                                      validator: validate_GetKeyPair_603988,
                                      base: "/", url: url_GetKeyPair_603989,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPairs_604002 = ref object of OpenApiRestCall_602466
proc url_GetKeyPairs_604004(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetKeyPairs_604003(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604005 = header.getOrDefault("X-Amz-Date")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Date", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-Security-Token")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-Security-Token", valid_604006
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604007 = header.getOrDefault("X-Amz-Target")
  valid_604007 = validateParameter(valid_604007, JString, required = true, default = newJString(
      "Lightsail_20161128.GetKeyPairs"))
  if valid_604007 != nil:
    section.add "X-Amz-Target", valid_604007
  var valid_604008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604008 = validateParameter(valid_604008, JString, required = false,
                                 default = nil)
  if valid_604008 != nil:
    section.add "X-Amz-Content-Sha256", valid_604008
  var valid_604009 = header.getOrDefault("X-Amz-Algorithm")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "X-Amz-Algorithm", valid_604009
  var valid_604010 = header.getOrDefault("X-Amz-Signature")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "X-Amz-Signature", valid_604010
  var valid_604011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604011 = validateParameter(valid_604011, JString, required = false,
                                 default = nil)
  if valid_604011 != nil:
    section.add "X-Amz-SignedHeaders", valid_604011
  var valid_604012 = header.getOrDefault("X-Amz-Credential")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "X-Amz-Credential", valid_604012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604014: Call_GetKeyPairs_604002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all key pairs in the user's account.
  ## 
  let valid = call_604014.validator(path, query, header, formData, body)
  let scheme = call_604014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604014.url(scheme.get, call_604014.host, call_604014.base,
                         call_604014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604014, url, valid)

proc call*(call_604015: Call_GetKeyPairs_604002; body: JsonNode): Recallable =
  ## getKeyPairs
  ## Returns information about all key pairs in the user's account.
  ##   body: JObject (required)
  var body_604016 = newJObject()
  if body != nil:
    body_604016 = body
  result = call_604015.call(nil, nil, nil, nil, body_604016)

var getKeyPairs* = Call_GetKeyPairs_604002(name: "getKeyPairs",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetKeyPairs",
                                        validator: validate_GetKeyPairs_604003,
                                        base: "/", url: url_GetKeyPairs_604004,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancer_604017 = ref object of OpenApiRestCall_602466
proc url_GetLoadBalancer_604019(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLoadBalancer_604018(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604020 = header.getOrDefault("X-Amz-Date")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Date", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-Security-Token")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-Security-Token", valid_604021
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604022 = header.getOrDefault("X-Amz-Target")
  valid_604022 = validateParameter(valid_604022, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancer"))
  if valid_604022 != nil:
    section.add "X-Amz-Target", valid_604022
  var valid_604023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-Content-Sha256", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-Algorithm")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Algorithm", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-Signature")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Signature", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-SignedHeaders", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-Credential")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-Credential", valid_604027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604029: Call_GetLoadBalancer_604017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified Lightsail load balancer.
  ## 
  let valid = call_604029.validator(path, query, header, formData, body)
  let scheme = call_604029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604029.url(scheme.get, call_604029.host, call_604029.base,
                         call_604029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604029, url, valid)

proc call*(call_604030: Call_GetLoadBalancer_604017; body: JsonNode): Recallable =
  ## getLoadBalancer
  ## Returns information about the specified Lightsail load balancer.
  ##   body: JObject (required)
  var body_604031 = newJObject()
  if body != nil:
    body_604031 = body
  result = call_604030.call(nil, nil, nil, nil, body_604031)

var getLoadBalancer* = Call_GetLoadBalancer_604017(name: "getLoadBalancer",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancer",
    validator: validate_GetLoadBalancer_604018, base: "/", url: url_GetLoadBalancer_604019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancerMetricData_604032 = ref object of OpenApiRestCall_602466
proc url_GetLoadBalancerMetricData_604034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLoadBalancerMetricData_604033(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604035 = header.getOrDefault("X-Amz-Date")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Date", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-Security-Token")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Security-Token", valid_604036
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604037 = header.getOrDefault("X-Amz-Target")
  valid_604037 = validateParameter(valid_604037, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancerMetricData"))
  if valid_604037 != nil:
    section.add "X-Amz-Target", valid_604037
  var valid_604038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "X-Amz-Content-Sha256", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-Algorithm")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Algorithm", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Signature")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Signature", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-SignedHeaders", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Credential")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Credential", valid_604042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604044: Call_GetLoadBalancerMetricData_604032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about health metrics for your Lightsail load balancer.
  ## 
  let valid = call_604044.validator(path, query, header, formData, body)
  let scheme = call_604044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604044.url(scheme.get, call_604044.host, call_604044.base,
                         call_604044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604044, url, valid)

proc call*(call_604045: Call_GetLoadBalancerMetricData_604032; body: JsonNode): Recallable =
  ## getLoadBalancerMetricData
  ## Returns information about health metrics for your Lightsail load balancer.
  ##   body: JObject (required)
  var body_604046 = newJObject()
  if body != nil:
    body_604046 = body
  result = call_604045.call(nil, nil, nil, nil, body_604046)

var getLoadBalancerMetricData* = Call_GetLoadBalancerMetricData_604032(
    name: "getLoadBalancerMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancerMetricData",
    validator: validate_GetLoadBalancerMetricData_604033, base: "/",
    url: url_GetLoadBalancerMetricData_604034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancerTlsCertificates_604047 = ref object of OpenApiRestCall_602466
proc url_GetLoadBalancerTlsCertificates_604049(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLoadBalancerTlsCertificates_604048(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604050 = header.getOrDefault("X-Amz-Date")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Date", valid_604050
  var valid_604051 = header.getOrDefault("X-Amz-Security-Token")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-Security-Token", valid_604051
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604052 = header.getOrDefault("X-Amz-Target")
  valid_604052 = validateParameter(valid_604052, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancerTlsCertificates"))
  if valid_604052 != nil:
    section.add "X-Amz-Target", valid_604052
  var valid_604053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "X-Amz-Content-Sha256", valid_604053
  var valid_604054 = header.getOrDefault("X-Amz-Algorithm")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "X-Amz-Algorithm", valid_604054
  var valid_604055 = header.getOrDefault("X-Amz-Signature")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "X-Amz-Signature", valid_604055
  var valid_604056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-SignedHeaders", valid_604056
  var valid_604057 = header.getOrDefault("X-Amz-Credential")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Credential", valid_604057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604059: Call_GetLoadBalancerTlsCertificates_604047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the TLS certificates that are associated with the specified Lightsail load balancer.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.</p>
  ## 
  let valid = call_604059.validator(path, query, header, formData, body)
  let scheme = call_604059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604059.url(scheme.get, call_604059.host, call_604059.base,
                         call_604059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604059, url, valid)

proc call*(call_604060: Call_GetLoadBalancerTlsCertificates_604047; body: JsonNode): Recallable =
  ## getLoadBalancerTlsCertificates
  ## <p>Returns information about the TLS certificates that are associated with the specified Lightsail load balancer.</p> <p>TLS is just an updated, more secure version of Secure Socket Layer (SSL).</p> <p>You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.</p>
  ##   body: JObject (required)
  var body_604061 = newJObject()
  if body != nil:
    body_604061 = body
  result = call_604060.call(nil, nil, nil, nil, body_604061)

var getLoadBalancerTlsCertificates* = Call_GetLoadBalancerTlsCertificates_604047(
    name: "getLoadBalancerTlsCertificates", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancerTlsCertificates",
    validator: validate_GetLoadBalancerTlsCertificates_604048, base: "/",
    url: url_GetLoadBalancerTlsCertificates_604049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoadBalancers_604062 = ref object of OpenApiRestCall_602466
proc url_GetLoadBalancers_604064(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLoadBalancers_604063(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604065 = header.getOrDefault("X-Amz-Date")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "X-Amz-Date", valid_604065
  var valid_604066 = header.getOrDefault("X-Amz-Security-Token")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-Security-Token", valid_604066
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604067 = header.getOrDefault("X-Amz-Target")
  valid_604067 = validateParameter(valid_604067, JString, required = true, default = newJString(
      "Lightsail_20161128.GetLoadBalancers"))
  if valid_604067 != nil:
    section.add "X-Amz-Target", valid_604067
  var valid_604068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604068 = validateParameter(valid_604068, JString, required = false,
                                 default = nil)
  if valid_604068 != nil:
    section.add "X-Amz-Content-Sha256", valid_604068
  var valid_604069 = header.getOrDefault("X-Amz-Algorithm")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-Algorithm", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-Signature")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Signature", valid_604070
  var valid_604071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "X-Amz-SignedHeaders", valid_604071
  var valid_604072 = header.getOrDefault("X-Amz-Credential")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Credential", valid_604072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604074: Call_GetLoadBalancers_604062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all load balancers in an account.</p> <p>If you are describing a long list of load balancers, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ## 
  let valid = call_604074.validator(path, query, header, formData, body)
  let scheme = call_604074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604074.url(scheme.get, call_604074.host, call_604074.base,
                         call_604074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604074, url, valid)

proc call*(call_604075: Call_GetLoadBalancers_604062; body: JsonNode): Recallable =
  ## getLoadBalancers
  ## <p>Returns information about all load balancers in an account.</p> <p>If you are describing a long list of load balancers, you can paginate the output to make the list more manageable. You can use the pageToken and nextPageToken values to retrieve the next items in the list.</p>
  ##   body: JObject (required)
  var body_604076 = newJObject()
  if body != nil:
    body_604076 = body
  result = call_604075.call(nil, nil, nil, nil, body_604076)

var getLoadBalancers* = Call_GetLoadBalancers_604062(name: "getLoadBalancers",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetLoadBalancers",
    validator: validate_GetLoadBalancers_604063, base: "/",
    url: url_GetLoadBalancers_604064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperation_604077 = ref object of OpenApiRestCall_602466
proc url_GetOperation_604079(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOperation_604078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604080 = header.getOrDefault("X-Amz-Date")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Date", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-Security-Token")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Security-Token", valid_604081
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604082 = header.getOrDefault("X-Amz-Target")
  valid_604082 = validateParameter(valid_604082, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperation"))
  if valid_604082 != nil:
    section.add "X-Amz-Target", valid_604082
  var valid_604083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "X-Amz-Content-Sha256", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-Algorithm")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-Algorithm", valid_604084
  var valid_604085 = header.getOrDefault("X-Amz-Signature")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Signature", valid_604085
  var valid_604086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "X-Amz-SignedHeaders", valid_604086
  var valid_604087 = header.getOrDefault("X-Amz-Credential")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-Credential", valid_604087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604089: Call_GetOperation_604077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
  ## 
  let valid = call_604089.validator(path, query, header, formData, body)
  let scheme = call_604089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604089.url(scheme.get, call_604089.host, call_604089.base,
                         call_604089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604089, url, valid)

proc call*(call_604090: Call_GetOperation_604077; body: JsonNode): Recallable =
  ## getOperation
  ## Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
  ##   body: JObject (required)
  var body_604091 = newJObject()
  if body != nil:
    body_604091 = body
  result = call_604090.call(nil, nil, nil, nil, body_604091)

var getOperation* = Call_GetOperation_604077(name: "getOperation",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperation",
    validator: validate_GetOperation_604078, base: "/", url: url_GetOperation_604079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperations_604092 = ref object of OpenApiRestCall_602466
proc url_GetOperations_604094(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOperations_604093(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604095 = header.getOrDefault("X-Amz-Date")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Date", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-Security-Token")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Security-Token", valid_604096
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604097 = header.getOrDefault("X-Amz-Target")
  valid_604097 = validateParameter(valid_604097, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperations"))
  if valid_604097 != nil:
    section.add "X-Amz-Target", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-Content-Sha256", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-Algorithm")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Algorithm", valid_604099
  var valid_604100 = header.getOrDefault("X-Amz-Signature")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "X-Amz-Signature", valid_604100
  var valid_604101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "X-Amz-SignedHeaders", valid_604101
  var valid_604102 = header.getOrDefault("X-Amz-Credential")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "X-Amz-Credential", valid_604102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604104: Call_GetOperations_604092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
  ## 
  let valid = call_604104.validator(path, query, header, formData, body)
  let scheme = call_604104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604104.url(scheme.get, call_604104.host, call_604104.base,
                         call_604104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604104, url, valid)

proc call*(call_604105: Call_GetOperations_604092; body: JsonNode): Recallable =
  ## getOperations
  ## <p>Returns information about all operations.</p> <p>Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to <code>GetOperations</code> use the maximum (last) <code>statusChangedAt</code> value from the previous request.</p>
  ##   body: JObject (required)
  var body_604106 = newJObject()
  if body != nil:
    body_604106 = body
  result = call_604105.call(nil, nil, nil, nil, body_604106)

var getOperations* = Call_GetOperations_604092(name: "getOperations",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperations",
    validator: validate_GetOperations_604093, base: "/", url: url_GetOperations_604094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperationsForResource_604107 = ref object of OpenApiRestCall_602466
proc url_GetOperationsForResource_604109(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOperationsForResource_604108(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604110 = header.getOrDefault("X-Amz-Date")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Date", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Security-Token")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Security-Token", valid_604111
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604112 = header.getOrDefault("X-Amz-Target")
  valid_604112 = validateParameter(valid_604112, JString, required = true, default = newJString(
      "Lightsail_20161128.GetOperationsForResource"))
  if valid_604112 != nil:
    section.add "X-Amz-Target", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Content-Sha256", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Algorithm")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Algorithm", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Signature")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Signature", valid_604115
  var valid_604116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-SignedHeaders", valid_604116
  var valid_604117 = header.getOrDefault("X-Amz-Credential")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-Credential", valid_604117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604119: Call_GetOperationsForResource_604107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
  ## 
  let valid = call_604119.validator(path, query, header, formData, body)
  let scheme = call_604119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604119.url(scheme.get, call_604119.host, call_604119.base,
                         call_604119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604119, url, valid)

proc call*(call_604120: Call_GetOperationsForResource_604107; body: JsonNode): Recallable =
  ## getOperationsForResource
  ## Gets operations for a specific resource (e.g., an instance or a static IP).
  ##   body: JObject (required)
  var body_604121 = newJObject()
  if body != nil:
    body_604121 = body
  result = call_604120.call(nil, nil, nil, nil, body_604121)

var getOperationsForResource* = Call_GetOperationsForResource_604107(
    name: "getOperationsForResource", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetOperationsForResource",
    validator: validate_GetOperationsForResource_604108, base: "/",
    url: url_GetOperationsForResource_604109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegions_604122 = ref object of OpenApiRestCall_602466
proc url_GetRegions_604124(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRegions_604123(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604125 = header.getOrDefault("X-Amz-Date")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-Date", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-Security-Token")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Security-Token", valid_604126
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604127 = header.getOrDefault("X-Amz-Target")
  valid_604127 = validateParameter(valid_604127, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRegions"))
  if valid_604127 != nil:
    section.add "X-Amz-Target", valid_604127
  var valid_604128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-Content-Sha256", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Algorithm")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Algorithm", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Signature")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Signature", valid_604130
  var valid_604131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-SignedHeaders", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-Credential")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-Credential", valid_604132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604134: Call_GetRegions_604122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all valid regions for Amazon Lightsail. Use the <code>include availability zones</code> parameter to also return the Availability Zones in a region.
  ## 
  let valid = call_604134.validator(path, query, header, formData, body)
  let scheme = call_604134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604134.url(scheme.get, call_604134.host, call_604134.base,
                         call_604134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604134, url, valid)

proc call*(call_604135: Call_GetRegions_604122; body: JsonNode): Recallable =
  ## getRegions
  ## Returns a list of all valid regions for Amazon Lightsail. Use the <code>include availability zones</code> parameter to also return the Availability Zones in a region.
  ##   body: JObject (required)
  var body_604136 = newJObject()
  if body != nil:
    body_604136 = body
  result = call_604135.call(nil, nil, nil, nil, body_604136)

var getRegions* = Call_GetRegions_604122(name: "getRegions",
                                      meth: HttpMethod.HttpPost,
                                      host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetRegions",
                                      validator: validate_GetRegions_604123,
                                      base: "/", url: url_GetRegions_604124,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabase_604137 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabase_604139(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabase_604138(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604140 = header.getOrDefault("X-Amz-Date")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Date", valid_604140
  var valid_604141 = header.getOrDefault("X-Amz-Security-Token")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-Security-Token", valid_604141
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604142 = header.getOrDefault("X-Amz-Target")
  valid_604142 = validateParameter(valid_604142, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabase"))
  if valid_604142 != nil:
    section.add "X-Amz-Target", valid_604142
  var valid_604143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Content-Sha256", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Algorithm")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Algorithm", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Signature")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Signature", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-SignedHeaders", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-Credential")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-Credential", valid_604147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604149: Call_GetRelationalDatabase_604137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific database in Amazon Lightsail.
  ## 
  let valid = call_604149.validator(path, query, header, formData, body)
  let scheme = call_604149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604149.url(scheme.get, call_604149.host, call_604149.base,
                         call_604149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604149, url, valid)

proc call*(call_604150: Call_GetRelationalDatabase_604137; body: JsonNode): Recallable =
  ## getRelationalDatabase
  ## Returns information about a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_604151 = newJObject()
  if body != nil:
    body_604151 = body
  result = call_604150.call(nil, nil, nil, nil, body_604151)

var getRelationalDatabase* = Call_GetRelationalDatabase_604137(
    name: "getRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabase",
    validator: validate_GetRelationalDatabase_604138, base: "/",
    url: url_GetRelationalDatabase_604139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseBlueprints_604152 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabaseBlueprints_604154(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabaseBlueprints_604153(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604155 = header.getOrDefault("X-Amz-Date")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-Date", valid_604155
  var valid_604156 = header.getOrDefault("X-Amz-Security-Token")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-Security-Token", valid_604156
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604157 = header.getOrDefault("X-Amz-Target")
  valid_604157 = validateParameter(valid_604157, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseBlueprints"))
  if valid_604157 != nil:
    section.add "X-Amz-Target", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-Content-Sha256", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Algorithm")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Algorithm", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Signature")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Signature", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-SignedHeaders", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-Credential")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-Credential", valid_604162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604164: Call_GetRelationalDatabaseBlueprints_604152;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database.</p> <p>You can use a blueprint ID to create a new database that runs a specific database engine.</p>
  ## 
  let valid = call_604164.validator(path, query, header, formData, body)
  let scheme = call_604164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604164.url(scheme.get, call_604164.host, call_604164.base,
                         call_604164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604164, url, valid)

proc call*(call_604165: Call_GetRelationalDatabaseBlueprints_604152; body: JsonNode): Recallable =
  ## getRelationalDatabaseBlueprints
  ## <p>Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database.</p> <p>You can use a blueprint ID to create a new database that runs a specific database engine.</p>
  ##   body: JObject (required)
  var body_604166 = newJObject()
  if body != nil:
    body_604166 = body
  result = call_604165.call(nil, nil, nil, nil, body_604166)

var getRelationalDatabaseBlueprints* = Call_GetRelationalDatabaseBlueprints_604152(
    name: "getRelationalDatabaseBlueprints", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseBlueprints",
    validator: validate_GetRelationalDatabaseBlueprints_604153, base: "/",
    url: url_GetRelationalDatabaseBlueprints_604154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseBundles_604167 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabaseBundles_604169(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabaseBundles_604168(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604170 = header.getOrDefault("X-Amz-Date")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "X-Amz-Date", valid_604170
  var valid_604171 = header.getOrDefault("X-Amz-Security-Token")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "X-Amz-Security-Token", valid_604171
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604172 = header.getOrDefault("X-Amz-Target")
  valid_604172 = validateParameter(valid_604172, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseBundles"))
  if valid_604172 != nil:
    section.add "X-Amz-Target", valid_604172
  var valid_604173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "X-Amz-Content-Sha256", valid_604173
  var valid_604174 = header.getOrDefault("X-Amz-Algorithm")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-Algorithm", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-Signature")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Signature", valid_604175
  var valid_604176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "X-Amz-SignedHeaders", valid_604176
  var valid_604177 = header.getOrDefault("X-Amz-Credential")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-Credential", valid_604177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604179: Call_GetRelationalDatabaseBundles_604167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database.</p> <p>You can use a bundle ID to create a new database with explicit performance specifications.</p>
  ## 
  let valid = call_604179.validator(path, query, header, formData, body)
  let scheme = call_604179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604179.url(scheme.get, call_604179.host, call_604179.base,
                         call_604179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604179, url, valid)

proc call*(call_604180: Call_GetRelationalDatabaseBundles_604167; body: JsonNode): Recallable =
  ## getRelationalDatabaseBundles
  ## <p>Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database.</p> <p>You can use a bundle ID to create a new database with explicit performance specifications.</p>
  ##   body: JObject (required)
  var body_604181 = newJObject()
  if body != nil:
    body_604181 = body
  result = call_604180.call(nil, nil, nil, nil, body_604181)

var getRelationalDatabaseBundles* = Call_GetRelationalDatabaseBundles_604167(
    name: "getRelationalDatabaseBundles", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseBundles",
    validator: validate_GetRelationalDatabaseBundles_604168, base: "/",
    url: url_GetRelationalDatabaseBundles_604169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseEvents_604182 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabaseEvents_604184(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabaseEvents_604183(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604185 = header.getOrDefault("X-Amz-Date")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-Date", valid_604185
  var valid_604186 = header.getOrDefault("X-Amz-Security-Token")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-Security-Token", valid_604186
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604187 = header.getOrDefault("X-Amz-Target")
  valid_604187 = validateParameter(valid_604187, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseEvents"))
  if valid_604187 != nil:
    section.add "X-Amz-Target", valid_604187
  var valid_604188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604188 = validateParameter(valid_604188, JString, required = false,
                                 default = nil)
  if valid_604188 != nil:
    section.add "X-Amz-Content-Sha256", valid_604188
  var valid_604189 = header.getOrDefault("X-Amz-Algorithm")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "X-Amz-Algorithm", valid_604189
  var valid_604190 = header.getOrDefault("X-Amz-Signature")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-Signature", valid_604190
  var valid_604191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-SignedHeaders", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-Credential")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Credential", valid_604192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604194: Call_GetRelationalDatabaseEvents_604182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of events for a specific database in Amazon Lightsail.
  ## 
  let valid = call_604194.validator(path, query, header, formData, body)
  let scheme = call_604194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604194.url(scheme.get, call_604194.host, call_604194.base,
                         call_604194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604194, url, valid)

proc call*(call_604195: Call_GetRelationalDatabaseEvents_604182; body: JsonNode): Recallable =
  ## getRelationalDatabaseEvents
  ## Returns a list of events for a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_604196 = newJObject()
  if body != nil:
    body_604196 = body
  result = call_604195.call(nil, nil, nil, nil, body_604196)

var getRelationalDatabaseEvents* = Call_GetRelationalDatabaseEvents_604182(
    name: "getRelationalDatabaseEvents", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseEvents",
    validator: validate_GetRelationalDatabaseEvents_604183, base: "/",
    url: url_GetRelationalDatabaseEvents_604184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseLogEvents_604197 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabaseLogEvents_604199(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabaseLogEvents_604198(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604200 = header.getOrDefault("X-Amz-Date")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Date", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-Security-Token")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Security-Token", valid_604201
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604202 = header.getOrDefault("X-Amz-Target")
  valid_604202 = validateParameter(valid_604202, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseLogEvents"))
  if valid_604202 != nil:
    section.add "X-Amz-Target", valid_604202
  var valid_604203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-Content-Sha256", valid_604203
  var valid_604204 = header.getOrDefault("X-Amz-Algorithm")
  valid_604204 = validateParameter(valid_604204, JString, required = false,
                                 default = nil)
  if valid_604204 != nil:
    section.add "X-Amz-Algorithm", valid_604204
  var valid_604205 = header.getOrDefault("X-Amz-Signature")
  valid_604205 = validateParameter(valid_604205, JString, required = false,
                                 default = nil)
  if valid_604205 != nil:
    section.add "X-Amz-Signature", valid_604205
  var valid_604206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604206 = validateParameter(valid_604206, JString, required = false,
                                 default = nil)
  if valid_604206 != nil:
    section.add "X-Amz-SignedHeaders", valid_604206
  var valid_604207 = header.getOrDefault("X-Amz-Credential")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "X-Amz-Credential", valid_604207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604209: Call_GetRelationalDatabaseLogEvents_604197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of log events for a database in Amazon Lightsail.
  ## 
  let valid = call_604209.validator(path, query, header, formData, body)
  let scheme = call_604209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604209.url(scheme.get, call_604209.host, call_604209.base,
                         call_604209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604209, url, valid)

proc call*(call_604210: Call_GetRelationalDatabaseLogEvents_604197; body: JsonNode): Recallable =
  ## getRelationalDatabaseLogEvents
  ## Returns a list of log events for a database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_604211 = newJObject()
  if body != nil:
    body_604211 = body
  result = call_604210.call(nil, nil, nil, nil, body_604211)

var getRelationalDatabaseLogEvents* = Call_GetRelationalDatabaseLogEvents_604197(
    name: "getRelationalDatabaseLogEvents", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseLogEvents",
    validator: validate_GetRelationalDatabaseLogEvents_604198, base: "/",
    url: url_GetRelationalDatabaseLogEvents_604199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseLogStreams_604212 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabaseLogStreams_604214(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabaseLogStreams_604213(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604215 = header.getOrDefault("X-Amz-Date")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Date", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Security-Token")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Security-Token", valid_604216
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604217 = header.getOrDefault("X-Amz-Target")
  valid_604217 = validateParameter(valid_604217, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseLogStreams"))
  if valid_604217 != nil:
    section.add "X-Amz-Target", valid_604217
  var valid_604218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "X-Amz-Content-Sha256", valid_604218
  var valid_604219 = header.getOrDefault("X-Amz-Algorithm")
  valid_604219 = validateParameter(valid_604219, JString, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "X-Amz-Algorithm", valid_604219
  var valid_604220 = header.getOrDefault("X-Amz-Signature")
  valid_604220 = validateParameter(valid_604220, JString, required = false,
                                 default = nil)
  if valid_604220 != nil:
    section.add "X-Amz-Signature", valid_604220
  var valid_604221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604221 = validateParameter(valid_604221, JString, required = false,
                                 default = nil)
  if valid_604221 != nil:
    section.add "X-Amz-SignedHeaders", valid_604221
  var valid_604222 = header.getOrDefault("X-Amz-Credential")
  valid_604222 = validateParameter(valid_604222, JString, required = false,
                                 default = nil)
  if valid_604222 != nil:
    section.add "X-Amz-Credential", valid_604222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604224: Call_GetRelationalDatabaseLogStreams_604212;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of available log streams for a specific database in Amazon Lightsail.
  ## 
  let valid = call_604224.validator(path, query, header, formData, body)
  let scheme = call_604224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604224.url(scheme.get, call_604224.host, call_604224.base,
                         call_604224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604224, url, valid)

proc call*(call_604225: Call_GetRelationalDatabaseLogStreams_604212; body: JsonNode): Recallable =
  ## getRelationalDatabaseLogStreams
  ## Returns a list of available log streams for a specific database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_604226 = newJObject()
  if body != nil:
    body_604226 = body
  result = call_604225.call(nil, nil, nil, nil, body_604226)

var getRelationalDatabaseLogStreams* = Call_GetRelationalDatabaseLogStreams_604212(
    name: "getRelationalDatabaseLogStreams", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseLogStreams",
    validator: validate_GetRelationalDatabaseLogStreams_604213, base: "/",
    url: url_GetRelationalDatabaseLogStreams_604214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseMasterUserPassword_604227 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabaseMasterUserPassword_604229(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabaseMasterUserPassword_604228(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604230 = header.getOrDefault("X-Amz-Date")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Date", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-Security-Token")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Security-Token", valid_604231
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604232 = header.getOrDefault("X-Amz-Target")
  valid_604232 = validateParameter(valid_604232, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseMasterUserPassword"))
  if valid_604232 != nil:
    section.add "X-Amz-Target", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Content-Sha256", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-Algorithm")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Algorithm", valid_604234
  var valid_604235 = header.getOrDefault("X-Amz-Signature")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "X-Amz-Signature", valid_604235
  var valid_604236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604236 = validateParameter(valid_604236, JString, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "X-Amz-SignedHeaders", valid_604236
  var valid_604237 = header.getOrDefault("X-Amz-Credential")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "X-Amz-Credential", valid_604237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604239: Call_GetRelationalDatabaseMasterUserPassword_604227;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the current, previous, or pending versions of the master user password for a Lightsail database.</p> <p>The <code>GetRelationalDatabaseMasterUserPassword</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.</p>
  ## 
  let valid = call_604239.validator(path, query, header, formData, body)
  let scheme = call_604239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604239.url(scheme.get, call_604239.host, call_604239.base,
                         call_604239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604239, url, valid)

proc call*(call_604240: Call_GetRelationalDatabaseMasterUserPassword_604227;
          body: JsonNode): Recallable =
  ## getRelationalDatabaseMasterUserPassword
  ## <p>Returns the current, previous, or pending versions of the master user password for a Lightsail database.</p> <p>The <code>GetRelationalDatabaseMasterUserPassword</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.</p>
  ##   body: JObject (required)
  var body_604241 = newJObject()
  if body != nil:
    body_604241 = body
  result = call_604240.call(nil, nil, nil, nil, body_604241)

var getRelationalDatabaseMasterUserPassword* = Call_GetRelationalDatabaseMasterUserPassword_604227(
    name: "getRelationalDatabaseMasterUserPassword", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseMasterUserPassword",
    validator: validate_GetRelationalDatabaseMasterUserPassword_604228, base: "/",
    url: url_GetRelationalDatabaseMasterUserPassword_604229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseMetricData_604242 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabaseMetricData_604244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabaseMetricData_604243(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604245 = header.getOrDefault("X-Amz-Date")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "X-Amz-Date", valid_604245
  var valid_604246 = header.getOrDefault("X-Amz-Security-Token")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Security-Token", valid_604246
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604247 = header.getOrDefault("X-Amz-Target")
  valid_604247 = validateParameter(valid_604247, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseMetricData"))
  if valid_604247 != nil:
    section.add "X-Amz-Target", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Content-Sha256", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-Algorithm")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Algorithm", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Signature")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Signature", valid_604250
  var valid_604251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "X-Amz-SignedHeaders", valid_604251
  var valid_604252 = header.getOrDefault("X-Amz-Credential")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "X-Amz-Credential", valid_604252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604254: Call_GetRelationalDatabaseMetricData_604242;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the data points of the specified metric for a database in Amazon Lightsail.
  ## 
  let valid = call_604254.validator(path, query, header, formData, body)
  let scheme = call_604254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604254.url(scheme.get, call_604254.host, call_604254.base,
                         call_604254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604254, url, valid)

proc call*(call_604255: Call_GetRelationalDatabaseMetricData_604242; body: JsonNode): Recallable =
  ## getRelationalDatabaseMetricData
  ## Returns the data points of the specified metric for a database in Amazon Lightsail.
  ##   body: JObject (required)
  var body_604256 = newJObject()
  if body != nil:
    body_604256 = body
  result = call_604255.call(nil, nil, nil, nil, body_604256)

var getRelationalDatabaseMetricData* = Call_GetRelationalDatabaseMetricData_604242(
    name: "getRelationalDatabaseMetricData", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseMetricData",
    validator: validate_GetRelationalDatabaseMetricData_604243, base: "/",
    url: url_GetRelationalDatabaseMetricData_604244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseParameters_604257 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabaseParameters_604259(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabaseParameters_604258(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604260 = header.getOrDefault("X-Amz-Date")
  valid_604260 = validateParameter(valid_604260, JString, required = false,
                                 default = nil)
  if valid_604260 != nil:
    section.add "X-Amz-Date", valid_604260
  var valid_604261 = header.getOrDefault("X-Amz-Security-Token")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-Security-Token", valid_604261
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604262 = header.getOrDefault("X-Amz-Target")
  valid_604262 = validateParameter(valid_604262, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseParameters"))
  if valid_604262 != nil:
    section.add "X-Amz-Target", valid_604262
  var valid_604263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "X-Amz-Content-Sha256", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-Algorithm")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-Algorithm", valid_604264
  var valid_604265 = header.getOrDefault("X-Amz-Signature")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Signature", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-SignedHeaders", valid_604266
  var valid_604267 = header.getOrDefault("X-Amz-Credential")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-Credential", valid_604267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604269: Call_GetRelationalDatabaseParameters_604257;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail.</p> <p>In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.</p>
  ## 
  let valid = call_604269.validator(path, query, header, formData, body)
  let scheme = call_604269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604269.url(scheme.get, call_604269.host, call_604269.base,
                         call_604269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604269, url, valid)

proc call*(call_604270: Call_GetRelationalDatabaseParameters_604257; body: JsonNode): Recallable =
  ## getRelationalDatabaseParameters
  ## <p>Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail.</p> <p>In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.</p>
  ##   body: JObject (required)
  var body_604271 = newJObject()
  if body != nil:
    body_604271 = body
  result = call_604270.call(nil, nil, nil, nil, body_604271)

var getRelationalDatabaseParameters* = Call_GetRelationalDatabaseParameters_604257(
    name: "getRelationalDatabaseParameters", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseParameters",
    validator: validate_GetRelationalDatabaseParameters_604258, base: "/",
    url: url_GetRelationalDatabaseParameters_604259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseSnapshot_604272 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabaseSnapshot_604274(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabaseSnapshot_604273(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604275 = header.getOrDefault("X-Amz-Date")
  valid_604275 = validateParameter(valid_604275, JString, required = false,
                                 default = nil)
  if valid_604275 != nil:
    section.add "X-Amz-Date", valid_604275
  var valid_604276 = header.getOrDefault("X-Amz-Security-Token")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "X-Amz-Security-Token", valid_604276
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604277 = header.getOrDefault("X-Amz-Target")
  valid_604277 = validateParameter(valid_604277, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseSnapshot"))
  if valid_604277 != nil:
    section.add "X-Amz-Target", valid_604277
  var valid_604278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "X-Amz-Content-Sha256", valid_604278
  var valid_604279 = header.getOrDefault("X-Amz-Algorithm")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "X-Amz-Algorithm", valid_604279
  var valid_604280 = header.getOrDefault("X-Amz-Signature")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Signature", valid_604280
  var valid_604281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-SignedHeaders", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Credential")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Credential", valid_604282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604284: Call_GetRelationalDatabaseSnapshot_604272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific database snapshot in Amazon Lightsail.
  ## 
  let valid = call_604284.validator(path, query, header, formData, body)
  let scheme = call_604284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604284.url(scheme.get, call_604284.host, call_604284.base,
                         call_604284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604284, url, valid)

proc call*(call_604285: Call_GetRelationalDatabaseSnapshot_604272; body: JsonNode): Recallable =
  ## getRelationalDatabaseSnapshot
  ## Returns information about a specific database snapshot in Amazon Lightsail.
  ##   body: JObject (required)
  var body_604286 = newJObject()
  if body != nil:
    body_604286 = body
  result = call_604285.call(nil, nil, nil, nil, body_604286)

var getRelationalDatabaseSnapshot* = Call_GetRelationalDatabaseSnapshot_604272(
    name: "getRelationalDatabaseSnapshot", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseSnapshot",
    validator: validate_GetRelationalDatabaseSnapshot_604273, base: "/",
    url: url_GetRelationalDatabaseSnapshot_604274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabaseSnapshots_604287 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabaseSnapshots_604289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabaseSnapshots_604288(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604290 = header.getOrDefault("X-Amz-Date")
  valid_604290 = validateParameter(valid_604290, JString, required = false,
                                 default = nil)
  if valid_604290 != nil:
    section.add "X-Amz-Date", valid_604290
  var valid_604291 = header.getOrDefault("X-Amz-Security-Token")
  valid_604291 = validateParameter(valid_604291, JString, required = false,
                                 default = nil)
  if valid_604291 != nil:
    section.add "X-Amz-Security-Token", valid_604291
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604292 = header.getOrDefault("X-Amz-Target")
  valid_604292 = validateParameter(valid_604292, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabaseSnapshots"))
  if valid_604292 != nil:
    section.add "X-Amz-Target", valid_604292
  var valid_604293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604293 = validateParameter(valid_604293, JString, required = false,
                                 default = nil)
  if valid_604293 != nil:
    section.add "X-Amz-Content-Sha256", valid_604293
  var valid_604294 = header.getOrDefault("X-Amz-Algorithm")
  valid_604294 = validateParameter(valid_604294, JString, required = false,
                                 default = nil)
  if valid_604294 != nil:
    section.add "X-Amz-Algorithm", valid_604294
  var valid_604295 = header.getOrDefault("X-Amz-Signature")
  valid_604295 = validateParameter(valid_604295, JString, required = false,
                                 default = nil)
  if valid_604295 != nil:
    section.add "X-Amz-Signature", valid_604295
  var valid_604296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604296 = validateParameter(valid_604296, JString, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "X-Amz-SignedHeaders", valid_604296
  var valid_604297 = header.getOrDefault("X-Amz-Credential")
  valid_604297 = validateParameter(valid_604297, JString, required = false,
                                 default = nil)
  if valid_604297 != nil:
    section.add "X-Amz-Credential", valid_604297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604299: Call_GetRelationalDatabaseSnapshots_604287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all of your database snapshots in Amazon Lightsail.
  ## 
  let valid = call_604299.validator(path, query, header, formData, body)
  let scheme = call_604299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604299.url(scheme.get, call_604299.host, call_604299.base,
                         call_604299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604299, url, valid)

proc call*(call_604300: Call_GetRelationalDatabaseSnapshots_604287; body: JsonNode): Recallable =
  ## getRelationalDatabaseSnapshots
  ## Returns information about all of your database snapshots in Amazon Lightsail.
  ##   body: JObject (required)
  var body_604301 = newJObject()
  if body != nil:
    body_604301 = body
  result = call_604300.call(nil, nil, nil, nil, body_604301)

var getRelationalDatabaseSnapshots* = Call_GetRelationalDatabaseSnapshots_604287(
    name: "getRelationalDatabaseSnapshots", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabaseSnapshots",
    validator: validate_GetRelationalDatabaseSnapshots_604288, base: "/",
    url: url_GetRelationalDatabaseSnapshots_604289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRelationalDatabases_604302 = ref object of OpenApiRestCall_602466
proc url_GetRelationalDatabases_604304(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRelationalDatabases_604303(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604305 = header.getOrDefault("X-Amz-Date")
  valid_604305 = validateParameter(valid_604305, JString, required = false,
                                 default = nil)
  if valid_604305 != nil:
    section.add "X-Amz-Date", valid_604305
  var valid_604306 = header.getOrDefault("X-Amz-Security-Token")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "X-Amz-Security-Token", valid_604306
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604307 = header.getOrDefault("X-Amz-Target")
  valid_604307 = validateParameter(valid_604307, JString, required = true, default = newJString(
      "Lightsail_20161128.GetRelationalDatabases"))
  if valid_604307 != nil:
    section.add "X-Amz-Target", valid_604307
  var valid_604308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604308 = validateParameter(valid_604308, JString, required = false,
                                 default = nil)
  if valid_604308 != nil:
    section.add "X-Amz-Content-Sha256", valid_604308
  var valid_604309 = header.getOrDefault("X-Amz-Algorithm")
  valid_604309 = validateParameter(valid_604309, JString, required = false,
                                 default = nil)
  if valid_604309 != nil:
    section.add "X-Amz-Algorithm", valid_604309
  var valid_604310 = header.getOrDefault("X-Amz-Signature")
  valid_604310 = validateParameter(valid_604310, JString, required = false,
                                 default = nil)
  if valid_604310 != nil:
    section.add "X-Amz-Signature", valid_604310
  var valid_604311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604311 = validateParameter(valid_604311, JString, required = false,
                                 default = nil)
  if valid_604311 != nil:
    section.add "X-Amz-SignedHeaders", valid_604311
  var valid_604312 = header.getOrDefault("X-Amz-Credential")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "X-Amz-Credential", valid_604312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604314: Call_GetRelationalDatabases_604302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all of your databases in Amazon Lightsail.
  ## 
  let valid = call_604314.validator(path, query, header, formData, body)
  let scheme = call_604314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604314.url(scheme.get, call_604314.host, call_604314.base,
                         call_604314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604314, url, valid)

proc call*(call_604315: Call_GetRelationalDatabases_604302; body: JsonNode): Recallable =
  ## getRelationalDatabases
  ## Returns information about all of your databases in Amazon Lightsail.
  ##   body: JObject (required)
  var body_604316 = newJObject()
  if body != nil:
    body_604316 = body
  result = call_604315.call(nil, nil, nil, nil, body_604316)

var getRelationalDatabases* = Call_GetRelationalDatabases_604302(
    name: "getRelationalDatabases", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetRelationalDatabases",
    validator: validate_GetRelationalDatabases_604303, base: "/",
    url: url_GetRelationalDatabases_604304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStaticIp_604317 = ref object of OpenApiRestCall_602466
proc url_GetStaticIp_604319(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetStaticIp_604318(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604320 = header.getOrDefault("X-Amz-Date")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "X-Amz-Date", valid_604320
  var valid_604321 = header.getOrDefault("X-Amz-Security-Token")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "X-Amz-Security-Token", valid_604321
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604322 = header.getOrDefault("X-Amz-Target")
  valid_604322 = validateParameter(valid_604322, JString, required = true, default = newJString(
      "Lightsail_20161128.GetStaticIp"))
  if valid_604322 != nil:
    section.add "X-Amz-Target", valid_604322
  var valid_604323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604323 = validateParameter(valid_604323, JString, required = false,
                                 default = nil)
  if valid_604323 != nil:
    section.add "X-Amz-Content-Sha256", valid_604323
  var valid_604324 = header.getOrDefault("X-Amz-Algorithm")
  valid_604324 = validateParameter(valid_604324, JString, required = false,
                                 default = nil)
  if valid_604324 != nil:
    section.add "X-Amz-Algorithm", valid_604324
  var valid_604325 = header.getOrDefault("X-Amz-Signature")
  valid_604325 = validateParameter(valid_604325, JString, required = false,
                                 default = nil)
  if valid_604325 != nil:
    section.add "X-Amz-Signature", valid_604325
  var valid_604326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604326 = validateParameter(valid_604326, JString, required = false,
                                 default = nil)
  if valid_604326 != nil:
    section.add "X-Amz-SignedHeaders", valid_604326
  var valid_604327 = header.getOrDefault("X-Amz-Credential")
  valid_604327 = validateParameter(valid_604327, JString, required = false,
                                 default = nil)
  if valid_604327 != nil:
    section.add "X-Amz-Credential", valid_604327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604329: Call_GetStaticIp_604317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific static IP.
  ## 
  let valid = call_604329.validator(path, query, header, formData, body)
  let scheme = call_604329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604329.url(scheme.get, call_604329.host, call_604329.base,
                         call_604329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604329, url, valid)

proc call*(call_604330: Call_GetStaticIp_604317; body: JsonNode): Recallable =
  ## getStaticIp
  ## Returns information about a specific static IP.
  ##   body: JObject (required)
  var body_604331 = newJObject()
  if body != nil:
    body_604331 = body
  result = call_604330.call(nil, nil, nil, nil, body_604331)

var getStaticIp* = Call_GetStaticIp_604317(name: "getStaticIp",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.GetStaticIp",
                                        validator: validate_GetStaticIp_604318,
                                        base: "/", url: url_GetStaticIp_604319,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStaticIps_604332 = ref object of OpenApiRestCall_602466
proc url_GetStaticIps_604334(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetStaticIps_604333(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604335 = header.getOrDefault("X-Amz-Date")
  valid_604335 = validateParameter(valid_604335, JString, required = false,
                                 default = nil)
  if valid_604335 != nil:
    section.add "X-Amz-Date", valid_604335
  var valid_604336 = header.getOrDefault("X-Amz-Security-Token")
  valid_604336 = validateParameter(valid_604336, JString, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "X-Amz-Security-Token", valid_604336
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604337 = header.getOrDefault("X-Amz-Target")
  valid_604337 = validateParameter(valid_604337, JString, required = true, default = newJString(
      "Lightsail_20161128.GetStaticIps"))
  if valid_604337 != nil:
    section.add "X-Amz-Target", valid_604337
  var valid_604338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604338 = validateParameter(valid_604338, JString, required = false,
                                 default = nil)
  if valid_604338 != nil:
    section.add "X-Amz-Content-Sha256", valid_604338
  var valid_604339 = header.getOrDefault("X-Amz-Algorithm")
  valid_604339 = validateParameter(valid_604339, JString, required = false,
                                 default = nil)
  if valid_604339 != nil:
    section.add "X-Amz-Algorithm", valid_604339
  var valid_604340 = header.getOrDefault("X-Amz-Signature")
  valid_604340 = validateParameter(valid_604340, JString, required = false,
                                 default = nil)
  if valid_604340 != nil:
    section.add "X-Amz-Signature", valid_604340
  var valid_604341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604341 = validateParameter(valid_604341, JString, required = false,
                                 default = nil)
  if valid_604341 != nil:
    section.add "X-Amz-SignedHeaders", valid_604341
  var valid_604342 = header.getOrDefault("X-Amz-Credential")
  valid_604342 = validateParameter(valid_604342, JString, required = false,
                                 default = nil)
  if valid_604342 != nil:
    section.add "X-Amz-Credential", valid_604342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604344: Call_GetStaticIps_604332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about all static IPs in the user's account.
  ## 
  let valid = call_604344.validator(path, query, header, formData, body)
  let scheme = call_604344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604344.url(scheme.get, call_604344.host, call_604344.base,
                         call_604344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604344, url, valid)

proc call*(call_604345: Call_GetStaticIps_604332; body: JsonNode): Recallable =
  ## getStaticIps
  ## Returns information about all static IPs in the user's account.
  ##   body: JObject (required)
  var body_604346 = newJObject()
  if body != nil:
    body_604346 = body
  result = call_604345.call(nil, nil, nil, nil, body_604346)

var getStaticIps* = Call_GetStaticIps_604332(name: "getStaticIps",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.GetStaticIps",
    validator: validate_GetStaticIps_604333, base: "/", url: url_GetStaticIps_604334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportKeyPair_604347 = ref object of OpenApiRestCall_602466
proc url_ImportKeyPair_604349(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportKeyPair_604348(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604350 = header.getOrDefault("X-Amz-Date")
  valid_604350 = validateParameter(valid_604350, JString, required = false,
                                 default = nil)
  if valid_604350 != nil:
    section.add "X-Amz-Date", valid_604350
  var valid_604351 = header.getOrDefault("X-Amz-Security-Token")
  valid_604351 = validateParameter(valid_604351, JString, required = false,
                                 default = nil)
  if valid_604351 != nil:
    section.add "X-Amz-Security-Token", valid_604351
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604352 = header.getOrDefault("X-Amz-Target")
  valid_604352 = validateParameter(valid_604352, JString, required = true, default = newJString(
      "Lightsail_20161128.ImportKeyPair"))
  if valid_604352 != nil:
    section.add "X-Amz-Target", valid_604352
  var valid_604353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604353 = validateParameter(valid_604353, JString, required = false,
                                 default = nil)
  if valid_604353 != nil:
    section.add "X-Amz-Content-Sha256", valid_604353
  var valid_604354 = header.getOrDefault("X-Amz-Algorithm")
  valid_604354 = validateParameter(valid_604354, JString, required = false,
                                 default = nil)
  if valid_604354 != nil:
    section.add "X-Amz-Algorithm", valid_604354
  var valid_604355 = header.getOrDefault("X-Amz-Signature")
  valid_604355 = validateParameter(valid_604355, JString, required = false,
                                 default = nil)
  if valid_604355 != nil:
    section.add "X-Amz-Signature", valid_604355
  var valid_604356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604356 = validateParameter(valid_604356, JString, required = false,
                                 default = nil)
  if valid_604356 != nil:
    section.add "X-Amz-SignedHeaders", valid_604356
  var valid_604357 = header.getOrDefault("X-Amz-Credential")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-Credential", valid_604357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604359: Call_ImportKeyPair_604347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports a public SSH key from a specific key pair.
  ## 
  let valid = call_604359.validator(path, query, header, formData, body)
  let scheme = call_604359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604359.url(scheme.get, call_604359.host, call_604359.base,
                         call_604359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604359, url, valid)

proc call*(call_604360: Call_ImportKeyPair_604347; body: JsonNode): Recallable =
  ## importKeyPair
  ## Imports a public SSH key from a specific key pair.
  ##   body: JObject (required)
  var body_604361 = newJObject()
  if body != nil:
    body_604361 = body
  result = call_604360.call(nil, nil, nil, nil, body_604361)

var importKeyPair* = Call_ImportKeyPair_604347(name: "importKeyPair",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ImportKeyPair",
    validator: validate_ImportKeyPair_604348, base: "/", url: url_ImportKeyPair_604349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_IsVpcPeered_604362 = ref object of OpenApiRestCall_602466
proc url_IsVpcPeered_604364(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_IsVpcPeered_604363(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604365 = header.getOrDefault("X-Amz-Date")
  valid_604365 = validateParameter(valid_604365, JString, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "X-Amz-Date", valid_604365
  var valid_604366 = header.getOrDefault("X-Amz-Security-Token")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "X-Amz-Security-Token", valid_604366
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604367 = header.getOrDefault("X-Amz-Target")
  valid_604367 = validateParameter(valid_604367, JString, required = true, default = newJString(
      "Lightsail_20161128.IsVpcPeered"))
  if valid_604367 != nil:
    section.add "X-Amz-Target", valid_604367
  var valid_604368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604368 = validateParameter(valid_604368, JString, required = false,
                                 default = nil)
  if valid_604368 != nil:
    section.add "X-Amz-Content-Sha256", valid_604368
  var valid_604369 = header.getOrDefault("X-Amz-Algorithm")
  valid_604369 = validateParameter(valid_604369, JString, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "X-Amz-Algorithm", valid_604369
  var valid_604370 = header.getOrDefault("X-Amz-Signature")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "X-Amz-Signature", valid_604370
  var valid_604371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "X-Amz-SignedHeaders", valid_604371
  var valid_604372 = header.getOrDefault("X-Amz-Credential")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = nil)
  if valid_604372 != nil:
    section.add "X-Amz-Credential", valid_604372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604374: Call_IsVpcPeered_604362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a Boolean value indicating whether your Lightsail VPC is peered.
  ## 
  let valid = call_604374.validator(path, query, header, formData, body)
  let scheme = call_604374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604374.url(scheme.get, call_604374.host, call_604374.base,
                         call_604374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604374, url, valid)

proc call*(call_604375: Call_IsVpcPeered_604362; body: JsonNode): Recallable =
  ## isVpcPeered
  ## Returns a Boolean value indicating whether your Lightsail VPC is peered.
  ##   body: JObject (required)
  var body_604376 = newJObject()
  if body != nil:
    body_604376 = body
  result = call_604375.call(nil, nil, nil, nil, body_604376)

var isVpcPeered* = Call_IsVpcPeered_604362(name: "isVpcPeered",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.IsVpcPeered",
                                        validator: validate_IsVpcPeered_604363,
                                        base: "/", url: url_IsVpcPeered_604364,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_OpenInstancePublicPorts_604377 = ref object of OpenApiRestCall_602466
proc url_OpenInstancePublicPorts_604379(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_OpenInstancePublicPorts_604378(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604380 = header.getOrDefault("X-Amz-Date")
  valid_604380 = validateParameter(valid_604380, JString, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "X-Amz-Date", valid_604380
  var valid_604381 = header.getOrDefault("X-Amz-Security-Token")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "X-Amz-Security-Token", valid_604381
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604382 = header.getOrDefault("X-Amz-Target")
  valid_604382 = validateParameter(valid_604382, JString, required = true, default = newJString(
      "Lightsail_20161128.OpenInstancePublicPorts"))
  if valid_604382 != nil:
    section.add "X-Amz-Target", valid_604382
  var valid_604383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604383 = validateParameter(valid_604383, JString, required = false,
                                 default = nil)
  if valid_604383 != nil:
    section.add "X-Amz-Content-Sha256", valid_604383
  var valid_604384 = header.getOrDefault("X-Amz-Algorithm")
  valid_604384 = validateParameter(valid_604384, JString, required = false,
                                 default = nil)
  if valid_604384 != nil:
    section.add "X-Amz-Algorithm", valid_604384
  var valid_604385 = header.getOrDefault("X-Amz-Signature")
  valid_604385 = validateParameter(valid_604385, JString, required = false,
                                 default = nil)
  if valid_604385 != nil:
    section.add "X-Amz-Signature", valid_604385
  var valid_604386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604386 = validateParameter(valid_604386, JString, required = false,
                                 default = nil)
  if valid_604386 != nil:
    section.add "X-Amz-SignedHeaders", valid_604386
  var valid_604387 = header.getOrDefault("X-Amz-Credential")
  valid_604387 = validateParameter(valid_604387, JString, required = false,
                                 default = nil)
  if valid_604387 != nil:
    section.add "X-Amz-Credential", valid_604387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604389: Call_OpenInstancePublicPorts_604377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds public ports to an Amazon Lightsail instance.</p> <p>The <code>open instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604389.validator(path, query, header, formData, body)
  let scheme = call_604389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604389.url(scheme.get, call_604389.host, call_604389.base,
                         call_604389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604389, url, valid)

proc call*(call_604390: Call_OpenInstancePublicPorts_604377; body: JsonNode): Recallable =
  ## openInstancePublicPorts
  ## <p>Adds public ports to an Amazon Lightsail instance.</p> <p>The <code>open instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604391 = newJObject()
  if body != nil:
    body_604391 = body
  result = call_604390.call(nil, nil, nil, nil, body_604391)

var openInstancePublicPorts* = Call_OpenInstancePublicPorts_604377(
    name: "openInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.OpenInstancePublicPorts",
    validator: validate_OpenInstancePublicPorts_604378, base: "/",
    url: url_OpenInstancePublicPorts_604379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PeerVpc_604392 = ref object of OpenApiRestCall_602466
proc url_PeerVpc_604394(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PeerVpc_604393(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604395 = header.getOrDefault("X-Amz-Date")
  valid_604395 = validateParameter(valid_604395, JString, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "X-Amz-Date", valid_604395
  var valid_604396 = header.getOrDefault("X-Amz-Security-Token")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "X-Amz-Security-Token", valid_604396
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604397 = header.getOrDefault("X-Amz-Target")
  valid_604397 = validateParameter(valid_604397, JString, required = true, default = newJString(
      "Lightsail_20161128.PeerVpc"))
  if valid_604397 != nil:
    section.add "X-Amz-Target", valid_604397
  var valid_604398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604398 = validateParameter(valid_604398, JString, required = false,
                                 default = nil)
  if valid_604398 != nil:
    section.add "X-Amz-Content-Sha256", valid_604398
  var valid_604399 = header.getOrDefault("X-Amz-Algorithm")
  valid_604399 = validateParameter(valid_604399, JString, required = false,
                                 default = nil)
  if valid_604399 != nil:
    section.add "X-Amz-Algorithm", valid_604399
  var valid_604400 = header.getOrDefault("X-Amz-Signature")
  valid_604400 = validateParameter(valid_604400, JString, required = false,
                                 default = nil)
  if valid_604400 != nil:
    section.add "X-Amz-Signature", valid_604400
  var valid_604401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604401 = validateParameter(valid_604401, JString, required = false,
                                 default = nil)
  if valid_604401 != nil:
    section.add "X-Amz-SignedHeaders", valid_604401
  var valid_604402 = header.getOrDefault("X-Amz-Credential")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "X-Amz-Credential", valid_604402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604404: Call_PeerVpc_604392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tries to peer the Lightsail VPC with the user's default VPC.
  ## 
  let valid = call_604404.validator(path, query, header, formData, body)
  let scheme = call_604404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604404.url(scheme.get, call_604404.host, call_604404.base,
                         call_604404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604404, url, valid)

proc call*(call_604405: Call_PeerVpc_604392; body: JsonNode): Recallable =
  ## peerVpc
  ## Tries to peer the Lightsail VPC with the user's default VPC.
  ##   body: JObject (required)
  var body_604406 = newJObject()
  if body != nil:
    body_604406 = body
  result = call_604405.call(nil, nil, nil, nil, body_604406)

var peerVpc* = Call_PeerVpc_604392(name: "peerVpc", meth: HttpMethod.HttpPost,
                                host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.PeerVpc",
                                validator: validate_PeerVpc_604393, base: "/",
                                url: url_PeerVpc_604394,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInstancePublicPorts_604407 = ref object of OpenApiRestCall_602466
proc url_PutInstancePublicPorts_604409(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutInstancePublicPorts_604408(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604410 = header.getOrDefault("X-Amz-Date")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "X-Amz-Date", valid_604410
  var valid_604411 = header.getOrDefault("X-Amz-Security-Token")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-Security-Token", valid_604411
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604412 = header.getOrDefault("X-Amz-Target")
  valid_604412 = validateParameter(valid_604412, JString, required = true, default = newJString(
      "Lightsail_20161128.PutInstancePublicPorts"))
  if valid_604412 != nil:
    section.add "X-Amz-Target", valid_604412
  var valid_604413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604413 = validateParameter(valid_604413, JString, required = false,
                                 default = nil)
  if valid_604413 != nil:
    section.add "X-Amz-Content-Sha256", valid_604413
  var valid_604414 = header.getOrDefault("X-Amz-Algorithm")
  valid_604414 = validateParameter(valid_604414, JString, required = false,
                                 default = nil)
  if valid_604414 != nil:
    section.add "X-Amz-Algorithm", valid_604414
  var valid_604415 = header.getOrDefault("X-Amz-Signature")
  valid_604415 = validateParameter(valid_604415, JString, required = false,
                                 default = nil)
  if valid_604415 != nil:
    section.add "X-Amz-Signature", valid_604415
  var valid_604416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604416 = validateParameter(valid_604416, JString, required = false,
                                 default = nil)
  if valid_604416 != nil:
    section.add "X-Amz-SignedHeaders", valid_604416
  var valid_604417 = header.getOrDefault("X-Amz-Credential")
  valid_604417 = validateParameter(valid_604417, JString, required = false,
                                 default = nil)
  if valid_604417 != nil:
    section.add "X-Amz-Credential", valid_604417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604419: Call_PutInstancePublicPorts_604407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the specified open ports for an Amazon Lightsail instance, and closes all ports for every protocol not included in the current request.</p> <p>The <code>put instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604419.validator(path, query, header, formData, body)
  let scheme = call_604419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604419.url(scheme.get, call_604419.host, call_604419.base,
                         call_604419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604419, url, valid)

proc call*(call_604420: Call_PutInstancePublicPorts_604407; body: JsonNode): Recallable =
  ## putInstancePublicPorts
  ## <p>Sets the specified open ports for an Amazon Lightsail instance, and closes all ports for every protocol not included in the current request.</p> <p>The <code>put instance public ports</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604421 = newJObject()
  if body != nil:
    body_604421 = body
  result = call_604420.call(nil, nil, nil, nil, body_604421)

var putInstancePublicPorts* = Call_PutInstancePublicPorts_604407(
    name: "putInstancePublicPorts", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.PutInstancePublicPorts",
    validator: validate_PutInstancePublicPorts_604408, base: "/",
    url: url_PutInstancePublicPorts_604409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootInstance_604422 = ref object of OpenApiRestCall_602466
proc url_RebootInstance_604424(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RebootInstance_604423(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604425 = header.getOrDefault("X-Amz-Date")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "X-Amz-Date", valid_604425
  var valid_604426 = header.getOrDefault("X-Amz-Security-Token")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "X-Amz-Security-Token", valid_604426
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604427 = header.getOrDefault("X-Amz-Target")
  valid_604427 = validateParameter(valid_604427, JString, required = true, default = newJString(
      "Lightsail_20161128.RebootInstance"))
  if valid_604427 != nil:
    section.add "X-Amz-Target", valid_604427
  var valid_604428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "X-Amz-Content-Sha256", valid_604428
  var valid_604429 = header.getOrDefault("X-Amz-Algorithm")
  valid_604429 = validateParameter(valid_604429, JString, required = false,
                                 default = nil)
  if valid_604429 != nil:
    section.add "X-Amz-Algorithm", valid_604429
  var valid_604430 = header.getOrDefault("X-Amz-Signature")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "X-Amz-Signature", valid_604430
  var valid_604431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "X-Amz-SignedHeaders", valid_604431
  var valid_604432 = header.getOrDefault("X-Amz-Credential")
  valid_604432 = validateParameter(valid_604432, JString, required = false,
                                 default = nil)
  if valid_604432 != nil:
    section.add "X-Amz-Credential", valid_604432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604434: Call_RebootInstance_604422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restarts a specific instance.</p> <p>The <code>reboot instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604434.validator(path, query, header, formData, body)
  let scheme = call_604434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604434.url(scheme.get, call_604434.host, call_604434.base,
                         call_604434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604434, url, valid)

proc call*(call_604435: Call_RebootInstance_604422; body: JsonNode): Recallable =
  ## rebootInstance
  ## <p>Restarts a specific instance.</p> <p>The <code>reboot instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604436 = newJObject()
  if body != nil:
    body_604436 = body
  result = call_604435.call(nil, nil, nil, nil, body_604436)

var rebootInstance* = Call_RebootInstance_604422(name: "rebootInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.RebootInstance",
    validator: validate_RebootInstance_604423, base: "/", url: url_RebootInstance_604424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootRelationalDatabase_604437 = ref object of OpenApiRestCall_602466
proc url_RebootRelationalDatabase_604439(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RebootRelationalDatabase_604438(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604440 = header.getOrDefault("X-Amz-Date")
  valid_604440 = validateParameter(valid_604440, JString, required = false,
                                 default = nil)
  if valid_604440 != nil:
    section.add "X-Amz-Date", valid_604440
  var valid_604441 = header.getOrDefault("X-Amz-Security-Token")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-Security-Token", valid_604441
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604442 = header.getOrDefault("X-Amz-Target")
  valid_604442 = validateParameter(valid_604442, JString, required = true, default = newJString(
      "Lightsail_20161128.RebootRelationalDatabase"))
  if valid_604442 != nil:
    section.add "X-Amz-Target", valid_604442
  var valid_604443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "X-Amz-Content-Sha256", valid_604443
  var valid_604444 = header.getOrDefault("X-Amz-Algorithm")
  valid_604444 = validateParameter(valid_604444, JString, required = false,
                                 default = nil)
  if valid_604444 != nil:
    section.add "X-Amz-Algorithm", valid_604444
  var valid_604445 = header.getOrDefault("X-Amz-Signature")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "X-Amz-Signature", valid_604445
  var valid_604446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604446 = validateParameter(valid_604446, JString, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "X-Amz-SignedHeaders", valid_604446
  var valid_604447 = header.getOrDefault("X-Amz-Credential")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "X-Amz-Credential", valid_604447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604449: Call_RebootRelationalDatabase_604437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604449.validator(path, query, header, formData, body)
  let scheme = call_604449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604449.url(scheme.get, call_604449.host, call_604449.base,
                         call_604449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604449, url, valid)

proc call*(call_604450: Call_RebootRelationalDatabase_604437; body: JsonNode): Recallable =
  ## rebootRelationalDatabase
  ## <p>Restarts a specific database in Amazon Lightsail.</p> <p>The <code>reboot relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604451 = newJObject()
  if body != nil:
    body_604451 = body
  result = call_604450.call(nil, nil, nil, nil, body_604451)

var rebootRelationalDatabase* = Call_RebootRelationalDatabase_604437(
    name: "rebootRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.RebootRelationalDatabase",
    validator: validate_RebootRelationalDatabase_604438, base: "/",
    url: url_RebootRelationalDatabase_604439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReleaseStaticIp_604452 = ref object of OpenApiRestCall_602466
proc url_ReleaseStaticIp_604454(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ReleaseStaticIp_604453(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604455 = header.getOrDefault("X-Amz-Date")
  valid_604455 = validateParameter(valid_604455, JString, required = false,
                                 default = nil)
  if valid_604455 != nil:
    section.add "X-Amz-Date", valid_604455
  var valid_604456 = header.getOrDefault("X-Amz-Security-Token")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "X-Amz-Security-Token", valid_604456
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604457 = header.getOrDefault("X-Amz-Target")
  valid_604457 = validateParameter(valid_604457, JString, required = true, default = newJString(
      "Lightsail_20161128.ReleaseStaticIp"))
  if valid_604457 != nil:
    section.add "X-Amz-Target", valid_604457
  var valid_604458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604458 = validateParameter(valid_604458, JString, required = false,
                                 default = nil)
  if valid_604458 != nil:
    section.add "X-Amz-Content-Sha256", valid_604458
  var valid_604459 = header.getOrDefault("X-Amz-Algorithm")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "X-Amz-Algorithm", valid_604459
  var valid_604460 = header.getOrDefault("X-Amz-Signature")
  valid_604460 = validateParameter(valid_604460, JString, required = false,
                                 default = nil)
  if valid_604460 != nil:
    section.add "X-Amz-Signature", valid_604460
  var valid_604461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604461 = validateParameter(valid_604461, JString, required = false,
                                 default = nil)
  if valid_604461 != nil:
    section.add "X-Amz-SignedHeaders", valid_604461
  var valid_604462 = header.getOrDefault("X-Amz-Credential")
  valid_604462 = validateParameter(valid_604462, JString, required = false,
                                 default = nil)
  if valid_604462 != nil:
    section.add "X-Amz-Credential", valid_604462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604464: Call_ReleaseStaticIp_604452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specific static IP from your account.
  ## 
  let valid = call_604464.validator(path, query, header, formData, body)
  let scheme = call_604464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604464.url(scheme.get, call_604464.host, call_604464.base,
                         call_604464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604464, url, valid)

proc call*(call_604465: Call_ReleaseStaticIp_604452; body: JsonNode): Recallable =
  ## releaseStaticIp
  ## Deletes a specific static IP from your account.
  ##   body: JObject (required)
  var body_604466 = newJObject()
  if body != nil:
    body_604466 = body
  result = call_604465.call(nil, nil, nil, nil, body_604466)

var releaseStaticIp* = Call_ReleaseStaticIp_604452(name: "releaseStaticIp",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.ReleaseStaticIp",
    validator: validate_ReleaseStaticIp_604453, base: "/", url: url_ReleaseStaticIp_604454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartInstance_604467 = ref object of OpenApiRestCall_602466
proc url_StartInstance_604469(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartInstance_604468(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604470 = header.getOrDefault("X-Amz-Date")
  valid_604470 = validateParameter(valid_604470, JString, required = false,
                                 default = nil)
  if valid_604470 != nil:
    section.add "X-Amz-Date", valid_604470
  var valid_604471 = header.getOrDefault("X-Amz-Security-Token")
  valid_604471 = validateParameter(valid_604471, JString, required = false,
                                 default = nil)
  if valid_604471 != nil:
    section.add "X-Amz-Security-Token", valid_604471
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604472 = header.getOrDefault("X-Amz-Target")
  valid_604472 = validateParameter(valid_604472, JString, required = true, default = newJString(
      "Lightsail_20161128.StartInstance"))
  if valid_604472 != nil:
    section.add "X-Amz-Target", valid_604472
  var valid_604473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604473 = validateParameter(valid_604473, JString, required = false,
                                 default = nil)
  if valid_604473 != nil:
    section.add "X-Amz-Content-Sha256", valid_604473
  var valid_604474 = header.getOrDefault("X-Amz-Algorithm")
  valid_604474 = validateParameter(valid_604474, JString, required = false,
                                 default = nil)
  if valid_604474 != nil:
    section.add "X-Amz-Algorithm", valid_604474
  var valid_604475 = header.getOrDefault("X-Amz-Signature")
  valid_604475 = validateParameter(valid_604475, JString, required = false,
                                 default = nil)
  if valid_604475 != nil:
    section.add "X-Amz-Signature", valid_604475
  var valid_604476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604476 = validateParameter(valid_604476, JString, required = false,
                                 default = nil)
  if valid_604476 != nil:
    section.add "X-Amz-SignedHeaders", valid_604476
  var valid_604477 = header.getOrDefault("X-Amz-Credential")
  valid_604477 = validateParameter(valid_604477, JString, required = false,
                                 default = nil)
  if valid_604477 != nil:
    section.add "X-Amz-Credential", valid_604477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604479: Call_StartInstance_604467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604479.validator(path, query, header, formData, body)
  let scheme = call_604479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604479.url(scheme.get, call_604479.host, call_604479.base,
                         call_604479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604479, url, valid)

proc call*(call_604480: Call_StartInstance_604467; body: JsonNode): Recallable =
  ## startInstance
  ## <p>Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the <code>reboot instance</code> operation.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>start instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604481 = newJObject()
  if body != nil:
    body_604481 = body
  result = call_604480.call(nil, nil, nil, nil, body_604481)

var startInstance* = Call_StartInstance_604467(name: "startInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StartInstance",
    validator: validate_StartInstance_604468, base: "/", url: url_StartInstance_604469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRelationalDatabase_604482 = ref object of OpenApiRestCall_602466
proc url_StartRelationalDatabase_604484(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartRelationalDatabase_604483(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604485 = header.getOrDefault("X-Amz-Date")
  valid_604485 = validateParameter(valid_604485, JString, required = false,
                                 default = nil)
  if valid_604485 != nil:
    section.add "X-Amz-Date", valid_604485
  var valid_604486 = header.getOrDefault("X-Amz-Security-Token")
  valid_604486 = validateParameter(valid_604486, JString, required = false,
                                 default = nil)
  if valid_604486 != nil:
    section.add "X-Amz-Security-Token", valid_604486
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604487 = header.getOrDefault("X-Amz-Target")
  valid_604487 = validateParameter(valid_604487, JString, required = true, default = newJString(
      "Lightsail_20161128.StartRelationalDatabase"))
  if valid_604487 != nil:
    section.add "X-Amz-Target", valid_604487
  var valid_604488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604488 = validateParameter(valid_604488, JString, required = false,
                                 default = nil)
  if valid_604488 != nil:
    section.add "X-Amz-Content-Sha256", valid_604488
  var valid_604489 = header.getOrDefault("X-Amz-Algorithm")
  valid_604489 = validateParameter(valid_604489, JString, required = false,
                                 default = nil)
  if valid_604489 != nil:
    section.add "X-Amz-Algorithm", valid_604489
  var valid_604490 = header.getOrDefault("X-Amz-Signature")
  valid_604490 = validateParameter(valid_604490, JString, required = false,
                                 default = nil)
  if valid_604490 != nil:
    section.add "X-Amz-Signature", valid_604490
  var valid_604491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604491 = validateParameter(valid_604491, JString, required = false,
                                 default = nil)
  if valid_604491 != nil:
    section.add "X-Amz-SignedHeaders", valid_604491
  var valid_604492 = header.getOrDefault("X-Amz-Credential")
  valid_604492 = validateParameter(valid_604492, JString, required = false,
                                 default = nil)
  if valid_604492 != nil:
    section.add "X-Amz-Credential", valid_604492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604494: Call_StartRelationalDatabase_604482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the <code>reboot relational database</code> operation.</p> <p>The <code>start relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604494.validator(path, query, header, formData, body)
  let scheme = call_604494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604494.url(scheme.get, call_604494.host, call_604494.base,
                         call_604494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604494, url, valid)

proc call*(call_604495: Call_StartRelationalDatabase_604482; body: JsonNode): Recallable =
  ## startRelationalDatabase
  ## <p>Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the <code>reboot relational database</code> operation.</p> <p>The <code>start relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604496 = newJObject()
  if body != nil:
    body_604496 = body
  result = call_604495.call(nil, nil, nil, nil, body_604496)

var startRelationalDatabase* = Call_StartRelationalDatabase_604482(
    name: "startRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StartRelationalDatabase",
    validator: validate_StartRelationalDatabase_604483, base: "/",
    url: url_StartRelationalDatabase_604484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopInstance_604497 = ref object of OpenApiRestCall_602466
proc url_StopInstance_604499(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopInstance_604498(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604500 = header.getOrDefault("X-Amz-Date")
  valid_604500 = validateParameter(valid_604500, JString, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "X-Amz-Date", valid_604500
  var valid_604501 = header.getOrDefault("X-Amz-Security-Token")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "X-Amz-Security-Token", valid_604501
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604502 = header.getOrDefault("X-Amz-Target")
  valid_604502 = validateParameter(valid_604502, JString, required = true, default = newJString(
      "Lightsail_20161128.StopInstance"))
  if valid_604502 != nil:
    section.add "X-Amz-Target", valid_604502
  var valid_604503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604503 = validateParameter(valid_604503, JString, required = false,
                                 default = nil)
  if valid_604503 != nil:
    section.add "X-Amz-Content-Sha256", valid_604503
  var valid_604504 = header.getOrDefault("X-Amz-Algorithm")
  valid_604504 = validateParameter(valid_604504, JString, required = false,
                                 default = nil)
  if valid_604504 != nil:
    section.add "X-Amz-Algorithm", valid_604504
  var valid_604505 = header.getOrDefault("X-Amz-Signature")
  valid_604505 = validateParameter(valid_604505, JString, required = false,
                                 default = nil)
  if valid_604505 != nil:
    section.add "X-Amz-Signature", valid_604505
  var valid_604506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604506 = validateParameter(valid_604506, JString, required = false,
                                 default = nil)
  if valid_604506 != nil:
    section.add "X-Amz-SignedHeaders", valid_604506
  var valid_604507 = header.getOrDefault("X-Amz-Credential")
  valid_604507 = validateParameter(valid_604507, JString, required = false,
                                 default = nil)
  if valid_604507 != nil:
    section.add "X-Amz-Credential", valid_604507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604509: Call_StopInstance_604497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604509.validator(path, query, header, formData, body)
  let scheme = call_604509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604509.url(scheme.get, call_604509.host, call_604509.base,
                         call_604509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604509, url, valid)

proc call*(call_604510: Call_StopInstance_604497; body: JsonNode): Recallable =
  ## stopInstance
  ## <p>Stops a specific Amazon Lightsail instance that is currently running.</p> <note> <p>When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/lightsail-create-static-ip">Lightsail Dev Guide</a>.</p> </note> <p>The <code>stop instance</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>instance name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604511 = newJObject()
  if body != nil:
    body_604511 = body
  result = call_604510.call(nil, nil, nil, nil, body_604511)

var stopInstance* = Call_StopInstance_604497(name: "stopInstance",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StopInstance",
    validator: validate_StopInstance_604498, base: "/", url: url_StopInstance_604499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopRelationalDatabase_604512 = ref object of OpenApiRestCall_602466
proc url_StopRelationalDatabase_604514(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopRelationalDatabase_604513(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604515 = header.getOrDefault("X-Amz-Date")
  valid_604515 = validateParameter(valid_604515, JString, required = false,
                                 default = nil)
  if valid_604515 != nil:
    section.add "X-Amz-Date", valid_604515
  var valid_604516 = header.getOrDefault("X-Amz-Security-Token")
  valid_604516 = validateParameter(valid_604516, JString, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "X-Amz-Security-Token", valid_604516
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604517 = header.getOrDefault("X-Amz-Target")
  valid_604517 = validateParameter(valid_604517, JString, required = true, default = newJString(
      "Lightsail_20161128.StopRelationalDatabase"))
  if valid_604517 != nil:
    section.add "X-Amz-Target", valid_604517
  var valid_604518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604518 = validateParameter(valid_604518, JString, required = false,
                                 default = nil)
  if valid_604518 != nil:
    section.add "X-Amz-Content-Sha256", valid_604518
  var valid_604519 = header.getOrDefault("X-Amz-Algorithm")
  valid_604519 = validateParameter(valid_604519, JString, required = false,
                                 default = nil)
  if valid_604519 != nil:
    section.add "X-Amz-Algorithm", valid_604519
  var valid_604520 = header.getOrDefault("X-Amz-Signature")
  valid_604520 = validateParameter(valid_604520, JString, required = false,
                                 default = nil)
  if valid_604520 != nil:
    section.add "X-Amz-Signature", valid_604520
  var valid_604521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604521 = validateParameter(valid_604521, JString, required = false,
                                 default = nil)
  if valid_604521 != nil:
    section.add "X-Amz-SignedHeaders", valid_604521
  var valid_604522 = header.getOrDefault("X-Amz-Credential")
  valid_604522 = validateParameter(valid_604522, JString, required = false,
                                 default = nil)
  if valid_604522 != nil:
    section.add "X-Amz-Credential", valid_604522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604524: Call_StopRelationalDatabase_604512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a specific database that is currently running in Amazon Lightsail.</p> <p>The <code>stop relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604524.validator(path, query, header, formData, body)
  let scheme = call_604524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604524.url(scheme.get, call_604524.host, call_604524.base,
                         call_604524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604524, url, valid)

proc call*(call_604525: Call_StopRelationalDatabase_604512; body: JsonNode): Recallable =
  ## stopRelationalDatabase
  ## <p>Stops a specific database that is currently running in Amazon Lightsail.</p> <p>The <code>stop relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604526 = newJObject()
  if body != nil:
    body_604526 = body
  result = call_604525.call(nil, nil, nil, nil, body_604526)

var stopRelationalDatabase* = Call_StopRelationalDatabase_604512(
    name: "stopRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.StopRelationalDatabase",
    validator: validate_StopRelationalDatabase_604513, base: "/",
    url: url_StopRelationalDatabase_604514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_604527 = ref object of OpenApiRestCall_602466
proc url_TagResource_604529(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_604528(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604530 = header.getOrDefault("X-Amz-Date")
  valid_604530 = validateParameter(valid_604530, JString, required = false,
                                 default = nil)
  if valid_604530 != nil:
    section.add "X-Amz-Date", valid_604530
  var valid_604531 = header.getOrDefault("X-Amz-Security-Token")
  valid_604531 = validateParameter(valid_604531, JString, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "X-Amz-Security-Token", valid_604531
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604532 = header.getOrDefault("X-Amz-Target")
  valid_604532 = validateParameter(valid_604532, JString, required = true, default = newJString(
      "Lightsail_20161128.TagResource"))
  if valid_604532 != nil:
    section.add "X-Amz-Target", valid_604532
  var valid_604533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604533 = validateParameter(valid_604533, JString, required = false,
                                 default = nil)
  if valid_604533 != nil:
    section.add "X-Amz-Content-Sha256", valid_604533
  var valid_604534 = header.getOrDefault("X-Amz-Algorithm")
  valid_604534 = validateParameter(valid_604534, JString, required = false,
                                 default = nil)
  if valid_604534 != nil:
    section.add "X-Amz-Algorithm", valid_604534
  var valid_604535 = header.getOrDefault("X-Amz-Signature")
  valid_604535 = validateParameter(valid_604535, JString, required = false,
                                 default = nil)
  if valid_604535 != nil:
    section.add "X-Amz-Signature", valid_604535
  var valid_604536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604536 = validateParameter(valid_604536, JString, required = false,
                                 default = nil)
  if valid_604536 != nil:
    section.add "X-Amz-SignedHeaders", valid_604536
  var valid_604537 = header.getOrDefault("X-Amz-Credential")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "X-Amz-Credential", valid_604537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604539: Call_TagResource_604527; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-tags">Lightsail Dev Guide</a>.</p> <p>The <code>tag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604539.validator(path, query, header, formData, body)
  let scheme = call_604539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604539.url(scheme.get, call_604539.host, call_604539.base,
                         call_604539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604539, url, valid)

proc call*(call_604540: Call_TagResource_604527; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-tags">Lightsail Dev Guide</a>.</p> <p>The <code>tag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604541 = newJObject()
  if body != nil:
    body_604541 = body
  result = call_604540.call(nil, nil, nil, nil, body_604541)

var tagResource* = Call_TagResource_604527(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.TagResource",
                                        validator: validate_TagResource_604528,
                                        base: "/", url: url_TagResource_604529,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnpeerVpc_604542 = ref object of OpenApiRestCall_602466
proc url_UnpeerVpc_604544(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UnpeerVpc_604543(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604545 = header.getOrDefault("X-Amz-Date")
  valid_604545 = validateParameter(valid_604545, JString, required = false,
                                 default = nil)
  if valid_604545 != nil:
    section.add "X-Amz-Date", valid_604545
  var valid_604546 = header.getOrDefault("X-Amz-Security-Token")
  valid_604546 = validateParameter(valid_604546, JString, required = false,
                                 default = nil)
  if valid_604546 != nil:
    section.add "X-Amz-Security-Token", valid_604546
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604547 = header.getOrDefault("X-Amz-Target")
  valid_604547 = validateParameter(valid_604547, JString, required = true, default = newJString(
      "Lightsail_20161128.UnpeerVpc"))
  if valid_604547 != nil:
    section.add "X-Amz-Target", valid_604547
  var valid_604548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604548 = validateParameter(valid_604548, JString, required = false,
                                 default = nil)
  if valid_604548 != nil:
    section.add "X-Amz-Content-Sha256", valid_604548
  var valid_604549 = header.getOrDefault("X-Amz-Algorithm")
  valid_604549 = validateParameter(valid_604549, JString, required = false,
                                 default = nil)
  if valid_604549 != nil:
    section.add "X-Amz-Algorithm", valid_604549
  var valid_604550 = header.getOrDefault("X-Amz-Signature")
  valid_604550 = validateParameter(valid_604550, JString, required = false,
                                 default = nil)
  if valid_604550 != nil:
    section.add "X-Amz-Signature", valid_604550
  var valid_604551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604551 = validateParameter(valid_604551, JString, required = false,
                                 default = nil)
  if valid_604551 != nil:
    section.add "X-Amz-SignedHeaders", valid_604551
  var valid_604552 = header.getOrDefault("X-Amz-Credential")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "X-Amz-Credential", valid_604552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604554: Call_UnpeerVpc_604542; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to unpeer the Lightsail VPC from the user's default VPC.
  ## 
  let valid = call_604554.validator(path, query, header, formData, body)
  let scheme = call_604554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604554.url(scheme.get, call_604554.host, call_604554.base,
                         call_604554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604554, url, valid)

proc call*(call_604555: Call_UnpeerVpc_604542; body: JsonNode): Recallable =
  ## unpeerVpc
  ## Attempts to unpeer the Lightsail VPC from the user's default VPC.
  ##   body: JObject (required)
  var body_604556 = newJObject()
  if body != nil:
    body_604556 = body
  result = call_604555.call(nil, nil, nil, nil, body_604556)

var unpeerVpc* = Call_UnpeerVpc_604542(name: "unpeerVpc", meth: HttpMethod.HttpPost,
                                    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.UnpeerVpc",
                                    validator: validate_UnpeerVpc_604543,
                                    base: "/", url: url_UnpeerVpc_604544,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_604557 = ref object of OpenApiRestCall_602466
proc url_UntagResource_604559(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_604558(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604560 = header.getOrDefault("X-Amz-Date")
  valid_604560 = validateParameter(valid_604560, JString, required = false,
                                 default = nil)
  if valid_604560 != nil:
    section.add "X-Amz-Date", valid_604560
  var valid_604561 = header.getOrDefault("X-Amz-Security-Token")
  valid_604561 = validateParameter(valid_604561, JString, required = false,
                                 default = nil)
  if valid_604561 != nil:
    section.add "X-Amz-Security-Token", valid_604561
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604562 = header.getOrDefault("X-Amz-Target")
  valid_604562 = validateParameter(valid_604562, JString, required = true, default = newJString(
      "Lightsail_20161128.UntagResource"))
  if valid_604562 != nil:
    section.add "X-Amz-Target", valid_604562
  var valid_604563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604563 = validateParameter(valid_604563, JString, required = false,
                                 default = nil)
  if valid_604563 != nil:
    section.add "X-Amz-Content-Sha256", valid_604563
  var valid_604564 = header.getOrDefault("X-Amz-Algorithm")
  valid_604564 = validateParameter(valid_604564, JString, required = false,
                                 default = nil)
  if valid_604564 != nil:
    section.add "X-Amz-Algorithm", valid_604564
  var valid_604565 = header.getOrDefault("X-Amz-Signature")
  valid_604565 = validateParameter(valid_604565, JString, required = false,
                                 default = nil)
  if valid_604565 != nil:
    section.add "X-Amz-Signature", valid_604565
  var valid_604566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604566 = validateParameter(valid_604566, JString, required = false,
                                 default = nil)
  if valid_604566 != nil:
    section.add "X-Amz-SignedHeaders", valid_604566
  var valid_604567 = header.getOrDefault("X-Amz-Credential")
  valid_604567 = validateParameter(valid_604567, JString, required = false,
                                 default = nil)
  if valid_604567 != nil:
    section.add "X-Amz-Credential", valid_604567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604569: Call_UntagResource_604557; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604569.validator(path, query, header, formData, body)
  let scheme = call_604569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604569.url(scheme.get, call_604569.host, call_604569.base,
                         call_604569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604569, url, valid)

proc call*(call_604570: Call_UntagResource_604557; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource.</p> <p>The <code>untag resource</code> operation supports tag-based access control via request tags and resource tags applied to the resource identified by <code>resource name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604571 = newJObject()
  if body != nil:
    body_604571 = body
  result = call_604570.call(nil, nil, nil, nil, body_604571)

var untagResource* = Call_UntagResource_604557(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UntagResource",
    validator: validate_UntagResource_604558, base: "/", url: url_UntagResource_604559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainEntry_604572 = ref object of OpenApiRestCall_602466
proc url_UpdateDomainEntry_604574(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDomainEntry_604573(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604575 = header.getOrDefault("X-Amz-Date")
  valid_604575 = validateParameter(valid_604575, JString, required = false,
                                 default = nil)
  if valid_604575 != nil:
    section.add "X-Amz-Date", valid_604575
  var valid_604576 = header.getOrDefault("X-Amz-Security-Token")
  valid_604576 = validateParameter(valid_604576, JString, required = false,
                                 default = nil)
  if valid_604576 != nil:
    section.add "X-Amz-Security-Token", valid_604576
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604577 = header.getOrDefault("X-Amz-Target")
  valid_604577 = validateParameter(valid_604577, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateDomainEntry"))
  if valid_604577 != nil:
    section.add "X-Amz-Target", valid_604577
  var valid_604578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604578 = validateParameter(valid_604578, JString, required = false,
                                 default = nil)
  if valid_604578 != nil:
    section.add "X-Amz-Content-Sha256", valid_604578
  var valid_604579 = header.getOrDefault("X-Amz-Algorithm")
  valid_604579 = validateParameter(valid_604579, JString, required = false,
                                 default = nil)
  if valid_604579 != nil:
    section.add "X-Amz-Algorithm", valid_604579
  var valid_604580 = header.getOrDefault("X-Amz-Signature")
  valid_604580 = validateParameter(valid_604580, JString, required = false,
                                 default = nil)
  if valid_604580 != nil:
    section.add "X-Amz-Signature", valid_604580
  var valid_604581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604581 = validateParameter(valid_604581, JString, required = false,
                                 default = nil)
  if valid_604581 != nil:
    section.add "X-Amz-SignedHeaders", valid_604581
  var valid_604582 = header.getOrDefault("X-Amz-Credential")
  valid_604582 = validateParameter(valid_604582, JString, required = false,
                                 default = nil)
  if valid_604582 != nil:
    section.add "X-Amz-Credential", valid_604582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604584: Call_UpdateDomainEntry_604572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a domain recordset after it is created.</p> <p>The <code>update domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604584.validator(path, query, header, formData, body)
  let scheme = call_604584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604584.url(scheme.get, call_604584.host, call_604584.base,
                         call_604584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604584, url, valid)

proc call*(call_604585: Call_UpdateDomainEntry_604572; body: JsonNode): Recallable =
  ## updateDomainEntry
  ## <p>Updates a domain recordset after it is created.</p> <p>The <code>update domain entry</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>domain name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604586 = newJObject()
  if body != nil:
    body_604586 = body
  result = call_604585.call(nil, nil, nil, nil, body_604586)

var updateDomainEntry* = Call_UpdateDomainEntry_604572(name: "updateDomainEntry",
    meth: HttpMethod.HttpPost, host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateDomainEntry",
    validator: validate_UpdateDomainEntry_604573, base: "/",
    url: url_UpdateDomainEntry_604574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLoadBalancerAttribute_604587 = ref object of OpenApiRestCall_602466
proc url_UpdateLoadBalancerAttribute_604589(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateLoadBalancerAttribute_604588(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604590 = header.getOrDefault("X-Amz-Date")
  valid_604590 = validateParameter(valid_604590, JString, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "X-Amz-Date", valid_604590
  var valid_604591 = header.getOrDefault("X-Amz-Security-Token")
  valid_604591 = validateParameter(valid_604591, JString, required = false,
                                 default = nil)
  if valid_604591 != nil:
    section.add "X-Amz-Security-Token", valid_604591
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604592 = header.getOrDefault("X-Amz-Target")
  valid_604592 = validateParameter(valid_604592, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateLoadBalancerAttribute"))
  if valid_604592 != nil:
    section.add "X-Amz-Target", valid_604592
  var valid_604593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604593 = validateParameter(valid_604593, JString, required = false,
                                 default = nil)
  if valid_604593 != nil:
    section.add "X-Amz-Content-Sha256", valid_604593
  var valid_604594 = header.getOrDefault("X-Amz-Algorithm")
  valid_604594 = validateParameter(valid_604594, JString, required = false,
                                 default = nil)
  if valid_604594 != nil:
    section.add "X-Amz-Algorithm", valid_604594
  var valid_604595 = header.getOrDefault("X-Amz-Signature")
  valid_604595 = validateParameter(valid_604595, JString, required = false,
                                 default = nil)
  if valid_604595 != nil:
    section.add "X-Amz-Signature", valid_604595
  var valid_604596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604596 = validateParameter(valid_604596, JString, required = false,
                                 default = nil)
  if valid_604596 != nil:
    section.add "X-Amz-SignedHeaders", valid_604596
  var valid_604597 = header.getOrDefault("X-Amz-Credential")
  valid_604597 = validateParameter(valid_604597, JString, required = false,
                                 default = nil)
  if valid_604597 != nil:
    section.add "X-Amz-Credential", valid_604597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604599: Call_UpdateLoadBalancerAttribute_604587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604599.validator(path, query, header, formData, body)
  let scheme = call_604599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604599.url(scheme.get, call_604599.host, call_604599.base,
                         call_604599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604599, url, valid)

proc call*(call_604600: Call_UpdateLoadBalancerAttribute_604587; body: JsonNode): Recallable =
  ## updateLoadBalancerAttribute
  ## <p>Updates the specified attribute for a load balancer. You can only update one attribute at a time.</p> <p>The <code>update load balancer attribute</code> operation supports tag-based access control via resource tags applied to the resource identified by <code>load balancer name</code>. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604601 = newJObject()
  if body != nil:
    body_604601 = body
  result = call_604600.call(nil, nil, nil, nil, body_604601)

var updateLoadBalancerAttribute* = Call_UpdateLoadBalancerAttribute_604587(
    name: "updateLoadBalancerAttribute", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateLoadBalancerAttribute",
    validator: validate_UpdateLoadBalancerAttribute_604588, base: "/",
    url: url_UpdateLoadBalancerAttribute_604589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRelationalDatabase_604602 = ref object of OpenApiRestCall_602466
proc url_UpdateRelationalDatabase_604604(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRelationalDatabase_604603(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604605 = header.getOrDefault("X-Amz-Date")
  valid_604605 = validateParameter(valid_604605, JString, required = false,
                                 default = nil)
  if valid_604605 != nil:
    section.add "X-Amz-Date", valid_604605
  var valid_604606 = header.getOrDefault("X-Amz-Security-Token")
  valid_604606 = validateParameter(valid_604606, JString, required = false,
                                 default = nil)
  if valid_604606 != nil:
    section.add "X-Amz-Security-Token", valid_604606
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604607 = header.getOrDefault("X-Amz-Target")
  valid_604607 = validateParameter(valid_604607, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateRelationalDatabase"))
  if valid_604607 != nil:
    section.add "X-Amz-Target", valid_604607
  var valid_604608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604608 = validateParameter(valid_604608, JString, required = false,
                                 default = nil)
  if valid_604608 != nil:
    section.add "X-Amz-Content-Sha256", valid_604608
  var valid_604609 = header.getOrDefault("X-Amz-Algorithm")
  valid_604609 = validateParameter(valid_604609, JString, required = false,
                                 default = nil)
  if valid_604609 != nil:
    section.add "X-Amz-Algorithm", valid_604609
  var valid_604610 = header.getOrDefault("X-Amz-Signature")
  valid_604610 = validateParameter(valid_604610, JString, required = false,
                                 default = nil)
  if valid_604610 != nil:
    section.add "X-Amz-Signature", valid_604610
  var valid_604611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604611 = validateParameter(valid_604611, JString, required = false,
                                 default = nil)
  if valid_604611 != nil:
    section.add "X-Amz-SignedHeaders", valid_604611
  var valid_604612 = header.getOrDefault("X-Amz-Credential")
  valid_604612 = validateParameter(valid_604612, JString, required = false,
                                 default = nil)
  if valid_604612 != nil:
    section.add "X-Amz-Credential", valid_604612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604614: Call_UpdateRelationalDatabase_604602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604614.validator(path, query, header, formData, body)
  let scheme = call_604614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604614.url(scheme.get, call_604614.host, call_604614.base,
                         call_604614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604614, url, valid)

proc call*(call_604615: Call_UpdateRelationalDatabase_604602; body: JsonNode): Recallable =
  ## updateRelationalDatabase
  ## <p>Allows the update of one or more attributes of a database in Amazon Lightsail.</p> <p>Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window.</p> <p>The <code>update relational database</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604616 = newJObject()
  if body != nil:
    body_604616 = body
  result = call_604615.call(nil, nil, nil, nil, body_604616)

var updateRelationalDatabase* = Call_UpdateRelationalDatabase_604602(
    name: "updateRelationalDatabase", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com",
    route: "/#X-Amz-Target=Lightsail_20161128.UpdateRelationalDatabase",
    validator: validate_UpdateRelationalDatabase_604603, base: "/",
    url: url_UpdateRelationalDatabase_604604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRelationalDatabaseParameters_604617 = ref object of OpenApiRestCall_602466
proc url_UpdateRelationalDatabaseParameters_604619(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRelationalDatabaseParameters_604618(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which paramater updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
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
  var valid_604620 = header.getOrDefault("X-Amz-Date")
  valid_604620 = validateParameter(valid_604620, JString, required = false,
                                 default = nil)
  if valid_604620 != nil:
    section.add "X-Amz-Date", valid_604620
  var valid_604621 = header.getOrDefault("X-Amz-Security-Token")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "X-Amz-Security-Token", valid_604621
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604622 = header.getOrDefault("X-Amz-Target")
  valid_604622 = validateParameter(valid_604622, JString, required = true, default = newJString(
      "Lightsail_20161128.UpdateRelationalDatabaseParameters"))
  if valid_604622 != nil:
    section.add "X-Amz-Target", valid_604622
  var valid_604623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604623 = validateParameter(valid_604623, JString, required = false,
                                 default = nil)
  if valid_604623 != nil:
    section.add "X-Amz-Content-Sha256", valid_604623
  var valid_604624 = header.getOrDefault("X-Amz-Algorithm")
  valid_604624 = validateParameter(valid_604624, JString, required = false,
                                 default = nil)
  if valid_604624 != nil:
    section.add "X-Amz-Algorithm", valid_604624
  var valid_604625 = header.getOrDefault("X-Amz-Signature")
  valid_604625 = validateParameter(valid_604625, JString, required = false,
                                 default = nil)
  if valid_604625 != nil:
    section.add "X-Amz-Signature", valid_604625
  var valid_604626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604626 = validateParameter(valid_604626, JString, required = false,
                                 default = nil)
  if valid_604626 != nil:
    section.add "X-Amz-SignedHeaders", valid_604626
  var valid_604627 = header.getOrDefault("X-Amz-Credential")
  valid_604627 = validateParameter(valid_604627, JString, required = false,
                                 default = nil)
  if valid_604627 != nil:
    section.add "X-Amz-Credential", valid_604627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604629: Call_UpdateRelationalDatabaseParameters_604617;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which paramater updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ## 
  let valid = call_604629.validator(path, query, header, formData, body)
  let scheme = call_604629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604629.url(scheme.get, call_604629.host, call_604629.base,
                         call_604629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604629, url, valid)

proc call*(call_604630: Call_UpdateRelationalDatabaseParameters_604617;
          body: JsonNode): Recallable =
  ## updateRelationalDatabaseParameters
  ## <p>Allows the update of one or more parameters of a database in Amazon Lightsail.</p> <p>Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which paramater updates are applied: <code>dynamic</code> or <code>pending-reboot</code>. Parameters marked with a <code>dynamic</code> apply type are applied immediately. Parameters marked with a <code>pending-reboot</code> apply type are applied only after the database is rebooted using the <code>reboot relational database</code> operation.</p> <p>The <code>update relational database parameters</code> operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the <a href="https://lightsail.aws.amazon.com/ls/docs/en/articles/amazon-lightsail-controlling-access-using-tags">Lightsail Dev Guide</a>.</p>
  ##   body: JObject (required)
  var body_604631 = newJObject()
  if body != nil:
    body_604631 = body
  result = call_604630.call(nil, nil, nil, nil, body_604631)

var updateRelationalDatabaseParameters* = Call_UpdateRelationalDatabaseParameters_604617(
    name: "updateRelationalDatabaseParameters", meth: HttpMethod.HttpPost,
    host: "lightsail.amazonaws.com", route: "/#X-Amz-Target=Lightsail_20161128.UpdateRelationalDatabaseParameters",
    validator: validate_UpdateRelationalDatabaseParameters_604618, base: "/",
    url: url_UpdateRelationalDatabaseParameters_604619,
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
