
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
  Call_CreateMesh_601984 = ref object of OpenApiRestCall_601389
proc url_CreateMesh_601986(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateMesh_601985(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601987 = header.getOrDefault("X-Amz-Signature")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Signature", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Content-Sha256", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Date")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Date", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Credential")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Credential", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Security-Token")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Security-Token", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Algorithm")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Algorithm", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-SignedHeaders", valid_601993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601995: Call_CreateMesh_601984; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ## 
  let valid = call_601995.validator(path, query, header, formData, body)
  let scheme = call_601995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601995.url(scheme.get, call_601995.host, call_601995.base,
                         call_601995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601995, url, valid)

proc call*(call_601996: Call_CreateMesh_601984; body: JsonNode): Recallable =
  ## createMesh
  ## <p>Creates a service mesh. A service mesh is a logical boundary for network traffic between
  ##          the services that reside within it.</p>
  ##          <p>After you create your service mesh, you can create virtual services, virtual nodes,
  ##          virtual routers, and routes to distribute traffic between the applications in your
  ##          mesh.</p>
  ##   body: JObject (required)
  var body_601997 = newJObject()
  if body != nil:
    body_601997 = body
  result = call_601996.call(nil, nil, nil, nil, body_601997)

var createMesh* = Call_CreateMesh_601984(name: "createMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
                                      validator: validate_CreateMesh_601985,
                                      base: "/", url: url_CreateMesh_601986,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMeshes_601727 = ref object of OpenApiRestCall_601389
proc url_ListMeshes_601729(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListMeshes_601728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601841 = query.getOrDefault("nextToken")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "nextToken", valid_601841
  var valid_601842 = query.getOrDefault("limit")
  valid_601842 = validateParameter(valid_601842, JInt, required = false, default = nil)
  if valid_601842 != nil:
    section.add "limit", valid_601842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601843 = header.getOrDefault("X-Amz-Signature")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Signature", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Content-Sha256", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Date")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Date", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Credential")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Credential", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Security-Token")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Security-Token", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Algorithm")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Algorithm", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-SignedHeaders", valid_601849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601872: Call_ListMeshes_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing service meshes.
  ## 
  let valid = call_601872.validator(path, query, header, formData, body)
  let scheme = call_601872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601872.url(scheme.get, call_601872.host, call_601872.base,
                         call_601872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601872, url, valid)

proc call*(call_601943: Call_ListMeshes_601727; nextToken: string = ""; limit: int = 0): Recallable =
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
  var query_601944 = newJObject()
  add(query_601944, "nextToken", newJString(nextToken))
  add(query_601944, "limit", newJInt(limit))
  result = call_601943.call(nil, query_601944, nil, nil, nil)

var listMeshes* = Call_ListMeshes_601727(name: "listMeshes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes",
                                      validator: validate_ListMeshes_601728,
                                      base: "/", url: url_ListMeshes_601729,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_602030 = ref object of OpenApiRestCall_601389
proc url_CreateRoute_602032(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoute_602031(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   meshName: JString (required)
  ##           : The name of the service mesh to create the route in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router in which to create the route.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_602033 = path.getOrDefault("meshName")
  valid_602033 = validateParameter(valid_602033, JString, required = true,
                                 default = nil)
  if valid_602033 != nil:
    section.add "meshName", valid_602033
  var valid_602034 = path.getOrDefault("virtualRouterName")
  valid_602034 = validateParameter(valid_602034, JString, required = true,
                                 default = nil)
  if valid_602034 != nil:
    section.add "virtualRouterName", valid_602034
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602035 = header.getOrDefault("X-Amz-Signature")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Signature", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Content-Sha256", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Date")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Date", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Credential")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Credential", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Security-Token")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Security-Token", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Algorithm")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Algorithm", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-SignedHeaders", valid_602041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602043: Call_CreateRoute_602030; path: JsonNode; query: JsonNode;
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
  let valid = call_602043.validator(path, query, header, formData, body)
  let scheme = call_602043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602043.url(scheme.get, call_602043.host, call_602043.base,
                         call_602043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602043, url, valid)

proc call*(call_602044: Call_CreateRoute_602030; meshName: string; body: JsonNode;
          virtualRouterName: string): Recallable =
  ## createRoute
  ## <p>Creates a route that is associated with a virtual router.</p>
  ##          <p>You can use the <code>prefix</code> parameter in your route specification for path-based
  ##          routing of requests. For example, if your virtual service name is
  ##             <code>my-service.local</code> and you want the route to match requests to
  ##             <code>my-service.local/metrics</code>, your prefix should be
  ##          <code>/metrics</code>.</p>
  ##          <p>If your route matches a request, you can distribute traffic to one or more target
  ##          virtual nodes with relative weighting.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to create the route in.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router in which to create the route.
  var path_602045 = newJObject()
  var body_602046 = newJObject()
  add(path_602045, "meshName", newJString(meshName))
  if body != nil:
    body_602046 = body
  add(path_602045, "virtualRouterName", newJString(virtualRouterName))
  result = call_602044.call(path_602045, nil, nil, nil, body_602046)

var createRoute* = Call_CreateRoute_602030(name: "createRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                        validator: validate_CreateRoute_602031,
                                        base: "/", url: url_CreateRoute_602032,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutes_601998 = ref object of OpenApiRestCall_601389
proc url_ListRoutes_602000(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListRoutes_601999(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing routes in a service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to list routes in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to list routes in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_602015 = path.getOrDefault("meshName")
  valid_602015 = validateParameter(valid_602015, JString, required = true,
                                 default = nil)
  if valid_602015 != nil:
    section.add "meshName", valid_602015
  var valid_602016 = path.getOrDefault("virtualRouterName")
  valid_602016 = validateParameter(valid_602016, JString, required = true,
                                 default = nil)
  if valid_602016 != nil:
    section.add "virtualRouterName", valid_602016
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
  var valid_602017 = query.getOrDefault("nextToken")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "nextToken", valid_602017
  var valid_602018 = query.getOrDefault("limit")
  valid_602018 = validateParameter(valid_602018, JInt, required = false, default = nil)
  if valid_602018 != nil:
    section.add "limit", valid_602018
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602019 = header.getOrDefault("X-Amz-Signature")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Signature", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Content-Sha256", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Date")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Date", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Credential")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Credential", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Security-Token")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Security-Token", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Algorithm")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Algorithm", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-SignedHeaders", valid_602025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602026: Call_ListRoutes_601998; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing routes in a service mesh.
  ## 
  let valid = call_602026.validator(path, query, header, formData, body)
  let scheme = call_602026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602026.url(scheme.get, call_602026.host, call_602026.base,
                         call_602026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602026, url, valid)

proc call*(call_602027: Call_ListRoutes_601998; meshName: string;
          virtualRouterName: string; nextToken: string = ""; limit: int = 0): Recallable =
  ## listRoutes
  ## Returns a list of existing routes in a service mesh.
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
  ##   meshName: string (required)
  ##           : The name of the service mesh to list routes in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to list routes in.
  var path_602028 = newJObject()
  var query_602029 = newJObject()
  add(query_602029, "nextToken", newJString(nextToken))
  add(query_602029, "limit", newJInt(limit))
  add(path_602028, "meshName", newJString(meshName))
  add(path_602028, "virtualRouterName", newJString(virtualRouterName))
  result = call_602027.call(path_602028, query_602029, nil, nil, nil)

var listRoutes* = Call_ListRoutes_601998(name: "listRoutes",
                                      meth: HttpMethod.HttpGet,
                                      host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes",
                                      validator: validate_ListRoutes_601999,
                                      base: "/", url: url_ListRoutes_602000,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualNode_602064 = ref object of OpenApiRestCall_601389
proc url_CreateVirtualNode_602066(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVirtualNode_602065(path: JsonNode; query: JsonNode;
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
  var valid_602067 = path.getOrDefault("meshName")
  valid_602067 = validateParameter(valid_602067, JString, required = true,
                                 default = nil)
  if valid_602067 != nil:
    section.add "meshName", valid_602067
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602068 = header.getOrDefault("X-Amz-Signature")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Signature", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Content-Sha256", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Date")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Date", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Credential")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Credential", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Security-Token")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Security-Token", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Algorithm")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Algorithm", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-SignedHeaders", valid_602074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602076: Call_CreateVirtualNode_602064; path: JsonNode;
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
  let valid = call_602076.validator(path, query, header, formData, body)
  let scheme = call_602076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602076.url(scheme.get, call_602076.host, call_602076.base,
                         call_602076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602076, url, valid)

proc call*(call_602077: Call_CreateVirtualNode_602064; meshName: string;
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
  var path_602078 = newJObject()
  var body_602079 = newJObject()
  add(path_602078, "meshName", newJString(meshName))
  if body != nil:
    body_602079 = body
  result = call_602077.call(path_602078, nil, nil, nil, body_602079)

var createVirtualNode* = Call_CreateVirtualNode_602064(name: "createVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_CreateVirtualNode_602065, base: "/",
    url: url_CreateVirtualNode_602066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualNodes_602047 = ref object of OpenApiRestCall_601389
proc url_ListVirtualNodes_602049(protocol: Scheme; host: string; base: string;
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

proc validate_ListVirtualNodes_602048(path: JsonNode; query: JsonNode;
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
  var valid_602050 = path.getOrDefault("meshName")
  valid_602050 = validateParameter(valid_602050, JString, required = true,
                                 default = nil)
  if valid_602050 != nil:
    section.add "meshName", valid_602050
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
  var valid_602051 = query.getOrDefault("nextToken")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "nextToken", valid_602051
  var valid_602052 = query.getOrDefault("limit")
  valid_602052 = validateParameter(valid_602052, JInt, required = false, default = nil)
  if valid_602052 != nil:
    section.add "limit", valid_602052
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602053 = header.getOrDefault("X-Amz-Signature")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Signature", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Content-Sha256", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Date")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Date", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Credential")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Credential", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Security-Token")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Security-Token", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Algorithm")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Algorithm", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-SignedHeaders", valid_602059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602060: Call_ListVirtualNodes_602047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual nodes.
  ## 
  let valid = call_602060.validator(path, query, header, formData, body)
  let scheme = call_602060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602060.url(scheme.get, call_602060.host, call_602060.base,
                         call_602060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602060, url, valid)

proc call*(call_602061: Call_ListVirtualNodes_602047; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualNodes
  ## Returns a list of existing virtual nodes.
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
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual nodes in.
  var path_602062 = newJObject()
  var query_602063 = newJObject()
  add(query_602063, "nextToken", newJString(nextToken))
  add(query_602063, "limit", newJInt(limit))
  add(path_602062, "meshName", newJString(meshName))
  result = call_602061.call(path_602062, query_602063, nil, nil, nil)

var listVirtualNodes* = Call_ListVirtualNodes_602047(name: "listVirtualNodes",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes",
    validator: validate_ListVirtualNodes_602048, base: "/",
    url: url_ListVirtualNodes_602049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualRouter_602097 = ref object of OpenApiRestCall_601389
proc url_CreateVirtualRouter_602099(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVirtualRouter_602098(path: JsonNode; query: JsonNode;
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
  var valid_602100 = path.getOrDefault("meshName")
  valid_602100 = validateParameter(valid_602100, JString, required = true,
                                 default = nil)
  if valid_602100 != nil:
    section.add "meshName", valid_602100
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602101 = header.getOrDefault("X-Amz-Signature")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Signature", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Content-Sha256", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Date")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Date", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Credential")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Credential", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Security-Token")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Security-Token", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Algorithm")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Algorithm", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-SignedHeaders", valid_602107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602109: Call_CreateVirtualRouter_602097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual router within a service mesh.</p>
  ##          <p>Any inbound traffic that your virtual router expects should be specified as a
  ##             <code>listener</code>. </p>
  ##          <p>Virtual routers handle traffic for one or more virtual services within your mesh. After
  ##          you create your virtual router, create and associate routes for your virtual router that
  ##          direct incoming requests to different virtual nodes.</p>
  ## 
  let valid = call_602109.validator(path, query, header, formData, body)
  let scheme = call_602109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602109.url(scheme.get, call_602109.host, call_602109.base,
                         call_602109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602109, url, valid)

proc call*(call_602110: Call_CreateVirtualRouter_602097; meshName: string;
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
  var path_602111 = newJObject()
  var body_602112 = newJObject()
  add(path_602111, "meshName", newJString(meshName))
  if body != nil:
    body_602112 = body
  result = call_602110.call(path_602111, nil, nil, nil, body_602112)

var createVirtualRouter* = Call_CreateVirtualRouter_602097(
    name: "createVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_CreateVirtualRouter_602098, base: "/",
    url: url_CreateVirtualRouter_602099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualRouters_602080 = ref object of OpenApiRestCall_601389
proc url_ListVirtualRouters_602082(protocol: Scheme; host: string; base: string;
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

proc validate_ListVirtualRouters_602081(path: JsonNode; query: JsonNode;
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
  var valid_602083 = path.getOrDefault("meshName")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = nil)
  if valid_602083 != nil:
    section.add "meshName", valid_602083
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
  var valid_602084 = query.getOrDefault("nextToken")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "nextToken", valid_602084
  var valid_602085 = query.getOrDefault("limit")
  valid_602085 = validateParameter(valid_602085, JInt, required = false, default = nil)
  if valid_602085 != nil:
    section.add "limit", valid_602085
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602086 = header.getOrDefault("X-Amz-Signature")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Signature", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Content-Sha256", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Date")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Date", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Credential")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Credential", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Security-Token")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Security-Token", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Algorithm")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Algorithm", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-SignedHeaders", valid_602092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602093: Call_ListVirtualRouters_602080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual routers in a service mesh.
  ## 
  let valid = call_602093.validator(path, query, header, formData, body)
  let scheme = call_602093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602093.url(scheme.get, call_602093.host, call_602093.base,
                         call_602093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602093, url, valid)

proc call*(call_602094: Call_ListVirtualRouters_602080; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualRouters
  ## Returns a list of existing virtual routers in a service mesh.
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
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual routers in.
  var path_602095 = newJObject()
  var query_602096 = newJObject()
  add(query_602096, "nextToken", newJString(nextToken))
  add(query_602096, "limit", newJInt(limit))
  add(path_602095, "meshName", newJString(meshName))
  result = call_602094.call(path_602095, query_602096, nil, nil, nil)

var listVirtualRouters* = Call_ListVirtualRouters_602080(
    name: "listVirtualRouters", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters",
    validator: validate_ListVirtualRouters_602081, base: "/",
    url: url_ListVirtualRouters_602082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVirtualService_602130 = ref object of OpenApiRestCall_601389
proc url_CreateVirtualService_602132(protocol: Scheme; host: string; base: string;
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

proc validate_CreateVirtualService_602131(path: JsonNode; query: JsonNode;
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
  var valid_602133 = path.getOrDefault("meshName")
  valid_602133 = validateParameter(valid_602133, JString, required = true,
                                 default = nil)
  if valid_602133 != nil:
    section.add "meshName", valid_602133
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602134 = header.getOrDefault("X-Amz-Signature")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Signature", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Content-Sha256", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Date")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Date", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Credential")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Credential", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Security-Token")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Security-Token", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Algorithm")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Algorithm", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-SignedHeaders", valid_602140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602142: Call_CreateVirtualService_602130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a virtual service within a service mesh.</p>
  ##          <p>A virtual service is an abstraction of a real service that is provided by a virtual node
  ##          directly or indirectly by means of a virtual router. Dependent services call your virtual
  ##          service by its <code>virtualServiceName</code>, and those requests are routed to the
  ##          virtual node or virtual router that is specified as the provider for the virtual
  ##          service.</p>
  ## 
  let valid = call_602142.validator(path, query, header, formData, body)
  let scheme = call_602142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602142.url(scheme.get, call_602142.host, call_602142.base,
                         call_602142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602142, url, valid)

proc call*(call_602143: Call_CreateVirtualService_602130; meshName: string;
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
  var path_602144 = newJObject()
  var body_602145 = newJObject()
  add(path_602144, "meshName", newJString(meshName))
  if body != nil:
    body_602145 = body
  result = call_602143.call(path_602144, nil, nil, nil, body_602145)

var createVirtualService* = Call_CreateVirtualService_602130(
    name: "createVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_CreateVirtualService_602131, base: "/",
    url: url_CreateVirtualService_602132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVirtualServices_602113 = ref object of OpenApiRestCall_601389
proc url_ListVirtualServices_602115(protocol: Scheme; host: string; base: string;
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

proc validate_ListVirtualServices_602114(path: JsonNode; query: JsonNode;
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
  var valid_602116 = path.getOrDefault("meshName")
  valid_602116 = validateParameter(valid_602116, JString, required = true,
                                 default = nil)
  if valid_602116 != nil:
    section.add "meshName", valid_602116
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
  var valid_602117 = query.getOrDefault("nextToken")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "nextToken", valid_602117
  var valid_602118 = query.getOrDefault("limit")
  valid_602118 = validateParameter(valid_602118, JInt, required = false, default = nil)
  if valid_602118 != nil:
    section.add "limit", valid_602118
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602119 = header.getOrDefault("X-Amz-Signature")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Signature", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Content-Sha256", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Date")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Date", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Credential")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Credential", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Security-Token")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Security-Token", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Algorithm")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Algorithm", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-SignedHeaders", valid_602125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602126: Call_ListVirtualServices_602113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing virtual services in a service mesh.
  ## 
  let valid = call_602126.validator(path, query, header, formData, body)
  let scheme = call_602126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602126.url(scheme.get, call_602126.host, call_602126.base,
                         call_602126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602126, url, valid)

proc call*(call_602127: Call_ListVirtualServices_602113; meshName: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listVirtualServices
  ## Returns a list of existing virtual services in a service mesh.
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
  ##   meshName: string (required)
  ##           : The name of the service mesh to list virtual services in.
  var path_602128 = newJObject()
  var query_602129 = newJObject()
  add(query_602129, "nextToken", newJString(nextToken))
  add(query_602129, "limit", newJInt(limit))
  add(path_602128, "meshName", newJString(meshName))
  result = call_602127.call(path_602128, query_602129, nil, nil, nil)

var listVirtualServices* = Call_ListVirtualServices_602113(
    name: "listVirtualServices", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices",
    validator: validate_ListVirtualServices_602114, base: "/",
    url: url_ListVirtualServices_602115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMesh_602160 = ref object of OpenApiRestCall_601389
proc url_UpdateMesh_602162(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateMesh_602161(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602163 = path.getOrDefault("meshName")
  valid_602163 = validateParameter(valid_602163, JString, required = true,
                                 default = nil)
  if valid_602163 != nil:
    section.add "meshName", valid_602163
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602164 = header.getOrDefault("X-Amz-Signature")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Signature", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Content-Sha256", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Date")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Date", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Credential")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Credential", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Security-Token")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Security-Token", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Algorithm")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Algorithm", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-SignedHeaders", valid_602170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602172: Call_UpdateMesh_602160; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing service mesh.
  ## 
  let valid = call_602172.validator(path, query, header, formData, body)
  let scheme = call_602172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602172.url(scheme.get, call_602172.host, call_602172.base,
                         call_602172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602172, url, valid)

proc call*(call_602173: Call_UpdateMesh_602160; meshName: string; body: JsonNode): Recallable =
  ## updateMesh
  ## Updates an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to update.
  ##   body: JObject (required)
  var path_602174 = newJObject()
  var body_602175 = newJObject()
  add(path_602174, "meshName", newJString(meshName))
  if body != nil:
    body_602175 = body
  result = call_602173.call(path_602174, nil, nil, nil, body_602175)

var updateMesh* = Call_UpdateMesh_602160(name: "updateMesh",
                                      meth: HttpMethod.HttpPut,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_UpdateMesh_602161,
                                      base: "/", url: url_UpdateMesh_602162,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMesh_602146 = ref object of OpenApiRestCall_601389
proc url_DescribeMesh_602148(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeMesh_602147(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602149 = path.getOrDefault("meshName")
  valid_602149 = validateParameter(valid_602149, JString, required = true,
                                 default = nil)
  if valid_602149 != nil:
    section.add "meshName", valid_602149
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_602157: Call_DescribeMesh_602146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing service mesh.
  ## 
  let valid = call_602157.validator(path, query, header, formData, body)
  let scheme = call_602157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602157.url(scheme.get, call_602157.host, call_602157.base,
                         call_602157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602157, url, valid)

proc call*(call_602158: Call_DescribeMesh_602146; meshName: string): Recallable =
  ## describeMesh
  ## Describes an existing service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh to describe.
  var path_602159 = newJObject()
  add(path_602159, "meshName", newJString(meshName))
  result = call_602158.call(path_602159, nil, nil, nil, nil)

var describeMesh* = Call_DescribeMesh_602146(name: "describeMesh",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}", validator: validate_DescribeMesh_602147,
    base: "/", url: url_DescribeMesh_602148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMesh_602176 = ref object of OpenApiRestCall_601389
proc url_DeleteMesh_602178(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteMesh_602177(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602179 = path.getOrDefault("meshName")
  valid_602179 = validateParameter(valid_602179, JString, required = true,
                                 default = nil)
  if valid_602179 != nil:
    section.add "meshName", valid_602179
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_602187: Call_DeleteMesh_602176; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ## 
  let valid = call_602187.validator(path, query, header, formData, body)
  let scheme = call_602187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602187.url(scheme.get, call_602187.host, call_602187.base,
                         call_602187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602187, url, valid)

proc call*(call_602188: Call_DeleteMesh_602176; meshName: string): Recallable =
  ## deleteMesh
  ## <p>Deletes an existing service mesh.</p>
  ##          <p>You must delete all resources (virtual services, routes, virtual routers, and virtual
  ##          nodes) in the service mesh before you can delete the mesh itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete.
  var path_602189 = newJObject()
  add(path_602189, "meshName", newJString(meshName))
  result = call_602188.call(path_602189, nil, nil, nil, nil)

var deleteMesh* = Call_DeleteMesh_602176(name: "deleteMesh",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appmesh.amazonaws.com",
                                      route: "/v20190125/meshes/{meshName}",
                                      validator: validate_DeleteMesh_602177,
                                      base: "/", url: url_DeleteMesh_602178,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_602206 = ref object of OpenApiRestCall_601389
proc url_UpdateRoute_602208(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoute_602207(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to update.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the route resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router that the route is associated with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_602209 = path.getOrDefault("routeName")
  valid_602209 = validateParameter(valid_602209, JString, required = true,
                                 default = nil)
  if valid_602209 != nil:
    section.add "routeName", valid_602209
  var valid_602210 = path.getOrDefault("meshName")
  valid_602210 = validateParameter(valid_602210, JString, required = true,
                                 default = nil)
  if valid_602210 != nil:
    section.add "meshName", valid_602210
  var valid_602211 = path.getOrDefault("virtualRouterName")
  valid_602211 = validateParameter(valid_602211, JString, required = true,
                                 default = nil)
  if valid_602211 != nil:
    section.add "virtualRouterName", valid_602211
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602212 = header.getOrDefault("X-Amz-Signature")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Signature", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Content-Sha256", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Date")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Date", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Credential")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Credential", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Security-Token")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Security-Token", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Algorithm")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Algorithm", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-SignedHeaders", valid_602218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602220: Call_UpdateRoute_602206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing route for a specified service mesh and virtual router.
  ## 
  let valid = call_602220.validator(path, query, header, formData, body)
  let scheme = call_602220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602220.url(scheme.get, call_602220.host, call_602220.base,
                         call_602220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602220, url, valid)

proc call*(call_602221: Call_UpdateRoute_602206; routeName: string; meshName: string;
          body: JsonNode; virtualRouterName: string): Recallable =
  ## updateRoute
  ## Updates an existing route for a specified service mesh and virtual router.
  ##   routeName: string (required)
  ##            : The name of the route to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the route resides in.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router that the route is associated with.
  var path_602222 = newJObject()
  var body_602223 = newJObject()
  add(path_602222, "routeName", newJString(routeName))
  add(path_602222, "meshName", newJString(meshName))
  if body != nil:
    body_602223 = body
  add(path_602222, "virtualRouterName", newJString(virtualRouterName))
  result = call_602221.call(path_602222, nil, nil, nil, body_602223)

var updateRoute* = Call_UpdateRoute_602206(name: "updateRoute",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_UpdateRoute_602207,
                                        base: "/", url: url_UpdateRoute_602208,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRoute_602190 = ref object of OpenApiRestCall_601389
proc url_DescribeRoute_602192(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRoute_602191(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the route resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router that the route is associated with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_602193 = path.getOrDefault("routeName")
  valid_602193 = validateParameter(valid_602193, JString, required = true,
                                 default = nil)
  if valid_602193 != nil:
    section.add "routeName", valid_602193
  var valid_602194 = path.getOrDefault("meshName")
  valid_602194 = validateParameter(valid_602194, JString, required = true,
                                 default = nil)
  if valid_602194 != nil:
    section.add "meshName", valid_602194
  var valid_602195 = path.getOrDefault("virtualRouterName")
  valid_602195 = validateParameter(valid_602195, JString, required = true,
                                 default = nil)
  if valid_602195 != nil:
    section.add "virtualRouterName", valid_602195
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602196 = header.getOrDefault("X-Amz-Signature")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Signature", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Content-Sha256", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Date")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Date", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Credential")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Credential", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Security-Token")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Security-Token", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Algorithm")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Algorithm", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-SignedHeaders", valid_602202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_DescribeRoute_602190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing route.
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602203, url, valid)

proc call*(call_602204: Call_DescribeRoute_602190; routeName: string;
          meshName: string; virtualRouterName: string): Recallable =
  ## describeRoute
  ## Describes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the route resides in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router that the route is associated with.
  var path_602205 = newJObject()
  add(path_602205, "routeName", newJString(routeName))
  add(path_602205, "meshName", newJString(meshName))
  add(path_602205, "virtualRouterName", newJString(virtualRouterName))
  result = call_602204.call(path_602205, nil, nil, nil, nil)

var describeRoute* = Call_DescribeRoute_602190(name: "describeRoute",
    meth: HttpMethod.HttpGet, host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
    validator: validate_DescribeRoute_602191, base: "/", url: url_DescribeRoute_602192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_602224 = ref object of OpenApiRestCall_601389
proc url_DeleteRoute_602226(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoute_602225(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   routeName: JString (required)
  ##            : The name of the route to delete.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the route in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete the route in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `routeName` field"
  var valid_602227 = path.getOrDefault("routeName")
  valid_602227 = validateParameter(valid_602227, JString, required = true,
                                 default = nil)
  if valid_602227 != nil:
    section.add "routeName", valid_602227
  var valid_602228 = path.getOrDefault("meshName")
  valid_602228 = validateParameter(valid_602228, JString, required = true,
                                 default = nil)
  if valid_602228 != nil:
    section.add "meshName", valid_602228
  var valid_602229 = path.getOrDefault("virtualRouterName")
  valid_602229 = validateParameter(valid_602229, JString, required = true,
                                 default = nil)
  if valid_602229 != nil:
    section.add "virtualRouterName", valid_602229
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602230 = header.getOrDefault("X-Amz-Signature")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Signature", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Content-Sha256", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Date")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Date", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Credential")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Credential", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Security-Token")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Security-Token", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Algorithm")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Algorithm", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-SignedHeaders", valid_602236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602237: Call_DeleteRoute_602224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing route.
  ## 
  let valid = call_602237.validator(path, query, header, formData, body)
  let scheme = call_602237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602237.url(scheme.get, call_602237.host, call_602237.base,
                         call_602237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602237, url, valid)

proc call*(call_602238: Call_DeleteRoute_602224; routeName: string; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteRoute
  ## Deletes an existing route.
  ##   routeName: string (required)
  ##            : The name of the route to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the route in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete the route in.
  var path_602239 = newJObject()
  add(path_602239, "routeName", newJString(routeName))
  add(path_602239, "meshName", newJString(meshName))
  add(path_602239, "virtualRouterName", newJString(virtualRouterName))
  result = call_602238.call(path_602239, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_602224(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appmesh.amazonaws.com", route: "/v20190125/meshes/{meshName}/virtualRouter/{virtualRouterName}/routes/{routeName}",
                                        validator: validate_DeleteRoute_602225,
                                        base: "/", url: url_DeleteRoute_602226,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualNode_602255 = ref object of OpenApiRestCall_601389
proc url_UpdateVirtualNode_602257(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVirtualNode_602256(path: JsonNode; query: JsonNode;
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
  var valid_602258 = path.getOrDefault("meshName")
  valid_602258 = validateParameter(valid_602258, JString, required = true,
                                 default = nil)
  if valid_602258 != nil:
    section.add "meshName", valid_602258
  var valid_602259 = path.getOrDefault("virtualNodeName")
  valid_602259 = validateParameter(valid_602259, JString, required = true,
                                 default = nil)
  if valid_602259 != nil:
    section.add "virtualNodeName", valid_602259
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602260 = header.getOrDefault("X-Amz-Signature")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Signature", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Content-Sha256", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Date")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Date", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Credential")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Credential", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Security-Token")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Security-Token", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Algorithm")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Algorithm", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-SignedHeaders", valid_602266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602268: Call_UpdateVirtualNode_602255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual node in a specified service mesh.
  ## 
  let valid = call_602268.validator(path, query, header, formData, body)
  let scheme = call_602268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602268.url(scheme.get, call_602268.host, call_602268.base,
                         call_602268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602268, url, valid)

proc call*(call_602269: Call_UpdateVirtualNode_602255; meshName: string;
          body: JsonNode; virtualNodeName: string): Recallable =
  ## updateVirtualNode
  ## Updates an existing virtual node in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   body: JObject (required)
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to update.
  var path_602270 = newJObject()
  var body_602271 = newJObject()
  add(path_602270, "meshName", newJString(meshName))
  if body != nil:
    body_602271 = body
  add(path_602270, "virtualNodeName", newJString(virtualNodeName))
  result = call_602269.call(path_602270, nil, nil, nil, body_602271)

var updateVirtualNode* = Call_UpdateVirtualNode_602255(name: "updateVirtualNode",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_UpdateVirtualNode_602256, base: "/",
    url: url_UpdateVirtualNode_602257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualNode_602240 = ref object of OpenApiRestCall_601389
proc url_DescribeVirtualNode_602242(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeVirtualNode_602241(path: JsonNode; query: JsonNode;
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
  var valid_602243 = path.getOrDefault("meshName")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = nil)
  if valid_602243 != nil:
    section.add "meshName", valid_602243
  var valid_602244 = path.getOrDefault("virtualNodeName")
  valid_602244 = validateParameter(valid_602244, JString, required = true,
                                 default = nil)
  if valid_602244 != nil:
    section.add "virtualNodeName", valid_602244
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602245 = header.getOrDefault("X-Amz-Signature")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Signature", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Content-Sha256", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Date")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Date", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Credential")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Credential", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Security-Token")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Security-Token", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Algorithm")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Algorithm", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-SignedHeaders", valid_602251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602252: Call_DescribeVirtualNode_602240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual node.
  ## 
  let valid = call_602252.validator(path, query, header, formData, body)
  let scheme = call_602252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602252.url(scheme.get, call_602252.host, call_602252.base,
                         call_602252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602252, url, valid)

proc call*(call_602253: Call_DescribeVirtualNode_602240; meshName: string;
          virtualNodeName: string): Recallable =
  ## describeVirtualNode
  ## Describes an existing virtual node.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual node resides in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to describe.
  var path_602254 = newJObject()
  add(path_602254, "meshName", newJString(meshName))
  add(path_602254, "virtualNodeName", newJString(virtualNodeName))
  result = call_602253.call(path_602254, nil, nil, nil, nil)

var describeVirtualNode* = Call_DescribeVirtualNode_602240(
    name: "describeVirtualNode", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DescribeVirtualNode_602241, base: "/",
    url: url_DescribeVirtualNode_602242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualNode_602272 = ref object of OpenApiRestCall_601389
proc url_DeleteVirtualNode_602274(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVirtualNode_602273(path: JsonNode; query: JsonNode;
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
  var valid_602275 = path.getOrDefault("meshName")
  valid_602275 = validateParameter(valid_602275, JString, required = true,
                                 default = nil)
  if valid_602275 != nil:
    section.add "meshName", valid_602275
  var valid_602276 = path.getOrDefault("virtualNodeName")
  valid_602276 = validateParameter(valid_602276, JString, required = true,
                                 default = nil)
  if valid_602276 != nil:
    section.add "virtualNodeName", valid_602276
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602277 = header.getOrDefault("X-Amz-Signature")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Signature", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Content-Sha256", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Date")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Date", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Credential")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Credential", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Security-Token")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Security-Token", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Algorithm")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Algorithm", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-SignedHeaders", valid_602283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602284: Call_DeleteVirtualNode_602272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ## 
  let valid = call_602284.validator(path, query, header, formData, body)
  let scheme = call_602284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602284.url(scheme.get, call_602284.host, call_602284.base,
                         call_602284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602284, url, valid)

proc call*(call_602285: Call_DeleteVirtualNode_602272; meshName: string;
          virtualNodeName: string): Recallable =
  ## deleteVirtualNode
  ## <p>Deletes an existing virtual node.</p>
  ##          <p>You must delete any virtual services that list a virtual node as a service provider
  ##          before you can delete the virtual node itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual node in.
  ##   virtualNodeName: string (required)
  ##                  : The name of the virtual node to delete.
  var path_602286 = newJObject()
  add(path_602286, "meshName", newJString(meshName))
  add(path_602286, "virtualNodeName", newJString(virtualNodeName))
  result = call_602285.call(path_602286, nil, nil, nil, nil)

var deleteVirtualNode* = Call_DeleteVirtualNode_602272(name: "deleteVirtualNode",
    meth: HttpMethod.HttpDelete, host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualNodes/{virtualNodeName}",
    validator: validate_DeleteVirtualNode_602273, base: "/",
    url: url_DeleteVirtualNode_602274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualRouter_602302 = ref object of OpenApiRestCall_601389
proc url_UpdateVirtualRouter_602304(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVirtualRouter_602303(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_602305 = path.getOrDefault("meshName")
  valid_602305 = validateParameter(valid_602305, JString, required = true,
                                 default = nil)
  if valid_602305 != nil:
    section.add "meshName", valid_602305
  var valid_602306 = path.getOrDefault("virtualRouterName")
  valid_602306 = validateParameter(valid_602306, JString, required = true,
                                 default = nil)
  if valid_602306 != nil:
    section.add "virtualRouterName", valid_602306
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602307 = header.getOrDefault("X-Amz-Signature")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Signature", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Content-Sha256", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Date")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Date", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Credential")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Credential", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Security-Token")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Security-Token", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Algorithm")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Algorithm", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-SignedHeaders", valid_602313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602315: Call_UpdateVirtualRouter_602302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual router in a specified service mesh.
  ## 
  let valid = call_602315.validator(path, query, header, formData, body)
  let scheme = call_602315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602315.url(scheme.get, call_602315.host, call_602315.base,
                         call_602315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602315, url, valid)

proc call*(call_602316: Call_UpdateVirtualRouter_602302; meshName: string;
          body: JsonNode; virtualRouterName: string): Recallable =
  ## updateVirtualRouter
  ## Updates an existing virtual router in a specified service mesh.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   body: JObject (required)
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to update.
  var path_602317 = newJObject()
  var body_602318 = newJObject()
  add(path_602317, "meshName", newJString(meshName))
  if body != nil:
    body_602318 = body
  add(path_602317, "virtualRouterName", newJString(virtualRouterName))
  result = call_602316.call(path_602317, nil, nil, nil, body_602318)

var updateVirtualRouter* = Call_UpdateVirtualRouter_602302(
    name: "updateVirtualRouter", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_UpdateVirtualRouter_602303, base: "/",
    url: url_UpdateVirtualRouter_602304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualRouter_602287 = ref object of OpenApiRestCall_601389
proc url_DescribeVirtualRouter_602289(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeVirtualRouter_602288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual router.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_602290 = path.getOrDefault("meshName")
  valid_602290 = validateParameter(valid_602290, JString, required = true,
                                 default = nil)
  if valid_602290 != nil:
    section.add "meshName", valid_602290
  var valid_602291 = path.getOrDefault("virtualRouterName")
  valid_602291 = validateParameter(valid_602291, JString, required = true,
                                 default = nil)
  if valid_602291 != nil:
    section.add "virtualRouterName", valid_602291
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602292 = header.getOrDefault("X-Amz-Signature")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Signature", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Content-Sha256", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Date")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Date", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Credential")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Credential", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Security-Token")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Security-Token", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Algorithm")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Algorithm", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-SignedHeaders", valid_602298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602299: Call_DescribeVirtualRouter_602287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual router.
  ## 
  let valid = call_602299.validator(path, query, header, formData, body)
  let scheme = call_602299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602299.url(scheme.get, call_602299.host, call_602299.base,
                         call_602299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602299, url, valid)

proc call*(call_602300: Call_DescribeVirtualRouter_602287; meshName: string;
          virtualRouterName: string): Recallable =
  ## describeVirtualRouter
  ## Describes an existing virtual router.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual router resides in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to describe.
  var path_602301 = newJObject()
  add(path_602301, "meshName", newJString(meshName))
  add(path_602301, "virtualRouterName", newJString(virtualRouterName))
  result = call_602300.call(path_602301, nil, nil, nil, nil)

var describeVirtualRouter* = Call_DescribeVirtualRouter_602287(
    name: "describeVirtualRouter", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DescribeVirtualRouter_602288, base: "/",
    url: url_DescribeVirtualRouter_602289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualRouter_602319 = ref object of OpenApiRestCall_601389
proc url_DeleteVirtualRouter_602321(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVirtualRouter_602320(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual router in.
  ##   virtualRouterName: JString (required)
  ##                    : The name of the virtual router to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `meshName` field"
  var valid_602322 = path.getOrDefault("meshName")
  valid_602322 = validateParameter(valid_602322, JString, required = true,
                                 default = nil)
  if valid_602322 != nil:
    section.add "meshName", valid_602322
  var valid_602323 = path.getOrDefault("virtualRouterName")
  valid_602323 = validateParameter(valid_602323, JString, required = true,
                                 default = nil)
  if valid_602323 != nil:
    section.add "virtualRouterName", valid_602323
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602324 = header.getOrDefault("X-Amz-Signature")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Signature", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Content-Sha256", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Date")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Date", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Credential")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Credential", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Security-Token")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Security-Token", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Algorithm")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Algorithm", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-SignedHeaders", valid_602330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602331: Call_DeleteVirtualRouter_602319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ## 
  let valid = call_602331.validator(path, query, header, formData, body)
  let scheme = call_602331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602331.url(scheme.get, call_602331.host, call_602331.base,
                         call_602331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602331, url, valid)

proc call*(call_602332: Call_DeleteVirtualRouter_602319; meshName: string;
          virtualRouterName: string): Recallable =
  ## deleteVirtualRouter
  ## <p>Deletes an existing virtual router.</p>
  ##          <p>You must delete any routes associated with the virtual router before you can delete the
  ##          router itself.</p>
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual router in.
  ##   virtualRouterName: string (required)
  ##                    : The name of the virtual router to delete.
  var path_602333 = newJObject()
  add(path_602333, "meshName", newJString(meshName))
  add(path_602333, "virtualRouterName", newJString(virtualRouterName))
  result = call_602332.call(path_602333, nil, nil, nil, nil)

var deleteVirtualRouter* = Call_DeleteVirtualRouter_602319(
    name: "deleteVirtualRouter", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualRouters/{virtualRouterName}",
    validator: validate_DeleteVirtualRouter_602320, base: "/",
    url: url_DeleteVirtualRouter_602321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualService_602349 = ref object of OpenApiRestCall_601389
proc url_UpdateVirtualService_602351(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateVirtualService_602350(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing virtual service in a specified service mesh.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to update.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual service resides in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualServiceName` field"
  var valid_602352 = path.getOrDefault("virtualServiceName")
  valid_602352 = validateParameter(valid_602352, JString, required = true,
                                 default = nil)
  if valid_602352 != nil:
    section.add "virtualServiceName", valid_602352
  var valid_602353 = path.getOrDefault("meshName")
  valid_602353 = validateParameter(valid_602353, JString, required = true,
                                 default = nil)
  if valid_602353 != nil:
    section.add "meshName", valid_602353
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602354 = header.getOrDefault("X-Amz-Signature")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Signature", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Content-Sha256", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Date")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Date", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Credential")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Credential", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Security-Token")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Security-Token", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Algorithm")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Algorithm", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-SignedHeaders", valid_602360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602362: Call_UpdateVirtualService_602349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing virtual service in a specified service mesh.
  ## 
  let valid = call_602362.validator(path, query, header, formData, body)
  let scheme = call_602362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602362.url(scheme.get, call_602362.host, call_602362.base,
                         call_602362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602362, url, valid)

proc call*(call_602363: Call_UpdateVirtualService_602349;
          virtualServiceName: string; meshName: string; body: JsonNode): Recallable =
  ## updateVirtualService
  ## Updates an existing virtual service in a specified service mesh.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to update.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  ##   body: JObject (required)
  var path_602364 = newJObject()
  var body_602365 = newJObject()
  add(path_602364, "virtualServiceName", newJString(virtualServiceName))
  add(path_602364, "meshName", newJString(meshName))
  if body != nil:
    body_602365 = body
  result = call_602363.call(path_602364, nil, nil, nil, body_602365)

var updateVirtualService* = Call_UpdateVirtualService_602349(
    name: "updateVirtualService", meth: HttpMethod.HttpPut,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_UpdateVirtualService_602350, base: "/",
    url: url_UpdateVirtualService_602351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualService_602334 = ref object of OpenApiRestCall_601389
proc url_DescribeVirtualService_602336(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeVirtualService_602335(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing virtual service.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to describe.
  ##   meshName: JString (required)
  ##           : The name of the service mesh that the virtual service resides in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualServiceName` field"
  var valid_602337 = path.getOrDefault("virtualServiceName")
  valid_602337 = validateParameter(valid_602337, JString, required = true,
                                 default = nil)
  if valid_602337 != nil:
    section.add "virtualServiceName", valid_602337
  var valid_602338 = path.getOrDefault("meshName")
  valid_602338 = validateParameter(valid_602338, JString, required = true,
                                 default = nil)
  if valid_602338 != nil:
    section.add "meshName", valid_602338
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602339 = header.getOrDefault("X-Amz-Signature")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Signature", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Content-Sha256", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Date")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Date", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Credential")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Credential", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-Security-Token")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-Security-Token", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Algorithm")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Algorithm", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-SignedHeaders", valid_602345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602346: Call_DescribeVirtualService_602334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing virtual service.
  ## 
  let valid = call_602346.validator(path, query, header, formData, body)
  let scheme = call_602346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602346.url(scheme.get, call_602346.host, call_602346.base,
                         call_602346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602346, url, valid)

proc call*(call_602347: Call_DescribeVirtualService_602334;
          virtualServiceName: string; meshName: string): Recallable =
  ## describeVirtualService
  ## Describes an existing virtual service.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to describe.
  ##   meshName: string (required)
  ##           : The name of the service mesh that the virtual service resides in.
  var path_602348 = newJObject()
  add(path_602348, "virtualServiceName", newJString(virtualServiceName))
  add(path_602348, "meshName", newJString(meshName))
  result = call_602347.call(path_602348, nil, nil, nil, nil)

var describeVirtualService* = Call_DescribeVirtualService_602334(
    name: "describeVirtualService", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DescribeVirtualService_602335, base: "/",
    url: url_DescribeVirtualService_602336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualService_602366 = ref object of OpenApiRestCall_601389
proc url_DeleteVirtualService_602368(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVirtualService_602367(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing virtual service.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   virtualServiceName: JString (required)
  ##                     : The name of the virtual service to delete.
  ##   meshName: JString (required)
  ##           : The name of the service mesh to delete the virtual service in.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `virtualServiceName` field"
  var valid_602369 = path.getOrDefault("virtualServiceName")
  valid_602369 = validateParameter(valid_602369, JString, required = true,
                                 default = nil)
  if valid_602369 != nil:
    section.add "virtualServiceName", valid_602369
  var valid_602370 = path.getOrDefault("meshName")
  valid_602370 = validateParameter(valid_602370, JString, required = true,
                                 default = nil)
  if valid_602370 != nil:
    section.add "meshName", valid_602370
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602371 = header.getOrDefault("X-Amz-Signature")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Signature", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Content-Sha256", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Date")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Date", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Credential")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Credential", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Security-Token")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Security-Token", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Algorithm")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Algorithm", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-SignedHeaders", valid_602377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602378: Call_DeleteVirtualService_602366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing virtual service.
  ## 
  let valid = call_602378.validator(path, query, header, formData, body)
  let scheme = call_602378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602378.url(scheme.get, call_602378.host, call_602378.base,
                         call_602378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602378, url, valid)

proc call*(call_602379: Call_DeleteVirtualService_602366;
          virtualServiceName: string; meshName: string): Recallable =
  ## deleteVirtualService
  ## Deletes an existing virtual service.
  ##   virtualServiceName: string (required)
  ##                     : The name of the virtual service to delete.
  ##   meshName: string (required)
  ##           : The name of the service mesh to delete the virtual service in.
  var path_602380 = newJObject()
  add(path_602380, "virtualServiceName", newJString(virtualServiceName))
  add(path_602380, "meshName", newJString(meshName))
  result = call_602379.call(path_602380, nil, nil, nil, nil)

var deleteVirtualService* = Call_DeleteVirtualService_602366(
    name: "deleteVirtualService", meth: HttpMethod.HttpDelete,
    host: "appmesh.amazonaws.com",
    route: "/v20190125/meshes/{meshName}/virtualServices/{virtualServiceName}",
    validator: validate_DeleteVirtualService_602367, base: "/",
    url: url_DeleteVirtualService_602368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602381 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602383(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602382(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List the tags for an App Mesh resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
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
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource to list the tags for.
  section = newJObject()
  var valid_602384 = query.getOrDefault("nextToken")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "nextToken", valid_602384
  var valid_602385 = query.getOrDefault("limit")
  valid_602385 = validateParameter(valid_602385, JInt, required = false, default = nil)
  if valid_602385 != nil:
    section.add "limit", valid_602385
  assert query != nil,
        "query argument is necessary due to required `resourceArn` field"
  var valid_602386 = query.getOrDefault("resourceArn")
  valid_602386 = validateParameter(valid_602386, JString, required = true,
                                 default = nil)
  if valid_602386 != nil:
    section.add "resourceArn", valid_602386
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602387 = header.getOrDefault("X-Amz-Signature")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Signature", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Content-Sha256", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-Date")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Date", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Credential")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Credential", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Security-Token")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Security-Token", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Algorithm")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Algorithm", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-SignedHeaders", valid_602393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602394: Call_ListTagsForResource_602381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an App Mesh resource.
  ## 
  let valid = call_602394.validator(path, query, header, formData, body)
  let scheme = call_602394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602394.url(scheme.get, call_602394.host, call_602394.base,
                         call_602394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602394, url, valid)

proc call*(call_602395: Call_ListTagsForResource_602381; resourceArn: string;
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listTagsForResource
  ## List the tags for an App Mesh resource.
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
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource to list the tags for.
  var query_602396 = newJObject()
  add(query_602396, "nextToken", newJString(nextToken))
  add(query_602396, "limit", newJInt(limit))
  add(query_602396, "resourceArn", newJString(resourceArn))
  result = call_602395.call(nil, query_602396, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602381(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appmesh.amazonaws.com", route: "/v20190125/tags#resourceArn",
    validator: validate_ListTagsForResource_602382, base: "/",
    url: url_ListTagsForResource_602383, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602397 = ref object of OpenApiRestCall_601389
proc url_TagResource_602399(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602398(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602400 = query.getOrDefault("resourceArn")
  valid_602400 = validateParameter(valid_602400, JString, required = true,
                                 default = nil)
  if valid_602400 != nil:
    section.add "resourceArn", valid_602400
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602401 = header.getOrDefault("X-Amz-Signature")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Signature", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Content-Sha256", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Date")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Date", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Credential")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Credential", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Security-Token")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Security-Token", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Algorithm")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Algorithm", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-SignedHeaders", valid_602407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602409: Call_TagResource_602397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ## 
  let valid = call_602409.validator(path, query, header, formData, body)
  let scheme = call_602409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602409.url(scheme.get, call_602409.host, call_602409.base,
                         call_602409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602409, url, valid)

proc call*(call_602410: Call_TagResource_602397; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>.
  ##          If existing tags on a resource aren't specified in the request parameters, they aren't
  ##          changed. When a resource is deleted, the tags associated with that resource are also
  ##          deleted.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to add tags to.
  var query_602411 = newJObject()
  var body_602412 = newJObject()
  if body != nil:
    body_602412 = body
  add(query_602411, "resourceArn", newJString(resourceArn))
  result = call_602410.call(nil, query_602411, nil, nil, body_602412)

var tagResource* = Call_TagResource_602397(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "appmesh.amazonaws.com",
                                        route: "/v20190125/tag#resourceArn",
                                        validator: validate_TagResource_602398,
                                        base: "/", url: url_TagResource_602399,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602413 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602415(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602414(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602416 = query.getOrDefault("resourceArn")
  valid_602416 = validateParameter(valid_602416, JString, required = true,
                                 default = nil)
  if valid_602416 != nil:
    section.add "resourceArn", valid_602416
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602417 = header.getOrDefault("X-Amz-Signature")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Signature", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Content-Sha256", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Date")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Date", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Credential")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Credential", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Security-Token")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Security-Token", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Algorithm")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Algorithm", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-SignedHeaders", valid_602423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602425: Call_UntagResource_602413; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_602425.validator(path, query, header, formData, body)
  let scheme = call_602425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602425.url(scheme.get, call_602425.host, call_602425.base,
                         call_602425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602425, url, valid)

proc call*(call_602426: Call_UntagResource_602413; body: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to delete tags from.
  var query_602427 = newJObject()
  var body_602428 = newJObject()
  if body != nil:
    body_602428 = body
  add(query_602427, "resourceArn", newJString(resourceArn))
  result = call_602426.call(nil, query_602427, nil, nil, body_602428)

var untagResource* = Call_UntagResource_602413(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "appmesh.amazonaws.com",
    route: "/v20190125/untag#resourceArn", validator: validate_UntagResource_602414,
    base: "/", url: url_UntagResource_602415, schemes: {Scheme.Https, Scheme.Http})
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
