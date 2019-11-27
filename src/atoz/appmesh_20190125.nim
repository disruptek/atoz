
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS App Mesh
## version: 2019-01-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS App Mesh is a service mesh based on the Envoy proxy that makes it easy to monitor and
##          control microservices. App Mesh standardizes how your microservices communicate, giving you
##          end-to-end visibility and helping to ensure high availability for your applications.</p>
##          <p>App Mesh gives you consistent visibility and network traffic controls for every
##          microservice in an application. You can use App Mesh with AWS Fargate, Amazon ECS, Amazon EKS,
##          Kubernetes on AWS, and Amazon EC2.</p>
##          <note>
##             <p>App Mesh supports microservice applications that use service discovery naming for their
##             components. For more information about service discovery on Amazon ECS, see <a href="http://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html">Service Discovery</a> in the
##                <i>Amazon Elastic Container Service Developer Guide</i>. Kubernetes <code>kube-dns</code> and
##                <code>coredns</code> are supported. For more information, see <a href="https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/">DNS
##                for Services and Pods</a> in the Kubernetes documentation.</p>
##          </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/appmesh/
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "appmesh.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appmesh.ap-southeast-1.amazonaws.com",
                           "us-west-2": "appmesh.us-west-2.amazonaws.com",
                           "eu-west-2": "appmesh.eu-west-2.amazonaws.com", "ap-northeast-3": "appmesh.ap-northeast-3.amazonaws.com", "eu-central-1": "appmesh.eu-central-1.amazonaws.com",
                           "us-east-2": "appmesh.us-east-2.amazonaws.com",
                           "us-east-1": "appmesh.us-east-1.amazonaws.com", "cn-northwest-1": "appmesh.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "appmesh.ap-south-1.amazonaws.com",
                           "eu-north-1": "appmesh.eu-north-1.amazonaws.com", "ap-northeast-2": "appmesh.ap-northeast-2.amazonaws.com",
                           "us-west-1": "appmesh.us-west-1.amazonaws.com", "us-gov-east-1": "appmesh.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "appmesh.eu-west-3.amazonaws.com",
                           "cn-north-1": "appmesh.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "appmesh.sa-east-1.amazonaws.com",
                           "eu-west-1": "appmesh.eu-west-1.amazonaws.com", "us-gov-west-1": "appmesh.us-gov-west-1.amazonaws.com", "ap-southeast-2": "appmesh.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "appmesh.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "appmesh.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "appmesh.ap-southeast-1.amazonaws.com",
      "us-west-2": "appmesh.us-west-2.amazonaws.com",
      "eu-west-2": "appmesh.eu-west-2.amazonaws.com",
      "ap-northeast-3": "appmesh.ap-northeast-3.amazonaws.com",
      "eu-central-1": "appmesh.eu-central-1.amazonaws.com",
      "us-east-2": "appmesh.us-east-2.amazonaws.com",
      "us-east-1": "appmesh.us-east-1.amazonaws.com",
      "cn-northwest-1": "appmesh.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "appmesh.ap-south-1.amazonaws.com",
      "eu-north-1": "appmesh.eu-north-1.amazonaws.com",
      "ap-northeast-2": "appmesh.ap-northeast-2.amazonaws.com",
      "us-west-1": "appmesh.us-west-1.amazonaws.com",
      "us-gov-east-1": "appmesh.us-gov-east-1.amazonaws.com",
      "eu-west-3": "appmesh.eu-west-3.amazonaws.com",
      "cn-north-1": "appmesh.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "appmesh.sa-east-1.amazonaws.com",
      "eu-west-1": "appmesh.eu-west-1.amazonaws.com",
      "us-gov-west-1": "appmesh.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "appmesh.ap-southeast-2.amazonaws.com",
      "ca-central-1": "appmesh.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "appmesh"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateMesh_599962 = ref object of OpenApiRestCall_599368
proc url_CreateMesh_599964(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMesh_599963(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599965 = header.getOrDefault("X-Amz-Date")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Date", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Security-Token")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Security-Token", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Content-Sha256", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-Algorithm")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Algorithm", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Signature")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Signature", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-SignedHeaders", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Credential")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Credential", valid_599971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599973: Call_CreateMesh_599962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ## 
  let valid = call_599973.validator(path, query, header, formData, body)
  let scheme = call_599973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599973.url(scheme.get, call_599973.host, call_599973.base,
                         call_599973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599973, url, valid)

proc call*(call_599974: Call_CreateMesh_599962; body: JsonNode): Recallable =
  ## createMesh
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ##   body: JObject (required)
  var body_599975 = newJObject()
  if body != nil:
    body_599975 = body
  result = call_599974.call(nil, nil, nil, nil, body_599975)

var createMesh* = Call_CreateMesh_599962(name: "createMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
                                      validator: validate_CreateMesh_599963,
                                      base: "/", url: url_CreateMesh_599964,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeshes_599705 = ref object of OpenApiRestCall_599368
proc url_ListMeshes_599707(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMeshes_599706(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing service meshes.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListMeshes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.</p> 
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is used only to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListMeshes</code> in paginated output.
  ##          When you use this parameter, <code>ListMeshes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListMeshes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListMeshes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_599819 = query.getOrDefault("nextToken")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "nextToken", valid_599819
  var valid_599820 = query.getOrDefault("limit")
  valid_599820 = validateParameter(valid_599820, JInt, required = false, default = nil)
  if valid_599820 != nil:
    section.add "limit", valid_599820
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
  var valid_599821 = header.getOrDefault("X-Amz-Date")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Date", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Security-Token")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Security-Token", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Content-Sha256", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-Algorithm")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Algorithm", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Signature")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Signature", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-SignedHeaders", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Credential")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Credential", valid_599827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599850: Call_ListMeshes_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing service meshes.
  ## 
  let valid = call_599850.validator(path, query, header, formData, body)
  let scheme = call_599850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599850.url(scheme.get, call_599850.host, call_599850.base,
                         call_599850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599850, url, valid)

proc call*(call_599921: Call_ListMeshes_599705; nextToken: string = ""; limit: int = 0): Recallable =
  ## listMeshes
  ## Returns a list of existing service meshes.
  ##   nextToken: string
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListMeshes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.</p> 
  ##          <note>
  ##             <p>This token should be treated as an opaque identifier that is used only to
  ##                 retrieve the next items in a list and not for other programmatic purposes.</p>
  ##         </note>
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListMeshes</code> in paginated output.
  ##          When you use this parameter, <code>ListMeshes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListMeshes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListMeshes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  var query_599922 = newJObject()
  add(query_599922, "nextToken", newJString(nextToken))
  add(query_599922, "limit", newJInt(limit))
  result = call_599921.call(nil, query_599922, nil, nil, nil)

var listMeshes* = Call_ListMeshes_599705(name: "listMeshes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
                                      validator: validate_ListMeshes_599706,
                                      base: "/", url: url_ListMeshes_599707,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_600008 = ref object of OpenApiRestCall_599368
proc url_CreateRoute_600010(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRoute_600009(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual service name is
  ##             <code>my-service.local</code> and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to create the route.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the route in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_600011 = path.getOrDefault("virtualRouterName")
  valid_600011 = validateParameter(valid_600011, JString, required = true,
                                 default = nil)
  if valid_600011 != nil:
    section.add "virtualRouterName", valid_600011
  var valid_600012 = path.getOrDefault("meshName")
  valid_600012 = validateParameter(valid_600012, JString, required = true,
                                 default = nil)
  if valid_600012 != nil:
    section.add "meshName", valid_600012
  result.add "path", section
  section = newJObject()
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
  var valid_600013 = header.getOrDefault("X-Amz-Date")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Date", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Security-Token")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Security-Token", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Content-Sha256", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-Algorithm")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Algorithm", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Signature")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Signature", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-SignedHeaders", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Credential")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Credential", valid_600019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600021: Call_CreateRoute_600008; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual service name is
  ##             <code>my-service.local</code> and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ## 
  let valid = call_600021.validator(path, query, header, formData, body)
  let scheme = call_600021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600021.url(scheme.get, call_600021.host, call_600021.base,
                         call_600021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600021, url, valid)

proc call*(call_600022: Call_CreateRoute_600008; virtualRouterName: string;
          meshName: string; body: JsonNode): Recallable =
  ## createRoute
  ## <p>Creates a route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual service name is
  ##             <code>my-service.local</code> and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to create the route.
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the route in.
  ##   body: JObject (required)
  var path_600023 = newJObject()
  var body_600024 = newJObject()
  add(path_600023, "virtualRouterName", newJString(virtualRouterName))
  add(path_600023, "meshName", newJString(meshName))
  if body != nil:
    body_600024 = body
  result = call_600022.call(path_600023, nil, nil, nil, body_600024)

var createRoute* = Call_CreateRoute_600008(name: "createRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                        validator: validate_CreateRoute_600009,
                                        base: "/", url: url_CreateRoute_600010,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutes_599976 = ref object of OpenApiRestCall_599368
proc url_ListRoutes_599978(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRoutes_599977(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing routes in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to list routes in.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list routes in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_599993 = path.getOrDefault("virtualRouterName")
  valid_599993 = validateParameter(valid_599993, JString, required = true,
                                 default = nil)
  if valid_599993 != nil:
    section.add "virtualRouterName", valid_599993
  var valid_599994 = path.getOrDefault("meshName")
  valid_599994 = validateParameter(valid_599994, JString, required = true,
                                 default = nil)
  if valid_599994 != nil:
    section.add "meshName", valid_599994
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListRoutes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListRoutes</code> in paginated output.
  ##          When you use this parameter, <code>ListRoutes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListRoutes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListRoutes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_599995 = query.getOrDefault("nextToken")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "nextToken", valid_599995
  var valid_599996 = query.getOrDefault("limit")
  valid_599996 = validateParameter(valid_599996, JInt, required = false, default = nil)
  if valid_599996 != nil:
    section.add "limit", valid_599996
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
  var valid_599997 = header.getOrDefault("X-Amz-Date")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Date", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Security-Token")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Security-Token", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Content-Sha256", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Algorithm")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Algorithm", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Signature")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Signature", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-SignedHeaders", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Credential")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Credential", valid_600003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600004: Call_ListRoutes_599976; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing routes in a service mesh.
  ## 
  let valid = call_600004.validator(path, query, header, formData, body)
  let scheme = call_600004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600004.url(scheme.get, call_600004.host, call_600004.base,
                         call_600004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600004, url, valid)

proc call*(call_600005: Call_ListRoutes_599976; virtualRouterName: string;
          meshName: string; nextToken: string = ""; limit: int = 0): Recallable =
  ## listRoutes
  ## Returns a list of existing routes in a service mesh.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to list routes in.
  ##   meshName: string (required)
  ##           : The name of the service mesh to list routes in.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListRoutes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListRoutes</code> in paginated output.
  ##          When you use this parameter, <code>ListRoutes</code> returns only <code>limit</code>
  ##          results in a single page along with a <code>nextToken</code> response element. You can see
  ##          the remaining results of the initial request by sending another <code>ListRoutes</code>
  ##          request with the returned <code>nextToken</code> value. This value can be between
  ##          1 and 100. If you don't use this parameter,
  ##             <code>ListRoutes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  var path_600006 = newJObject()
  var query_600007 = newJObject()
  add(path_600006, "virtualRouterName", newJString(virtualRouterName))
  add(path_600006, "meshName", newJString(meshName))
  add(query_600007, "nextToken", newJString(nextToken))
  add(query_600007, "limit", newJInt(limit))
  result = call_600005.call(path_600006, query_600007, nil, nil, nil)

var listRoutes* = Call_ListRoutes_599976(name: "listRoutes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                      validator: validate_ListRoutes_599977,
                                      base: "/", url: url_ListRoutes_599978,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualNode_600042 = ref object of OpenApiRestCall_599368
proc url_CreateVirtualNode_600044(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVirtualNode_600043(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as a logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you can specify the
  ##          service discovery information for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name: for example, <code>mesh/default/virtualNode/simpleapp</code>) as the
  ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
  ##          proxy container in your task definition or pod spec. This is then mapped to the
  ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
  ##          <note>
  ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
  ##             the <code>node.cluster</code> value that is set by
  ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
  ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
  ##          </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the virtual node in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600045 = path.getOrDefault("meshName")
  valid_600045 = validateParameter(valid_600045, JString, required = true,
                                 default = nil)
  if valid_600045 != nil:
    section.add "meshName", valid_600045
  result.add "path", section
  section = newJObject()
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
  var valid_600046 = header.getOrDefault("X-Amz-Date")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Date", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Security-Token")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Security-Token", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Content-Sha256", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-Algorithm")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Algorithm", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Signature")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Signature", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-SignedHeaders", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Credential")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Credential", valid_600052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600054: Call_CreateVirtualNode_600042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as a logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you can specify the
  ##          service discovery information for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name: for example, <code>mesh/default/virtualNode/simpleapp</code>) as the
  ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
  ##          proxy container in your task definition or pod spec. This is then mapped to the
  ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
  ##          <note>
  ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
  ##             the <code>node.cluster</code> value that is set by
  ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
  ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
  ##          </note>
  ## 
  let valid = call_600054.validator(path, query, header, formData, body)
  let scheme = call_600054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600054.url(scheme.get, call_600054.host, call_600054.base,
                         call_600054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600054, url, valid)

proc call*(call_600055: Call_CreateVirtualNode_600042; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualNode
  ## <p>Creates a virtual node within a service mesh.</p>
  ##          <p>A virtual node acts as a logical pointer to a particular task group, such as an Amazon ECS
  ##          service or a Kubernetes deployment. When you create a virtual node, you can specify the
  ##          service discovery information for your task group.</p>
  ##          <p>Any inbound traffic that your virtual node expects should be specified as a
  ##             <code>listener</code>. Any outbound traffic that your virtual node expects to reach
  ##          should be specified as a <code>backend</code>.</p>
  ##          <p>The response metadata for your new virtual node contains the <code>arn</code> that is
  ##          associated with the virtual node. Set this value (either the full ARN or the truncated
  ##          resource name: for example, <code>mesh/default/virtualNode/simpleapp</code>) as the
  ##             <code>APPMESH_VIRTUAL_NODE_NAME</code> environment variable for your task group's Envoy
  ##          proxy container in your task definition or pod spec. This is then mapped to the
  ##             <code>node.id</code> and <code>node.cluster</code> Envoy parameters.</p>
  ##          <note>
  ##             <p>If you require your Envoy stats or tracing to use a different name, you can override
  ##             the <code>node.cluster</code> value that is set by
  ##                <code>APPMESH_VIRTUAL_NODE_NAME</code> with the
  ##                <code>APPMESH_VIRTUAL_NODE_CLUSTER</code> environment variable.</p>
  ##          </note>
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the virtual node in.
  ##   body: JObject (required)
  var path_600056 = newJObject()
  var body_600057 = newJObject()
  add(path_600056, "meshName", newJString(meshName))
  if body != nil:
    body_600057 = body
  result = call_600055.call(path_600056, nil, nil, nil, body_600057)

var createVirtualNode* = Call_CreateVirtualNode_600042(name: "createVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_CreateVirtualNode_600043, base: "/",
    url: url_CreateVirtualNode_600044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualNodes_600025 = ref object of OpenApiRestCall_599368
proc url_ListVirtualNodes_600027(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVirtualNodes_600026(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of existing virtual nodes.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list virtual nodes in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600028 = path.getOrDefault("meshName")
  valid_600028 = validateParameter(valid_600028, JString, required = true,
                                 default = nil)
  if valid_600028 != nil:
    section.add "meshName", valid_600028
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualNodes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListVirtualNodes</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualNodes</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualNodes</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualNodes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_600029 = query.getOrDefault("nextToken")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "nextToken", valid_600029
  var valid_600030 = query.getOrDefault("limit")
  valid_600030 = validateParameter(valid_600030, JInt, required = false, default = nil)
  if valid_600030 != nil:
    section.add "limit", valid_600030
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
  var valid_600031 = header.getOrDefault("X-Amz-Date")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Date", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Security-Token")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Security-Token", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Content-Sha256", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Algorithm")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Algorithm", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Signature")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Signature", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-SignedHeaders", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Credential")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Credential", valid_600037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600038: Call_ListVirtualNodes_600025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual nodes.
  ## 
  let valid = call_600038.validator(path, query, header, formData, body)
  let scheme = call_600038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600038.url(scheme.get, call_600038.host, call_600038.base,
                         call_600038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600038, url, valid)

proc call*(call_600039: Call_ListVirtualNodes_600025; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualNodes
  ## Returns a list of existing virtual nodes.
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual nodes in.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualNodes</code> request where <code>limit</code> was used and the results
  ##          exceeded the value of that parameter. Pagination continues from the end of the previous
  ##          results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListVirtualNodes</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualNodes</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualNodes</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualNodes</code> returns up to 100 results and a
  ##             <code>nextToken</code> value if applicable.
  var path_600040 = newJObject()
  var query_600041 = newJObject()
  add(path_600040, "meshName", newJString(meshName))
  add(query_600041, "nextToken", newJString(nextToken))
  add(query_600041, "limit", newJInt(limit))
  result = call_600039.call(path_600040, query_600041, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_600025(name: "listVirtualNodes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_ListVirtualNodes_600026, base: "/",
    url: url_ListVirtualNodes_600027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualRouter_600075 = ref object of OpenApiRestCall_599368
proc url_CreateVirtualRouter_600077(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVirtualRouter_600076(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the virtual router in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600078 = path.getOrDefault("meshName")
  valid_600078 = validateParameter(valid_600078, JString, required = true,
                                 default = nil)
  if valid_600078 != nil:
    section.add "meshName", valid_600078
  result.add "path", section
  section = newJObject()
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
  var valid_600079 = header.getOrDefault("X-Amz-Date")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Date", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Security-Token")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Security-Token", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Content-Sha256", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Algorithm")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Algorithm", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Signature")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Signature", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-SignedHeaders", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Credential")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Credential", valid_600085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600087: Call_CreateVirtualRouter_600075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
  ## 
  let valid = call_600087.validator(path, query, header, formData, body)
  let scheme = call_600087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600087.url(scheme.get, call_600087.host, call_600087.base,
                         call_600087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600087, url, valid)

proc call*(call_600088: Call_CreateVirtualRouter_600075; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualRouter
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the virtual router in.
  ##   body: JObject (required)
  var path_600089 = newJObject()
  var body_600090 = newJObject()
  add(path_600089, "meshName", newJString(meshName))
  if body != nil:
    body_600090 = body
  result = call_600088.call(path_600089, nil, nil, nil, body_600090)

var createVirtualRouter* = Call_CreateVirtualRouter_600075(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_CreateVirtualRouter_600076, base: "/",
    url: url_CreateVirtualRouter_600077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualRouters_600058 = ref object of OpenApiRestCall_599368
proc url_ListVirtualRouters_600060(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVirtualRouters_600059(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list virtual routers in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600061 = path.getOrDefault("meshName")
  valid_600061 = validateParameter(valid_600061, JString, required = true,
                                 default = nil)
  if valid_600061 != nil:
    section.add "meshName", valid_600061
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListVirtualRouters</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualRouters</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualRouters</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualRouters</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_600062 = query.getOrDefault("nextToken")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "nextToken", valid_600062
  var valid_600063 = query.getOrDefault("limit")
  valid_600063 = validateParameter(valid_600063, JInt, required = false, default = nil)
  if valid_600063 != nil:
    section.add "limit", valid_600063
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
  var valid_600064 = header.getOrDefault("X-Amz-Date")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Date", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Security-Token")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Security-Token", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Content-Sha256", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Algorithm")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Algorithm", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Signature")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Signature", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-SignedHeaders", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Credential")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Credential", valid_600070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600071: Call_ListVirtualRouters_600058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  let valid = call_600071.validator(path, query, header, formData, body)
  let scheme = call_600071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600071.url(scheme.get, call_600071.host, call_600071.base,
                         call_600071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600071, url, valid)

proc call*(call_600072: Call_ListVirtualRouters_600058; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualRouters
  ## Returns a list of existing virtual routers in a service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual routers in.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualRouters</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListVirtualRouters</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualRouters</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualRouters</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualRouters</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
  var path_600073 = newJObject()
  var query_600074 = newJObject()
  add(path_600073, "meshName", newJString(meshName))
  add(query_600074, "nextToken", newJString(nextToken))
  add(query_600074, "limit", newJInt(limit))
  result = call_600072.call(path_600073, query_600074, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_600058(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_600059, base: "/",
    url: url_ListVirtualRouters_600060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualService_600108 = ref object of OpenApiRestCall_599368
proc url_CreateVirtualService_600110(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVirtualService_600109(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the virtual service in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600111 = path.getOrDefault("meshName")
  valid_600111 = validateParameter(valid_600111, JString, required = true,
                                 default = nil)
  if valid_600111 != nil:
    section.add "meshName", valid_600111
  result.add "path", section
  section = newJObject()
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
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Content-Sha256", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Algorithm")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Algorithm", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Signature")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Signature", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-SignedHeaders", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Credential")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Credential", valid_600118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600120: Call_CreateVirtualService_600108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ## 
  let valid = call_600120.validator(path, query, header, formData, body)
  let scheme = call_600120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600120.url(scheme.get, call_600120.host, call_600120.base,
                         call_600120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600120, url, valid)

proc call*(call_600121: Call_CreateVirtualService_600108; meshName: string;
          body: JsonNode): Recallable =
  ## createVirtualService
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the virtual service in.
  ##   body: JObject (required)
  var path_600122 = newJObject()
  var body_600123 = newJObject()
  add(path_600122, "meshName", newJString(meshName))
  if body != nil:
    body_600123 = body
  result = call_600121.call(path_600122, nil, nil, nil, body_600123)

var createVirtualService* = Call_CreateVirtualService_600108(
    name: "createVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_CreateVirtualService_600109, base: "/",
    url: url_CreateVirtualService_600110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualServices_600091 = ref object of OpenApiRestCall_599368
proc url_ListVirtualServices_600093(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVirtualServices_600092(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of existing virtual services in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list virtual services in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600094 = path.getOrDefault("meshName")
  valid_600094 = validateParameter(valid_600094, JString, required = true,
                                 default = nil)
  if valid_600094 != nil:
    section.add "meshName", valid_600094
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualServices</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of results returned by <code>ListVirtualServices</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualServices</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualServices</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualServices</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_600095 = query.getOrDefault("nextToken")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "nextToken", valid_600095
  var valid_600096 = query.getOrDefault("limit")
  valid_600096 = validateParameter(valid_600096, JInt, required = false, default = nil)
  if valid_600096 != nil:
    section.add "limit", valid_600096
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
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Content-Sha256", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Algorithm")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Algorithm", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Signature")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Signature", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-SignedHeaders", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Credential")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Credential", valid_600103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600104: Call_ListVirtualServices_600091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual services in a service mesh.
  ## 
  let valid = call_600104.validator(path, query, header, formData, body)
  let scheme = call_600104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600104.url(scheme.get, call_600104.host, call_600104.base,
                         call_600104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600104, url, valid)

proc call*(call_600105: Call_ListVirtualServices_600091; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualServices
  ## Returns a list of existing virtual services in a service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual services in.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListVirtualServices</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of results returned by <code>ListVirtualServices</code> in paginated
  ##          output. When you use this parameter, <code>ListVirtualServices</code> returns only
  ##             <code>limit</code> results in a single page along with a <code>nextToken</code> response
  ##          element. You can see the remaining results of the initial request by sending another
  ##             <code>ListVirtualServices</code> request with the returned <code>nextToken</code> value.
  ##          This value can be between 1 and 100. If you don't use this
  ##          parameter, <code>ListVirtualServices</code> returns up to 100 results and
  ##          a <code>nextToken</code> value if applicable.
  var path_600106 = newJObject()
  var query_600107 = newJObject()
  add(path_600106, "meshName", newJString(meshName))
  add(query_600107, "nextToken", newJString(nextToken))
  add(query_600107, "limit", newJInt(limit))
  result = call_600105.call(path_600106, query_600107, nil, nil, nil)

var listVirtualServices* = Call_ListVirtualServices_600091(
    name: "listVirtualServices", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_ListVirtualServices_600092, base: "/",
    url: url_ListVirtualServices_600093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMesh_600138 = ref object of OpenApiRestCall_599368
proc url_UpdateMesh_600140(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMesh_600139(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600141 = path.getOrDefault("meshName")
  valid_600141 = validateParameter(valid_600141, JString, required = true,
                                 default = nil)
  if valid_600141 != nil:
    section.add "meshName", valid_600141
  result.add "path", section
  section = newJObject()
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
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Content-Sha256", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Algorithm")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Algorithm", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Signature")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Signature", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-SignedHeaders", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Credential")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Credential", valid_600148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600150: Call_UpdateMesh_600138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing service mesh.
  ## 
  let valid = call_600150.validator(path, query, header, formData, body)
  let scheme = call_600150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600150.url(scheme.get, call_600150.host, call_600150.base,
                         call_600150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600150, url, valid)

proc call*(call_600151: Call_UpdateMesh_600138; meshName: string; body: JsonNode): Recallable =
  ## updateMesh
  ## Updates an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to update.
  ##   body: JObject (required)
  var path_600152 = newJObject()
  var body_600153 = newJObject()
  add(path_600152, "meshName", newJString(meshName))
  if body != nil:
    body_600153 = body
  result = call_600151.call(path_600152, nil, nil, nil, body_600153)

var updateMesh* = Call_UpdateMesh_600138(name: "updateMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_UpdateMesh_600139,
                                      base: "/", url: url_UpdateMesh_600140,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_600124 = ref object of OpenApiRestCall_599368
proc url_DescribeMesh_600126(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeMesh_600125(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600127 = path.getOrDefault("meshName")
  valid_600127 = validateParameter(valid_600127, JString, required = true,
                                 default = nil)
  if valid_600127 != nil:
    section.add "meshName", valid_600127
  result.add "path", section
  section = newJObject()
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
  var valid_600128 = header.getOrDefault("X-Amz-Date")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Date", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Security-Token")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Security-Token", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600135: Call_DescribeMesh_600124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing service mesh.
  ## 
  let valid = call_600135.validator(path, query, header, formData, body)
  let scheme = call_600135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600135.url(scheme.get, call_600135.host, call_600135.base,
                         call_600135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600135, url, valid)

proc call*(call_600136: Call_DescribeMesh_600124; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to describe.
  var path_600137 = newJObject()
  add(path_600137, "meshName", newJString(meshName))
  result = call_600136.call(path_600137, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_600124(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}", validator: validate_DescribeMesh_600125,
    base: "/", url: url_DescribeMesh_600126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_600154 = ref object of OpenApiRestCall_599368
proc url_DeleteMesh_600156(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMesh_600155(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600157 = path.getOrDefault("meshName")
  valid_600157 = validateParameter(valid_600157, JString, required = true,
                                 default = nil)
  if valid_600157 != nil:
    section.add "meshName", valid_600157
  result.add "path", section
  section = newJObject()
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
  var valid_600158 = header.getOrDefault("X-Amz-Date")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Date", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Security-Token")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Security-Token", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600165: Call_DeleteMesh_600154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ## 
  let valid = call_600165.validator(path, query, header, formData, body)
  let scheme = call_600165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600165.url(scheme.get, call_600165.host, call_600165.base,
                         call_600165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600165, url, valid)

proc call*(call_600166: Call_DeleteMesh_600154; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete.
  var path_600167 = newJObject()
  add(path_600167, "meshName", newJString(meshName))
  result = call_600166.call(path_600167, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_600154(name: "deleteMesh",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_DeleteMesh_600155,
                                      base: "/", url: url_DeleteMesh_600156,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_600184 = ref object of OpenApiRestCall_599368
proc url_UpdateRoute_600186(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRoute_600185(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router that the route is associated with.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the route resides in.
  ##   routeName: JString (required)
  ##            : The name of the route to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_600187 = path.getOrDefault("virtualRouterName")
  valid_600187 = validateParameter(valid_600187, JString, required = true,
                                 default = nil)
  if valid_600187 != nil:
    section.add "virtualRouterName", valid_600187
  var valid_600188 = path.getOrDefault("meshName")
  valid_600188 = validateParameter(valid_600188, JString, required = true,
                                 default = nil)
  if valid_600188 != nil:
    section.add "meshName", valid_600188
  var valid_600189 = path.getOrDefault("routeName")
  valid_600189 = validateParameter(valid_600189, JString, required = true,
                                 default = nil)
  if valid_600189 != nil:
    section.add "routeName", valid_600189
  result.add "path", section
  section = newJObject()
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
  var valid_600190 = header.getOrDefault("X-Amz-Date")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Date", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Security-Token")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Security-Token", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Content-Sha256", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Algorithm")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Algorithm", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Signature")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Signature", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-SignedHeaders", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Credential")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Credential", valid_600196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600198: Call_UpdateRoute_600184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  let valid = call_600198.validator(path, query, header, formData, body)
  let scheme = call_600198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600198.url(scheme.get, call_600198.host, call_600198.base,
                         call_600198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600198, url, valid)

proc call*(call_600199: Call_UpdateRoute_600184; virtualRouterName: string;
          meshName: string; routeName: string; body: JsonNode): Recallable =
  ## updateRoute
  ## Updates an existing route for a specified service mesh and virtual router.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router that the route is associated with.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the route resides in.
  ##   routeName: string (required)
  ##            : The name of the route to update.
  ##   body: JObject (required)
  var path_600200 = newJObject()
  var body_600201 = newJObject()
  add(path_600200, "virtualRouterName", newJString(virtualRouterName))
  add(path_600200, "meshName", newJString(meshName))
  add(path_600200, "routeName", newJString(routeName))
  if body != nil:
    body_600201 = body
  result = call_600199.call(path_600200, nil, nil, nil, body_600201)

var updateRoute* = Call_UpdateRoute_600184(name: "updateRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_UpdateRoute_600185,
                                        base: "/", url: url_UpdateRoute_600186,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_600168 = ref object of OpenApiRestCall_599368
proc url_DescribeRoute_600170(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRoute_600169(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router that the route is associated with.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the route resides in.
  ##   routeName: JString (required)
  ##            : The name of the route to describe.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_600171 = path.getOrDefault("virtualRouterName")
  valid_600171 = validateParameter(valid_600171, JString, required = true,
                                 default = nil)
  if valid_600171 != nil:
    section.add "virtualRouterName", valid_600171
  var valid_600172 = path.getOrDefault("meshName")
  valid_600172 = validateParameter(valid_600172, JString, required = true,
                                 default = nil)
  if valid_600172 != nil:
    section.add "meshName", valid_600172
  var valid_600173 = path.getOrDefault("routeName")
  valid_600173 = validateParameter(valid_600173, JString, required = true,
                                 default = nil)
  if valid_600173 != nil:
    section.add "routeName", valid_600173
  result.add "path", section
  section = newJObject()
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
  var valid_600174 = header.getOrDefault("X-Amz-Date")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Date", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Security-Token")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Security-Token", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Content-Sha256", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Algorithm")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Algorithm", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Signature")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Signature", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-SignedHeaders", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-Credential")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Credential", valid_600180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_DescribeRoute_600168; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing route.
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_DescribeRoute_600168; virtualRouterName: string;
          meshName: string; routeName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router that the route is associated with.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the route resides in.
  ##   routeName: string (required)
  ##            : The name of the route to describe.
  var path_600183 = newJObject()
  add(path_600183, "virtualRouterName", newJString(virtualRouterName))
  add(path_600183, "meshName", newJString(meshName))
  add(path_600183, "routeName", newJString(routeName))
  result = call_600182.call(path_600183, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_600168(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_600169, base: "/", url: url_DescribeRoute_600170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_600202 = ref object of OpenApiRestCall_599368
proc url_DeleteRoute_600204(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  assert "routeName" in path, "`routeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouter/"),
               (kind: VariableSegment, value: "virtualRouterName"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRoute_600203(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete the route in.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the route in.
  ##   routeName: JString (required)
  ##            : The name of the route to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_600205 = path.getOrDefault("virtualRouterName")
  valid_600205 = validateParameter(valid_600205, JString, required = true,
                                 default = nil)
  if valid_600205 != nil:
    section.add "virtualRouterName", valid_600205
  var valid_600206 = path.getOrDefault("meshName")
  valid_600206 = validateParameter(valid_600206, JString, required = true,
                                 default = nil)
  if valid_600206 != nil:
    section.add "meshName", valid_600206
  var valid_600207 = path.getOrDefault("routeName")
  valid_600207 = validateParameter(valid_600207, JString, required = true,
                                 default = nil)
  if valid_600207 != nil:
    section.add "routeName", valid_600207
  result.add "path", section
  section = newJObject()
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
  var valid_600208 = header.getOrDefault("X-Amz-Date")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Date", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Security-Token")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Security-Token", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Content-Sha256", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Algorithm")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Algorithm", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Signature")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Signature", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-SignedHeaders", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Credential")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Credential", valid_600214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600215: Call_DeleteRoute_600202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing route.
  ## 
  let valid = call_600215.validator(path, query, header, formData, body)
  let scheme = call_600215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600215.url(scheme.get, call_600215.host, call_600215.base,
                         call_600215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600215, url, valid)

proc call*(call_600216: Call_DeleteRoute_600202; virtualRouterName: string;
          meshName: string; routeName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete the route in.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the route in.
  ##   routeName: string (required)
  ##            : The name of the route to delete.
  var path_600217 = newJObject()
  add(path_600217, "virtualRouterName", newJString(virtualRouterName))
  add(path_600217, "meshName", newJString(meshName))
  add(path_600217, "routeName", newJString(routeName))
  result = call_600216.call(path_600217, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_600202(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_DeleteRoute_600203,
                                        base: "/", url: url_DeleteRoute_600204,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_600233 = ref object of OpenApiRestCall_599368
proc url_UpdateVirtualNode_600235(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVirtualNode_600234(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600236 = path.getOrDefault("meshName")
  valid_600236 = validateParameter(valid_600236, JString, required = true,
                                 default = nil)
  if valid_600236 != nil:
    section.add "meshName", valid_600236
  var valid_600237 = path.getOrDefault("virtualNodeName")
  valid_600237 = validateParameter(valid_600237, JString, required = true,
                                 default = nil)
  if valid_600237 != nil:
    section.add "virtualNodeName", valid_600237
  result.add "path", section
  section = newJObject()
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
  var valid_600238 = header.getOrDefault("X-Amz-Date")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Date", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Security-Token")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Security-Token", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Content-Sha256", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Algorithm")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Algorithm", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Signature")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Signature", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-SignedHeaders", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-Credential")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Credential", valid_600244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600246: Call_UpdateVirtualNode_600233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  let valid = call_600246.validator(path, query, header, formData, body)
  let scheme = call_600246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600246.url(scheme.get, call_600246.host, call_600246.base,
                         call_600246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600246, url, valid)

proc call*(call_600247: Call_UpdateVirtualNode_600233; meshName: string;
          virtualNodeName: string; body: JsonNode): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to update.
  ##   body: JObject (required)
  var path_600248 = newJObject()
  var body_600249 = newJObject()
  add(path_600248, "meshName", newJString(meshName))
  add(path_600248, "virtualNodeName", newJString(virtualNodeName))
  if body != nil:
    body_600249 = body
  result = call_600247.call(path_600248, nil, nil, nil, body_600249)

var updateVirtualNode* = Call_UpdateVirtualNode_600233(name: "updateVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_600234, base: "/",
    url: url_UpdateVirtualNode_600235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_600218 = ref object of OpenApiRestCall_599368
proc url_DescribeVirtualNode_600220(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeVirtualNode_600219(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes an existing virtual node.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600221 = path.getOrDefault("meshName")
  valid_600221 = validateParameter(valid_600221, JString, required = true,
                                 default = nil)
  if valid_600221 != nil:
    section.add "meshName", valid_600221
  var valid_600222 = path.getOrDefault("virtualNodeName")
  valid_600222 = validateParameter(valid_600222, JString, required = true,
                                 default = nil)
  if valid_600222 != nil:
    section.add "virtualNodeName", valid_600222
  result.add "path", section
  section = newJObject()
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
  var valid_600223 = header.getOrDefault("X-Amz-Date")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Date", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Security-Token")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Security-Token", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Content-Sha256", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Algorithm")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Algorithm", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Signature")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Signature", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-SignedHeaders", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Credential")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Credential", valid_600229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600230: Call_DescribeVirtualNode_600218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual node.
  ## 
  let valid = call_600230.validator(path, query, header, formData, body)
  let scheme = call_600230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600230.url(scheme.get, call_600230.host, call_600230.base,
                         call_600230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600230, url, valid)

proc call*(call_600231: Call_DescribeVirtualNode_600218; meshName: string;
          virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to describe.
  var path_600232 = newJObject()
  add(path_600232, "meshName", newJString(meshName))
  add(path_600232, "virtualNodeName", newJString(virtualNodeName))
  result = call_600231.call(path_600232, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_600218(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_600219, base: "/",
    url: url_DescribeVirtualNode_600220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_600250 = ref object of OpenApiRestCall_599368
proc url_DeleteVirtualNode_600252(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualNodeName" in path, "`virtualNodeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualNodes/"),
               (kind: VariableSegment, value: "virtualNodeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVirtualNode_600251(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual node in.
  ##   virtualNodeName: JString (required)
  ##                  : The name of the virtual node to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600253 = path.getOrDefault("meshName")
  valid_600253 = validateParameter(valid_600253, JString, required = true,
                                 default = nil)
  if valid_600253 != nil:
    section.add "meshName", valid_600253
  var valid_600254 = path.getOrDefault("virtualNodeName")
  valid_600254 = validateParameter(valid_600254, JString, required = true,
                                 default = nil)
  if valid_600254 != nil:
    section.add "virtualNodeName", valid_600254
  result.add "path", section
  section = newJObject()
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
  var valid_600255 = header.getOrDefault("X-Amz-Date")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Date", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-Security-Token")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-Security-Token", valid_600256
  var valid_600257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Content-Sha256", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Algorithm")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Algorithm", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Signature")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Signature", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-SignedHeaders", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Credential")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Credential", valid_600261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600262: Call_DeleteVirtualNode_600250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ## 
  let valid = call_600262.validator(path, query, header, formData, body)
  let scheme = call_600262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600262.url(scheme.get, call_600262.host, call_600262.base,
                         call_600262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600262, url, valid)

proc call*(call_600263: Call_DeleteVirtualNode_600250; meshName: string;
          virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual node in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to delete.
  var path_600264 = newJObject()
  add(path_600264, "meshName", newJString(meshName))
  add(path_600264, "virtualNodeName", newJString(virtualNodeName))
  result = call_600263.call(path_600264, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_600250(name: "deleteVirtualNode",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_600251, base: "/",
    url: url_DeleteVirtualNode_600252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_600280 = ref object of OpenApiRestCall_599368
proc url_UpdateVirtualRouter_600282(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVirtualRouter_600281(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to update.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual router resides in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_600283 = path.getOrDefault("virtualRouterName")
  valid_600283 = validateParameter(valid_600283, JString, required = true,
                                 default = nil)
  if valid_600283 != nil:
    section.add "virtualRouterName", valid_600283
  var valid_600284 = path.getOrDefault("meshName")
  valid_600284 = validateParameter(valid_600284, JString, required = true,
                                 default = nil)
  if valid_600284 != nil:
    section.add "meshName", valid_600284
  result.add "path", section
  section = newJObject()
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
  var valid_600285 = header.getOrDefault("X-Amz-Date")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-Date", valid_600285
  var valid_600286 = header.getOrDefault("X-Amz-Security-Token")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "X-Amz-Security-Token", valid_600286
  var valid_600287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "X-Amz-Content-Sha256", valid_600287
  var valid_600288 = header.getOrDefault("X-Amz-Algorithm")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Algorithm", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-Signature")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Signature", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-SignedHeaders", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Credential")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Credential", valid_600291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600293: Call_UpdateVirtualRouter_600280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  let valid = call_600293.validator(path, query, header, formData, body)
  let scheme = call_600293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600293.url(scheme.get, call_600293.host, call_600293.base,
                         call_600293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600293, url, valid)

proc call*(call_600294: Call_UpdateVirtualRouter_600280; virtualRouterName: string;
          meshName: string; body: JsonNode): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   body: JObject (required)
  var path_600295 = newJObject()
  var body_600296 = newJObject()
  add(path_600295, "virtualRouterName", newJString(virtualRouterName))
  add(path_600295, "meshName", newJString(meshName))
  if body != nil:
    body_600296 = body
  result = call_600294.call(path_600295, nil, nil, nil, body_600296)

var updateVirtualRouter* = Call_UpdateVirtualRouter_600280(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_600281, base: "/",
    url: url_UpdateVirtualRouter_600282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_600265 = ref object of OpenApiRestCall_599368
proc url_DescribeVirtualRouter_600267(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeVirtualRouter_600266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual router resides in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_600268 = path.getOrDefault("virtualRouterName")
  valid_600268 = validateParameter(valid_600268, JString, required = true,
                                 default = nil)
  if valid_600268 != nil:
    section.add "virtualRouterName", valid_600268
  var valid_600269 = path.getOrDefault("meshName")
  valid_600269 = validateParameter(valid_600269, JString, required = true,
                                 default = nil)
  if valid_600269 != nil:
    section.add "meshName", valid_600269
  result.add "path", section
  section = newJObject()
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
  var valid_600270 = header.getOrDefault("X-Amz-Date")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-Date", valid_600270
  var valid_600271 = header.getOrDefault("X-Amz-Security-Token")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "X-Amz-Security-Token", valid_600271
  var valid_600272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Content-Sha256", valid_600272
  var valid_600273 = header.getOrDefault("X-Amz-Algorithm")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Algorithm", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Signature")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Signature", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-SignedHeaders", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Credential")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Credential", valid_600276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600277: Call_DescribeVirtualRouter_600265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual router.
  ## 
  let valid = call_600277.validator(path, query, header, formData, body)
  let scheme = call_600277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600277.url(scheme.get, call_600277.host, call_600277.base,
                         call_600277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600277, url, valid)

proc call*(call_600278: Call_DescribeVirtualRouter_600265;
          virtualRouterName: string; meshName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  var path_600279 = newJObject()
  add(path_600279, "virtualRouterName", newJString(virtualRouterName))
  add(path_600279, "meshName", newJString(meshName))
  result = call_600278.call(path_600279, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_600265(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_600266, base: "/",
    url: url_DescribeVirtualRouter_600267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_600297 = ref object of OpenApiRestCall_599368
proc url_DeleteVirtualRouter_600299(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualRouterName" in path,
        "`virtualRouterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualRouters/"),
               (kind: VariableSegment, value: "virtualRouterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVirtualRouter_600298(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual router in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualRouterName` field"
  var valid_600300 = path.getOrDefault("virtualRouterName")
  valid_600300 = validateParameter(valid_600300, JString, required = true,
                                 default = nil)
  if valid_600300 != nil:
    section.add "virtualRouterName", valid_600300
  var valid_600301 = path.getOrDefault("meshName")
  valid_600301 = validateParameter(valid_600301, JString, required = true,
                                 default = nil)
  if valid_600301 != nil:
    section.add "meshName", valid_600301
  result.add "path", section
  section = newJObject()
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
  var valid_600302 = header.getOrDefault("X-Amz-Date")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Date", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-Security-Token")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Security-Token", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-Content-Sha256", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Algorithm")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Algorithm", valid_600305
  var valid_600306 = header.getOrDefault("X-Amz-Signature")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-Signature", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-SignedHeaders", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Credential")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Credential", valid_600308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600309: Call_DeleteVirtualRouter_600297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  let valid = call_600309.validator(path, query, header, formData, body)
  let scheme = call_600309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600309.url(scheme.get, call_600309.host, call_600309.base,
                         call_600309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600309, url, valid)

proc call*(call_600310: Call_DeleteVirtualRouter_600297; virtualRouterName: string;
          meshName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual router in.
  var path_600311 = newJObject()
  add(path_600311, "virtualRouterName", newJString(virtualRouterName))
  add(path_600311, "meshName", newJString(meshName))
  result = call_600310.call(path_600311, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_600297(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_600298, base: "/",
    url: url_DeleteVirtualRouter_600299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualService_600327 = ref object of OpenApiRestCall_599368
proc url_UpdateVirtualService_600329(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualServiceName" in path,
        "`virtualServiceName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices/"),
               (kind: VariableSegment, value: "virtualServiceName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateVirtualService_600328(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing virtual service in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600330 = path.getOrDefault("meshName")
  valid_600330 = validateParameter(valid_600330, JString, required = true,
                                 default = nil)
  if valid_600330 != nil:
    section.add "meshName", valid_600330
  var valid_600331 = path.getOrDefault("virtualServiceName")
  valid_600331 = validateParameter(valid_600331, JString, required = true,
                                 default = nil)
  if valid_600331 != nil:
    section.add "virtualServiceName", valid_600331
  result.add "path", section
  section = newJObject()
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
  var valid_600332 = header.getOrDefault("X-Amz-Date")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-Date", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Security-Token")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Security-Token", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Content-Sha256", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Algorithm")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Algorithm", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Signature")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Signature", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-SignedHeaders", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Credential")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Credential", valid_600338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600340: Call_UpdateVirtualService_600327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual service in a specified service mesh.
  ## 
  let valid = call_600340.validator(path, query, header, formData, body)
  let scheme = call_600340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600340.url(scheme.get, call_600340.host, call_600340.base,
                         call_600340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600340, url, valid)

proc call*(call_600341: Call_UpdateVirtualService_600327; meshName: string;
          body: JsonNode; virtualServiceName: string): Recallable =
  ## updateVirtualService
  ## Updates an existing virtual service in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   body: JObject (required)
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to update.
  var path_600342 = newJObject()
  var body_600343 = newJObject()
  add(path_600342, "meshName", newJString(meshName))
  if body != nil:
    body_600343 = body
  add(path_600342, "virtualServiceName", newJString(virtualServiceName))
  result = call_600341.call(path_600342, nil, nil, nil, body_600343)

var updateVirtualService* = Call_UpdateVirtualService_600327(
    name: "updateVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_UpdateVirtualService_600328, base: "/",
    url: url_UpdateVirtualService_600329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualService_600312 = ref object of OpenApiRestCall_599368
proc url_DescribeVirtualService_600314(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualServiceName" in path,
        "`virtualServiceName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices/"),
               (kind: VariableSegment, value: "virtualServiceName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeVirtualService_600313(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual service.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600315 = path.getOrDefault("meshName")
  valid_600315 = validateParameter(valid_600315, JString, required = true,
                                 default = nil)
  if valid_600315 != nil:
    section.add "meshName", valid_600315
  var valid_600316 = path.getOrDefault("virtualServiceName")
  valid_600316 = validateParameter(valid_600316, JString, required = true,
                                 default = nil)
  if valid_600316 != nil:
    section.add "virtualServiceName", valid_600316
  result.add "path", section
  section = newJObject()
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
  var valid_600317 = header.getOrDefault("X-Amz-Date")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Date", valid_600317
  var valid_600318 = header.getOrDefault("X-Amz-Security-Token")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-Security-Token", valid_600318
  var valid_600319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Content-Sha256", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-Algorithm")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-Algorithm", valid_600320
  var valid_600321 = header.getOrDefault("X-Amz-Signature")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-Signature", valid_600321
  var valid_600322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-SignedHeaders", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Credential")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Credential", valid_600323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600324: Call_DescribeVirtualService_600312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual service.
  ## 
  let valid = call_600324.validator(path, query, header, formData, body)
  let scheme = call_600324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600324.url(scheme.get, call_600324.host, call_600324.base,
                         call_600324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600324, url, valid)

proc call*(call_600325: Call_DescribeVirtualService_600312; meshName: string;
          virtualServiceName: string): Recallable =
  ## describeVirtualService
  ## Describes an existing virtual service.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to describe.
  var path_600326 = newJObject()
  add(path_600326, "meshName", newJString(meshName))
  add(path_600326, "virtualServiceName", newJString(virtualServiceName))
  result = call_600325.call(path_600326, nil, nil, nil, nil)

var describeVirtualService* = Call_DescribeVirtualService_600312(
    name: "describeVirtualService", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DescribeVirtualService_600313, base: "/",
    url: url_DescribeVirtualService_600314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualService_600344 = ref object of OpenApiRestCall_599368
proc url_DeleteVirtualService_600346(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "meshName" in path, "`meshName` is a required path parameter"
  assert "virtualServiceName" in path,
        "`virtualServiceName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20190125/meshes/"),
               (kind: VariableSegment, value: "meshName"),
               (kind: ConstantSegment, value: "/virtualServices/"),
               (kind: VariableSegment, value: "virtualServiceName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVirtualService_600345(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing virtual service.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual service in.
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_600347 = path.getOrDefault("meshName")
  valid_600347 = validateParameter(valid_600347, JString, required = true,
                                 default = nil)
  if valid_600347 != nil:
    section.add "meshName", valid_600347
  var valid_600348 = path.getOrDefault("virtualServiceName")
  valid_600348 = validateParameter(valid_600348, JString, required = true,
                                 default = nil)
  if valid_600348 != nil:
    section.add "virtualServiceName", valid_600348
  result.add "path", section
  section = newJObject()
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
  var valid_600349 = header.getOrDefault("X-Amz-Date")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Date", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Security-Token")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Security-Token", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Content-Sha256", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Algorithm")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Algorithm", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Signature")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Signature", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-SignedHeaders", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Credential")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Credential", valid_600355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600356: Call_DeleteVirtualService_600344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing virtual service.
  ## 
  let valid = call_600356.validator(path, query, header, formData, body)
  let scheme = call_600356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600356.url(scheme.get, call_600356.host, call_600356.base,
                         call_600356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600356, url, valid)

proc call*(call_600357: Call_DeleteVirtualService_600344; meshName: string;
          virtualServiceName: string): Recallable =
  ## deleteVirtualService
  ## Deletes an existing virtual service.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual service in.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to delete.
  var path_600358 = newJObject()
  add(path_600358, "meshName", newJString(meshName))
  add(path_600358, "virtualServiceName", newJString(virtualServiceName))
  result = call_600357.call(path_600358, nil, nil, nil, nil)

var deleteVirtualService* = Call_DeleteVirtualService_600344(
    name: "deleteVirtualService", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DeleteVirtualService_600345, base: "/",
    url: url_DeleteVirtualService_600346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600359 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600361(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600360(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List the tags for an App Mesh resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource to list the tags for.
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListTagsForResource</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: JInt
  ##        : The maximum number of tag results returned by <code>ListTagsForResource</code> in
  ##          paginated output. When this parameter is used, <code>ListTagsForResource</code> returns
  ##          only <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. You can see the remaining results of the initial request by sending
  ##          another <code>ListTagsForResource</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If you don't use
  ##          this parameter, <code>ListTagsForResource</code> returns up to 100
  ##          results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_600362 = query.getOrDefault("resourceArn")
  valid_600362 = validateParameter(valid_600362, JString, required = true,
                                 default = nil)
  if valid_600362 != nil:
    section.add "resourceArn", valid_600362
  var valid_600363 = query.getOrDefault("nextToken")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "nextToken", valid_600363
  var valid_600364 = query.getOrDefault("limit")
  valid_600364 = validateParameter(valid_600364, JInt, required = false, default = nil)
  if valid_600364 != nil:
    section.add "limit", valid_600364
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
  var valid_600365 = header.getOrDefault("X-Amz-Date")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Date", valid_600365
  var valid_600366 = header.getOrDefault("X-Amz-Security-Token")
  valid_600366 = validateParameter(valid_600366, JString, required = false,
                                 default = nil)
  if valid_600366 != nil:
    section.add "X-Amz-Security-Token", valid_600366
  var valid_600367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Content-Sha256", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Algorithm")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Algorithm", valid_600368
  var valid_600369 = header.getOrDefault("X-Amz-Signature")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Signature", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-SignedHeaders", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Credential")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Credential", valid_600371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600372: Call_ListTagsForResource_600359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an App Mesh resource.
  ## 
  let valid = call_600372.validator(path, query, header, formData, body)
  let scheme = call_600372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600372.url(scheme.get, call_600372.host, call_600372.base,
                         call_600372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600372, url, valid)

proc call*(call_600373: Call_ListTagsForResource_600359; resourceArn: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listTagsForResource
  ## List the tags for an App Mesh resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource to list the tags for.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated
  ##             <code>ListTagsForResource</code> request where <code>limit</code> was used and the
  ##          results exceeded the value of that parameter. Pagination continues from the end of the
  ##          previous results that returned the <code>nextToken</code> value.
  ##   limit: int
  ##        : The maximum number of tag results returned by <code>ListTagsForResource</code> in
  ##          paginated output. When this parameter is used, <code>ListTagsForResource</code> returns
  ##          only <code>limit</code> results in a single page along with a <code>nextToken</code>
  ##          response element. You can see the remaining results of the initial request by sending
  ##          another <code>ListTagsForResource</code> request with the returned <code>nextToken</code>
  ##          value. This value can be between 1 and 100. If you don't use
  ##          this parameter, <code>ListTagsForResource</code> returns up to 100
  ##          results and a <code>nextToken</code> value if applicable.
  var query_600374 = newJObject()
  add(query_600374, "resourceArn", newJString(resourceArn))
  add(query_600374, "nextToken", newJString(nextToken))
  add(query_600374, "limit", newJInt(limit))
  result = call_600373.call(nil, query_600374, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600359(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/v20190125/tags#resourceArn",
    validator: validate_ListTagsForResource_600360, base: "/",
    url: url_ListTagsForResource_600361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600375 = ref object of OpenApiRestCall_599368
proc url_TagResource_600377(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600376(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource to add tags to.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_600378 = query.getOrDefault("resourceArn")
  valid_600378 = validateParameter(valid_600378, JString, required = true,
                                 default = nil)
  if valid_600378 != nil:
    section.add "resourceArn", valid_600378
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
  var valid_600379 = header.getOrDefault("X-Amz-Date")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "X-Amz-Date", valid_600379
  var valid_600380 = header.getOrDefault("X-Amz-Security-Token")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-Security-Token", valid_600380
  var valid_600381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-Content-Sha256", valid_600381
  var valid_600382 = header.getOrDefault("X-Amz-Algorithm")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Algorithm", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Signature")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Signature", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-SignedHeaders", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Credential")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Credential", valid_600385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600387: Call_TagResource_600375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ## 
  let valid = call_600387.validator(path, query, header, formData, body)
  let scheme = call_600387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600387.url(scheme.get, call_600387.host, call_600387.base,
                         call_600387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600387, url, valid)

proc call*(call_600388: Call_TagResource_600375; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to add tags to.
  ##   body: JObject (required)
  var query_600389 = newJObject()
  var body_600390 = newJObject()
  add(query_600389, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_600390 = body
  result = call_600388.call(nil, query_600389, nil, nil, body_600390)

var tagResource* = Call_TagResource_600375(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com",
                                        route: "/v20190125/tag#resourceArn",
                                        validator: validate_TagResource_600376,
                                        base: "/", url: url_TagResource_600377,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600391 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600393(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600392(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes specified tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource to delete tags from.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_600394 = query.getOrDefault("resourceArn")
  valid_600394 = validateParameter(valid_600394, JString, required = true,
                                 default = nil)
  if valid_600394 != nil:
    section.add "resourceArn", valid_600394
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
  var valid_600395 = header.getOrDefault("X-Amz-Date")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Date", valid_600395
  var valid_600396 = header.getOrDefault("X-Amz-Security-Token")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-Security-Token", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Content-Sha256", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Algorithm")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Algorithm", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-Signature")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Signature", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-SignedHeaders", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Credential")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Credential", valid_600401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600403: Call_UntagResource_600391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_600403.validator(path, query, header, formData, body)
  let scheme = call_600403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600403.url(scheme.get, call_600403.host, call_600403.base,
                         call_600403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600403, url, valid)

proc call*(call_600404: Call_UntagResource_600391; resourceArn: string;
          body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to delete tags from.
  ##   body: JObject (required)
  var query_600405 = newJObject()
  var body_600406 = newJObject()
  add(query_600405, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_600406 = body
  result = call_600404.call(nil, query_600405, nil, nil, body_600406)

var untagResource* = Call_UntagResource_600391(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/untag#resourceArn", validator: validate_UntagResource_600392,
    base: "/", url: url_UntagResource_600393, schemes: {Scheme.Https, Scheme.Http})
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
